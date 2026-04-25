import Cocoa
import ApplicationServices
import Carbon.HIToolbox
import CoreWLAN
import EventKit
import FlutterMacOS
import IOBluetooth
import IOKit.pwr_mgt
import LaunchAtLogin
import Network

private let lockbarChannelName = "lockbar/macos"
private let lockbarPermissionRequestKey = "lockbar.hasRequestedPermission"
private let suggestionPanelWidth: CGFloat = 420
private let keepAwakeReason = "LockBar keep-awake" as CFString

private enum KeepAwakeAssertionError: Error {
  case creationFailed(type: String, code: IOReturn)
}

private final class SuggestionPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
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

class MainFlutterWindow: NSWindow {
  private let calendarStore = EKEventStore()
  private let isoFormatter = ISO8601DateFormatter()
  private let networkMonitor = NWPathMonitor()
  private let networkMonitorQueue = DispatchQueue(label: "lockbar.network-monitor")
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
    stopKeepAwake()
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
        self.stopKeepAwake()
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
      case "stopKeepAwake":
        self.stopKeepAwake()
        result(nil)
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
    stopKeepAwake()

    do {
      try startKeepAwakeAssertions()
      if let durationSeconds {
        scheduleKeepAwakeStop(after: durationSeconds)
      }
      result(nil)
    } catch {
      stopKeepAwake()
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
      self?.stopKeepAwake()
    }
    keepAwakeStopTimer = timer
    timer.resume()
  }

  private func stopKeepAwake() {
    keepAwakeStopTimer?.cancel()
    keepAwakeStopTimer = nil

    for assertionID in keepAwakeAssertionIDs {
      IOPMAssertionRelease(assertionID)
    }
    keepAwakeAssertionIDs.removeAll()
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
    guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
      return []
    }

    return devices
      .filter { $0.isConnected() }
      .compactMap { $0.nameOrAddress }
      .sorted()
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
