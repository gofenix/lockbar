// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get preparingLockBar => 'Preparing LockBar…';

  @override
  String get heroTitle => 'One click. Screen locked.';

  @override
  String get heroDescription =>
      'Left-click the menu bar item to lock instantly. Right-click to open the menu and manage startup behavior.';

  @override
  String get leftClickLocks => 'Left click locks';

  @override
  String get rightClickOpensMenu => 'Right click opens menu';

  @override
  String get permissionGrantedTitle => 'Accessibility access is enabled';

  @override
  String get permissionGrantedDescription =>
      'LockBar can now synthesize the standard macOS lock shortcut from the menu bar without opening a full app window.';

  @override
  String get permissionDeniedTitle => 'Accessibility is still off';

  @override
  String get permissionDeniedDescription =>
      'Open System Settings, go to Privacy & Security > Accessibility, enable LockBar, then return here or click the tray icon again.';

  @override
  String get permissionNotDeterminedTitle => 'Permission is needed once';

  @override
  String get permissionNotDeterminedDescription =>
      'LockBar needs the macOS Accessibility permission to send the standard Control + Command + Q shortcut on your behalf.';

  @override
  String get refreshStatus => 'Refresh Status';

  @override
  String get requestPermission => 'Request Permission';

  @override
  String get openSystemSettings => 'Open System Settings';

  @override
  String get controlsTitle => 'Controls';

  @override
  String get launchAtLogin => 'Launch at Login';

  @override
  String get launchAtLoginDescription =>
      'Keep LockBar in the menu bar after every restart.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageDescription =>
      'Choose whether LockBar follows the system language or uses a manual override.';

  @override
  String get followSystem => 'Follow System';

  @override
  String get englishLanguageName => 'English';

  @override
  String get simplifiedChineseLanguageName => '简体中文';

  @override
  String currentLanguageLabel(Object language) {
    return 'Current language: $language';
  }

  @override
  String get lockNow => 'Lock Now';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutDescription =>
      'Built for macOS 13 and later. LockBar uses the system Accessibility permission only to synthesize the standard Control + Command + Q lock shortcut.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get quitAction => 'Quit';

  @override
  String get statusTrayReady =>
      'Tray clicks are ready to lock your Mac instantly.';

  @override
  String get statusPermissionNeededOnce =>
      'Grant Accessibility access once, then LockBar can lock on a single click.';

  @override
  String get statusStartupFailed =>
      'LockBar could not finish startup. Reopen the app or check the macOS console for native setup errors.';

  @override
  String get statusPermissionGranted =>
      'Accessibility access is enabled. LockBar can now lock your Mac from the menu bar.';

  @override
  String get statusPermissionRefreshFailed =>
      'LockBar could not refresh the current permission state.';

  @override
  String get statusPermissionStillNeeded =>
      'LockBar still needs Accessibility permission before it can lock your Mac.';

  @override
  String get statusTrayActionFailed =>
      'LockBar could not complete the tray action.';

  @override
  String get statusAccessibilityStillOff =>
      'Accessibility access is still off. Enable it in System Settings, then try again.';

  @override
  String get statusLockServiceUnavailable =>
      'LockBar could not talk to the macOS lock service.';

  @override
  String get statusOpenedSystemSettings =>
      'System Settings was opened. Enable LockBar under Privacy & Security > Accessibility.';

  @override
  String get statusOpenSystemSettingsFailed =>
      'LockBar could not open System Settings automatically.';

  @override
  String get statusLaunchAtLoginEnabled =>
      'LockBar will now launch when you log in.';

  @override
  String get statusLaunchAtLoginDisabled =>
      'Launch at login has been turned off.';

  @override
  String get statusLaunchAtLoginFailed =>
      'LockBar could not update the login item setting.';

  @override
  String get statusPermissionGrantedClickTrayAgain =>
      'Accessibility access is enabled. Click the tray icon again to lock instantly.';

  @override
  String get statusPermissionEnableThenRetry =>
      'LockBar needs Accessibility access before it can lock your Mac. Enable it in System Settings, then try again.';

  @override
  String get statusLockCommandSent => 'Lock command sent.';

  @override
  String get statusLockFailureEventSource =>
      'LockBar could not create the system keyboard event source.';

  @override
  String get statusLockFailureEventSequence =>
      'LockBar could not build the keyboard shortcut event sequence.';

  @override
  String get statusLockFailureGeneric =>
      'LockBar could not trigger the system lock shortcut.';

  @override
  String get statusLocalePreferenceFailed =>
      'LockBar could not save the language preference.';
}
