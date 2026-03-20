import Cocoa
import ApplicationServices
import Carbon.HIToolbox
import FlutterMacOS
import LaunchAtLogin

private let lockbarChannelName = "lockbar/macos"
private let lockbarPermissionRequestKey = "lockbar.hasRequestedPermission"

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let messenger = flutterViewController.engine.binaryMessenger
    configureLaunchAtStartupChannel(binaryMessenger: messenger)
    configureLockbarChannel(binaryMessenger: messenger)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
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
    FlutterMethodChannel(name: lockbarChannelName, binaryMessenger: binaryMessenger)
      .setMethodCallHandler { [weak self] call, result in
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

  private func requestPermission() -> String {
    UserDefaults.standard.set(true, forKey: lockbarPermissionRequestKey)
    return CGRequestPostEventAccess() ? "granted" : "denied"
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
}
