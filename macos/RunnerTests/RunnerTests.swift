import Cocoa
import XCTest

@testable import LockBar

final class RunnerTests: XCTestCase {
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
