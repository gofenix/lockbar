import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_support.dart';
import 'lockbar_controller.dart';
import 'models/ai_models.dart';
import 'models/command_panel_models.dart';
import 'models/lockbar_models.dart';
import 'platform/lockbar_platform.dart';

abstract class LockbarTrayClient {
  void addListener(TrayListener listener);

  void removeListener(TrayListener listener);

  Future<void> destroy();

  Future<void> setIcon(
    String path, {
    required int iconSize,
    required bool isTemplate,
  });

  Future<void> setTitle(String title);

  Future<void> setToolTip(String toolTip);
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
  StreamSubscription<CommandPanelAction>? _commandPanelActionsSubscription;
  bool _commandPanelVisible = false;
  String? _lastCommandPanelSignature;

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
    _commandPanelActionsSubscription = platform.commandPanelActions.listen(
      _handleCommandPanelAction,
    );

    await _configureTray();
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
    _commandPanelActionsSubscription?.cancel();
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

  Future<void> _syncTrayTitle({bool force = false}) async {
    final nextTitle = buildTrayTitle();
    if (!force && _lastTrayTitle == nextTitle) {
      return;
    }
    _lastTrayTitle = nextTitle;
    await trayClient.setTitle(nextTitle);
  }

  @visibleForTesting
  Future<CommandPanelData> buildCommandPanelData() async {
    final localizations = localizationsForLocale(controller.effectiveLocale);
    final keepAwakeSession = controller.keepAwakeSession;
    final keepAwakeRemaining = controller.keepAwakeRemaining;
    final canLockNow = controller.permissionState == PermissionState.granted;
    final bluetoothDevices = await _bluetoothBatteryDevicesForCommandPanel();

    return CommandPanelData(
      title: 'LockBar',
      statusText: _commandPanelStatusText(
        localizations,
        keepAwakeSession,
        keepAwakeRemaining,
      ),
      subtitleText: canLockNow
          ? localizations.primaryActionDescription
          : _permissionSummary(localizations),
      lockNowLabel: localizations.lockNow,
      canLockNow: canLockNow,
      keepAwakeTitle: _cleanMenuTitle(localizations.keepAwakeAction),
      keepAwakeSubtitle: keepAwakeStatusLabel(
        localizations,
        keepAwakeSession,
        keepAwakeRemaining,
      ),
      keepAwakeActive: keepAwakeSession != null,
      keepAwakePreset: keepAwakeSession?.preset,
      keepAwake30MinutesLabel: '30m',
      keepAwake1HourLabel: '1h',
      keepAwake2HoursLabel: '2h',
      keepAwakeIndefinitelyLabel: '\u221e',
      cancelKeepAwakeLabel: localizations.cancelKeepAwakeAction,
      bluetoothDevicesTitle: localizations.commandPanelBluetoothDevicesTitle,
      bluetoothDevices: bluetoothDevices,
      launchAtLoginLabel: localizations.launchAtLogin,
      launchAtLoginEnabled: controller.launchAtStartupEnabled,
      openSettingsLabel: localizations.openSettings,
      quitLabel: localizations.quitAction,
    );
  }

  Future<List<BluetoothBatteryDevice>>
  _bluetoothBatteryDevicesForCommandPanel() async {
    try {
      final devices = await platform.getBluetoothBatteryDevices();
      return devices.where((device) => device.hasBatteryLevel).toList()
        ..sort(BluetoothBatteryDevice.compareByName);
    } catch (_) {
      return const [];
    }
  }

  String _commandPanelStatusText(
    AppLocalizations localizations,
    KeepAwakeSessionState? keepAwakeSession,
    Duration? keepAwakeRemaining,
  ) {
    if (controller.permissionState == PermissionState.denied) {
      return localizations.permissionDeniedTitle;
    }
    if (controller.permissionState == PermissionState.notDetermined) {
      return localizations.permissionNotDeterminedTitle;
    }
    if (keepAwakeSession == null) {
      return localizations.trayTitleReady;
    }
    if (keepAwakeSession.isIndefinite) {
      return localizations.trayTitleKeepAwakeIndefinitely;
    }
    return localizations.trayTitleKeepAwake(
      formatClockDuration(keepAwakeRemaining ?? Duration.zero),
    );
  }

  String _permissionSummary(AppLocalizations localizations) {
    return switch (controller.permissionState) {
      PermissionState.denied => localizations.permissionDeniedTitle,
      PermissionState.notDetermined =>
        localizations.permissionNotDeterminedTitle,
      PermissionState.granted => localizations.primaryActionDescription,
    };
  }

  String _cleanMenuTitle(String value) {
    return value.replaceAll('\u2026', '').trim();
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

  @visibleForTesting
  Future<void> syncCommandPanelForTesting({bool force = false}) async {
    await _syncCommandPanel(force: force);
  }

  @visibleForTesting
  Future<void> showCommandPanelForTesting() async {
    await _showCommandPanel();
  }

  @visibleForTesting
  Future<void> handleCommandPanelActionForTesting(
    CommandPanelAction action,
  ) async {
    await _handleCommandPanelAction(action);
  }

  Future<void> _handleControllerChanged() async {
    if (!_started) {
      return;
    }
    await _syncCommandPanel();
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

  Future<void> _handleCommandPanelAction(CommandPanelAction action) async {
    if (action == CommandPanelAction.hide) {
      _commandPanelVisible = false;
      _lastCommandPanelSignature = null;
      return;
    }

    switch (action) {
      case CommandPanelAction.lockNow:
        await _hideCommandPanel();
        await controller.lockNowFromSettings();
        break;
      case CommandPanelAction.keepAwake30Minutes:
        await controller.startKeepAwakeSession(const Duration(minutes: 30));
        break;
      case CommandPanelAction.keepAwake1Hour:
        await controller.startKeepAwakeSession(const Duration(hours: 1));
        break;
      case CommandPanelAction.keepAwake2Hours:
        await controller.startKeepAwakeSession(const Duration(hours: 2));
        break;
      case CommandPanelAction.keepAwakeIndefinitely:
        await controller.startKeepAwakeIndefinitely();
        break;
      case CommandPanelAction.cancelKeepAwake:
        await controller.cancelKeepAwakeSession();
        break;
      case CommandPanelAction.toggleLaunchAtLogin:
        await controller.setLaunchAtStartup(!controller.launchAtStartupEnabled);
        break;
      case CommandPanelAction.openSettings:
        await _hideCommandPanel();
        controller.openSettingsWindow();
        break;
      case CommandPanelAction.quit:
        await _hideCommandPanel();
        await _quitApp();
        break;
      case CommandPanelAction.hide:
        break;
    }
  }

  Future<void> _hideCommandPanel() async {
    _commandPanelVisible = false;
    _lastCommandPanelSignature = null;
    await platform.hideCommandPanel();
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_handlePrimaryTrayAction());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(_showCommandPanel());
  }

  Future<void> _showCommandPanel() async {
    final data = await buildCommandPanelData();
    _commandPanelVisible = true;
    _lastCommandPanelSignature = data.signature;
    await platform.showCommandPanel(data);
  }

  Future<void> _syncCommandPanel({bool force = false}) async {
    if (!_commandPanelVisible) {
      return;
    }
    final data = await buildCommandPanelData();
    if (!force && _lastCommandPanelSignature == data.signature) {
      return;
    }
    _lastCommandPanelSignature = data.signature;
    await platform.updateCommandPanel(data);
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
