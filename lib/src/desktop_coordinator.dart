import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'l10n/locale_support.dart';
import 'lockbar_controller.dart';
import 'models/ai_models.dart';
import 'models/lockbar_models.dart';
import 'platform/lockbar_platform.dart';

abstract class LockbarTrayClient {
  void addListener(TrayListener listener);

  void removeListener(TrayListener listener);

  Future<void> destroy();

  Future<void> setContextMenu(Menu menu);

  Future<void> setIcon(
    String path, {
    required int iconSize,
    required bool isTemplate,
  });

  Future<void> setTitle(String title);

  Future<void> setToolTip(String toolTip);

  Future<void> popUpContextMenu();
}

class SystemLockbarTrayClient implements LockbarTrayClient {
  const SystemLockbarTrayClient();

  @override
  void addListener(TrayListener listener) {
    trayManager.addListener(listener);
  }

  @override
  void removeListener(TrayListener listener) {
    trayManager.removeListener(listener);
  }

  @override
  Future<void> destroy() async {
    await trayManager.destroy();
  }

  @override
  Future<void> setContextMenu(Menu menu) async {
    await trayManager.setContextMenu(menu);
  }

  @override
  Future<void> setIcon(
    String path, {
    required int iconSize,
    required bool isTemplate,
  }) async {
    await trayManager.setIcon(path, iconSize: iconSize, isTemplate: isTemplate);
  }

  @override
  Future<void> setTitle(String title) async {
    await trayManager.setTitle(title);
  }

  @override
  Future<void> setToolTip(String toolTip) async {
    await trayManager.setToolTip(toolTip);
  }

  @override
  Future<void> popUpContextMenu() async {
    await trayManager.popUpContextMenu();
  }
}

class LockbarDesktopCoordinator with TrayListener, WindowListener {
  LockbarDesktopCoordinator({
    required this.controller,
    required this.platform,
    LockbarTrayClient? trayClient,
  }) : trayClient = trayClient ?? const SystemLockbarTrayClient();

  final LockbarController controller;
  final LockbarPlatform platform;
  final LockbarTrayClient trayClient;

  bool _started = false;
  bool _didPrepareSettingsWindow = false;
  String? _lastSyncedLocaleTag;
  String? _lastTrayTitle;
  bool? _lastSettingsVisible;
  bool? _lastSuggestionPanelVisible;
  String? _lastSuggestionPanelSignature;
  bool? _lastSuggestionIndicatorVisible;
  StreamSubscription<SuggestionPanelAction>? _panelActionsSubscription;

  static const _settingsWindowSize = Size(520, 560);
  static const _settingsWindowMinSize = Size(460, 500);

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    controller.addListener(_handleControllerChanged);
    trayClient.addListener(this);
    windowManager.addListener(this);
    _panelActionsSubscription = platform.suggestionPanelActions.listen(
      _handleSuggestionPanelAction,
    );

    await _configureTray();
    await _syncContextMenu();
    await _syncTrayTitle(force: true);
    await _syncNativeLocale();
    await _syncTrayIconAppearance(force: true);
    await _syncSettingsWindow(force: true);
    await _syncSuggestionPanel(force: true);
  }

  void dispose() {
    if (!_started) {
      return;
    }
    _panelActionsSubscription?.cancel();
    controller.removeListener(_handleControllerChanged);
    trayClient.removeListener(this);
    windowManager.removeListener(this);
  }

  Future<void> _configureTray() async {
    await _applyTrayIcon(controller.hasSuggestionIndicator);
    await trayClient.setToolTip('LockBar');
  }

  String _trayIconAsset(bool attention) {
    return attention
        ? 'assets/tray/tray_icon_color.png'
        : 'assets/tray/tray_icon_template.png';
  }

  Future<void> _applyTrayIcon(bool attention) async {
    await trayClient.setIcon(
      _trayIconAsset(attention),
      iconSize: 19,
      isTemplate: !attention,
    );
  }

  Future<void> _syncTrayIconAppearance({bool force = false}) async {
    final attention = controller.hasSuggestionIndicator;
    if (!force && _lastSuggestionIndicatorVisible == attention) {
      return;
    }
    _lastSuggestionIndicatorVisible = attention;
    await _applyTrayIcon(attention);
  }

  Future<void> _syncContextMenu() async {
    await trayClient.setContextMenu(buildContextMenu());
  }

  Future<void> _syncTrayTitle({bool force = false}) async {
    final nextTitle = buildTrayTitle();
    if (!force && _lastTrayTitle == nextTitle) {
      return;
    }
    _lastTrayTitle = nextTitle;
    await trayClient.setTitle(nextTitle);
  }

  @visibleForTesting
  Menu buildContextMenu() {
    final localizations = localizationsForLocale(controller.effectiveLocale);
    final items = <MenuItem>[];

    if (controller.activeSuggestion != null) {
      items.add(
        MenuItem(
          key: _MenuAction.reviewSuggestion.name,
          label: localizations.aiReviewSuggestionAction,
        ),
      );
      items.add(
        MenuItem(
          key: _MenuAction.suggestionLockNow.name,
          label: localizations.lockNow,
        ),
      );
      items.add(
        MenuItem(
          key: _MenuAction.suggestionLater.name,
          label: localizations.aiLaterAction,
        ),
      );
      items.add(
        MenuItem(
          key: _MenuAction.suggestionNotNow.name,
          label: localizations.aiNotNowAction,
        ),
      );
      items.add(MenuItem.separator());
    }

    if (controller.focusSession == null) {
      items.add(
        MenuItem.submenu(
          key: _MenuAction.startFocus.name,
          label: localizations.aiStartFocusAction,
          submenu: Menu(
            items: [
              MenuItem(
                key: _MenuAction.startFocus25.name,
                label: localizations.aiFocusPreset25,
              ),
              MenuItem(
                key: _MenuAction.startFocus50.name,
                label: localizations.aiFocusPreset50,
              ),
            ],
          ),
        ),
      );
    } else {
      items.add(
        MenuItem(
          label: focusMenuStatusLabel(localizations, controller.focusRemaining),
          disabled: true,
        ),
      );
      items.add(
        MenuItem(
          key: _MenuAction.cancelFocus.name,
          label: localizations.aiCancelFocusAction,
        ),
      );
    }

    items.add(
      MenuItem(
        key: _MenuAction.endWorkday.name,
        label: localizations.aiEndWorkdayAction,
      ),
    );

    if (controller.delayedLock == null) {
      items.add(
        MenuItem.submenu(
          key: _MenuAction.scheduleLock.name,
          label: localizations.aiLockInAction,
          submenu: Menu(
            items: [
              MenuItem(
                key: _MenuAction.lockIn30Seconds.name,
                label: localizations.aiLockIn30Seconds,
              ),
              MenuItem(
                key: _MenuAction.lockIn2Minutes.name,
                label: localizations.aiLockIn2Minutes,
              ),
              MenuItem(
                key: _MenuAction.lockIn5Minutes.name,
                label: localizations.aiLockIn5Minutes,
              ),
            ],
          ),
        ),
      );
    } else {
      items.add(
        MenuItem(
          key: _MenuAction.cancelDelayedLock.name,
          label: localizations.aiCancelDelayedLockAction,
        ),
      );
    }

    final keepAwakeSession = controller.keepAwakeSession;
    final keepAwakeRemaining = controller.keepAwakeRemaining;
    final keepAwakeItems = <MenuItem>[
      if (keepAwakeSession != null)
        MenuItem(
          label: keepAwakeMenuStatusLabel(
            localizations,
            keepAwakeSession,
            keepAwakeRemaining,
          ),
          disabled: true,
        ),
      if (keepAwakeSession != null) MenuItem.separator(),
      MenuItem.checkbox(
        key: _MenuAction.keepAwake30Minutes.name,
        label: localizations.keepAwakeFor30MinutesAction,
        checked: keepAwakeSession?.preset == KeepAwakePreset.thirtyMinutes,
      ),
      MenuItem.checkbox(
        key: _MenuAction.keepAwake1Hour.name,
        label: localizations.keepAwakeForOneHourAction,
        checked: keepAwakeSession?.preset == KeepAwakePreset.oneHour,
      ),
      MenuItem.checkbox(
        key: _MenuAction.keepAwake2Hours.name,
        label: localizations.keepAwakeForTwoHoursAction,
        checked: keepAwakeSession?.preset == KeepAwakePreset.twoHours,
      ),
      MenuItem.checkbox(
        key: _MenuAction.keepAwakeIndefinitely.name,
        label: localizations.keepAwakeIndefinitelyAction,
        checked: keepAwakeSession?.preset == KeepAwakePreset.indefinite,
      ),
    ];
    items.add(
      MenuItem.submenu(
        key: _MenuAction.keepAwake.name,
        label: localizations.keepAwakeAction,
        submenu: Menu(items: keepAwakeItems),
      ),
    );

    if (controller.keepAwakeSession != null) {
      items.add(
        MenuItem(
          key: _MenuAction.cancelKeepAwake.name,
          label: localizations.cancelKeepAwakeAction,
        ),
      );
    }

    items.add(MenuItem.separator());
    items.add(
      MenuItem(key: _MenuAction.lockNow.name, label: localizations.lockNow),
    );
    items.add(
      MenuItem.checkbox(
        key: _MenuAction.launchAtLogin.name,
        label: localizations.launchAtLogin,
        checked: controller.launchAtStartupEnabled,
        onClick: (menuItem) {
          menuItem.checked = !(menuItem.checked ?? false);
        },
      ),
    );
    items.add(
      MenuItem(
        key: _MenuAction.openSettings.name,
        label: localizations.openSettings,
      ),
    );
    items.add(MenuItem.separator());
    items.add(
      MenuItem(key: _MenuAction.quit.name, label: localizations.quitAction),
    );

    return Menu(items: items);
  }

  @visibleForTesting
  String buildTrayTitle() {
    final localizations = localizationsForLocale(controller.effectiveLocale);
    return trayTitle(
      localizations,
      focusSession: controller.focusSession,
      focusRemaining: controller.focusRemaining,
      keepAwakeSession: controller.keepAwakeSession,
      keepAwakeRemaining: controller.keepAwakeRemaining,
    );
  }

  @visibleForTesting
  Future<void> syncTrayTitleForTesting({bool force = false}) async {
    await _syncTrayTitle(force: force);
  }

  Future<void> _handleControllerChanged() async {
    if (!_started) {
      return;
    }
    await _syncContextMenu();
    await _syncTrayTitle();
    await _syncNativeLocale();
    await _syncTrayIconAppearance();
    await _syncSettingsWindow();
    await _syncSuggestionPanel();
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

  Future<void> _syncSettingsWindow({bool force = false}) async {
    final visible = controller.isSettingsWindowVisible;
    if (!force && _lastSettingsVisible == visible) {
      return;
    }

    if (!visible) {
      await windowManager.hide();
      _lastSettingsVisible = false;
      return;
    }

    await windowManager.setAlwaysOnTop(false);
    await windowManager.setMinimumSize(_settingsWindowMinSize);
    if (!_didPrepareSettingsWindow) {
      await windowManager.setSize(_settingsWindowSize);
      await windowManager.center();
      _didPrepareSettingsWindow = true;
    }
    await windowManager.show();
    await platform.activateApp();
    await windowManager.focus();
    _lastSettingsVisible = true;
  }

  Future<void> _syncSuggestionPanel({bool force = false}) async {
    final data = _buildSuggestionPanelData();
    final visible = controller.isSuggestionPanelVisible && data != null;
    final signature = data == null
        ? null
        : [
            data.title,
            data.headline,
            data.reason,
            data.usedSignalLabels.join('|'),
            controller.effectiveLocale.toLanguageTag(),
          ].join('::');

    if (!visible) {
      if (force || _lastSuggestionPanelVisible != false) {
        await platform.hideSuggestionPanel();
      }
      _lastSuggestionPanelVisible = false;
      _lastSuggestionPanelSignature = null;
      return;
    }

    if (_lastSuggestionPanelVisible != true) {
      await platform.showSuggestionPanel(data);
    } else if (force || _lastSuggestionPanelSignature != signature) {
      await platform.updateSuggestionPanel(data);
    }

    _lastSuggestionPanelVisible = true;
    _lastSuggestionPanelSignature = signature;
  }

  SuggestionPanelData? _buildSuggestionPanelData() {
    final suggestion = controller.activeSuggestion;
    if (suggestion == null) {
      return null;
    }
    final localizations = localizationsForLocale(controller.effectiveLocale);
    return SuggestionPanelData(
      title: localizations.aiCardTitle,
      headline: suggestion.headline,
      reason: suggestion.reason,
      lockNowLabel: localizations.lockNow,
      laterLabel: localizations.aiLaterAction,
      notNowLabel: localizations.aiNotNowAction,
      whyActionLabel: localizations.aiWhyAction,
      whySectionTitle: localizations.aiWhyInlineTitle,
      usedSignalLabels: suggestion.usedSignals
          .map((signal) => aiSignalLabel(localizations, signal))
          .toList(growable: false),
    );
  }

  Future<void> _handleSuggestionPanelAction(
    SuggestionPanelAction action,
  ) async {
    switch (action) {
      case SuggestionPanelAction.lockNow:
        await controller.acceptActiveSuggestionLockNow();
      case SuggestionPanelAction.later:
        await controller.acceptActiveSuggestionLater();
      case SuggestionPanelAction.notNow:
        await controller.dismissActiveSuggestionNotNow();
      case SuggestionPanelAction.hide:
        controller.handleSuggestionPanelHidden();
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_handlePrimaryTrayAction());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayClient.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key;
    switch (key) {
      case 'lockNow':
        unawaited(controller.lockNowFromSettings());
        break;
      case 'launchAtLogin':
        unawaited(controller.setLaunchAtStartup(menuItem.checked ?? false));
        break;
      case 'openSettings':
        controller.openSettingsWindow();
        break;
      case 'quit':
        unawaited(_quitApp());
        break;
      case 'startFocus25':
        unawaited(controller.startFocusSession(const Duration(minutes: 25)));
        break;
      case 'startFocus50':
        unawaited(controller.startFocusSession(const Duration(minutes: 50)));
        break;
      case 'cancelFocus':
        unawaited(controller.cancelFocusSession());
        break;
      case 'endWorkday':
        unawaited(controller.triggerWorkdayWrapUp());
        break;
      case 'lockIn30Seconds':
        unawaited(controller.scheduleDelayedLock(const Duration(seconds: 30)));
        break;
      case 'lockIn2Minutes':
        unawaited(controller.scheduleDelayedLock(const Duration(minutes: 2)));
        break;
      case 'lockIn5Minutes':
        unawaited(controller.scheduleDelayedLock(const Duration(minutes: 5)));
        break;
      case 'cancelDelayedLock':
        unawaited(controller.cancelDelayedLock());
        break;
      case 'keepAwake30Minutes':
        unawaited(
          controller.startKeepAwakeSession(const Duration(minutes: 30)),
        );
        break;
      case 'keepAwake1Hour':
        unawaited(controller.startKeepAwakeSession(const Duration(hours: 1)));
        break;
      case 'keepAwake2Hours':
        unawaited(controller.startKeepAwakeSession(const Duration(hours: 2)));
        break;
      case 'keepAwakeIndefinitely':
        unawaited(controller.startKeepAwakeIndefinitely());
        break;
      case 'cancelKeepAwake':
        unawaited(controller.cancelKeepAwakeSession());
        break;
      case 'reviewSuggestion':
        controller.reopenActiveSuggestionCard();
        break;
      case 'suggestionLockNow':
        unawaited(controller.acceptActiveSuggestionLockNow());
        break;
      case 'suggestionLater':
        unawaited(controller.acceptActiveSuggestionLater());
        break;
      case 'suggestionNotNow':
        unawaited(controller.dismissActiveSuggestionNotNow());
        break;
    }
  }

  @override
  void onWindowClose() {
    controller.handleWindowClosed();
  }

  @override
  void onWindowFocus() {
    unawaited(controller.refreshPermissionState());
    unawaited(controller.refreshCalendarPermissionState());
  }

  Future<void> _handlePrimaryTrayAction() async {
    final outcome = await controller.handlePrimaryTrayAction();
    if (outcome == TrayPrimaryActionOutcome.needsSettings) {
      controller.openSettingsWindow();
    }
  }

  Future<void> _quitApp() async {
    await trayClient.destroy();
    await platform.quitApp();
  }
}

enum _MenuAction {
  reviewSuggestion,
  suggestionLockNow,
  suggestionLater,
  suggestionNotNow,
  startFocus,
  startFocus25,
  startFocus50,
  cancelFocus,
  endWorkday,
  scheduleLock,
  lockIn30Seconds,
  lockIn2Minutes,
  lockIn5Minutes,
  cancelDelayedLock,
  keepAwake,
  keepAwake30Minutes,
  keepAwake1Hour,
  keepAwake2Hours,
  keepAwakeIndefinitely,
  cancelKeepAwake,
  lockNow,
  launchAtLogin,
  openSettings,
  quit,
}
