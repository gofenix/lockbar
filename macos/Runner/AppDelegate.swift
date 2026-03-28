import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let appMenuLocalizer = AppMenuLocalizer()

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    NSApp.setActivationPolicy(.accessory)
    configureApplicationMenu()
    updateNativeLocalization(localeTag: nil)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      showSettingsWindow(nil)
    }
    return true
  }

  func updateNativeLocalization(localeTag: String?) {
    appMenuLocalizer.apply(
      menu: NSApp.mainMenu,
      appName: applicationName,
      localeTag: localeTag
    )
  }

  @objc func showSettingsWindow(_ sender: Any?) {
    NSApp.activate(ignoringOtherApps: true)
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
  }

  private var applicationName: String {
    let bundle = Bundle.main
    return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
      ?? "LockBar"
  }

  private func configureApplicationMenu() {
    guard let appMenu = NSApp.mainMenu?.items.first?.submenu else {
      return
    }

    if appMenu.items.indices.contains(2) {
      let settingsItem = appMenu.items[2]
      settingsItem.target = self
      settingsItem.action = #selector(showSettingsWindow(_:))
    }
  }
}
