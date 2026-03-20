import 'dart:async';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'l10n/locale_support.dart';
import 'lockbar_controller.dart';
import 'models/lockbar_models.dart';
import 'platform/lockbar_platform.dart';

class LockbarDesktopCoordinator with TrayListener, WindowListener {
  LockbarDesktopCoordinator({required this.controller, required this.platform});

  final LockbarController controller;
  final LockbarPlatform platform;

  bool _started = false;
  String? _lastSyncedLocaleTag;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    controller.addListener(_handleControllerChanged);
    trayManager.addListener(this);
    windowManager.addListener(this);

    await _configureTray();
    await _syncContextMenu();
    await _syncNativeLocale();
  }

  void dispose() {
    if (!_started) {
      return;
    }
    controller.removeListener(_handleControllerChanged);
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }

  Future<void> _configureTray() async {
    await trayManager.setIcon(
      'assets/tray/tray_icon_color.png',
      iconSize: 18,
    );
    await trayManager.setToolTip('LockBar');
  }

  Future<void> _syncContextMenu() async {
    final localizations = localizationsForLocale(controller.effectiveLocale);
    final menu = Menu(
      items: [
        MenuItem(key: _MenuAction.lockNow.name, label: localizations.lockNow),
        MenuItem.checkbox(
          key: _MenuAction.launchAtLogin.name,
          label: localizations.launchAtLogin,
          checked: controller.launchAtStartupEnabled,
          onClick: (menuItem) {
            menuItem.checked = !(menuItem.checked ?? false);
          },
        ),
        MenuItem(
          key: _MenuAction.openSettings.name,
          label: localizations.openSettings,
        ),
        MenuItem.separator(),
        MenuItem(key: _MenuAction.quit.name, label: localizations.quitAction),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  Future<void> _showSettingsWindow() async {
    await windowManager.show();
    await platform.activateApp();
    await windowManager.focus();
  }

  Future<void> _handleControllerChanged() async {
    if (!_started) {
      return;
    }
    await _syncContextMenu();
    await _syncNativeLocale();
  }

  Future<void> _syncNativeLocale() async {
    final locale = controller.effectiveLocale;
    final localeTag = locale.toLanguageTag();
    if (_lastSyncedLocaleTag == localeTag) {
      return;
    }

    _lastSyncedLocaleTag = localeTag;
    await platform.setNativeLocale(locale);
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_handlePrimaryTrayAction());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key;
    if (key == _MenuAction.lockNow.name) {
      unawaited(controller.lockNowFromSettings());
      return;
    }
    if (key == _MenuAction.launchAtLogin.name) {
      unawaited(controller.setLaunchAtStartup(menuItem.checked ?? false));
      return;
    }
    if (key == _MenuAction.openSettings.name) {
      unawaited(_showSettingsWindow());
      return;
    }
    if (key == _MenuAction.quit.name) {
      unawaited(_quitApp());
    }
  }

  @override
  void onWindowClose() {
    unawaited(windowManager.hide());
  }

  @override
  void onWindowFocus() {
    unawaited(controller.refreshPermissionState());
  }

  Future<void> _handlePrimaryTrayAction() async {
    final outcome = await controller.handlePrimaryTrayAction();
    if (outcome == TrayPrimaryActionOutcome.needsSettings) {
      await _showSettingsWindow();
    }
  }

  Future<void> _quitApp() async {
    await trayManager.destroy();
    await platform.quitApp();
  }
}

enum _MenuAction { lockNow, launchAtLogin, openSettings, quit }
