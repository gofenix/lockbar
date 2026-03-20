import 'package:flutter/services.dart';
import 'dart:ui';

import '../models/lockbar_models.dart';

abstract class LockbarPlatform {
  Future<PermissionState> getPermissionState();

  Future<PermissionRequestResult> requestPermission();

  Future<LockResult> lockNow();

  Future<void> openAccessibilitySettings();

  Future<void> activateApp();

  Future<void> quitApp();

  Future<AppInfo> getAppInfo();

  Future<void> setNativeLocale(Locale locale);
}

class MethodChannelLockbarPlatform implements LockbarPlatform {
  static const MethodChannel _channel = MethodChannel('lockbar/macos');

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
  Future<void> setNativeLocale(Locale locale) {
    return _channel.invokeMethod<void>('setNativeLocale', {
      'localeTag': locale.toLanguageTag(),
    });
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

  PermissionRequestResult _parsePermissionRequestResult(String? rawResult) {
    switch (rawResult) {
      case 'granted':
        return PermissionRequestResult.granted;
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
}
