import Cocoa

final class AppMenuLocalizer {
  func apply(menu: NSMenu?, appName: String, localeTag: String?) {
    guard let menu else {
      return
    }

    let strings = AppMenuStrings(localeTag: localeTag)

    menu.items[safe: 0]?.title = appName

    if let appMenuItem = menu.items[safe: 0], let appMenu = appMenuItem.submenu {
      appMenu.title = appName
      appMenu.items[safe: 0]?.title = strings.formatted("menu.app.about", appName)
      appMenu.items[safe: 2]?.title = strings.value("menu.app.settings")
      appMenu.items[safe: 4]?.title = strings.value("menu.app.services")
      appMenu.items[safe: 4]?.submenu?.title = strings.value("menu.app.services")
      appMenu.items[safe: 6]?.title = strings.formatted("menu.app.hide", appName)
      appMenu.items[safe: 7]?.title = strings.value("menu.app.hideOthers")
      appMenu.items[safe: 8]?.title = strings.value("menu.app.showAll")
      appMenu.items[safe: 10]?.title = strings.formatted("menu.app.quit", appName)
    }

    if let editMenuItem = menu.items[safe: 1], let editMenu = editMenuItem.submenu {
      editMenuItem.title = strings.value("menu.edit.title")
      editMenu.title = strings.value("menu.edit.title")
      editMenu.items[safe: 0]?.title = strings.value("menu.edit.undo")
      editMenu.items[safe: 1]?.title = strings.value("menu.edit.redo")
      editMenu.items[safe: 3]?.title = strings.value("menu.edit.cut")
      editMenu.items[safe: 4]?.title = strings.value("menu.edit.copy")
      editMenu.items[safe: 5]?.title = strings.value("menu.edit.paste")
      editMenu.items[safe: 6]?.title = strings.value("menu.edit.pasteAndMatchStyle")
      editMenu.items[safe: 7]?.title = strings.value("menu.edit.delete")
      editMenu.items[safe: 8]?.title = strings.value("menu.edit.selectAll")

      if let findItem = editMenu.items[safe: 10], let findMenu = findItem.submenu {
        findItem.title = strings.value("menu.edit.find.title")
        findMenu.title = strings.value("menu.edit.find.title")
        findMenu.items[safe: 0]?.title = strings.value("menu.edit.find.find")
        findMenu.items[safe: 1]?.title = strings.value("menu.edit.find.findAndReplace")
        findMenu.items[safe: 2]?.title = strings.value("menu.edit.find.findNext")
        findMenu.items[safe: 3]?.title = strings.value("menu.edit.find.findPrevious")
        findMenu.items[safe: 4]?.title = strings.value("menu.edit.find.useSelectionForFind")
        findMenu.items[safe: 5]?.title = strings.value("menu.edit.find.jumpToSelection")
      }

      if let spellingItem = editMenu.items[safe: 11], let spellingMenu = spellingItem.submenu {
        spellingItem.title = strings.value("menu.edit.spelling.title")
        spellingMenu.title = strings.value("menu.edit.spelling.title")
        spellingMenu.items[safe: 0]?.title = strings.value("menu.edit.spelling.show")
        spellingMenu.items[safe: 1]?.title = strings.value("menu.edit.spelling.check")
        spellingMenu.items[safe: 3]?.title = strings.value("menu.edit.spelling.checkWhileTyping")
        spellingMenu.items[safe: 4]?.title = strings.value("menu.edit.spelling.checkGrammar")
        spellingMenu.items[safe: 5]?.title = strings.value("menu.edit.spelling.correctAutomatically")
      }

      if let substitutionsItem = editMenu.items[safe: 12],
         let substitutionsMenu = substitutionsItem.submenu
      {
        substitutionsItem.title = strings.value("menu.edit.substitutions.title")
        substitutionsMenu.title = strings.value("menu.edit.substitutions.title")
        substitutionsMenu.items[safe: 0]?.title = strings.value("menu.edit.substitutions.show")
        substitutionsMenu.items[safe: 2]?.title = strings.value("menu.edit.substitutions.smartCopyPaste")
        substitutionsMenu.items[safe: 3]?.title = strings.value("menu.edit.substitutions.smartQuotes")
        substitutionsMenu.items[safe: 4]?.title = strings.value("menu.edit.substitutions.smartDashes")
        substitutionsMenu.items[safe: 5]?.title = strings.value("menu.edit.substitutions.smartLinks")
        substitutionsMenu.items[safe: 6]?.title = strings.value("menu.edit.substitutions.dataDetectors")
        substitutionsMenu.items[safe: 7]?.title = strings.value("menu.edit.substitutions.textReplacement")
      }

      if let transformationsItem = editMenu.items[safe: 13],
         let transformationsMenu = transformationsItem.submenu
      {
        transformationsItem.title = strings.value("menu.edit.transformations.title")
        transformationsMenu.title = strings.value("menu.edit.transformations.title")
        transformationsMenu.items[safe: 0]?.title = strings.value("menu.edit.transformations.upper")
        transformationsMenu.items[safe: 1]?.title = strings.value("menu.edit.transformations.lower")
        transformationsMenu.items[safe: 2]?.title = strings.value("menu.edit.transformations.capitalize")
      }

      if let speechItem = editMenu.items[safe: 14], let speechMenu = speechItem.submenu {
        speechItem.title = strings.value("menu.edit.speech.title")
        speechMenu.title = strings.value("menu.edit.speech.title")
        speechMenu.items[safe: 0]?.title = strings.value("menu.edit.speech.start")
        speechMenu.items[safe: 1]?.title = strings.value("menu.edit.speech.stop")
      }
    }

    if let viewMenuItem = menu.items[safe: 2], let viewMenu = viewMenuItem.submenu {
      viewMenuItem.title = strings.value("menu.view.title")
      viewMenu.title = strings.value("menu.view.title")
      viewMenu.items[safe: 0]?.title = strings.value("menu.view.enterFullScreen")
    }

    if let windowMenuItem = menu.items[safe: 3], let windowMenu = windowMenuItem.submenu {
      windowMenuItem.title = strings.value("menu.window.title")
      windowMenu.title = strings.value("menu.window.title")
      windowMenu.items[safe: 0]?.title = strings.value("menu.window.minimize")
      windowMenu.items[safe: 1]?.title = strings.value("menu.window.zoom")
      windowMenu.items[safe: 3]?.title = strings.value("menu.window.bringAllToFront")
    }

    if let helpMenuItem = menu.items[safe: 4], let helpMenu = helpMenuItem.submenu {
      helpMenuItem.title = strings.value("menu.help.title")
      helpMenu.title = strings.value("menu.help.title")
    }
  }
}

private struct AppMenuStrings {
  init(localeTag: String?) {
    self.bundle = AppShellLocale(localeTag: localeTag).bundle
  }

  let bundle: Bundle

  func value(_ key: String) -> String {
    bundle.localizedString(forKey: key, value: nil, table: "AppMenu")
  }

  func formatted(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: value(key), arguments: arguments)
  }
}

private enum AppShellLocale {
  case english
  case simplifiedChinese

  init(localeTag: String?) {
    let resolvedTag = localeTag ?? Locale.preferredLanguages.first ?? "en"
    if resolvedTag.lowercased().hasPrefix("zh") {
      self = .simplifiedChinese
    } else {
      self = .english
    }
  }

  var bundle: Bundle {
    let resources: [String]
    switch self {
    case .english:
      resources = ["en"]
    case .simplifiedChinese:
      resources = ["zh-Hans", "zh"]
    }

    for resource in resources {
      if let path = Bundle.main.path(forResource: resource, ofType: "lproj"),
         let bundle = Bundle(path: path)
      {
        return bundle
      }
    }

    return .main
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    guard indices.contains(index) else {
      return nil
    }
    return self[index]
  }
}
