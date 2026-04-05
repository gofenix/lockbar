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
  String get settingsSubtitle =>
      'Menu bar controls, permissions, and smart suggestions.';

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
  String get lockingSectionTitle => 'Locking';

  @override
  String get primaryActionTitle => 'Primary click';

  @override
  String get primaryActionDescription =>
      'Left click locks immediately. Secondary click opens commands.';

  @override
  String get primaryActionTipTitle => 'First-run tip';

  @override
  String get primaryActionTipDescription =>
      'Left click locks now. Secondary click opens commands.';

  @override
  String get gotItAction => 'Got it';

  @override
  String get manualActionsTitle => 'Manual actions';

  @override
  String durationMinutesLabel(Object count) {
    return '$count min';
  }

  @override
  String durationSecondsLabel(Object count) {
    return '$count sec';
  }

  @override
  String get permissionGrantedTitle => 'Accessibility access is enabled';

  @override
  String get permissionGrantedDescription =>
      'LockBar can now synthesize the standard macOS lock shortcut from the menu bar without opening a full app window.';

  @override
  String get permissionDeniedTitle => 'Accessibility is still off';

  @override
  String get permissionDeniedDescription =>
      'Open System Settings, go to Privacy & Security > Accessibility, enable LockBar, then return here or click the tray icon again. If it still does not take effect, quit and reopen LockBar.';

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
      'Accessibility access is still off. Enable it in System Settings, then try again. If you just enabled it and macOS has not refreshed yet, quit and reopen LockBar.';

  @override
  String get statusLockServiceUnavailable =>
      'LockBar could not talk to the macOS lock service.';

  @override
  String get statusOpenedSystemSettings =>
      'System Settings was opened. Enable LockBar under Privacy & Security > Accessibility. If the change does not take effect afterward, quit and reopen LockBar.';

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
      'LockBar needs Accessibility access before it can lock your Mac. Enable it in System Settings, then try again. If you just enabled it and it still does not work, quit and reopen LockBar.';

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

  @override
  String get statusAiModeEnabled => 'Smart suggestions are on.';

  @override
  String get statusAiModeDisabled =>
      'Smart suggestions are off. LockBar will not collect context or contact the AI service.';

  @override
  String get statusAiSettingsSaveFailed =>
      'LockBar could not save the AI settings.';

  @override
  String get statusAiConfigurationSaved => 'AI connection saved locally.';

  @override
  String get statusAiConfigurationMissing =>
      'AI is on, but the base URL or API key is missing. Open Settings and save the AI connection first.';

  @override
  String get statusAiConnectionVerificationRequired =>
      'Configure, test, and save an AI connection before turning suggestions on.';

  @override
  String get statusAiConnectionTestSucceeded => 'AI connection verified.';

  @override
  String get statusAiConnectionTestFailed =>
      'LockBar could not verify the AI connection. Review the base URL, API key, and endpoint response, then test again.';

  @override
  String get statusAiRequestTimedOut =>
      'The AI request timed out. Try again in a moment, or check the network and endpoint latency.';

  @override
  String get statusAiRequestFailed =>
      'LockBar could not reach the AI service. Check the API key, network, or Anthropic-compatible MiniMax endpoint.';

  @override
  String get statusAiInvalidResponse =>
      'The AI service returned a response LockBar could not parse.';

  @override
  String get statusAiMemoryReset =>
      'LockBar cleared the current memory profile and action history.';

  @override
  String get statusAiMemoryResetFailed =>
      'LockBar could not reset the AI memory profile.';

  @override
  String get statusFocusSessionStarted => 'Focus session started.';

  @override
  String get statusFocusSessionCancelled => 'Focus session cancelled.';

  @override
  String get statusDelayedLockScheduled => 'Delayed lock scheduled.';

  @override
  String get statusDelayedLockCancelled => 'Delayed lock cancelled.';

  @override
  String get statusKeepAwakeStarted =>
      'Display will stay awake for the next hour.';

  @override
  String get statusKeepAwakeStartedIndefinitely =>
      'Display will stay awake until you stop it.';

  @override
  String get statusKeepAwakeCancelled => 'Keep-awake session stopped.';

  @override
  String get statusKeepAwakeExpired => 'Keep-awake session ended.';

  @override
  String get statusKeepAwakeFailed => 'Could not start the keep-awake session.';

  @override
  String get statusWorkdayReviewStarted => 'Workday wrap-up started.';

  @override
  String get aiStatusOn => 'AI on';

  @override
  String get aiStatusOff => 'AI off';

  @override
  String get aiCardTitle => 'Smart suggestion';

  @override
  String get aiCardSubtitle => 'Private until you turn it on';

  @override
  String get aiLaterAction => 'Later';

  @override
  String get aiNotNowAction => 'Not now';

  @override
  String get aiReviewSuggestionAction => 'Review Suggestion…';

  @override
  String get aiWhyAction => 'Why did you suggest this?';

  @override
  String get aiWhyInlineTitle => 'Signals used';

  @override
  String get aiWhyDialogTitle => 'Why this suggestion';

  @override
  String get doneAction => 'Done';

  @override
  String aiConfidenceLabel(Object value) {
    return 'Confidence $value%';
  }

  @override
  String get aiSectionTitle => 'AI';

  @override
  String get aiSectionDescription =>
      'Memory Coach keeps left-click locking untouched and only tries to learn when a lock suggestion would actually help. By default it starts with LockBar action history and away-and-return timing.';

  @override
  String get aiConnectionTitle => 'Connection';

  @override
  String aiConnectionConfiguredDescription(Object baseUrl, Object maskedKey) {
    return 'Base URL: $baseUrl\nAPI key: $maskedKey';
  }

  @override
  String get aiConnectionMissingDescription =>
      'No AI connection is saved yet. Open Configure, test the draft, then save it.';

  @override
  String aiConnectionStatusLine(Object status) {
    return 'Status: $status';
  }

  @override
  String aiConnectionVerifiedAtLine(Object value) {
    return 'Verified: $value';
  }

  @override
  String aiConnectionModelLine(Object value) {
    return 'Model: $value';
  }

  @override
  String aiConnectionLastErrorLine(Object value) {
    return 'Last error: $value';
  }

  @override
  String get aiConnectionPendingDraftHint =>
      'A local draft connection was found. Reopen Configure, test it, then save it.';

  @override
  String get aiConnectionNeedsTestHint =>
      'Save alone is not enough. Run Test once for the current connection before turning suggestions on.';

  @override
  String get aiConfigureAction => 'Configure…';

  @override
  String get aiClearConnectionAction => 'Clear';

  @override
  String get aiTestConnectionAction => 'Test';

  @override
  String get aiTestingConnectionAction => 'Testing…';

  @override
  String get aiSuggestionsToggle => 'AI suggestions';

  @override
  String get aiSuggestionsEnabledDescription =>
      'LockBar will use only the enabled inputs to judge whether this moment is worth a lock suggestion.';

  @override
  String get aiSuggestionsDisabledDescription =>
      'Turn this on only if you want LockBar to learn your lock timing. Nothing is collected before you do.';

  @override
  String get aiEnableAction => 'Turn On Smart Suggestions';

  @override
  String get aiOnboardingTitle => 'Turn on Smart Suggestions';

  @override
  String get aiOnboardingDescription =>
      'LockBar can suggest cleaner lock moments after focus, wrap-ups, and short idle returns. It keeps left click unchanged.';

  @override
  String get aiOnboardingDefaultsTitle => 'Default inputs';

  @override
  String get aiOnboardingPrivacyFootnote =>
      'Everything else stays off until you enable it manually.';

  @override
  String get aiConfigDialogTitle => 'Configure AI Connection';

  @override
  String get aiConfigDialogDescription =>
      'LockBar saves both the base URL and API key in this app\'s local configuration on this Mac.';

  @override
  String get aiConfigBaseUrlLabel => 'Base URL';

  @override
  String get aiConfigApiKeyLabel => 'API key';

  @override
  String aiConfigModelLine(Object value) {
    return 'Model: $value';
  }

  @override
  String get aiConfigDraftStatusTitle => 'Draft test status';

  @override
  String aiConfigDraftStatusLine(Object value) {
    return 'Status: $value';
  }

  @override
  String get aiConfigDraftNeedsTestHint =>
      'Test the current draft before saving it.';

  @override
  String get aiSaveConnectionAction => 'Save';

  @override
  String get aiBaseUrlRequired => 'Enter a base URL.';

  @override
  String get aiApiKeyRequired => 'Enter an API key.';

  @override
  String get aiSavedConnectionStateMissing => 'No saved connection';

  @override
  String get aiSavedConnectionStateVerifiedHealthy => 'Verified and healthy';

  @override
  String get aiSavedConnectionStateVerifiedDegraded =>
      'Verified, but the most recent request failed';

  @override
  String get aiDraftTestStateIdle => 'Not tested yet';

  @override
  String get aiDraftTestStateTesting => 'Testing draft';

  @override
  String get aiDraftTestStateSuccess => 'Draft verified';

  @override
  String get aiDraftTestStateFailure => 'Draft test failed';

  @override
  String get aiNetworkStatusLabel => 'AI network';

  @override
  String get aiCurrentMemoryLabel => 'Current memory';

  @override
  String get aiDataSourcesTitle => 'Inputs for suggestions';

  @override
  String get aiRecentSuggestionTitle => 'Latest suggestion';

  @override
  String get aiDecisionHistoryTitle => 'Decision History';

  @override
  String get aiDecisionHistoryDescription =>
      'Each trigger is stored locally with collected context, model input, model output, and the final decision chain.';

  @override
  String get aiDecisionHistoryEmpty =>
      'No AI decision traces have been recorded yet.';

  @override
  String get aiClearHistoryAction => 'Clear history';

  @override
  String get aiInspectorStoredLocally => 'Stored locally on this Mac';

  @override
  String get aiInspectorRawContextNotice => 'Contains raw context text';

  @override
  String get aiInspectorNoCredentialsNotice => 'Never includes API credentials';

  @override
  String get aiTraceCollectedSection => 'Collected';

  @override
  String get aiTraceSentSection => 'Sent to AI';

  @override
  String get aiTraceReturnedSection => 'AI Returned';

  @override
  String get aiTraceOutcomeSection => 'Outcome';

  @override
  String get aiTraceEnabledSourcesLabel => 'Enabled sources';

  @override
  String get aiTraceContextSnapshotLabel => 'Context snapshot';

  @override
  String get aiTraceMemorySnapshotLabel => 'Memory profile';

  @override
  String get aiTraceRequestBodyLabel => 'Request body';

  @override
  String get aiTraceRawResponseLabel => 'Raw response';

  @override
  String get aiTraceParsedResponseLabel => 'Parsed response';

  @override
  String get aiTraceErrorLabel => 'Error';

  @override
  String get aiTraceRecommendationLabel => 'Recommendation';

  @override
  String get aiTraceTriggerFocusEnded => 'Focus ended';

  @override
  String get aiTraceTriggerWorkdayEnded => 'Workday ended';

  @override
  String get aiTraceTriggerDelayedLockRequested => 'Delayed lock requested';

  @override
  String get aiTraceTriggerCalendarBoundary => 'Calendar boundary';

  @override
  String get aiTraceTriggerBluetoothChanged => 'Bluetooth changed';

  @override
  String get aiTraceTriggerAwayReturned => 'Away and return';

  @override
  String get aiTraceTriggerNetworkChanged => 'Network changed';

  @override
  String get aiTraceTriggerAppContextChanged => 'App context changed';

  @override
  String get aiTraceTriggerEveningWindDown => 'Evening wind-down';

  @override
  String get aiTraceOutcomeSuggested => 'Suggested';

  @override
  String get aiTraceOutcomeNoSuggestion => 'No suggestion';

  @override
  String get aiTraceOutcomeFutureProtectionOnly => 'Future protection only';

  @override
  String get aiTraceOutcomeTimedOut => 'Request timed out';

  @override
  String get aiTraceOutcomeRequestFailed => 'Request failed';

  @override
  String get aiTraceOutcomeInvalidResponse => 'Invalid response';

  @override
  String get aiTraceOutcomeBlockedByConfig => 'Blocked by configuration';

  @override
  String get aiTraceDecisionLockNow => 'Lock now';

  @override
  String get aiTraceDecisionLaterTwoMinutes => 'Later (2 min)';

  @override
  String get aiTraceDecisionLaterFiveMinutes => 'Later (5 min)';

  @override
  String get aiTraceDecisionNotNow => 'Not now';

  @override
  String get aiTraceDecisionDismissed => 'Dismissed';

  @override
  String get aiTraceDecisionIgnored => 'Ignored';

  @override
  String aiRecentSuggestionLabel(Object headline) {
    return 'Latest suggestion: $headline';
  }

  @override
  String get aiTraySuggestionPrefix => 'AI cue';

  @override
  String get aiStartFocusAction => 'Start Focus';

  @override
  String get aiFocusPreset25 => 'Focus 25 min';

  @override
  String get aiFocusPreset50 => 'Focus 50 min';

  @override
  String get aiCancelFocusAction => 'Cancel Focus';

  @override
  String get aiEndWorkdayAction => 'End Workday';

  @override
  String get aiLockInAction => 'Lock in…';

  @override
  String get aiLockIn30Seconds => 'Lock in 30 sec';

  @override
  String get aiLockIn2Minutes => 'Lock in 2 min';

  @override
  String get aiLockIn5Minutes => 'Lock in 5 min';

  @override
  String get aiCancelDelayedLockAction => 'Cancel Delayed Lock';

  @override
  String get keepAwakeAction => 'Keep Awake…';

  @override
  String get keepAwakeFor30MinutesAction => '30 Minutes';

  @override
  String get keepAwakeForOneHourAction => '1 Hour';

  @override
  String get keepAwakeForTwoHoursAction => '2 Hours';

  @override
  String get keepAwakeIndefinitelyAction => 'Until Stopped';

  @override
  String get cancelKeepAwakeAction => 'Stop Keeping Awake';

  @override
  String get aiHeadlineFocusEnded => 'Focus block complete.';

  @override
  String get aiReasonFocusEndedFresh =>
      'You just closed a focus block. If you are stepping away, this is the cleanest moment to lock.';

  @override
  String get aiReasonFocusEndedBuffer =>
      'You usually leave yourself a small buffer after deep work. Lock now if you\'re done, or take the short runway again.';

  @override
  String get aiHeadlineWorkdayEnded => 'Workday looks wrapped.';

  @override
  String get aiReasonWorkdayEndedFresh =>
      'You marked the day as done. LockBar can help turn that into a clean stop.';

  @override
  String get aiReasonWorkdayEndedBuffer =>
      'You often want a short runway after ending the day. Lock now if you\'re fully done, or take a few minutes first.';

  @override
  String get aiHeadlineCalendarBoundary => 'Meeting boundary detected.';

  @override
  String aiReasonCalendarBoundary(Object title) {
    return '\"$title\" is right at the edge of your current context. If you\'re stepping away, this is a good lock point.';
  }

  @override
  String get aiFallbackCalendarTitle => 'this event';

  @override
  String get aiHeadlineBluetoothBoundary => 'Your setup just changed.';

  @override
  String aiReasonBluetoothBoundary(Object device) {
    return '$device disconnected or came back. LockBar treats that as a strong step-away signal.';
  }

  @override
  String get aiFallbackBluetoothDevice => 'A familiar device';

  @override
  String get aiHeadlineFutureProtection =>
      'That looked like an unguarded step-away.';

  @override
  String get aiReasonAwayReturned =>
      'You came back after being idle for a while. LockBar will use this as a memory cue, not a late lock-now prompt.';

  @override
  String get aiHeadlineDelayRequested => 'Short runway queued.';

  @override
  String get aiReasonDelayRequested =>
      'You asked for a delayed lock. Memory Coach will remember whether short runways feel better than immediate locks.';

  @override
  String get aiNetworkStatusReady => 'Configured locally';

  @override
  String get aiNetworkStatusTesting => 'Testing connection';

  @override
  String get aiNetworkStatusOnline => 'Cloud endpoint reachable';

  @override
  String get aiNetworkStatusOffline => 'Cloud endpoint unavailable';

  @override
  String get aiNetworkStatusNotConfigured => 'Connection not configured';

  @override
  String get aiDataSourceActionHistory => 'LockBar action history';

  @override
  String get aiDataSourceActionHistoryDescription =>
      'Learns when you usually choose to lock through LockBar.';

  @override
  String get aiDataSourceFrontmostApp => 'Frontmost app';

  @override
  String get aiDataSourceFrontmostAppDescription =>
      'Adds a coarse hint about what kind of work you are doing right now.';

  @override
  String get aiDataSourceWindowTitle => 'Window title';

  @override
  String get aiDataSourceWindowTitleDescription =>
      'Adds detailed app context. This is the most sensitive source.';

  @override
  String get aiDataSourceCalendar => 'Calendar title and timing';

  @override
  String get aiDataSourceCalendarDescription =>
      'Uses nearby event timing to catch clearer start and end boundaries.';

  @override
  String get aiDataSourceIdleState => 'Away and return';

  @override
  String get aiDataSourceIdleStateDescription =>
      'Detects when you stepped away from the Mac and came back.';

  @override
  String get aiDataSourceBluetooth => 'Bluetooth device changes';

  @override
  String get aiDataSourceBluetoothDescription =>
      'Uses familiar device disconnect or reconnect as a weak away signal.';

  @override
  String get aiDataSourceNetwork => 'Wi-Fi / network changes';

  @override
  String get aiDataSourceNetworkDescription =>
      'Uses network changes as an environment-change hint.';

  @override
  String aiDataSourceStatusLine(Object status) {
    return 'Current status: $status';
  }

  @override
  String get dataSourceStatusOff => 'Off';

  @override
  String get dataSourceStatusOn => 'On';

  @override
  String get dataSourceStatusNeedsPermission => 'Needs permission';

  @override
  String get dataSourceStatusUnavailable => 'Unavailable';

  @override
  String get privacySectionTitle => 'Privacy';

  @override
  String get calendarAccessDialogTitle => 'Allow calendar suggestions';

  @override
  String get calendarAccessDialogBody =>
      'LockBar will read nearby event titles and times only after you turn on the calendar source.';

  @override
  String get windowTitleAccessDialogTitle => 'Accessibility is required';

  @override
  String get windowTitleAccessDialogBody =>
      'Window titles use the same macOS Accessibility permission as one-click locking. Turn that on first if you want this source.';

  @override
  String get continueAction => 'Continue';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get aiSignalTimeOfDay => 'Time of day';

  @override
  String get aiSignalActionHistory => 'Recent LockBar actions';

  @override
  String get aiSignalFrontmostApp => 'Frontmost app';

  @override
  String get aiSignalWindowTitle => 'Window title';

  @override
  String get aiSignalCalendar => 'Calendar event timing';

  @override
  String get aiSignalIdleState => 'Away / return state';

  @override
  String get aiSignalBluetooth => 'Bluetooth device changes';

  @override
  String get aiSignalNetwork => 'Network environment';

  @override
  String get aiRitualsTitle => 'Manual rituals';

  @override
  String aiFocusRunningLabel(Object minutes) {
    return 'Focus session running: $minutes min';
  }

  @override
  String get aiFocusIdleLabel => 'No focus session is running.';

  @override
  String aiDelayedLockRunningLabel(Object duration) {
    return 'Delayed lock queued: $duration';
  }

  @override
  String get aiDelayedLockIdleLabel => 'No delayed lock is queued.';

  @override
  String get aiMemoryTitle => 'Memory';

  @override
  String get aiResetMemoryAction => 'Reset memory';

  @override
  String get aiMemorySummaryEmpty =>
      'Fresh memory. LockBar is still learning your timing.';

  @override
  String get aiMemoryHabitFocusBuffer =>
      'You usually leave yourself a short buffer after focus sessions.';

  @override
  String get aiMemoryHabitWorkdayRunway =>
      'You prefer a small runway before the final lock at the end of the day.';

  @override
  String get aiMemoryHabitEarlierPrompts =>
      'You respond better to earlier cues than after-the-fact reminders.';
}
