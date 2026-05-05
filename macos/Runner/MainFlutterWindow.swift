import Cocoa
import ApplicationServices
import Carbon.HIToolbox
import CoreWLAN
import EventKit
import FlutterMacOS
import IOBluetooth
import IOKit
import IOKit.pwr_mgt
import LaunchAtLogin
import Network

private let lockbarChannelName = "lockbar/macos"
private let lockbarPermissionRequestKey = "lockbar.hasRequestedPermission"
private let suggestionPanelWidth: CGFloat = 420
private let keepAwakeReason = "LockBar keep-awake" as CFString
private let automaticAppearancePreferenceKey =
  "AppleInterfaceStyleSwitchesAutomatically" as CFString
private let interfaceStylePreferenceKey = "AppleInterfaceStyle" as CFString
private let appearanceNotificationName = "AppleInterfaceThemeChangedNotification"

private enum KeepAwakeAssertionError: Error {
  case creationFailed(type: String, code: IOReturn)
}

func appearanceModeFromPreferences(
  automaticSwitches: Bool?,
  interfaceStyle: String?
) -> String {
  if automaticSwitches == true {
    return "automatic"
  }
  if interfaceStyle?.caseInsensitiveCompare("Dark") == .orderedSame {
    return "dark"
  }
  return "light"
}

private final class SuggestionPanel: NSPanel {
  var onCancel: (() -> Void)?

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }

  override func cancelOperation(_ sender: Any?) {
    onCancel?()
  }
}

private final class HoverTrackingView: NSView {
  var onHoverChanged: ((Bool) -> Void)?
  private var trackingArea: NSTrackingArea?

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let trackingArea {
      removeTrackingArea(trackingArea)
    }

    let nextArea = NSTrackingArea(
      rect: bounds,
      options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(nextArea)
    trackingArea = nextArea
  }

  override func mouseEntered(with event: NSEvent) {
    super.mouseEntered(with: event)
    onHoverChanged?(true)
  }

  override func mouseExited(with event: NSEvent) {
    super.mouseExited(with: event)
    onHoverChanged?(false)
  }
}

private struct SuggestionPanelPayload {
  let title: String
  let headline: String
  let reason: String
  let lockNowLabel: String
  let laterLabel: String
  let notNowLabel: String
  let whyActionLabel: String
  let whySectionTitle: String
  let usedSignalLabels: [String]

  init?(arguments: [String: Any]?) {
    guard let arguments,
          let title = arguments["title"] as? String,
          let headline = arguments["headline"] as? String,
          let reason = arguments["reason"] as? String,
          let lockNowLabel = arguments["lockNowLabel"] as? String,
          let laterLabel = arguments["laterLabel"] as? String,
          let notNowLabel = arguments["notNowLabel"] as? String,
          let whyActionLabel = arguments["whyActionLabel"] as? String,
          let whySectionTitle = arguments["whySectionTitle"] as? String
    else {
      return nil
    }

    self.title = title
    self.headline = headline
    self.reason = reason
    self.lockNowLabel = lockNowLabel
    self.laterLabel = laterLabel
    self.notNowLabel = notNowLabel
    self.whyActionLabel = whyActionLabel
    self.whySectionTitle = whySectionTitle
    self.usedSignalLabels = arguments["usedSignalLabels"] as? [String] ?? []
  }
}

private final class SuggestionPanelController: NSObject {
  private let onAction: (String) -> Void
  private let panel: SuggestionPanel
  private let rootView = HoverTrackingView()
  private let stackView = NSStackView()
  private let titleLabel = NSTextField(labelWithString: "")
  private let headlineLabel = NSTextField(wrappingLabelWithString: "")
  private let reasonLabel = NSTextField(wrappingLabelWithString: "")
  private let detailsToggleButton = NSButton(title: "", target: nil, action: nil)
  private let detailsTitleLabel = NSTextField(labelWithString: "")
  private let detailsStackView = NSStackView()
  private let signalsContainer = NSStackView()
  private let lockNowButton = NSButton(title: "", target: nil, action: nil)
  private let laterButton = NSButton(title: "", target: nil, action: nil)
  private let notNowButton = NSButton(title: "", target: nil, action: nil)

  private var autoHideTimer: Timer?
  private var isHovering = false
  private var isDetailsVisible = false
  private var currentSignalLabels: [String] = []

  init(onAction: @escaping (String) -> Void) {
    self.onAction = onAction
    self.panel = SuggestionPanel(
      contentRect: NSRect(x: 0, y: 0, width: suggestionPanelWidth, height: 230),
      styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    super.init()
    configurePanel()
    configureContent()
  }

  func show(payload: SuggestionPanelPayload) {
    update(payload: payload, animated: false)
    positionPanel(animated: false)
    panel.orderFrontRegardless()
    scheduleAutoHide()
  }

  func update(payload: SuggestionPanelPayload, animated: Bool = false) {
    titleLabel.stringValue = payload.title
    headlineLabel.stringValue = payload.headline
    reasonLabel.stringValue = payload.reason
    lockNowButton.title = payload.lockNowLabel
    laterButton.title = payload.laterLabel
    notNowButton.title = payload.notNowLabel
    detailsToggleButton.title = payload.whyActionLabel
    detailsTitleLabel.stringValue = payload.whySectionTitle
    currentSignalLabels = payload.usedSignalLabels

    rebuildSignalLabels()
    detailsToggleButton.isHidden = payload.usedSignalLabels.isEmpty
    if payload.usedSignalLabels.isEmpty {
      isDetailsVisible = false
    }
    detailsStackView.isHidden = !isDetailsVisible

    layoutPanel(animated: animated)
    if panel.isVisible && !isHovering && !isDetailsVisible {
      scheduleAutoHide()
    }
  }

  func hide() {
    cancelAutoHide()
    panel.orderOut(nil)
  }

  private func configurePanel() {
    panel.isReleasedWhenClosed = false
    panel.hasShadow = true
    panel.isFloatingPanel = false
    panel.level = .floating
    panel.collectionBehavior = [.moveToActiveSpace, .transient]
    panel.titleVisibility = .hidden
    panel.titlebarAppearsTransparent = true
    panel.standardWindowButton(.closeButton)?.isHidden = true
    panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
    panel.standardWindowButton(.zoomButton)?.isHidden = true
    panel.isMovableByWindowBackground = false
    panel.backgroundColor = .windowBackgroundColor
    panel.animationBehavior = .utilityWindow
  }

  private func configureContent() {
    rootView.translatesAutoresizingMaskIntoConstraints = false
    rootView.wantsLayer = true
    rootView.layer?.cornerRadius = 14
    rootView.layer?.borderWidth = 1
    rootView.layer?.borderColor = NSColor.separatorColor.cgColor
    rootView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    rootView.onHoverChanged = { [weak self] hovering in
      guard let self else { return }
      self.isHovering = hovering
      if hovering {
        self.cancelAutoHide()
      } else if self.panel.isVisible && !self.isDetailsVisible {
        self.scheduleAutoHide()
      }
    }

    stackView.orientation = .vertical
    stackView.spacing = 12
    stackView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
    titleLabel.textColor = .secondaryLabelColor

    headlineLabel.font = .systemFont(ofSize: 18, weight: .semibold)
    headlineLabel.maximumNumberOfLines = 3
    headlineLabel.lineBreakMode = .byWordWrapping

    reasonLabel.font = .systemFont(ofSize: 13)
    reasonLabel.textColor = .secondaryLabelColor
    reasonLabel.maximumNumberOfLines = 4
    reasonLabel.lineBreakMode = .byWordWrapping

    detailsToggleButton.target = self
    detailsToggleButton.action = #selector(toggleDetails)
    detailsToggleButton.bezelStyle = .inline
    detailsToggleButton.setButtonType(.momentaryPushIn)

    detailsTitleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
    detailsTitleLabel.textColor = .secondaryLabelColor

    detailsStackView.orientation = .vertical
    detailsStackView.spacing = 8
    detailsStackView.alignment = .leading
    detailsStackView.isHidden = true

    signalsContainer.orientation = .vertical
    signalsContainer.spacing = 4
    signalsContainer.alignment = .leading

    let actionRow = NSStackView()
    actionRow.orientation = .horizontal
    actionRow.spacing = 8
    actionRow.distribution = .fillProportionally

    lockNowButton.target = self
    lockNowButton.action = #selector(handleLockNow)
    lockNowButton.bezelStyle = .rounded
    lockNowButton.keyEquivalent = "\r"

    laterButton.target = self
    laterButton.action = #selector(handleLater)
    laterButton.bezelStyle = .rounded

    notNowButton.target = self
    notNowButton.action = #selector(handleNotNow)
    notNowButton.bezelStyle = .recessed

    actionRow.addArrangedSubview(lockNowButton)
    actionRow.addArrangedSubview(laterButton)
    actionRow.addArrangedSubview(notNowButton)

    detailsStackView.addArrangedSubview(detailsTitleLabel)
    detailsStackView.addArrangedSubview(signalsContainer)

    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(headlineLabel)
    stackView.addArrangedSubview(reasonLabel)
    stackView.addArrangedSubview(detailsToggleButton)
    stackView.addArrangedSubview(detailsStackView)
    stackView.addArrangedSubview(actionRow)

    rootView.addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 18),
      stackView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -18),
      stackView.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 18),
      stackView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -18),
      rootView.widthAnchor.constraint(equalToConstant: suggestionPanelWidth),
    ])

    panel.contentView = rootView
  }

  private func rebuildSignalLabels() {
    signalsContainer.arrangedSubviews.forEach { view in
      signalsContainer.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    for label in currentSignalLabels {
      let textField = NSTextField(wrappingLabelWithString: "• \(label)")
      textField.font = .systemFont(ofSize: 12)
      textField.textColor = .secondaryLabelColor
      textField.maximumNumberOfLines = 2
      signalsContainer.addArrangedSubview(textField)
    }
  }

  private func layoutPanel(animated: Bool) {
    rootView.layoutSubtreeIfNeeded()
    let targetSize = rootView.fittingSize
    let clampedHeight = max(targetSize.height, 190)
    let frame = panel.frameRect(forContentRect: NSRect(
      x: 0,
      y: 0,
      width: suggestionPanelWidth,
      height: clampedHeight
    ))

    var nextFrame = panel.frame
    nextFrame.size = frame.size
    nextFrame.origin = panelOrigin(for: frame.size)
    panel.setFrame(nextFrame, display: true, animate: animated)
  }

  private func positionPanel(animated: Bool) {
    layoutPanel(animated: animated)
  }

  private func panelOrigin(for size: NSSize) -> NSPoint {
    guard let screenFrame = NSScreen.main?.visibleFrame else {
      return NSPoint(x: 0, y: 0)
    }

    let x = screenFrame.maxX - size.width - 16
    let y = screenFrame.maxY - size.height - 10
    return NSPoint(x: x, y: y)
  }

  private func scheduleAutoHide() {
    cancelAutoHide()
    autoHideTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: false) {
      [weak self] _ in
      guard let self else { return }
      self.panel.orderOut(nil)
      self.onAction("hide")
    }
    if let autoHideTimer {
      RunLoop.main.add(autoHideTimer, forMode: .common)
    }
  }

  private func cancelAutoHide() {
    autoHideTimer?.invalidate()
    autoHideTimer = nil
  }

  private func closeForAction(_ action: String) {
    hide()
    onAction(action)
  }

  @objc private func handleLockNow() {
    closeForAction("lockNow")
  }

  @objc private func handleLater() {
    closeForAction("later")
  }

  @objc private func handleNotNow() {
    closeForAction("notNow")
  }

  @objc private func toggleDetails() {
    isDetailsVisible.toggle()
    detailsStackView.isHidden = !isDetailsVisible
    if isDetailsVisible {
      cancelAutoHide()
    } else if !isHovering {
      scheduleAutoHide()
    }
    layoutPanel(animated: true)
  }
}

struct BluetoothBatteryRecord {
  let names: Set<String>
  let addresses: Set<String>
  let batteryLevel: Int?
  let leftBatteryLevel: Int?
  let rightBatteryLevel: Int?
  let caseBatteryLevel: Int?

  var hasBatteryLevel: Bool {
    batteryLevel != nil ||
      leftBatteryLevel != nil ||
      rightBatteryLevel != nil ||
      caseBatteryLevel != nil
  }

  var signature: String {
    let battery = batteryLevel.map { String($0) } ?? "none"
    let leftBattery = leftBatteryLevel.map { String($0) } ?? "none"
    let rightBattery = rightBatteryLevel.map { String($0) } ?? "none"
    let caseBattery = caseBatteryLevel.map { String($0) } ?? "none"
    let parts: [String] = [
      names.sorted().joined(separator: ","),
      addresses.sorted().joined(separator: ","),
      battery,
      leftBattery,
      rightBattery,
      caseBattery,
    ]
    return parts.joined(separator: "|")
  }
}

func bluetoothBatteryRecordsFromSystemProfilerJSON(_ data: Data) -> [BluetoothBatteryRecord] {
  guard let rootObject = try? JSONSerialization.jsonObject(with: data),
        let root = rootObject as? [String: Any],
        let sections = root["SPBluetoothDataType"] as? [[String: Any]]
  else {
    return []
  }

  var records: [BluetoothBatteryRecord] = []

  for section in sections {
    let connectedDevices = section["device_connected"] as? [[String: Any]] ?? []
    for deviceWrapper in connectedDevices {
      for (rawName, rawProperties) in deviceWrapper {
        guard let properties = rawProperties as? [String: Any] else {
          continue
        }

        let displayName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let names = Set([displayName].map(normalizeBluetoothName).filter { !$0.isEmpty })
        let addresses = Set(bluetoothStringValues(
          from: properties,
          keys: ["device_address", "device_Address"]
        ).map(normalizeBluetoothAddress).filter { !$0.isEmpty })

        let record = BluetoothBatteryRecord(
          names: names,
          addresses: addresses,
          batteryLevel: bluetoothBatteryLevel(
            from: properties,
            keys: [
              "device_batteryLevelMain",
              "device_batteryLevel",
              "device_batteryLevelCombined",
            ]
          ),
          leftBatteryLevel: bluetoothBatteryLevel(
            from: properties,
            keys: [
              "device_batteryLevelLeft",
              "device_batteryLevelLeftBud",
              "device_batteryLevelL",
            ]
          ),
          rightBatteryLevel: bluetoothBatteryLevel(
            from: properties,
            keys: [
              "device_batteryLevelRight",
              "device_batteryLevelRightBud",
              "device_batteryLevelR",
            ]
          ),
          caseBatteryLevel: bluetoothBatteryLevel(
            from: properties,
            keys: [
              "device_batteryLevelCase",
              "device_batteryLevelCasePercent",
            ]
          )
        )

        if record.hasBatteryLevel && (!record.names.isEmpty || !record.addresses.isEmpty) {
          records.append(record)
        }
      }
    }
  }

  return records
}

func bluetoothStringValues(from properties: [String: Any], keys: [String]) -> [String] {
  keys.compactMap { key in
    if let value = properties[key] as? String {
      return value
    }
    if let value = properties[key] as? Data {
      return String(data: value, encoding: .utf8)
    }
    if let value = properties[key] as? NSNumber {
      return value.stringValue
    }
    return nil
  }
}

func bluetoothBatteryLevel(from properties: [String: Any], keys: [String]) -> Int? {
  for key in keys {
    if let level = parseBluetoothBatteryLevel(properties[key]) {
      return level
    }
  }
  return nil
}

func parseBluetoothBatteryLevel(_ value: Any?) -> Int? {
  if value is NSNull {
    return nil
  }

  if let number = value as? NSNumber {
    let doubleValue = number.doubleValue
    let level = doubleValue > 0 && doubleValue < 1
      ? Int((doubleValue * 100).rounded())
      : number.intValue
    return (0...100).contains(level) ? level : nil
  }

  if let string = value as? String {
    let cleaned = string
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "%", with: "")
    if let level = Int(cleaned), (0...100).contains(level) {
      return level
    }
  }

  return nil
}

func normalizeBluetoothName(_ value: String?) -> String {
  (value ?? "")
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .lowercased()
}

func normalizeBluetoothAddress(_ value: String?) -> String {
  (value ?? "")
    .lowercased()
    .filter { $0.isLetter || $0.isNumber }
}

private struct BluetoothBatteryLevels {
  var batteryLevel: Int?
  var leftBatteryLevel: Int?
  var rightBatteryLevel: Int?
  var caseBatteryLevel: Int?

  var hasBatteryLevel: Bool {
    batteryLevel != nil ||
      leftBatteryLevel != nil ||
      rightBatteryLevel != nil ||
      caseBatteryLevel != nil
  }

  mutating func merge(_ record: BluetoothBatteryRecord) {
    batteryLevel = batteryLevel ?? record.batteryLevel
    leftBatteryLevel = leftBatteryLevel ?? record.leftBatteryLevel
    rightBatteryLevel = rightBatteryLevel ?? record.rightBatteryLevel
    caseBatteryLevel = caseBatteryLevel ?? record.caseBatteryLevel
  }
}

class MainFlutterWindow: NSWindow {
  private let calendarStore = EKEventStore()
  private let isoFormatter = ISO8601DateFormatter()
  private let networkMonitor = NWPathMonitor()
  private let networkMonitorQueue = DispatchQueue(label: "lockbar.network-monitor")
  private let bluetoothBatteryQueue = DispatchQueue(label: "lockbar.bluetooth-battery")
  private var networkReachable = false
  private var platformChannel: FlutterMethodChannel?
  private var keepAwakeAssertionIDs: [IOPMAssertionID] = []
  private var keepAwakeStopTimer: DispatchSourceTimer?
  private lazy var suggestionPanelController = SuggestionPanelController {
    [weak self] action in
    self?.emitSuggestionPanelAction(action)
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let messenger = flutterViewController.engine.binaryMessenger
    configureLaunchAtStartupChannel(binaryMessenger: messenger)
    configureLockbarChannel(binaryMessenger: messenger)
    startNetworkMonitor()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  deinit {
    _ = stopKeepAwake()
    networkMonitor.cancel()
  }

  private func emitSuggestionPanelAction(_ action: String) {
    platformChannel?.invokeMethod("suggestionPanelAction", arguments: ["action": action])
  }

  private func startNetworkMonitor() {
    networkMonitor.pathUpdateHandler = { [weak self] path in
      self?.networkReachable = path.status == .satisfied
    }
    networkMonitor.start(queue: networkMonitorQueue)
  }

  private func configureLaunchAtStartupChannel(binaryMessenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "launch_at_startup", binaryMessenger: binaryMessenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "launchAtStartupIsEnabled":
          result(LaunchAtLogin.isEnabled)
        case "launchAtStartupSetEnabled":
          if let arguments = call.arguments as? [String: Any],
             let enabled = arguments["setEnabledValue"] as? Bool
          {
            LaunchAtLogin.isEnabled = enabled
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private func configureLockbarChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: lockbarChannelName, binaryMessenger: binaryMessenger)
    platformChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "window_unavailable",
            message: "The main window was released before the platform call completed.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "getPermissionState":
        result(self.currentPermissionState())
      case "requestPermission":
        result(self.requestPermission())
      case "lockNow":
        result(self.lockNow())
      case "openAccessibilitySettings":
        self.openAccessibilitySettings()
        result(nil)
      case "activateApp":
        self.activateApp()
        result(nil)
      case "quitApp":
        _ = self.stopKeepAwake()
        NSApp.terminate(nil)
        result(nil)
      case "setNativeLocale":
        if let arguments = call.arguments as? [String: Any] {
          self.updateNativeLocale(localeTag: arguments["localeTag"] as? String)
        } else {
          self.updateNativeLocale(localeTag: nil)
        }
        result(nil)
      case "getAppInfo":
        result(self.appInfo())
      case "getAppearanceMode":
        result(self.currentAppearanceMode())
      case "setAppearanceMode":
        self.setAppearanceMode(arguments: call.arguments as? [String: Any], result: result)
      case "getSystemContextSnapshot":
        let arguments = call.arguments as? [String: Any]
        self.getSystemContextSnapshot(arguments: arguments, result: result)
      case "getCalendarPermissionState":
        result(self.currentCalendarPermissionState())
      case "requestCalendarAccess":
        self.requestCalendarAccess(result: result)
      case "startKeepAwake":
        self.startKeepAwake(arguments: call.arguments as? [String: Any], result: result)
      case "startKeepAwakeIndefinitely":
        self.startKeepAwakeIndefinitely(result: result)
      case "getKeepAwakeState":
        result(self.keepAwakeState())
      case "stopKeepAwake":
        result(self.stopKeepAwake())
      case "getBluetoothBatteryDevices":
        self.bluetoothBatteryQueue.async {
          let devices = self.bluetoothBatteryDevices()
          DispatchQueue.main.async {
            result(devices)
          }
        }
      case "showSuggestionPanel":
        self.handleSuggestionPanel(arguments: call.arguments as? [String: Any], isUpdate: false)
        result(nil)
      case "updateSuggestionPanel":
        self.handleSuggestionPanel(arguments: call.arguments as? [String: Any], isUpdate: true)
        result(nil)
      case "hideSuggestionPanel":
        self.suggestionPanelController.hide()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func currentPermissionState() -> String {
    if CGPreflightPostEventAccess() {
      return "granted"
    }

    let hasRequestedPermission = UserDefaults.standard.bool(forKey: lockbarPermissionRequestKey)
    return hasRequestedPermission ? "denied" : "notDetermined"
  }

  private func startKeepAwake(arguments: [String: Any]?, result: FlutterResult) {
    guard let rawDuration = arguments?["durationSeconds"] as? Int, rawDuration > 0 else {
      result(
        FlutterError(
          code: "invalid_keep_awake_duration",
          message: "durationSeconds must be a positive integer.",
          details: nil
        )
      )
      return
    }

    beginKeepAwakeSession(durationSeconds: rawDuration, result: result)
  }

  private func startKeepAwakeIndefinitely(result: FlutterResult) {
    beginKeepAwakeSession(durationSeconds: nil, result: result)
  }

  private func beginKeepAwakeSession(durationSeconds: Int?, result: FlutterResult) {
    _ = stopKeepAwake()

    do {
      try startKeepAwakeAssertions()
      if let durationSeconds {
        scheduleKeepAwakeStop(after: durationSeconds)
      }
      result(nil)
    } catch {
      _ = stopKeepAwake()
      result(
        FlutterError(
          code: "keep_awake_start_failed",
          message: "Failed to start keep-awake assertions.",
          details: String(describing: error)
        )
      )
    }
  }

  private func startKeepAwakeAssertions() throws {
    var assertionIDs: [IOPMAssertionID] = []
    do {
      assertionIDs.append(
        try createKeepAwakeAssertion(type: kIOPMAssertionTypeNoDisplaySleep)
      )
      assertionIDs.append(
        try createKeepAwakeAssertion(type: kIOPMAssertionTypeNoIdleSleep)
      )
      keepAwakeAssertionIDs = assertionIDs
    } catch {
      for assertionID in assertionIDs {
        IOPMAssertionRelease(assertionID)
      }
      throw error
    }
  }

  private func createKeepAwakeAssertion(type: String) throws -> IOPMAssertionID {
    var assertionID = IOPMAssertionID(kIOPMNullAssertionID)
    let status = IOPMAssertionCreateWithName(
      type as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      keepAwakeReason,
      &assertionID
    )
    guard status == kIOReturnSuccess else {
      throw KeepAwakeAssertionError.creationFailed(type: type, code: status)
    }
    return assertionID
  }

  private func scheduleKeepAwakeStop(after durationSeconds: Int) {
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now() + .seconds(durationSeconds))
    timer.setEventHandler { [weak self] in
      _ = self?.stopKeepAwake()
    }
    keepAwakeStopTimer = timer
    timer.resume()
  }

  private func keepAwakeState(releasedCount: Int = 0) -> [String: Any] {
    [
      "isActive": !keepAwakeAssertionIDs.isEmpty,
      "assertionCount": keepAwakeAssertionIDs.count,
      "releasedCount": releasedCount
    ]
  }

  private func stopKeepAwake() -> [String: Any] {
    keepAwakeStopTimer?.cancel()
    keepAwakeStopTimer = nil

    let releasedCount = keepAwakeAssertionIDs.count
    for assertionID in keepAwakeAssertionIDs {
      IOPMAssertionRelease(assertionID)
    }
    keepAwakeAssertionIDs.removeAll()
    return keepAwakeState(releasedCount: releasedCount)
  }

  private func requestPermission() -> String {
    UserDefaults.standard.set(true, forKey: lockbarPermissionRequestKey)
    return CGRequestPostEventAccess() ? "granted" : "denied"
  }

  private func currentCalendarPermissionState() -> String {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(macOS 14.0, *) {
      switch status {
      case .fullAccess, .authorized:
        return "granted"
      case .denied, .restricted, .writeOnly:
        return "denied"
      case .notDetermined:
        return "notDetermined"
      @unknown default:
        return "denied"
      }
    }

    switch status {
    case .authorized:
      return "granted"
    case .denied, .restricted:
      return "denied"
    case .notDetermined:
      return "notDetermined"
    #if compiler(>=5.9)
    case .fullAccess, .writeOnly:
      return "denied"
    #endif
    @unknown default:
      return "denied"
    }
  }

  private func requestCalendarAccess(result: @escaping FlutterResult) {
    if currentCalendarPermissionState() == "granted" {
      result("granted")
      return
    }

    if #available(macOS 14.0, *) {
      calendarStore.requestFullAccessToEvents { granted, _ in
        DispatchQueue.main.async {
          result(granted ? "granted" : self.currentCalendarPermissionState())
        }
      }
    } else {
      calendarStore.requestAccess(to: .event) { granted, _ in
        DispatchQueue.main.async {
          result(granted ? "granted" : self.currentCalendarPermissionState())
        }
      }
    }
  }

  private func lockNow() -> [String: String] {
    guard CGPreflightPostEventAccess() else {
      return ["status": "permissionDenied"]
    }

    guard let source = CGEventSource(stateID: .hidSystemState) else {
      return [
        "status": "failure",
        "code": "eventSourceUnavailable",
      ]
    }

    let sequence: [(CGKeyCode, Bool, CGEventFlags)] = [
      (CGKeyCode(kVK_Control), true, []),
      (CGKeyCode(kVK_Command), true, [.maskControl]),
      (CGKeyCode(kVK_ANSI_Q), true, [.maskControl, .maskCommand]),
      (CGKeyCode(kVK_ANSI_Q), false, [.maskControl, .maskCommand]),
      (CGKeyCode(kVK_Command), false, [.maskControl]),
      (CGKeyCode(kVK_Control), false, []),
    ]

    for (keyCode, isKeyDown, flags) in sequence {
      guard let event = CGEvent(
        keyboardEventSource: source,
        virtualKey: keyCode,
        keyDown: isKeyDown
      ) else {
        return [
          "status": "failure",
          "code": "eventSequenceUnavailable",
        ]
      }

      event.flags = flags
      event.post(tap: .cghidEventTap)
      usleep(12_000)
    }

    return ["status": "success"]
  }

  private func openAccessibilitySettings() {
    let candidateURLs = [
      "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
      "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
    ]

    for rawURL in candidateURLs {
      if let url = URL(string: rawURL), NSWorkspace.shared.open(url) {
        return
      }
    }

    let fallbackURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
    NSWorkspace.shared.open(fallbackURL)
  }

  private func activateApp() {
    NSApp.activate(ignoringOtherApps: true)
    makeKeyAndOrderFront(nil)
  }

  private func updateNativeLocale(localeTag: String?) {
    (NSApp.delegate as? AppDelegate)?.updateNativeLocalization(localeTag: localeTag)
  }

  private func appInfo() -> [String: String] {
    let infoDictionary = Bundle.main.infoDictionary
    let name = infoDictionary?["CFBundleName"] as? String ?? "LockBar"
    let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let buildNumber = infoDictionary?["CFBundleVersion"] as? String ?? "1"

    return [
      "name": name,
      "version": version,
      "buildNumber": buildNumber,
    ]
  }

  private func currentAppearanceMode() -> String {
    appearanceModeFromPreferences(
      automaticSwitches: globalPreferenceBool(automaticAppearancePreferenceKey),
      interfaceStyle: globalPreferenceString(interfaceStylePreferenceKey)
    )
  }

  private func setAppearanceMode(arguments: [String: Any]?, result: FlutterResult) {
    guard let mode = arguments?["mode"] as? String else {
      result(
        FlutterError(
          code: "invalid_appearance_mode",
          message: "mode must be one of light, dark, or automatic.",
          details: nil
        )
      )
      return
    }

    do {
      switch mode {
      case "light":
        setAutomaticAppearanceEnabled(false)
        setManualAppearanceStyle("light")
      case "dark":
        setAutomaticAppearanceEnabled(false)
        setManualAppearanceStyle("dark")
      case "automatic":
        setAutomaticAppearanceEnabled(true)
        notifyAppearanceChanged()
      default:
        result(
          FlutterError(
            code: "invalid_appearance_mode",
            message: "Unsupported appearance mode: \(mode).",
            details: nil
          )
        )
        return
      }
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "appearance_mode_failed",
          message: "Failed to change the macOS appearance mode.",
          details: String(describing: error)
        )
      )
    }
  }

  private func globalPreferenceBool(_ key: CFString) -> Bool? {
    let value = CFPreferencesCopyValue(
      key,
      kCFPreferencesAnyApplication,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    )
    if let boolValue = value as? Bool {
      return boolValue
    }
    if let numberValue = value as? NSNumber {
      return numberValue.boolValue
    }
    return nil
  }

  private func globalPreferenceString(_ key: CFString) -> String? {
    CFPreferencesCopyValue(
      key,
      kCFPreferencesAnyApplication,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    ) as? String
  }

  private func setAutomaticAppearanceEnabled(_ enabled: Bool) {
    CFPreferencesSetValue(
      automaticAppearancePreferenceKey,
      NSNumber(value: enabled),
      kCFPreferencesAnyApplication,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    )
    CFPreferencesSynchronize(
      kCFPreferencesAnyApplication,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    )
  }

  private func setManualAppearanceStyle(_ style: String) {
    let value: CFString = (style == "dark" ? "Dark" : "") as CFString
    CFPreferencesSetValue(
      interfaceStylePreferenceKey,
      value,
      kCFPreferencesAnyApplication,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    )
    CFPreferencesSynchronize(
      kCFPreferencesAnyApplication,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    )
  }

  private func setSystemEventsDarkMode(_ enabled: Bool) throws {
    let scriptSource = """
    tell application "System Events" to tell appearance preferences to set dark mode to \(enabled ? "true" : "false")
    """
    guard let script = NSAppleScript(source: scriptSource) else {
      throw NSError(
        domain: "LockBar.Appearance",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not create AppleScript."]
      )
    }

    var error: NSDictionary?
    script.executeAndReturnError(&error)
    if let error {
      throw NSError(
        domain: "LockBar.Appearance",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: error.description]
      )
    }
  }

  private func notifyAppearanceChanged() {
    DistributedNotificationCenter.default().post(
      name: Notification.Name(appearanceNotificationName),
      object: nil
    )
  }

  private func getSystemContextSnapshot(
    arguments: [String: Any]?,
    result: @escaping FlutterResult
  ) {
    let sourceKeys = Set(arguments?["sources"] as? [String] ?? [])
    result(systemContextSnapshot(sourceKeys: sourceKeys))
  }

  private func handleSuggestionPanel(arguments: [String: Any]?, isUpdate: Bool) {
    guard let payload = SuggestionPanelPayload(arguments: arguments) else {
      return
    }

    if isUpdate {
      suggestionPanelController.update(payload: payload, animated: true)
    } else {
      suggestionPanelController.show(payload: payload)
    }
  }

  private func systemContextSnapshot(sourceKeys: Set<String>) -> [String: Any] {
    let frontmostApp = NSWorkspace.shared.frontmostApplication
    let shouldReadApp = sourceKeys.contains("frontmostApp")
    let shouldReadWindowTitle = sourceKeys.contains("windowTitle")
    let shouldReadCalendar = sourceKeys.contains("calendar")
    let shouldReadBluetooth = sourceKeys.contains("bluetooth")
    let shouldReadNetwork = sourceKeys.contains("network")
    let shouldReadIdle = sourceKeys.contains("idleState")
    let calendarEvents = shouldReadCalendar
      ? currentCalendarEvents()
      : (current: nil, next: nil)

    return [
      "collectedAt": isoFormatter.string(from: Date()),
      "frontmostAppName": shouldReadApp ? ((frontmostApp?.localizedName ?? NSNull()) as Any) : NSNull(),
      "frontmostBundleId": shouldReadApp ? ((frontmostApp?.bundleIdentifier ?? NSNull()) as Any) : NSNull(),
      "frontmostWindowTitle": shouldReadWindowTitle ? ((focusedWindowTitle(for: frontmostApp) ?? NSNull()) as Any) : NSNull(),
      "idleSeconds": shouldReadIdle
        ? CGEventSource.secondsSinceLastEventType(
          .combinedSessionState,
          eventType: .null
        )
        : 0,
      "networkName": shouldReadNetwork ? ((currentNetworkName() ?? NSNull()) as Any) : NSNull(),
      "networkReachable": shouldReadNetwork ? networkReachable : false,
      "bluetoothDevices": shouldReadBluetooth ? connectedBluetoothDevices() : [],
      "currentCalendarEvent": shouldReadCalendar ? ((calendarEvents.current ?? NSNull()) as Any) : NSNull(),
      "nextCalendarEvent": shouldReadCalendar ? ((calendarEvents.next ?? NSNull()) as Any) : NSNull(),
      "accessibilityTrusted": AXIsProcessTrusted(),
    ]
  }

  private func currentNetworkName() -> String? {
    if let ssid = CWWiFiClient.shared().interface()?.ssid(), !ssid.isEmpty {
      return ssid
    }

    return networkReachable ? "Wired / VPN" : nil
  }

  private func focusedWindowTitle(for app: NSRunningApplication?) -> String? {
    guard AXIsProcessTrusted(), let app else {
      return nil
    }

    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var focusedWindow: CFTypeRef?
    let windowResult = AXUIElementCopyAttributeValue(
      appElement,
      kAXFocusedWindowAttribute as CFString,
      &focusedWindow
    )
    guard windowResult == .success, let axWindow = focusedWindow else {
      return nil
    }

    var title: CFTypeRef?
    let titleResult = AXUIElementCopyAttributeValue(
      axWindow as! AXUIElement,
      kAXTitleAttribute as CFString,
      &title
    )
    guard titleResult == .success else {
      return nil
    }

    return title as? String
  }

  private func connectedBluetoothDevices() -> [String] {
    connectedPairedBluetoothDevices()
      .compactMap { $0.nameOrAddress }
      .sorted()
  }

  private func connectedPairedBluetoothDevices() -> [IOBluetoothDevice] {
    guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
      return []
    }

    return devices.filter { $0.isConnected() }
  }

  private func bluetoothBatteryDevices() -> [[String: Any]] {
    let records = bluetoothBatteryRecordsFromAllSources()
    if records.isEmpty {
      return []
    }

    return connectedPairedBluetoothDevices()
      .compactMap { device -> [String: Any]? in
        let displayName = bluetoothDisplayName(for: device)
        let normalizedName = normalizeBluetoothName(displayName)
        let normalizedAddress = normalizeBluetoothAddress(device.addressString)
        var levels = BluetoothBatteryLevels()

        for record in records where bluetoothRecord(
          record,
          matchesName: normalizedName,
          address: normalizedAddress
        ) {
          levels.merge(record)
        }

        guard levels.hasBatteryLevel else {
          return nil
        }

        var payload: [String: Any] = ["name": displayName]
        if let batteryLevel = levels.batteryLevel {
          payload["batteryLevel"] = batteryLevel
        }
        if let leftBatteryLevel = levels.leftBatteryLevel {
          payload["leftBatteryLevel"] = leftBatteryLevel
        }
        if let rightBatteryLevel = levels.rightBatteryLevel {
          payload["rightBatteryLevel"] = rightBatteryLevel
        }
        if let caseBatteryLevel = levels.caseBatteryLevel {
          payload["caseBatteryLevel"] = caseBatteryLevel
        }
        return payload
      }
      .sorted { lhs, rhs in
        let lhsName = (lhs["name"] as? String ?? "").localizedCaseInsensitiveCompare(rhs["name"] as? String ?? "")
        return lhsName == .orderedAscending
      }
  }

  private func bluetoothBatteryRecordsFromAllSources() -> [BluetoothBatteryRecord] {
    let sourceRecords = bluetoothBatteryRecordsFromRegistry() +
      bluetoothBatteryRecordsFromSystemProfiler()

    var records: [BluetoothBatteryRecord] = []
    var seenSignatures = Set<String>()
    for record in sourceRecords where !seenSignatures.contains(record.signature) {
      records.append(record)
      seenSignatures.insert(record.signature)
    }
    return records
  }

  private func bluetoothDisplayName(for device: IOBluetoothDevice) -> String {
    let candidates = [
      device.name,
      device.nameOrAddress,
      device.addressString,
    ]
    for candidate in candidates {
      let name = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      if !name.isEmpty {
        return name
      }
    }
    return "Bluetooth Device"
  }

  private func bluetoothRecord(
    _ record: BluetoothBatteryRecord,
    matchesName normalizedName: String,
    address normalizedAddress: String
  ) -> Bool {
    if !normalizedAddress.isEmpty && record.addresses.contains(normalizedAddress) {
      return true
    }

    guard !normalizedName.isEmpty else {
      return false
    }

    return record.names.contains { recordName in
      recordName == normalizedName ||
        (recordName.count >= 4 && normalizedName.contains(recordName)) ||
        (normalizedName.count >= 4 && recordName.contains(normalizedName))
    }
  }

  private func bluetoothBatteryRecordsFromRegistry() -> [BluetoothBatteryRecord] {
    let registryClasses = [
      "AppleDeviceManagementHIDEventService",
      "IOBluetoothHIDDriver",
      "IOHIDDevice",
    ]

    var records: [BluetoothBatteryRecord] = []
    var seenSignatures = Set<String>()
    for registryClass in registryClasses {
      for record in bluetoothBatteryRecords(matchingRegistryClass: registryClass)
        where !seenSignatures.contains(record.signature) {
        records.append(record)
        seenSignatures.insert(record.signature)
      }
    }
    return records
  }

  private func bluetoothBatteryRecordsFromSystemProfiler() -> [BluetoothBatteryRecord] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
    process.arguments = ["SPBluetoothDataType", "-json"]

    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = Pipe()

    do {
      try process.run()
    } catch {
      return []
    }

    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      return []
    }

    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return bluetoothBatteryRecordsFromSystemProfilerJSON(data)
  }

  private func bluetoothBatteryRecords(
    matchingRegistryClass registryClass: String
  ) -> [BluetoothBatteryRecord] {
    guard let matchingDictionary = IOServiceMatching(registryClass) else {
      return []
    }

    var iterator: io_iterator_t = 0
    let result = IOServiceGetMatchingServices(
      kIOMainPortDefault,
      matchingDictionary,
      &iterator
    )
    guard result == KERN_SUCCESS else {
      return []
    }
    defer { IOObjectRelease(iterator) }

    var records: [BluetoothBatteryRecord] = []
    while true {
      let service = IOIteratorNext(iterator)
      if service == 0 {
        break
      }
      if let record = bluetoothBatteryRecord(for: service) {
        records.append(record)
      }
      IOObjectRelease(service)
    }
    return records
  }

  private func bluetoothBatteryRecord(for service: io_registry_entry_t) -> BluetoothBatteryRecord? {
    let properties = registryProperties(for: service)
    let names = Set(bluetoothStringValues(
      from: properties,
      keys: [
        "Product",
        "ProductName",
        "DeviceName",
        "Name",
        "UserVisibleName",
        "BluetoothDeviceName",
      ]
    ).map(normalizeBluetoothName).filter { !$0.isEmpty })
    let addresses = Set(bluetoothStringValues(
      from: properties,
      keys: [
        "DeviceAddress",
        "BluetoothDeviceAddress",
        "BD_ADDR",
        "Address",
        "BluetoothAddress",
      ]
    ).map(normalizeBluetoothAddress).filter { !$0.isEmpty })

    let record = BluetoothBatteryRecord(
      names: names,
      addresses: addresses,
      batteryLevel: bluetoothBatteryLevel(
        from: properties,
        keys: [
          "BatteryPercent",
          "BatteryPercentage",
          "BatteryLevel",
          "Battery Level",
          "AppleDeviceBatteryLevel",
          "DeviceBatteryPercent",
          "BatteryPercentCombined",
          "BatteryPercentSingle",
        ]
      ),
      leftBatteryLevel: bluetoothBatteryLevel(
        from: properties,
        keys: [
          "BatteryPercentLeft",
          "BatteryPercentLeftBud",
          "LeftBatteryPercent",
          "BatteryPercentL",
          "BatteryLevelLeft",
          "LeftBatteryLevel",
        ]
      ),
      rightBatteryLevel: bluetoothBatteryLevel(
        from: properties,
        keys: [
          "BatteryPercentRight",
          "BatteryPercentRightBud",
          "RightBatteryPercent",
          "BatteryPercentR",
          "BatteryLevelRight",
          "RightBatteryLevel",
        ]
      ),
      caseBatteryLevel: bluetoothBatteryLevel(
        from: properties,
        keys: [
          "BatteryPercentCase",
          "CaseBatteryPercent",
          "BatteryLevelCase",
          "CaseBatteryLevel",
        ]
      )
    )

    guard record.hasBatteryLevel && (!record.names.isEmpty || !record.addresses.isEmpty) else {
      return nil
    }
    return record
  }

  private func registryProperties(for service: io_registry_entry_t) -> [String: Any] {
    var properties: Unmanaged<CFMutableDictionary>?
    let result = IORegistryEntryCreateCFProperties(
      service,
      &properties,
      kCFAllocatorDefault,
      0
    )
    guard result == KERN_SUCCESS,
          let dictionary = properties?.takeRetainedValue() as? [String: Any]
    else {
      return [:]
    }
    return dictionary
  }

  private func currentCalendarEvents() -> (current: [String: Any]?, next: [String: Any]?) {
    guard isCalendarReadable else {
      return (nil, nil)
    }

    let now = Date()
    let predicate = calendarStore.predicateForEvents(
      withStart: now.addingTimeInterval(-600),
      end: now.addingTimeInterval(3 * 60 * 60),
      calendars: nil
    )
    let events = calendarStore.events(matching: predicate).sorted { lhs, rhs in
      lhs.startDate < rhs.startDate
    }

    let current = events.first { event in
      event.startDate <= now && event.endDate >= now
    }
    let next = events.first { event in
      event.startDate > now
    }

    return (serializeCalendarEvent(current), serializeCalendarEvent(next))
  }

  private var isCalendarReadable: Bool {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(macOS 14.0, *) {
      return status == .fullAccess || status == .authorized
    }
    return status == .authorized
  }

  private func serializeCalendarEvent(_ event: EKEvent?) -> [String: Any]? {
    guard let event,
          let title = event.title,
          !title.isEmpty
    else {
      return nil
    }

    return [
      "title": title,
      "startAt": isoFormatter.string(from: event.startDate),
      "endAt": isoFormatter.string(from: event.endDate),
    ]
  }
}
