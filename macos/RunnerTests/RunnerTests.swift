import Cocoa
import XCTest

@testable import LockBar

final class RunnerTests: XCTestCase {
  func testAppearanceModeFromPreferencesPrefersAutomatic() {
    XCTAssertEqual(
      appearanceModeFromPreferences(
        automaticSwitches: true,
        interfaceStyle: nil
      ),
      "automatic"
    )
    XCTAssertEqual(
      appearanceModeFromPreferences(
        automaticSwitches: true,
        interfaceStyle: "Dark"
      ),
      "automatic"
    )
  }

  func testAppearanceModeFromPreferencesFallsBackToManualStyle() {
    XCTAssertEqual(
      appearanceModeFromPreferences(
        automaticSwitches: false,
        interfaceStyle: "Dark"
      ),
      "dark"
    )
    XCTAssertEqual(
      appearanceModeFromPreferences(
        automaticSwitches: nil,
        interfaceStyle: nil
      ),
      "light"
    )
  }

  func testSystemProfilerBluetoothParserReadsConnectedMouseMainBattery() throws {
    let json = """
    {
      "SPBluetoothDataType": [
        {
          "device_connected": [
            {
              "MX Master 3": {
                "device_address": "E7:C6:C5:25:73:59",
                "device_batteryLevelMain": "100%",
                "device_minorType": "Mouse"
              }
            }
          ],
          "device_not_connected": [
            {
              "Fenix AirPods": {
                "device_address": "F8:4D:89:55:A6:3A",
                "device_batteryLevelMain": "77%"
              }
            }
          ]
        }
      ]
    }
    """.data(using: .utf8)!

    let records = bluetoothBatteryRecordsFromSystemProfilerJSON(json)

    XCTAssertEqual(records.count, 1)
    XCTAssertTrue(records[0].names.contains("mx master 3"))
    XCTAssertTrue(records[0].addresses.contains("e7c6c5257359"))
    XCTAssertEqual(records[0].batteryLevel, 100)
  }

  func testSystemProfilerBluetoothParserReadsEarbudComponentBatteries() throws {
    let json = """
    {
      "SPBluetoothDataType": [
        {
          "device_connected": [
            {
              "AirPods Pro": {
                "device_address": "AA:BB:CC:DD:EE:FF",
                "device_batteryLevelLeft": "76%",
                "device_batteryLevelRight": "71%",
                "device_batteryLevelCase": "54%"
              }
            }
          ]
        }
      ]
    }
    """.data(using: .utf8)!

    let records = bluetoothBatteryRecordsFromSystemProfilerJSON(json)

    XCTAssertEqual(records.count, 1)
    XCTAssertEqual(records[0].leftBatteryLevel, 76)
    XCTAssertEqual(records[0].rightBatteryLevel, 71)
    XCTAssertEqual(records[0].caseBatteryLevel, 54)
  }

  func testSystemProfilerBluetoothParserIgnoresDisconnectedDevices() throws {
    let json = """
    {
      "SPBluetoothDataType": [
        {
          "device_connected": [],
          "device_not_connected": [
            {
              "Keyboard": {
                "device_address": "11:22:33:44:55:66",
                "device_batteryLevelMain": "88%"
              }
            }
          ]
        }
      ]
    }
    """.data(using: .utf8)!

    let records = bluetoothBatteryRecordsFromSystemProfilerJSON(json)

    XCTAssertTrue(records.isEmpty)
  }

  func testAppMenuLocalizerAppliesEnglishTitles() {
    let menu = makeMainMenu()

    AppMenuLocalizer().apply(menu: menu, appName: "LockBar", localeTag: "en")

    XCTAssertEqual(menu.items[0].submenu?.items[0].title, "About LockBar")
    XCTAssertEqual(menu.items[0].submenu?.items[2].title, "Settings…")
    XCTAssertEqual(menu.items[1].title, "Edit")
    XCTAssertEqual(menu.items[1].submenu?.items[10].submenu?.items[0].title, "Find…")
    XCTAssertEqual(menu.items[3].title, "Window")
    XCTAssertEqual(menu.items[4].title, "Help")
  }

  func testAppMenuLocalizerAppliesSimplifiedChineseTitles() {
    let menu = makeMainMenu()

    AppMenuLocalizer().apply(menu: menu, appName: "LockBar", localeTag: "zh-Hans")

    XCTAssertEqual(menu.items[0].submenu?.items[0].title, "关于 LockBar")
    XCTAssertEqual(menu.items[0].submenu?.items[2].title, "设置…")
    XCTAssertEqual(menu.items[1].title, "编辑")
    XCTAssertEqual(menu.items[1].submenu?.items[10].submenu?.items[0].title, "查找…")
    XCTAssertEqual(menu.items[3].title, "窗口")
    XCTAssertEqual(menu.items[4].title, "帮助")
  }

  private func makeMainMenu() -> NSMenu {
    let menu = NSMenu(title: "Main")

    let appItem = NSMenuItem(title: "App", action: nil, keyEquivalent: "")
    appItem.submenu = submenu(itemCount: 11)
    menu.addItem(appItem)

    let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
    let editMenu = submenu(itemCount: 15)
    editMenu.items[10].submenu = submenu(itemCount: 6)
    editMenu.items[11].submenu = submenu(itemCount: 6)
    editMenu.items[12].submenu = submenu(itemCount: 8)
    editMenu.items[13].submenu = submenu(itemCount: 3)
    editMenu.items[14].submenu = submenu(itemCount: 2)
    editItem.submenu = editMenu
    menu.addItem(editItem)

    let viewItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
    viewItem.submenu = submenu(itemCount: 1)
    menu.addItem(viewItem)

    let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
    windowItem.submenu = submenu(itemCount: 4)
    menu.addItem(windowItem)

    let helpItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
    helpItem.submenu = submenu(itemCount: 0)
    menu.addItem(helpItem)

    return menu
  }

  private func submenu(itemCount: Int) -> NSMenu {
    let menu = NSMenu(title: "")
    for index in 0..<itemCount {
      menu.addItem(
        NSMenuItem(
          title: "Item \(index)",
          action: nil,
          keyEquivalent: ""
        )
      )
    }
    return menu
  }
}
