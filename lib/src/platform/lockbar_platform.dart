import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../models/ai_models.dart';
import '../models/command_panel_models.dart';
import '../models/lockbar_models.dart';

abstract class LockbarPlatform {
  Future<PermissionState> getPermissionState();

  Future<PermissionRequestResult> requestPermission();

  Future<LockResult> lockNow();

  Future<void> openAccessibilitySettings();

  Future<void> activateApp();

  Future<void> quitApp();

  Future<AppInfo> getAppInfo();

  Future<AppearanceMode> getAppearanceMode();

  Future<void> setAppearanceMode(AppearanceMode mode);

  Future<void> setNativeLocale(Locale locale);

  Future<SystemContextSnapshot> getSystemContextSnapshot({
    Set<AiDataSource> sources = const <AiDataSource>{},
  });

  Future<PermissionState> getCalendarPermissionState();

  Future<PermissionRequestResult> requestCalendarAccess();

  Future<void> startKeepAwake(Duration duration);

  Future<void> startKeepAwakeIndefinitely();

  Future<KeepAwakePlatformState> getKeepAwakeState();

  Future<KeepAwakePlatformState> stopKeepAwake();

  Future<List<BluetoothBatteryDevice>> getBluetoothBatteryDevices();

  Stream<SuggestionPanelAction> get suggestionPanelActions;

  Future<void> showSuggestionPanel(SuggestionPanelData data);

  Future<void> updateSuggestionPanel(SuggestionPanelData data);

  Future<void> hideSuggestionPanel();
}

class MethodChannelLockbarPlatform implements LockbarPlatform {
  static const MethodChannel _channel = MethodChannel('lockbar/macos');
  static final StreamController<SuggestionPanelAction> _panelActionsController =
      StreamController<SuggestionPanelAction>.broadcast();
  static bool _handlerInitialized = false;

  MethodChannelLockbarPlatform() {
    if (_handlerInitialized) {
      return;
    }
    _handlerInitialized = true;
    _channel.setMethodCallHandler((call) async {
      final arguments = call.arguments as Map<dynamic, dynamic>? ?? const {};
      final rawAction = arguments['action'] as String?;

      switch (call.method) {
        case 'suggestionPanelAction':
          _panelActionsController.add(_parseSuggestionPanelAction(rawAction));
          break;
        default:
          throw PlatformException(
            code: 'unsupported_callback',
            message: 'Unsupported native callback: ${call.method}',
          );
      }
    });
  }

  @override
  Future<PermissionState> getPermissionState() async {
    final rawState = await _channel.invokeMethod<String>('getPermissionState');
    return _parsePermissionState(rawState);
  }

  @override
  Future<PermissionRequestResult> requestPermission() async {
    final rawResult = await _channel.invokeMethod<String>('requestPermission');
    return _parsePermissionRequestResult(rawResult);
  }

  @override
  Future<LockResult> lockNow() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('lockNow');
    final rawStatus = result?['status'] as String?;
    final rawCode = result?['code'] as String?;

    return LockResult(
      status: _parseLockResultStatus(rawStatus),
      failureCode: _parseFailureCode(rawCode),
    );
  }

  @override
  Future<void> openAccessibilitySettings() {
    return _channel.invokeMethod<void>('openAccessibilitySettings');
  }

  @override
  Future<void> activateApp() {
    return _channel.invokeMethod<void>('activateApp');
  }

  @override
  Future<void> quitApp() {
    return _channel.invokeMethod<void>('quitApp');
  }

  @override
  Future<AppInfo> getAppInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getAppInfo',
    );
    return AppInfo(
      name: result?['name'] as String? ?? 'LockBar',
      version: result?['version'] as String? ?? '1.0.0',
      buildNumber: result?['buildNumber'] as String? ?? '1',
    );
  }

  @override
  Future<AppearanceMode> getAppearanceMode() async {
    final rawMode = await _channel.invokeMethod<String>('getAppearanceMode');
    return _parseAppearanceMode(rawMode);
  }

  @override
  Future<void> setAppearanceMode(AppearanceMode mode) {
    return _channel.invokeMethod<void>('setAppearanceMode', {
      'mode': mode.storageKey,
    });
  }

  @override
  Future<void> setNativeLocale(Locale locale) {
    return _channel.invokeMethod<void>('setNativeLocale', {
      'localeTag': locale.toLanguageTag(),
    });
  }

  @override
  Future<SystemContextSnapshot> getSystemContextSnapshot({
    Set<AiDataSource> sources = const <AiDataSource>{},
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getSystemContextSnapshot',
      {'sources': sources.map((source) => source.storageKey).toList()},
    );
    return SystemContextSnapshot.fromMap(result);
  }

  @override
  Future<PermissionState> getCalendarPermissionState() async {
    final rawState = await _channel.invokeMethod<String>(
      'getCalendarPermissionState',
    );
    return _parsePermissionState(rawState);
  }

  @override
  Future<PermissionRequestResult> requestCalendarAccess() async {
    final rawResult = await _channel.invokeMethod<String>(
      'requestCalendarAccess',
    );
    return _parsePermissionRequestResult(rawResult);
  }

  @override
  Future<void> startKeepAwake(Duration duration) {
    return _channel.invokeMethod<void>('startKeepAwake', {
      'durationSeconds': duration.inSeconds,
    });
  }

  @override
  Future<void> startKeepAwakeIndefinitely() {
    return _channel.invokeMethod<void>('startKeepAwakeIndefinitely');
  }

  @override
  Future<KeepAwakePlatformState> getKeepAwakeState() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getKeepAwakeState',
    );
    return KeepAwakePlatformState.fromMap(result);
  }

  @override
  Future<KeepAwakePlatformState> stopKeepAwake() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'stopKeepAwake',
    );
    return KeepAwakePlatformState.fromMap(result);
  }

  @override
  Future<List<BluetoothBatteryDevice>> getBluetoothBatteryDevices() async {
    final result = await _channel.invokeListMethod<dynamic>(
      'getBluetoothBatteryDevices',
    );
    final devices =
        (result ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map(BluetoothBatteryDevice.fromMap)
            .whereType<BluetoothBatteryDevice>()
            .where((device) => device.hasBatteryLevel)
            .toList()
          ..sort(BluetoothBatteryDevice.compareByName);
    return devices;
  }

  @override
  Stream<SuggestionPanelAction> get suggestionPanelActions =>
      _panelActionsController.stream;

  @override
  Future<void> showSuggestionPanel(SuggestionPanelData data) {
    return _channel.invokeMethod<void>('showSuggestionPanel', data.toMap());
  }

  @override
  Future<void> updateSuggestionPanel(SuggestionPanelData data) {
    return _channel.invokeMethod<void>('updateSuggestionPanel', data.toMap());
  }

  @override
  Future<void> hideSuggestionPanel() {
    return _channel.invokeMethod<void>('hideSuggestionPanel');
  }

  PermissionState _parsePermissionState(String? rawState) {
    switch (rawState) {
      case 'granted':
        return PermissionState.granted;
      case 'denied':
        return PermissionState.denied;
      case 'notDetermined':
      case null:
        return PermissionState.notDetermined;
      default:
        throw PlatformException(
          code: 'invalid_permission_state',
          message: 'Unsupported permission state: $rawState',
        );
    }
  }

  AppearanceMode _parseAppearanceMode(String? rawMode) {
    switch (rawMode) {
      case 'light':
        return AppearanceMode.light;
      case 'dark':
        return AppearanceMode.dark;
      case 'automatic':
        return AppearanceMode.automatic;
      case null:
        return AppearanceMode.light;
      default:
        throw PlatformException(
          code: 'invalid_appearance_mode',
          message: 'Unsupported appearance mode: $rawMode',
        );
    }
  }

  PermissionRequestResult _parsePermissionRequestResult(String? rawResult) {
    switch (rawResult) {
      case 'granted':
        return PermissionRequestResult.granted;
      case 'notDetermined':
      case 'denied':
      case null:
        return PermissionRequestResult.denied;
      default:
        throw PlatformException(
          code: 'invalid_permission_request_result',
          message: 'Unsupported permission request result: $rawResult',
        );
    }
  }

  LockResultStatus _parseLockResultStatus(String? rawStatus) {
    switch (rawStatus) {
      case 'success':
        return LockResultStatus.success;
      case 'permissionDenied':
        return LockResultStatus.permissionDenied;
      case 'failure':
      case null:
        return LockResultStatus.failure;
      default:
        throw PlatformException(
          code: 'invalid_lock_result',
          message: 'Unsupported lock result status: $rawStatus',
        );
    }
  }

  LockFailureCode? _parseFailureCode(String? rawCode) {
    if (rawCode == null) {
      return null;
    }

    return switch (rawCode) {
      'eventSourceUnavailable' => LockFailureCode.eventSourceUnavailable,
      'eventSequenceUnavailable' => LockFailureCode.eventSequenceUnavailable,
      _ => LockFailureCode.unknown,
    };
  }

  SuggestionPanelAction _parseSuggestionPanelAction(String? rawAction) {
    return switch (rawAction) {
      'lockNow' => SuggestionPanelAction.lockNow,
      'later' => SuggestionPanelAction.later,
      'notNow' => SuggestionPanelAction.notNow,
      'hide' => SuggestionPanelAction.hide,
      _ => throw PlatformException(
        code: 'invalid_suggestion_panel_action',
        message: 'Unsupported suggestion panel action: $rawAction',
      ),
    };
  }
}
