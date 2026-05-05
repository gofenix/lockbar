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

  Future<void> setContextMenu(Menu menu);

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
  Future<void> setContextMenu(Menu menu) async {
    await trayManager.setContextMenu(menu);
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
  List<BluetoothBatteryDevice> _cachedBluetoothBatteryDevices = const [];
  Future<List<BluetoothBatteryDevice>>? _bluetoothBatteryRefresh;
  String? _lastCommandMenuSignature;
  bool _hasCommandMenu = false;
  StreamSubscription<SuggestionPanelAction>? _panelActionsSubscription;

  static const _settingsWindowSize = Size(520, 560);
  static const _settingsWindowMinSize = Size(460, 500);
  static const _settingsWindowMaxSize = Size(10000, 10000);

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
    await _syncTrayTitle(force: true);
    await _syncNativeLocale();
    await _syncTrayIconAppearance(force: true);
    await _syncSettingsWindow(force: true);
    await _syncSuggestionPanel(force: true);
    await _syncCommandMenu(force: true);
    _refreshBluetoothBatteryDevicesInBackground();
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

  Future<void> _syncTrayTitle({bool force = false}) async {
    final nextTitle = buildStatusItemTitle();
    if (!force && _lastTrayTitle == nextTitle) {
      return;
    }
    _lastTrayTitle = nextTitle;
    await trayClient.setTitle(nextTitle);
  }

  @visibleForTesting
  Future<CommandPanelData> buildCommandPanelData({
    bool refreshBluetoothDevices = true,
  }) async {
    final localizations = localizationsForLocale(controller.effectiveLocale);
    final keepAwakeSession = controller.keepAwakeSession;
    final keepAwakeRemaining = controller.keepAwakeRemaining;
    final canLockNow = controller.permissionState == PermissionState.granted;
    final appearanceMode = await platform.getAppearanceMode();
    final bluetoothDevices = refreshBluetoothDevices
        ? await _refreshBluetoothBatteryDevices()
        : _cachedBluetoothBatteryDevices;

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
      appearanceTitle: localizations.appearanceAction,
      appearanceMode: appearanceMode,
      appearanceLightLabel: localizations.appearanceLightAction,
      appearanceDarkLabel: localizations.appearanceDarkAction,
      appearanceAutomaticLabel: localizations.appearanceAutomaticAction,
      bluetoothDevicesTitle: localizations.commandPanelBluetoothDevicesTitle,
      bluetoothDevices: bluetoothDevices,
      launchAtLoginLabel: localizations.launchAtLogin,
      launchAtLoginEnabled: controller.launchAtStartupEnabled,
      openSettingsLabel: localizations.openSettings,
      quitLabel: localizations.quitAction,
    );
  }

  void _refreshBluetoothBatteryDevicesInBackground() {
    unawaited(_refreshBluetoothBatteryDevices());
  }

  Future<List<BluetoothBatteryDevice>> _refreshBluetoothBatteryDevices() {
    final inFlight = _bluetoothBatteryRefresh;
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<List<BluetoothBatteryDevice>> refresh;
    refresh = _loadBluetoothBatteryDevices().whenComplete(() {
      if (identical(_bluetoothBatteryRefresh, refresh)) {
        _bluetoothBatteryRefresh = null;
      }
    });
    _bluetoothBatteryRefresh = refresh;
    return refresh;
  }

  Future<List<BluetoothBatteryDevice>> _loadBluetoothBatteryDevices() async {
    try {
      final devices = await platform.getBluetoothBatteryDevices();
      _cachedBluetoothBatteryDevices =
          devices.where((device) => device.hasBatteryLevel).toList()
            ..sort(BluetoothBatteryDevice.compareByName);
      if (_started) {
        unawaited(_syncCommandMenu(force: true));
      }
      return _cachedBluetoothBatteryDevices;
    } catch (_) {
      return _cachedBluetoothBatteryDevices;
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
  String buildStatusItemTitle() {
    if (controller.focusSession == null &&
        controller.keepAwakeSession == null) {
      return '';
    }
    return buildTrayTitle();
  }

  @visibleForTesting
  Future<void> syncTrayTitleForTesting({bool force = false}) async {
    await _syncTrayTitle(force: force);
  }

  @visibleForTesting
  Future<void> syncCommandMenuForTesting({bool force = false}) async {
    await _syncCommandMenu(force: force);
  }

  @visibleForTesting
  Future<Menu> buildCommandMenuForTesting() async {
    return _buildCommandMenu();
  }

  @visibleForTesting
  Future<void> showCommandPanelForTesting() async {
    await _showCommandMenu(refreshBluetoothDevices: true);
  }

  @visibleForTesting
  Future<void> handleCommandPanelActionForTesting(
    CommandPanelAction action,
  ) async {
    await handleCommandPanelAction(action);
  }

  Future<void> handleCommandPanelAction(CommandPanelAction action) async {
    await _handleCommandPanelAction(action);
  }

  Future<void> _handleControllerChanged() async {
    if (!_started) {
      return;
    }
    await _syncTrayTitle();
    await _syncNativeLocale();
    await _syncTrayIconAppearance();
    await _syncSettingsWindow();
    await _syncSuggestionPanel();
    await _syncCommandMenu();
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
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(_settingsWindowMinSize);
    await windowManager.setMaximumSize(_settingsWindowMaxSize);
    await windowManager.setBackgroundColor(const Color(0xFFF4F5F7));
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
    switch (action) {
      case CommandPanelAction.lockNow:
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
      case CommandPanelAction.setAppearanceLight:
        await _setAppearanceMode(AppearanceMode.light);
        break;
      case CommandPanelAction.setAppearanceDark:
        await _setAppearanceMode(AppearanceMode.dark);
        break;
      case CommandPanelAction.setAppearanceAutomatic:
        await _setAppearanceMode(AppearanceMode.automatic);
        break;
      case CommandPanelAction.toggleLaunchAtLogin:
        await controller.setLaunchAtStartup(!controller.launchAtStartupEnabled);
        break;
      case CommandPanelAction.openSettings:
        controller.openSettingsWindow();
        break;
      case CommandPanelAction.quit:
        await _quitApp();
        break;
      case CommandPanelAction.hide:
        break;
    }
  }

  Future<void> _setAppearanceMode(AppearanceMode mode) async {
    try {
      await platform.setAppearanceMode(mode);
    } catch (_) {
      // Keep the menu responsive if macOS Automation permission is denied.
    } finally {
      await _syncCommandMenu(force: true);
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_handlePrimaryTrayAction());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(_showCommandMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final action = CommandPanelAction.fromStorageKey(menuItem.key);
    if (action == CommandPanelAction.hide) {
      return;
    }
    unawaited(_handleCommandPanelAction(action));
  }

  Future<void> _showCommandMenu({bool refreshBluetoothDevices = false}) async {
    if (refreshBluetoothDevices || !_hasCommandMenu) {
      await _syncCommandMenu(
        force: refreshBluetoothDevices || !_hasCommandMenu,
        refreshBluetoothDevices: refreshBluetoothDevices,
      );
    } else {
      _refreshBluetoothBatteryDevicesInBackground();
    }
    await trayClient.popUpContextMenu();
  }

  Future<void> _syncCommandMenu({
    bool force = false,
    bool refreshBluetoothDevices = false,
  }) async {
    final data = await buildCommandPanelData(
      refreshBluetoothDevices: refreshBluetoothDevices,
    );
    if (!force && _lastCommandMenuSignature == data.signature) {
      return;
    }
    await trayClient.setContextMenu(_buildCommandMenuFromData(data));
    _lastCommandMenuSignature = data.signature;
    _hasCommandMenu = true;
  }

  Future<Menu> _buildCommandMenu({bool refreshBluetoothDevices = true}) async {
    final data = await buildCommandPanelData(
      refreshBluetoothDevices: refreshBluetoothDevices,
    );
    return _buildCommandMenuFromData(data);
  }

  Menu _buildCommandMenuFromData(CommandPanelData data) {
    final localizations = localizationsForLocale(controller.effectiveLocale);
    final items = <MenuItem>[
      MenuItem(label: data.statusText, disabled: true),
      MenuItem.separator(),
      MenuItem(
        key: CommandPanelAction.lockNow.storageKey,
        label: data.lockNowLabel,
        disabled: !data.canLockNow,
      ),
      MenuItem.submenu(
        label: data.keepAwakeTitle,
        submenu: Menu(
          items: [
            _keepAwakePresetItem(
              action: CommandPanelAction.keepAwake30Minutes,
              label: localizations.keepAwakeFor30MinutesAction,
              selected: data.keepAwakePreset == KeepAwakePreset.thirtyMinutes,
            ),
            _keepAwakePresetItem(
              action: CommandPanelAction.keepAwake1Hour,
              label: localizations.keepAwakeForOneHourAction,
              selected: data.keepAwakePreset == KeepAwakePreset.oneHour,
            ),
            _keepAwakePresetItem(
              action: CommandPanelAction.keepAwake2Hours,
              label: localizations.keepAwakeForTwoHoursAction,
              selected: data.keepAwakePreset == KeepAwakePreset.twoHours,
            ),
            _keepAwakePresetItem(
              action: CommandPanelAction.keepAwakeIndefinitely,
              label: localizations.keepAwakeIndefinitelyAction,
              selected: data.keepAwakePreset == KeepAwakePreset.indefinite,
            ),
            MenuItem.separator(),
            MenuItem(
              key: CommandPanelAction.cancelKeepAwake.storageKey,
              label: data.cancelKeepAwakeLabel,
              disabled: !data.keepAwakeActive,
            ),
          ],
        ),
      ),
      MenuItem.submenu(
        label: data.appearanceTitle,
        submenu: Menu(
          items: [
            _appearanceModeItem(
              action: CommandPanelAction.setAppearanceLight,
              label: data.appearanceLightLabel,
              selected: data.appearanceMode == AppearanceMode.light,
            ),
            _appearanceModeItem(
              action: CommandPanelAction.setAppearanceDark,
              label: data.appearanceDarkLabel,
              selected: data.appearanceMode == AppearanceMode.dark,
            ),
            _appearanceModeItem(
              action: CommandPanelAction.setAppearanceAutomatic,
              label: data.appearanceAutomaticLabel,
              selected: data.appearanceMode == AppearanceMode.automatic,
            ),
          ],
        ),
      ),
      MenuItem.checkbox(
        key: CommandPanelAction.toggleLaunchAtLogin.storageKey,
        label: data.launchAtLoginLabel,
        checked: data.launchAtLoginEnabled,
      ),
    ];

    if (data.bluetoothDevices.isNotEmpty) {
      items.add(MenuItem.separator());
      items.add(
        MenuItem.submenu(
          label: data.bluetoothDevicesTitle,
          submenu: Menu(
            items: data.bluetoothDevices
                .map(
                  (device) => MenuItem(
                    label: '${device.name}  ${_batterySummary(device)}',
                    disabled: true,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
    }

    items.addAll([
      MenuItem.separator(),
      MenuItem(
        key: CommandPanelAction.openSettings.storageKey,
        label: data.openSettingsLabel,
      ),
      MenuItem(key: CommandPanelAction.quit.storageKey, label: data.quitLabel),
    ]);

    return Menu(items: items);
  }

  MenuItem _appearanceModeItem({
    required CommandPanelAction action,
    required String label,
    required bool selected,
  }) {
    return MenuItem.checkbox(
      key: action.storageKey,
      label: label,
      checked: selected,
    );
  }

  MenuItem _keepAwakePresetItem({
    required CommandPanelAction action,
    required String label,
    required bool selected,
  }) {
    return MenuItem.checkbox(
      key: action.storageKey,
      label: label,
      checked: selected,
    );
  }

  String _batterySummary(BluetoothBatteryDevice device) {
    final parts = <String>[];
    if (device.leftBatteryLevel != null) {
      parts.add('L ${device.leftBatteryLevel}%');
    }
    if (device.rightBatteryLevel != null) {
      parts.add('R ${device.rightBatteryLevel}%');
    }
    if (device.caseBatteryLevel != null) {
      parts.add('Case ${device.caseBatteryLevel}%');
    }
    if (parts.isNotEmpty) {
      return parts.join(' / ');
    }
    return '${device.batteryLevel}%';
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
