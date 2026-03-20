import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'l10n/locale_support.dart';
import 'models/lockbar_models.dart';
import 'platform/lockbar_platform.dart';
import 'services/launch_at_startup_service.dart';
import 'services/locale_preferences_service.dart';

class LockbarController extends ChangeNotifier {
  LockbarController({
    required this.platform,
    required this.launchAtStartupService,
    required this.localePreferencesService,
    required Locale initialSystemLocale,
  }) : _systemLocale = resolveSupportedLocale(initialSystemLocale);

  final LockbarPlatform platform;
  final LaunchAtStartupService launchAtStartupService;
  final LocalePreferencesService localePreferencesService;

  PermissionState _permissionState = PermissionState.notDetermined;
  bool _launchAtStartupEnabled = false;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _didInitialize = false;
  AppLocalePreference _localePreference = AppLocalePreference.system;
  StatusMessage? _statusMessage;
  Locale _systemLocale = englishAppLocale;
  AppInfo _appInfo = const AppInfo(
    name: 'LockBar',
    version: '1.0.0',
    buildNumber: '1',
  );

  PermissionState get permissionState => _permissionState;
  bool get launchAtStartupEnabled => _launchAtStartupEnabled;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  bool get hasError => _statusMessage?.isError ?? false;
  StatusMessage? get statusMessage => _statusMessage;
  AppInfo get appInfo => _appInfo;
  AppLocalePreference get localePreference => _localePreference;
  Locale get effectiveLocale =>
      localeForPreference(_localePreference, _systemLocale);
  bool get canLockNow =>
      _permissionState == PermissionState.granted && !_isBusy;

  Future<void> initialize() async {
    if (_didInitialize) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final permissionFuture = platform.getPermissionState();
      final launchAtLoginFuture = launchAtStartupService.isEnabled();
      final appInfoFuture = platform.getAppInfo();
      final localePreferenceFuture = localePreferencesService.loadPreference();

      _permissionState = await permissionFuture;
      _launchAtStartupEnabled = await launchAtLoginFuture;
      _appInfo = await appInfoFuture;
      _localePreference = await localePreferenceFuture;
      _setStatusKey(
        _permissionState == PermissionState.granted
            ? StatusMessageKey.trayReady
            : StatusMessageKey.permissionNeededOnce,
      );
    } catch (_) {
      _setErrorKey(StatusMessageKey.startupFailed);
    } finally {
      _didInitialize = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPermissionState() async {
    final previousState = _permissionState;
    try {
      _permissionState = await platform.getPermissionState();
      if (_permissionState == PermissionState.granted &&
          previousState != PermissionState.granted) {
        _setStatusKey(StatusMessageKey.permissionGranted);
      }
    } catch (_) {
      _setErrorKey(StatusMessageKey.permissionRefreshFailed);
    }
    notifyListeners();
  }

  Future<TrayPrimaryActionOutcome> handlePrimaryTrayAction() async {
    if (_isBusy) {
      return TrayPrimaryActionOutcome.failed;
    }

    _isBusy = true;
    notifyListeners();

    try {
      _permissionState = await platform.getPermissionState();
      if (_permissionState == PermissionState.notDetermined) {
        await _requestPermissionInternal();
        return TrayPrimaryActionOutcome.needsSettings;
      }
      if (_permissionState == PermissionState.denied) {
        _setErrorKey(StatusMessageKey.permissionStillNeeded);
        return TrayPrimaryActionOutcome.needsSettings;
      }

      final result = await platform.lockNow();
      switch (result.status) {
        case LockResultStatus.success:
          _setStatusKey(StatusMessageKey.lockCommandSent);
          return TrayPrimaryActionOutcome.locked;
        case LockResultStatus.permissionDenied:
          _permissionState = PermissionState.denied;
          _setErrorKey(StatusMessageKey.permissionStillNeeded);
          return TrayPrimaryActionOutcome.needsSettings;
        case LockResultStatus.failure:
          _setErrorKey(_messageKeyForFailure(result.failureCode));
          return TrayPrimaryActionOutcome.failed;
      }
    } catch (_) {
      _setErrorKey(StatusMessageKey.trayActionFailed);
      return TrayPrimaryActionOutcome.failed;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> lockNowFromSettings() async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    notifyListeners();

    try {
      _permissionState = await platform.getPermissionState();
      if (_permissionState == PermissionState.notDetermined) {
        await _requestPermissionInternal();
        return;
      }
      if (_permissionState == PermissionState.denied) {
        _setErrorKey(StatusMessageKey.accessibilityStillOff);
        return;
      }

      final result = await platform.lockNow();
      switch (result.status) {
        case LockResultStatus.success:
          _setStatusKey(StatusMessageKey.lockCommandSent);
          break;
        case LockResultStatus.permissionDenied:
          _permissionState = PermissionState.denied;
          _setErrorKey(StatusMessageKey.accessibilityStillOff);
          break;
        case LockResultStatus.failure:
          _setErrorKey(_messageKeyForFailure(result.failureCode));
          break;
      }
    } catch (_) {
      _setErrorKey(StatusMessageKey.lockServiceUnavailable);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    notifyListeners();

    try {
      await _requestPermissionInternal();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await platform.openAccessibilitySettings();
      _setStatusKey(StatusMessageKey.openedSystemSettings);
    } catch (_) {
      _setErrorKey(StatusMessageKey.openSystemSettingsFailed);
    }
    notifyListeners();
  }

  Future<void> setLaunchAtStartup(bool enabled) async {
    if (_isBusy) {
      return;
    }

    final previousValue = _launchAtStartupEnabled;
    _launchAtStartupEnabled = enabled;
    _isBusy = true;
    notifyListeners();

    try {
      await launchAtStartupService.setEnabled(enabled);
      _launchAtStartupEnabled = await launchAtStartupService.isEnabled();
      _setStatusKey(
        _launchAtStartupEnabled
            ? StatusMessageKey.launchAtLoginEnabled
            : StatusMessageKey.launchAtLoginDisabled,
      );
    } catch (_) {
      _launchAtStartupEnabled = previousValue;
      _setErrorKey(StatusMessageKey.launchAtLoginFailed);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> setLocalePreference(AppLocalePreference preference) async {
    if (_localePreference == preference) {
      return;
    }

    final previousPreference = _localePreference;
    _localePreference = preference;
    notifyListeners();

    try {
      await localePreferencesService.savePreference(preference);
    } catch (_) {
      _localePreference = previousPreference;
      _setErrorKey(StatusMessageKey.localePreferenceFailed);
      notifyListeners();
    }
  }

  void updateSystemLocale(Locale locale) {
    final nextLocale = resolveSupportedLocale(locale);
    if (nextLocale == _systemLocale) {
      return;
    }

    final previousEffectiveLocale = effectiveLocale;
    _systemLocale = nextLocale;
    if (_localePreference == AppLocalePreference.system &&
        previousEffectiveLocale != effectiveLocale) {
      notifyListeners();
    }
  }

  Future<void> _requestPermissionInternal() async {
    final requestResult = await platform.requestPermission();
    _permissionState = await platform.getPermissionState();

    if (requestResult == PermissionRequestResult.granted ||
        _permissionState == PermissionState.granted) {
      _setStatusKey(StatusMessageKey.permissionGrantedClickTrayAgain);
      return;
    }

    _setErrorKey(StatusMessageKey.permissionEnableThenRetry);
  }

  StatusMessageKey _messageKeyForFailure(LockFailureCode? failureCode) {
    return switch (failureCode) {
      LockFailureCode.eventSourceUnavailable =>
        StatusMessageKey.lockFailureEventSource,
      LockFailureCode.eventSequenceUnavailable =>
        StatusMessageKey.lockFailureEventSequence,
      LockFailureCode.unknown || null => StatusMessageKey.lockFailureGeneric,
    };
  }

  void _setStatusKey(StatusMessageKey key) {
    _statusMessage = StatusMessage.status(key);
  }

  void _setErrorKey(StatusMessageKey key) {
    _statusMessage = StatusMessage.error(key);
  }
}
