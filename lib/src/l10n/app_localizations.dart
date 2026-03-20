import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// No description provided for @preparingLockBar.
  ///
  /// In en, this message translates to:
  /// **'Preparing LockBar…'**
  String get preparingLockBar;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'One click. Screen locked.'**
  String get heroTitle;

  /// No description provided for @heroDescription.
  ///
  /// In en, this message translates to:
  /// **'Left-click the menu bar item to lock instantly. Right-click to open the menu and manage startup behavior.'**
  String get heroDescription;

  /// No description provided for @leftClickLocks.
  ///
  /// In en, this message translates to:
  /// **'Left click locks'**
  String get leftClickLocks;

  /// No description provided for @rightClickOpensMenu.
  ///
  /// In en, this message translates to:
  /// **'Right click opens menu'**
  String get rightClickOpensMenu;

  /// No description provided for @permissionGrantedTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access is enabled'**
  String get permissionGrantedTitle;

  /// No description provided for @permissionGrantedDescription.
  ///
  /// In en, this message translates to:
  /// **'LockBar can now synthesize the standard macOS lock shortcut from the menu bar without opening a full app window.'**
  String get permissionGrantedDescription;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility is still off'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedDescription.
  ///
  /// In en, this message translates to:
  /// **'Open System Settings, go to Privacy & Security > Accessibility, enable LockBar, then return here or click the tray icon again.'**
  String get permissionDeniedDescription;

  /// No description provided for @permissionNotDeterminedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission is needed once'**
  String get permissionNotDeterminedTitle;

  /// No description provided for @permissionNotDeterminedDescription.
  ///
  /// In en, this message translates to:
  /// **'LockBar needs the macOS Accessibility permission to send the standard Control + Command + Q shortcut on your behalf.'**
  String get permissionNotDeterminedDescription;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refreshStatus;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request Permission'**
  String get requestPermission;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open System Settings'**
  String get openSystemSettings;

  /// No description provided for @controlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get controlsTitle;

  /// No description provided for @launchAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Launch at Login'**
  String get launchAtLogin;

  /// No description provided for @launchAtLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep LockBar in the menu bar after every restart.'**
  String get launchAtLoginDescription;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose whether LockBar follows the system language or uses a manual override.'**
  String get languageDescription;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// No description provided for @englishLanguageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguageName;

  /// No description provided for @simplifiedChineseLanguageName.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get simplifiedChineseLanguageName;

  /// No description provided for @currentLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Current language: {language}'**
  String currentLanguageLabel(Object language);

  /// No description provided for @lockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock Now'**
  String get lockNow;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Built for macOS 13 and later. LockBar uses the system Accessibility permission only to synthesize the standard Control + Command + Q lock shortcut.'**
  String get aboutDescription;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @quitAction.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quitAction;

  /// No description provided for @statusTrayReady.
  ///
  /// In en, this message translates to:
  /// **'Tray clicks are ready to lock your Mac instantly.'**
  String get statusTrayReady;

  /// No description provided for @statusPermissionNeededOnce.
  ///
  /// In en, this message translates to:
  /// **'Grant Accessibility access once, then LockBar can lock on a single click.'**
  String get statusPermissionNeededOnce;

  /// No description provided for @statusStartupFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not finish startup. Reopen the app or check the macOS console for native setup errors.'**
  String get statusStartupFailed;

  /// No description provided for @statusPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access is enabled. LockBar can now lock your Mac from the menu bar.'**
  String get statusPermissionGranted;

  /// No description provided for @statusPermissionRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not refresh the current permission state.'**
  String get statusPermissionRefreshFailed;

  /// No description provided for @statusPermissionStillNeeded.
  ///
  /// In en, this message translates to:
  /// **'LockBar still needs Accessibility permission before it can lock your Mac.'**
  String get statusPermissionStillNeeded;

  /// No description provided for @statusTrayActionFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not complete the tray action.'**
  String get statusTrayActionFailed;

  /// No description provided for @statusAccessibilityStillOff.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access is still off. Enable it in System Settings, then try again.'**
  String get statusAccessibilityStillOff;

  /// No description provided for @statusLockServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not talk to the macOS lock service.'**
  String get statusLockServiceUnavailable;

  /// No description provided for @statusOpenedSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings was opened. Enable LockBar under Privacy & Security > Accessibility.'**
  String get statusOpenedSystemSettings;

  /// No description provided for @statusOpenSystemSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not open System Settings automatically.'**
  String get statusOpenSystemSettingsFailed;

  /// No description provided for @statusLaunchAtLoginEnabled.
  ///
  /// In en, this message translates to:
  /// **'LockBar will now launch when you log in.'**
  String get statusLaunchAtLoginEnabled;

  /// No description provided for @statusLaunchAtLoginDisabled.
  ///
  /// In en, this message translates to:
  /// **'Launch at login has been turned off.'**
  String get statusLaunchAtLoginDisabled;

  /// No description provided for @statusLaunchAtLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not update the login item setting.'**
  String get statusLaunchAtLoginFailed;

  /// No description provided for @statusPermissionGrantedClickTrayAgain.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access is enabled. Click the tray icon again to lock instantly.'**
  String get statusPermissionGrantedClickTrayAgain;

  /// No description provided for @statusPermissionEnableThenRetry.
  ///
  /// In en, this message translates to:
  /// **'LockBar needs Accessibility access before it can lock your Mac. Enable it in System Settings, then try again.'**
  String get statusPermissionEnableThenRetry;

  /// No description provided for @statusLockCommandSent.
  ///
  /// In en, this message translates to:
  /// **'Lock command sent.'**
  String get statusLockCommandSent;

  /// No description provided for @statusLockFailureEventSource.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not create the system keyboard event source.'**
  String get statusLockFailureEventSource;

  /// No description provided for @statusLockFailureEventSequence.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not build the keyboard shortcut event sequence.'**
  String get statusLockFailureEventSequence;

  /// No description provided for @statusLockFailureGeneric.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not trigger the system lock shortcut.'**
  String get statusLockFailureGeneric;

  /// No description provided for @statusLocalePreferenceFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not save the language preference.'**
  String get statusLocalePreferenceFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
