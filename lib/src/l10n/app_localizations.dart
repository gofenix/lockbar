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

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Menu bar controls, permissions, and smart suggestions.'**
  String get settingsSubtitle;

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

  /// No description provided for @lockingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Locking'**
  String get lockingSectionTitle;

  /// No description provided for @primaryActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary click'**
  String get primaryActionTitle;

  /// No description provided for @primaryActionDescription.
  ///
  /// In en, this message translates to:
  /// **'Left click locks immediately. Secondary click opens commands.'**
  String get primaryActionDescription;

  /// No description provided for @primaryActionTipTitle.
  ///
  /// In en, this message translates to:
  /// **'First-run tip'**
  String get primaryActionTipTitle;

  /// No description provided for @primaryActionTipDescription.
  ///
  /// In en, this message translates to:
  /// **'Left click locks now. Secondary click opens commands.'**
  String get primaryActionTipDescription;

  /// No description provided for @gotItAction.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItAction;

  /// No description provided for @manualActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual actions'**
  String get manualActionsTitle;

  /// No description provided for @durationMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String durationMinutesLabel(Object count);

  /// No description provided for @durationSecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} sec'**
  String durationSecondsLabel(Object count);

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
  /// **'Open System Settings, go to Privacy & Security > Accessibility, enable LockBar, then return here or click the tray icon again. If it still does not take effect, quit and reopen LockBar.'**
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
  /// **'Accessibility access is still off. Enable it in System Settings, then try again. If you just enabled it and macOS has not refreshed yet, quit and reopen LockBar.'**
  String get statusAccessibilityStillOff;

  /// No description provided for @statusLockServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not talk to the macOS lock service.'**
  String get statusLockServiceUnavailable;

  /// No description provided for @statusOpenedSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings was opened. Enable LockBar under Privacy & Security > Accessibility. If the change does not take effect afterward, quit and reopen LockBar.'**
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
  /// **'LockBar needs Accessibility access before it can lock your Mac. Enable it in System Settings, then try again. If you just enabled it and it still does not work, quit and reopen LockBar.'**
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

  /// No description provided for @statusAiModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Smart suggestions are on.'**
  String get statusAiModeEnabled;

  /// No description provided for @statusAiModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Smart suggestions are off. LockBar will not collect context or contact the AI service.'**
  String get statusAiModeDisabled;

  /// No description provided for @statusAiSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not save the AI settings.'**
  String get statusAiSettingsSaveFailed;

  /// No description provided for @statusAiConfigurationSaved.
  ///
  /// In en, this message translates to:
  /// **'AI connection saved locally.'**
  String get statusAiConfigurationSaved;

  /// No description provided for @statusAiConfigurationMissing.
  ///
  /// In en, this message translates to:
  /// **'AI is on, but the base URL or API key is missing. Open Settings and save the AI connection first.'**
  String get statusAiConfigurationMissing;

  /// No description provided for @statusAiConnectionVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Configure, test, and save an AI connection before turning suggestions on.'**
  String get statusAiConnectionVerificationRequired;

  /// No description provided for @statusAiConnectionTestSucceeded.
  ///
  /// In en, this message translates to:
  /// **'AI connection verified.'**
  String get statusAiConnectionTestSucceeded;

  /// No description provided for @statusAiConnectionTestFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not verify the AI connection. Review the base URL, API key, and endpoint response, then test again.'**
  String get statusAiConnectionTestFailed;

  /// No description provided for @statusAiRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not reach the AI service. Check the API key, network, or Anthropic-compatible MiniMax endpoint.'**
  String get statusAiRequestFailed;

  /// No description provided for @statusAiInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The AI service returned a response LockBar could not parse.'**
  String get statusAiInvalidResponse;

  /// No description provided for @statusAiMemoryReset.
  ///
  /// In en, this message translates to:
  /// **'LockBar cleared the current memory profile and action history.'**
  String get statusAiMemoryReset;

  /// No description provided for @statusAiMemoryResetFailed.
  ///
  /// In en, this message translates to:
  /// **'LockBar could not reset the AI memory profile.'**
  String get statusAiMemoryResetFailed;

  /// No description provided for @statusFocusSessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Focus session started.'**
  String get statusFocusSessionStarted;

  /// No description provided for @statusFocusSessionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Focus session cancelled.'**
  String get statusFocusSessionCancelled;

  /// No description provided for @statusDelayedLockScheduled.
  ///
  /// In en, this message translates to:
  /// **'Delayed lock scheduled.'**
  String get statusDelayedLockScheduled;

  /// No description provided for @statusDelayedLockCancelled.
  ///
  /// In en, this message translates to:
  /// **'Delayed lock cancelled.'**
  String get statusDelayedLockCancelled;

  /// No description provided for @statusWorkdayReviewStarted.
  ///
  /// In en, this message translates to:
  /// **'Workday wrap-up started.'**
  String get statusWorkdayReviewStarted;

  /// No description provided for @aiStatusOn.
  ///
  /// In en, this message translates to:
  /// **'AI on'**
  String get aiStatusOn;

  /// No description provided for @aiStatusOff.
  ///
  /// In en, this message translates to:
  /// **'AI off'**
  String get aiStatusOff;

  /// No description provided for @aiCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart suggestion'**
  String get aiCardTitle;

  /// No description provided for @aiCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private until you turn it on'**
  String get aiCardSubtitle;

  /// No description provided for @aiLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get aiLaterAction;

  /// No description provided for @aiNotNowAction.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get aiNotNowAction;

  /// No description provided for @aiReviewSuggestionAction.
  ///
  /// In en, this message translates to:
  /// **'Review Suggestion…'**
  String get aiReviewSuggestionAction;

  /// No description provided for @aiWhyAction.
  ///
  /// In en, this message translates to:
  /// **'Why did you suggest this?'**
  String get aiWhyAction;

  /// No description provided for @aiWhyInlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Signals used'**
  String get aiWhyInlineTitle;

  /// No description provided for @aiWhyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Why this suggestion'**
  String get aiWhyDialogTitle;

  /// No description provided for @doneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneAction;

  /// No description provided for @aiConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence {value}%'**
  String aiConfidenceLabel(Object value);

  /// No description provided for @aiSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiSectionTitle;

  /// No description provided for @aiSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Memory Coach keeps left-click locking untouched and only tries to learn when a lock suggestion would actually help. By default it starts with LockBar action history and away-and-return timing.'**
  String get aiSectionDescription;

  /// No description provided for @aiConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get aiConnectionTitle;

  /// No description provided for @aiConnectionConfiguredDescription.
  ///
  /// In en, this message translates to:
  /// **'Base URL: {baseUrl}\nAPI key: {maskedKey}'**
  String aiConnectionConfiguredDescription(Object baseUrl, Object maskedKey);

  /// No description provided for @aiConnectionMissingDescription.
  ///
  /// In en, this message translates to:
  /// **'No AI connection is saved yet. Open Configure, test the draft, then save it.'**
  String get aiConnectionMissingDescription;

  /// No description provided for @aiConnectionStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String aiConnectionStatusLine(Object status);

  /// No description provided for @aiConnectionVerifiedAtLine.
  ///
  /// In en, this message translates to:
  /// **'Verified: {value}'**
  String aiConnectionVerifiedAtLine(Object value);

  /// No description provided for @aiConnectionModelLine.
  ///
  /// In en, this message translates to:
  /// **'Model: {value}'**
  String aiConnectionModelLine(Object value);

  /// No description provided for @aiConnectionLastErrorLine.
  ///
  /// In en, this message translates to:
  /// **'Last error: {value}'**
  String aiConnectionLastErrorLine(Object value);

  /// No description provided for @aiConnectionPendingDraftHint.
  ///
  /// In en, this message translates to:
  /// **'A local draft connection was found. Reopen Configure, test it, then save it.'**
  String get aiConnectionPendingDraftHint;

  /// No description provided for @aiConnectionNeedsTestHint.
  ///
  /// In en, this message translates to:
  /// **'Save alone is not enough. Run Test once for the current connection before turning suggestions on.'**
  String get aiConnectionNeedsTestHint;

  /// No description provided for @aiConfigureAction.
  ///
  /// In en, this message translates to:
  /// **'Configure…'**
  String get aiConfigureAction;

  /// No description provided for @aiClearConnectionAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get aiClearConnectionAction;

  /// No description provided for @aiTestConnectionAction.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get aiTestConnectionAction;

  /// No description provided for @aiTestingConnectionAction.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get aiTestingConnectionAction;

  /// No description provided for @aiSuggestionsToggle.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions'**
  String get aiSuggestionsToggle;

  /// No description provided for @aiSuggestionsEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'LockBar will use only the enabled inputs to judge whether this moment is worth a lock suggestion.'**
  String get aiSuggestionsEnabledDescription;

  /// No description provided for @aiSuggestionsDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn this on only if you want LockBar to learn your lock timing. Nothing is collected before you do.'**
  String get aiSuggestionsDisabledDescription;

  /// No description provided for @aiEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Turn On Smart Suggestions'**
  String get aiEnableAction;

  /// No description provided for @aiOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on Smart Suggestions'**
  String get aiOnboardingTitle;

  /// No description provided for @aiOnboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'LockBar can suggest cleaner lock moments after focus, wrap-ups, and short idle returns. It keeps left click unchanged.'**
  String get aiOnboardingDescription;

  /// No description provided for @aiOnboardingDefaultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Default inputs'**
  String get aiOnboardingDefaultsTitle;

  /// No description provided for @aiOnboardingPrivacyFootnote.
  ///
  /// In en, this message translates to:
  /// **'Everything else stays off until you enable it manually.'**
  String get aiOnboardingPrivacyFootnote;

  /// No description provided for @aiConfigDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure AI Connection'**
  String get aiConfigDialogTitle;

  /// No description provided for @aiConfigDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'LockBar saves both the base URL and API key in this app\'s local configuration on this Mac.'**
  String get aiConfigDialogDescription;

  /// No description provided for @aiConfigBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get aiConfigBaseUrlLabel;

  /// No description provided for @aiConfigApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get aiConfigApiKeyLabel;

  /// No description provided for @aiConfigModelLine.
  ///
  /// In en, this message translates to:
  /// **'Model: {value}'**
  String aiConfigModelLine(Object value);

  /// No description provided for @aiConfigDraftStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft test status'**
  String get aiConfigDraftStatusTitle;

  /// No description provided for @aiConfigDraftStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {value}'**
  String aiConfigDraftStatusLine(Object value);

  /// No description provided for @aiConfigDraftNeedsTestHint.
  ///
  /// In en, this message translates to:
  /// **'Test the current draft before saving it.'**
  String get aiConfigDraftNeedsTestHint;

  /// No description provided for @aiSaveConnectionAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get aiSaveConnectionAction;

  /// No description provided for @aiBaseUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a base URL.'**
  String get aiBaseUrlRequired;

  /// No description provided for @aiApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an API key.'**
  String get aiApiKeyRequired;

  /// No description provided for @aiSavedConnectionStateMissing.
  ///
  /// In en, this message translates to:
  /// **'No saved connection'**
  String get aiSavedConnectionStateMissing;

  /// No description provided for @aiSavedConnectionStateVerifiedHealthy.
  ///
  /// In en, this message translates to:
  /// **'Verified and healthy'**
  String get aiSavedConnectionStateVerifiedHealthy;

  /// No description provided for @aiSavedConnectionStateVerifiedDegraded.
  ///
  /// In en, this message translates to:
  /// **'Verified, but the most recent request failed'**
  String get aiSavedConnectionStateVerifiedDegraded;

  /// No description provided for @aiDraftTestStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Not tested yet'**
  String get aiDraftTestStateIdle;

  /// No description provided for @aiDraftTestStateTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing draft'**
  String get aiDraftTestStateTesting;

  /// No description provided for @aiDraftTestStateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Draft verified'**
  String get aiDraftTestStateSuccess;

  /// No description provided for @aiDraftTestStateFailure.
  ///
  /// In en, this message translates to:
  /// **'Draft test failed'**
  String get aiDraftTestStateFailure;

  /// No description provided for @aiNetworkStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'AI network'**
  String get aiNetworkStatusLabel;

  /// No description provided for @aiCurrentMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Current memory'**
  String get aiCurrentMemoryLabel;

  /// No description provided for @aiDataSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Inputs for suggestions'**
  String get aiDataSourcesTitle;

  /// No description provided for @aiRecentSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest suggestion'**
  String get aiRecentSuggestionTitle;

  /// No description provided for @aiDecisionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Decision History'**
  String get aiDecisionHistoryTitle;

  /// No description provided for @aiDecisionHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Each trigger is stored locally with collected context, model input, model output, and the final decision chain.'**
  String get aiDecisionHistoryDescription;

  /// No description provided for @aiDecisionHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No AI decision traces have been recorded yet.'**
  String get aiDecisionHistoryEmpty;

  /// No description provided for @aiClearHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get aiClearHistoryAction;

  /// No description provided for @aiInspectorStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'Stored locally on this Mac'**
  String get aiInspectorStoredLocally;

  /// No description provided for @aiInspectorRawContextNotice.
  ///
  /// In en, this message translates to:
  /// **'Contains raw context text'**
  String get aiInspectorRawContextNotice;

  /// No description provided for @aiInspectorNoCredentialsNotice.
  ///
  /// In en, this message translates to:
  /// **'Never includes API credentials'**
  String get aiInspectorNoCredentialsNotice;

  /// No description provided for @aiTraceCollectedSection.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get aiTraceCollectedSection;

  /// No description provided for @aiTraceSentSection.
  ///
  /// In en, this message translates to:
  /// **'Sent to AI'**
  String get aiTraceSentSection;

  /// No description provided for @aiTraceReturnedSection.
  ///
  /// In en, this message translates to:
  /// **'AI Returned'**
  String get aiTraceReturnedSection;

  /// No description provided for @aiTraceOutcomeSection.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get aiTraceOutcomeSection;

  /// No description provided for @aiTraceEnabledSourcesLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled sources'**
  String get aiTraceEnabledSourcesLabel;

  /// No description provided for @aiTraceContextSnapshotLabel.
  ///
  /// In en, this message translates to:
  /// **'Context snapshot'**
  String get aiTraceContextSnapshotLabel;

  /// No description provided for @aiTraceMemorySnapshotLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory profile'**
  String get aiTraceMemorySnapshotLabel;

  /// No description provided for @aiTraceRequestBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Request body'**
  String get aiTraceRequestBodyLabel;

  /// No description provided for @aiTraceRawResponseLabel.
  ///
  /// In en, this message translates to:
  /// **'Raw response'**
  String get aiTraceRawResponseLabel;

  /// No description provided for @aiTraceParsedResponseLabel.
  ///
  /// In en, this message translates to:
  /// **'Parsed response'**
  String get aiTraceParsedResponseLabel;

  /// No description provided for @aiTraceErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get aiTraceErrorLabel;

  /// No description provided for @aiTraceRecommendationLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get aiTraceRecommendationLabel;

  /// No description provided for @aiTraceTriggerFocusEnded.
  ///
  /// In en, this message translates to:
  /// **'Focus ended'**
  String get aiTraceTriggerFocusEnded;

  /// No description provided for @aiTraceTriggerWorkdayEnded.
  ///
  /// In en, this message translates to:
  /// **'Workday ended'**
  String get aiTraceTriggerWorkdayEnded;

  /// No description provided for @aiTraceTriggerDelayedLockRequested.
  ///
  /// In en, this message translates to:
  /// **'Delayed lock requested'**
  String get aiTraceTriggerDelayedLockRequested;

  /// No description provided for @aiTraceTriggerCalendarBoundary.
  ///
  /// In en, this message translates to:
  /// **'Calendar boundary'**
  String get aiTraceTriggerCalendarBoundary;

  /// No description provided for @aiTraceTriggerBluetoothChanged.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth changed'**
  String get aiTraceTriggerBluetoothChanged;

  /// No description provided for @aiTraceTriggerAwayReturned.
  ///
  /// In en, this message translates to:
  /// **'Away and return'**
  String get aiTraceTriggerAwayReturned;

  /// No description provided for @aiTraceTriggerNetworkChanged.
  ///
  /// In en, this message translates to:
  /// **'Network changed'**
  String get aiTraceTriggerNetworkChanged;

  /// No description provided for @aiTraceTriggerAppContextChanged.
  ///
  /// In en, this message translates to:
  /// **'App context changed'**
  String get aiTraceTriggerAppContextChanged;

  /// No description provided for @aiTraceTriggerEveningWindDown.
  ///
  /// In en, this message translates to:
  /// **'Evening wind-down'**
  String get aiTraceTriggerEveningWindDown;

  /// No description provided for @aiTraceOutcomeSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get aiTraceOutcomeSuggested;

  /// No description provided for @aiTraceOutcomeNoSuggestion.
  ///
  /// In en, this message translates to:
  /// **'No suggestion'**
  String get aiTraceOutcomeNoSuggestion;

  /// No description provided for @aiTraceOutcomeFutureProtectionOnly.
  ///
  /// In en, this message translates to:
  /// **'Future protection only'**
  String get aiTraceOutcomeFutureProtectionOnly;

  /// No description provided for @aiTraceOutcomeRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed'**
  String get aiTraceOutcomeRequestFailed;

  /// No description provided for @aiTraceOutcomeInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response'**
  String get aiTraceOutcomeInvalidResponse;

  /// No description provided for @aiTraceOutcomeBlockedByConfig.
  ///
  /// In en, this message translates to:
  /// **'Blocked by configuration'**
  String get aiTraceOutcomeBlockedByConfig;

  /// No description provided for @aiTraceDecisionLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get aiTraceDecisionLockNow;

  /// No description provided for @aiTraceDecisionLaterTwoMinutes.
  ///
  /// In en, this message translates to:
  /// **'Later (2 min)'**
  String get aiTraceDecisionLaterTwoMinutes;

  /// No description provided for @aiTraceDecisionLaterFiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'Later (5 min)'**
  String get aiTraceDecisionLaterFiveMinutes;

  /// No description provided for @aiTraceDecisionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get aiTraceDecisionNotNow;

  /// No description provided for @aiTraceDecisionDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get aiTraceDecisionDismissed;

  /// No description provided for @aiTraceDecisionIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get aiTraceDecisionIgnored;

  /// No description provided for @aiRecentSuggestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest suggestion: {headline}'**
  String aiRecentSuggestionLabel(Object headline);

  /// No description provided for @aiTraySuggestionPrefix.
  ///
  /// In en, this message translates to:
  /// **'AI cue'**
  String get aiTraySuggestionPrefix;

  /// No description provided for @aiStartFocusAction.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get aiStartFocusAction;

  /// No description provided for @aiFocusPreset25.
  ///
  /// In en, this message translates to:
  /// **'Focus 25 min'**
  String get aiFocusPreset25;

  /// No description provided for @aiFocusPreset50.
  ///
  /// In en, this message translates to:
  /// **'Focus 50 min'**
  String get aiFocusPreset50;

  /// No description provided for @aiCancelFocusAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Focus'**
  String get aiCancelFocusAction;

  /// No description provided for @aiEndWorkdayAction.
  ///
  /// In en, this message translates to:
  /// **'End Workday'**
  String get aiEndWorkdayAction;

  /// No description provided for @aiLockInAction.
  ///
  /// In en, this message translates to:
  /// **'Lock in…'**
  String get aiLockInAction;

  /// No description provided for @aiLockIn30Seconds.
  ///
  /// In en, this message translates to:
  /// **'Lock in 30 sec'**
  String get aiLockIn30Seconds;

  /// No description provided for @aiLockIn2Minutes.
  ///
  /// In en, this message translates to:
  /// **'Lock in 2 min'**
  String get aiLockIn2Minutes;

  /// No description provided for @aiLockIn5Minutes.
  ///
  /// In en, this message translates to:
  /// **'Lock in 5 min'**
  String get aiLockIn5Minutes;

  /// No description provided for @aiCancelDelayedLockAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Delayed Lock'**
  String get aiCancelDelayedLockAction;

  /// No description provided for @aiHeadlineFocusEnded.
  ///
  /// In en, this message translates to:
  /// **'Focus block complete.'**
  String get aiHeadlineFocusEnded;

  /// No description provided for @aiReasonFocusEndedFresh.
  ///
  /// In en, this message translates to:
  /// **'You just closed a focus block. If you are stepping away, this is the cleanest moment to lock.'**
  String get aiReasonFocusEndedFresh;

  /// No description provided for @aiReasonFocusEndedBuffer.
  ///
  /// In en, this message translates to:
  /// **'You usually leave yourself a small buffer after deep work. Lock now if you\'re done, or take the short runway again.'**
  String get aiReasonFocusEndedBuffer;

  /// No description provided for @aiHeadlineWorkdayEnded.
  ///
  /// In en, this message translates to:
  /// **'Workday looks wrapped.'**
  String get aiHeadlineWorkdayEnded;

  /// No description provided for @aiReasonWorkdayEndedFresh.
  ///
  /// In en, this message translates to:
  /// **'You marked the day as done. LockBar can help turn that into a clean stop.'**
  String get aiReasonWorkdayEndedFresh;

  /// No description provided for @aiReasonWorkdayEndedBuffer.
  ///
  /// In en, this message translates to:
  /// **'You often want a short runway after ending the day. Lock now if you\'re fully done, or take a few minutes first.'**
  String get aiReasonWorkdayEndedBuffer;

  /// No description provided for @aiHeadlineCalendarBoundary.
  ///
  /// In en, this message translates to:
  /// **'Meeting boundary detected.'**
  String get aiHeadlineCalendarBoundary;

  /// No description provided for @aiReasonCalendarBoundary.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is right at the edge of your current context. If you\'re stepping away, this is a good lock point.'**
  String aiReasonCalendarBoundary(Object title);

  /// No description provided for @aiFallbackCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'this event'**
  String get aiFallbackCalendarTitle;

  /// No description provided for @aiHeadlineBluetoothBoundary.
  ///
  /// In en, this message translates to:
  /// **'Your setup just changed.'**
  String get aiHeadlineBluetoothBoundary;

  /// No description provided for @aiReasonBluetoothBoundary.
  ///
  /// In en, this message translates to:
  /// **'{device} disconnected or came back. LockBar treats that as a strong step-away signal.'**
  String aiReasonBluetoothBoundary(Object device);

  /// No description provided for @aiFallbackBluetoothDevice.
  ///
  /// In en, this message translates to:
  /// **'A familiar device'**
  String get aiFallbackBluetoothDevice;

  /// No description provided for @aiHeadlineFutureProtection.
  ///
  /// In en, this message translates to:
  /// **'That looked like an unguarded step-away.'**
  String get aiHeadlineFutureProtection;

  /// No description provided for @aiReasonAwayReturned.
  ///
  /// In en, this message translates to:
  /// **'You came back after being idle for a while. LockBar will use this as a memory cue, not a late lock-now prompt.'**
  String get aiReasonAwayReturned;

  /// No description provided for @aiHeadlineDelayRequested.
  ///
  /// In en, this message translates to:
  /// **'Short runway queued.'**
  String get aiHeadlineDelayRequested;

  /// No description provided for @aiReasonDelayRequested.
  ///
  /// In en, this message translates to:
  /// **'You asked for a delayed lock. Memory Coach will remember whether short runways feel better than immediate locks.'**
  String get aiReasonDelayRequested;

  /// No description provided for @aiNetworkStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Configured locally'**
  String get aiNetworkStatusReady;

  /// No description provided for @aiNetworkStatusTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing connection'**
  String get aiNetworkStatusTesting;

  /// No description provided for @aiNetworkStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Cloud endpoint reachable'**
  String get aiNetworkStatusOnline;

  /// No description provided for @aiNetworkStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Cloud endpoint unavailable'**
  String get aiNetworkStatusOffline;

  /// No description provided for @aiNetworkStatusNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Connection not configured'**
  String get aiNetworkStatusNotConfigured;

  /// No description provided for @aiDataSourceActionHistory.
  ///
  /// In en, this message translates to:
  /// **'LockBar action history'**
  String get aiDataSourceActionHistory;

  /// No description provided for @aiDataSourceActionHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Learns when you usually choose to lock through LockBar.'**
  String get aiDataSourceActionHistoryDescription;

  /// No description provided for @aiDataSourceFrontmostApp.
  ///
  /// In en, this message translates to:
  /// **'Frontmost app'**
  String get aiDataSourceFrontmostApp;

  /// No description provided for @aiDataSourceFrontmostAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Adds a coarse hint about what kind of work you are doing right now.'**
  String get aiDataSourceFrontmostAppDescription;

  /// No description provided for @aiDataSourceWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Window title'**
  String get aiDataSourceWindowTitle;

  /// No description provided for @aiDataSourceWindowTitleDescription.
  ///
  /// In en, this message translates to:
  /// **'Adds detailed app context. This is the most sensitive source.'**
  String get aiDataSourceWindowTitleDescription;

  /// No description provided for @aiDataSourceCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar title and timing'**
  String get aiDataSourceCalendar;

  /// No description provided for @aiDataSourceCalendarDescription.
  ///
  /// In en, this message translates to:
  /// **'Uses nearby event timing to catch clearer start and end boundaries.'**
  String get aiDataSourceCalendarDescription;

  /// No description provided for @aiDataSourceIdleState.
  ///
  /// In en, this message translates to:
  /// **'Away and return'**
  String get aiDataSourceIdleState;

  /// No description provided for @aiDataSourceIdleStateDescription.
  ///
  /// In en, this message translates to:
  /// **'Detects when you stepped away from the Mac and came back.'**
  String get aiDataSourceIdleStateDescription;

  /// No description provided for @aiDataSourceBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth device changes'**
  String get aiDataSourceBluetooth;

  /// No description provided for @aiDataSourceBluetoothDescription.
  ///
  /// In en, this message translates to:
  /// **'Uses familiar device disconnect or reconnect as a weak away signal.'**
  String get aiDataSourceBluetoothDescription;

  /// No description provided for @aiDataSourceNetwork.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi / network changes'**
  String get aiDataSourceNetwork;

  /// No description provided for @aiDataSourceNetworkDescription.
  ///
  /// In en, this message translates to:
  /// **'Uses network changes as an environment-change hint.'**
  String get aiDataSourceNetworkDescription;

  /// No description provided for @aiDataSourceStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Current status: {status}'**
  String aiDataSourceStatusLine(Object status);

  /// No description provided for @dataSourceStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get dataSourceStatusOff;

  /// No description provided for @dataSourceStatusOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get dataSourceStatusOn;

  /// No description provided for @dataSourceStatusNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Needs permission'**
  String get dataSourceStatusNeedsPermission;

  /// No description provided for @dataSourceStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get dataSourceStatusUnavailable;

  /// No description provided for @privacySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySectionTitle;

  /// No description provided for @calendarAccessDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow calendar suggestions'**
  String get calendarAccessDialogTitle;

  /// No description provided for @calendarAccessDialogBody.
  ///
  /// In en, this message translates to:
  /// **'LockBar will read nearby event titles and times only after you turn on the calendar source.'**
  String get calendarAccessDialogBody;

  /// No description provided for @windowTitleAccessDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility is required'**
  String get windowTitleAccessDialogTitle;

  /// No description provided for @windowTitleAccessDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Window titles use the same macOS Accessibility permission as one-click locking. Turn that on first if you want this source.'**
  String get windowTitleAccessDialogBody;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @aiSignalTimeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get aiSignalTimeOfDay;

  /// No description provided for @aiSignalActionHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent LockBar actions'**
  String get aiSignalActionHistory;

  /// No description provided for @aiSignalFrontmostApp.
  ///
  /// In en, this message translates to:
  /// **'Frontmost app'**
  String get aiSignalFrontmostApp;

  /// No description provided for @aiSignalWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Window title'**
  String get aiSignalWindowTitle;

  /// No description provided for @aiSignalCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar event timing'**
  String get aiSignalCalendar;

  /// No description provided for @aiSignalIdleState.
  ///
  /// In en, this message translates to:
  /// **'Away / return state'**
  String get aiSignalIdleState;

  /// No description provided for @aiSignalBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth device changes'**
  String get aiSignalBluetooth;

  /// No description provided for @aiSignalNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network environment'**
  String get aiSignalNetwork;

  /// No description provided for @aiRitualsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual rituals'**
  String get aiRitualsTitle;

  /// No description provided for @aiFocusRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus session running: {minutes} min'**
  String aiFocusRunningLabel(Object minutes);

  /// No description provided for @aiFocusIdleLabel.
  ///
  /// In en, this message translates to:
  /// **'No focus session is running.'**
  String get aiFocusIdleLabel;

  /// No description provided for @aiDelayedLockRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Delayed lock queued: {duration}'**
  String aiDelayedLockRunningLabel(Object duration);

  /// No description provided for @aiDelayedLockIdleLabel.
  ///
  /// In en, this message translates to:
  /// **'No delayed lock is queued.'**
  String get aiDelayedLockIdleLabel;

  /// No description provided for @aiMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get aiMemoryTitle;

  /// No description provided for @aiResetMemoryAction.
  ///
  /// In en, this message translates to:
  /// **'Reset memory'**
  String get aiResetMemoryAction;

  /// No description provided for @aiMemorySummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fresh memory. LockBar is still learning your timing.'**
  String get aiMemorySummaryEmpty;

  /// No description provided for @aiMemoryHabitFocusBuffer.
  ///
  /// In en, this message translates to:
  /// **'You usually leave yourself a short buffer after focus sessions.'**
  String get aiMemoryHabitFocusBuffer;

  /// No description provided for @aiMemoryHabitWorkdayRunway.
  ///
  /// In en, this message translates to:
  /// **'You prefer a small runway before the final lock at the end of the day.'**
  String get aiMemoryHabitWorkdayRunway;

  /// No description provided for @aiMemoryHabitEarlierPrompts.
  ///
  /// In en, this message translates to:
  /// **'You respond better to earlier cues than after-the-fact reminders.'**
  String get aiMemoryHabitEarlierPrompts;
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
