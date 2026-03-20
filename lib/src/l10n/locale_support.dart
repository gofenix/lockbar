import 'dart:ui';

import '../models/lockbar_models.dart';
import 'app_localizations.dart';

const englishAppLocale = Locale('en');
const simplifiedChineseAppLocale = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hans',
);

const supportedAppLocales = <Locale>[
  englishAppLocale,
  simplifiedChineseAppLocale,
];

Locale resolveSupportedLocale(Locale? locale) {
  if (locale != null && locale.languageCode.toLowerCase() == 'zh') {
    return simplifiedChineseAppLocale;
  }
  return englishAppLocale;
}

Locale localeForPreference(
  AppLocalePreference preference,
  Locale systemLocale,
) {
  return switch (preference) {
    AppLocalePreference.system => resolveSupportedLocale(systemLocale),
    AppLocalePreference.english => englishAppLocale,
    AppLocalePreference.simplifiedChinese => simplifiedChineseAppLocale,
  };
}

AppLocalizations localizationsForLocale(Locale locale) {
  return lookupAppLocalizations(resolveSupportedLocale(locale));
}

String preferenceLabel(
  AppLocalizations localizations,
  AppLocalePreference preference,
) {
  return switch (preference) {
    AppLocalePreference.system => localizations.followSystem,
    AppLocalePreference.english => localizations.englishLanguageName,
    AppLocalePreference.simplifiedChinese =>
      localizations.simplifiedChineseLanguageName,
  };
}

String localeLabel(AppLocalizations localizations, Locale locale) {
  return switch (resolveSupportedLocale(locale)) {
    englishAppLocale => localizations.englishLanguageName,
    simplifiedChineseAppLocale => localizations.simplifiedChineseLanguageName,
    _ => localizations.englishLanguageName,
  };
}

String? statusMessageText(
  AppLocalizations localizations,
  StatusMessage? message,
) {
  if (message == null) {
    return null;
  }

  return switch (message.key) {
    StatusMessageKey.trayReady => localizations.statusTrayReady,
    StatusMessageKey.permissionNeededOnce =>
      localizations.statusPermissionNeededOnce,
    StatusMessageKey.startupFailed => localizations.statusStartupFailed,
    StatusMessageKey.permissionGranted => localizations.statusPermissionGranted,
    StatusMessageKey.permissionRefreshFailed =>
      localizations.statusPermissionRefreshFailed,
    StatusMessageKey.permissionStillNeeded =>
      localizations.statusPermissionStillNeeded,
    StatusMessageKey.trayActionFailed => localizations.statusTrayActionFailed,
    StatusMessageKey.accessibilityStillOff =>
      localizations.statusAccessibilityStillOff,
    StatusMessageKey.lockServiceUnavailable =>
      localizations.statusLockServiceUnavailable,
    StatusMessageKey.openedSystemSettings =>
      localizations.statusOpenedSystemSettings,
    StatusMessageKey.openSystemSettingsFailed =>
      localizations.statusOpenSystemSettingsFailed,
    StatusMessageKey.launchAtLoginEnabled =>
      localizations.statusLaunchAtLoginEnabled,
    StatusMessageKey.launchAtLoginDisabled =>
      localizations.statusLaunchAtLoginDisabled,
    StatusMessageKey.launchAtLoginFailed =>
      localizations.statusLaunchAtLoginFailed,
    StatusMessageKey.permissionGrantedClickTrayAgain =>
      localizations.statusPermissionGrantedClickTrayAgain,
    StatusMessageKey.permissionEnableThenRetry =>
      localizations.statusPermissionEnableThenRetry,
    StatusMessageKey.lockCommandSent => localizations.statusLockCommandSent,
    StatusMessageKey.lockFailureEventSource =>
      localizations.statusLockFailureEventSource,
    StatusMessageKey.lockFailureEventSequence =>
      localizations.statusLockFailureEventSequence,
    StatusMessageKey.lockFailureGeneric =>
      localizations.statusLockFailureGeneric,
    StatusMessageKey.localePreferenceFailed =>
      localizations.statusLocalePreferenceFailed,
  };
}
