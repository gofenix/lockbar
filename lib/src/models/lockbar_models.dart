import 'dart:ui';

enum PermissionState { notDetermined, denied, granted }

enum PermissionRequestResult { granted, denied }

enum LockResultStatus { success, permissionDenied, failure }

enum LockFailureCode {
  eventSourceUnavailable,
  eventSequenceUnavailable,
  unknown,
}

enum TrayPrimaryActionOutcome { locked, needsSettings, failed }

enum AppLocalePreference {
  system,
  english,
  simplifiedChinese;

  String get storageValue => switch (this) {
    AppLocalePreference.system => 'system',
    AppLocalePreference.english => 'en',
    AppLocalePreference.simplifiedChinese => 'zh-Hans',
  };

  static AppLocalePreference fromStorage(String? value) => switch (value) {
    'en' => AppLocalePreference.english,
    'zh-Hans' => AppLocalePreference.simplifiedChinese,
    _ => AppLocalePreference.system,
  };
}

enum StatusMessageKey {
  trayReady,
  permissionNeededOnce,
  startupFailed,
  permissionGranted,
  permissionRefreshFailed,
  permissionStillNeeded,
  trayActionFailed,
  accessibilityStillOff,
  lockServiceUnavailable,
  openedSystemSettings,
  openSystemSettingsFailed,
  launchAtLoginEnabled,
  launchAtLoginDisabled,
  launchAtLoginFailed,
  permissionGrantedClickTrayAgain,
  permissionEnableThenRetry,
  lockCommandSent,
  lockFailureEventSource,
  lockFailureEventSequence,
  lockFailureGeneric,
  localePreferenceFailed,
  aiModeEnabled,
  aiModeDisabled,
  aiSettingsSaveFailed,
  aiConfigurationSaved,
  aiConfigurationMissing,
  aiConnectionVerificationRequired,
  aiConnectionTestSucceeded,
  aiConnectionTestFailed,
  aiRequestTimedOut,
  aiRequestFailed,
  aiInvalidResponse,
  aiMemoryReset,
  aiMemoryResetFailed,
  focusSessionStarted,
  focusSessionCancelled,
  delayedLockScheduled,
  delayedLockCancelled,
  keepAwakeStarted,
  keepAwakeStartedIndefinitely,
  keepAwakeCancelled,
  keepAwakeExpired,
  keepAwakeFailed,
  workdayReviewStarted,
}

class StatusMessage {
  const StatusMessage.status(this.key) : isError = false;

  const StatusMessage.error(this.key) : isError = true;

  final StatusMessageKey key;
  final bool isError;
}

class LockResult {
  const LockResult({required this.status, this.failureCode});

  final LockResultStatus status;
  final LockFailureCode? failureCode;
}

class AppInfo {
  const AppInfo({
    required this.name,
    required this.version,
    required this.buildNumber,
  });

  final String name;
  final String version;
  final String buildNumber;

  String get shortLabel => '$name $version ($buildNumber)';
}

class LocaleChoice {
  const LocaleChoice({required this.preference, required this.locale});

  final AppLocalePreference preference;
  final Locale locale;
}
