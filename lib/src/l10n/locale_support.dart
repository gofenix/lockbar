import 'dart:ui';

import '../models/ai_models.dart';
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

Locale parseLocaleTag(String localeTag) {
  final normalized = localeTag.toLowerCase();
  if (normalized.startsWith('zh')) {
    return simplifiedChineseAppLocale;
  }
  return englishAppLocale;
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
    StatusMessageKey.aiModeEnabled => localizations.statusAiModeEnabled,
    StatusMessageKey.aiModeDisabled => localizations.statusAiModeDisabled,
    StatusMessageKey.aiSettingsSaveFailed =>
      localizations.statusAiSettingsSaveFailed,
    StatusMessageKey.aiConfigurationSaved =>
      localizations.statusAiConfigurationSaved,
    StatusMessageKey.aiConfigurationMissing =>
      localizations.statusAiConfigurationMissing,
    StatusMessageKey.aiConnectionVerificationRequired =>
      localizations.statusAiConnectionVerificationRequired,
    StatusMessageKey.aiConnectionTestSucceeded =>
      localizations.statusAiConnectionTestSucceeded,
    StatusMessageKey.aiConnectionTestFailed =>
      localizations.statusAiConnectionTestFailed,
    StatusMessageKey.aiRequestTimedOut => localizations.statusAiRequestTimedOut,
    StatusMessageKey.aiRequestFailed => localizations.statusAiRequestFailed,
    StatusMessageKey.aiInvalidResponse => localizations.statusAiInvalidResponse,
    StatusMessageKey.aiMemoryReset => localizations.statusAiMemoryReset,
    StatusMessageKey.aiMemoryResetFailed =>
      localizations.statusAiMemoryResetFailed,
    StatusMessageKey.focusSessionStarted =>
      localizations.statusFocusSessionStarted,
    StatusMessageKey.focusSessionCancelled =>
      localizations.statusFocusSessionCancelled,
    StatusMessageKey.delayedLockScheduled =>
      localizations.statusDelayedLockScheduled,
    StatusMessageKey.delayedLockCancelled =>
      localizations.statusDelayedLockCancelled,
    StatusMessageKey.keepAwakeStarted => localizations.statusKeepAwakeStarted,
    StatusMessageKey.keepAwakeStartedIndefinitely =>
      localizations.statusKeepAwakeStartedIndefinitely,
    StatusMessageKey.keepAwakeCancelled =>
      localizations.statusKeepAwakeCancelled,
    StatusMessageKey.keepAwakeExpired => localizations.statusKeepAwakeExpired,
    StatusMessageKey.keepAwakeFailed => localizations.statusKeepAwakeFailed,
    StatusMessageKey.workdayReviewStarted =>
      localizations.statusWorkdayReviewStarted,
  };
}

String formatClockDuration(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String trayTitle(
  AppLocalizations localizations, {
  required FocusSessionState? focusSession,
  required Duration? focusRemaining,
  required KeepAwakeSessionState? keepAwakeSession,
  required Duration? keepAwakeRemaining,
}) {
  final finiteKeepAwakeSession =
      (keepAwakeSession == null || keepAwakeSession.isIndefinite)
      ? null
      : keepAwakeSession;

  if (focusSession != null && finiteKeepAwakeSession != null) {
    final keepAwakeEndsAt = finiteKeepAwakeSession.endsAt!;
    if (focusSession.endsAt.isBefore(keepAwakeEndsAt) ||
        focusSession.endsAt.isAtSameMomentAs(keepAwakeEndsAt)) {
      return localizations.trayTitleFocus(
        formatClockDuration(focusRemaining ?? Duration.zero),
      );
    }
    return localizations.trayTitleKeepAwake(
      formatClockDuration(keepAwakeRemaining ?? Duration.zero),
    );
  }

  if (focusSession != null) {
    return localizations.trayTitleFocus(
      formatClockDuration(focusRemaining ?? Duration.zero),
    );
  }

  if (finiteKeepAwakeSession != null) {
    return localizations.trayTitleKeepAwake(
      formatClockDuration(keepAwakeRemaining ?? Duration.zero),
    );
  }

  if (keepAwakeSession?.isIndefinite ?? false) {
    return localizations.trayTitleKeepAwakeIndefinitely;
  }

  return localizations.trayTitleReady;
}

String focusStatusLabel(
  AppLocalizations localizations,
  FocusSessionState? session,
  Duration? remaining,
) {
  if (session == null) {
    return localizations.aiFocusIdleLabel;
  }
  return localizations.aiFocusRunningCountdownLabel(
    formatClockDuration(remaining ?? Duration.zero),
  );
}

String focusMenuStatusLabel(
  AppLocalizations localizations,
  Duration? remaining,
) {
  return localizations.focusMenuStatusRunningLabel(
    formatClockDuration(remaining ?? Duration.zero),
  );
}

String keepAwakeStatusLabel(
  AppLocalizations localizations,
  KeepAwakeSessionState? session,
  Duration? remaining,
) {
  if (session == null) {
    return localizations.keepAwakeIdleLabel;
  }
  if (session.isIndefinite) {
    return localizations.keepAwakeRunningIndefinitelyLabel;
  }
  return localizations.keepAwakeRunningLabel(
    formatClockDuration(remaining ?? Duration.zero),
  );
}

String keepAwakeMenuStatusLabel(
  AppLocalizations localizations,
  KeepAwakeSessionState session,
  Duration? remaining,
) {
  if (session.isIndefinite) {
    return localizations.keepAwakeMenuStatusIndefinitelyLabel;
  }
  return localizations.keepAwakeMenuStatusRunningLabel(
    formatClockDuration(remaining ?? Duration.zero),
  );
}

String aiConnectionStatusLabel(
  AppLocalizations localizations,
  AiConnectionStatus status,
) {
  return switch (status) {
    AiConnectionStatus.ready => localizations.aiNetworkStatusReady,
    AiConnectionStatus.testing => localizations.aiNetworkStatusTesting,
    AiConnectionStatus.online => localizations.aiNetworkStatusOnline,
    AiConnectionStatus.offline => localizations.aiNetworkStatusOffline,
    AiConnectionStatus.notConfigured =>
      localizations.aiNetworkStatusNotConfigured,
  };
}

String aiSavedConnectionStateLabel(
  AppLocalizations localizations,
  AiSavedConnectionState state,
) {
  return switch (state) {
    AiSavedConnectionState.missing =>
      localizations.aiSavedConnectionStateMissing,
    AiSavedConnectionState.verifiedHealthy =>
      localizations.aiSavedConnectionStateVerifiedHealthy,
    AiSavedConnectionState.verifiedDegraded =>
      localizations.aiSavedConnectionStateVerifiedDegraded,
  };
}

String aiDraftTestStateLabel(
  AppLocalizations localizations,
  AiConnectionDraftTestState state,
) {
  return switch (state) {
    AiConnectionDraftTestState.idle => localizations.aiDraftTestStateIdle,
    AiConnectionDraftTestState.testing => localizations.aiDraftTestStateTesting,
    AiConnectionDraftTestState.success => localizations.aiDraftTestStateSuccess,
    AiConnectionDraftTestState.failure => localizations.aiDraftTestStateFailure,
  };
}

String aiDataSourceLabel(AppLocalizations localizations, AiDataSource source) {
  return switch (source) {
    AiDataSource.actionHistory => localizations.aiDataSourceActionHistory,
    AiDataSource.frontmostApp => localizations.aiDataSourceFrontmostApp,
    AiDataSource.windowTitle => localizations.aiDataSourceWindowTitle,
    AiDataSource.calendar => localizations.aiDataSourceCalendar,
    AiDataSource.idleState => localizations.aiDataSourceIdleState,
    AiDataSource.bluetooth => localizations.aiDataSourceBluetooth,
    AiDataSource.network => localizations.aiDataSourceNetwork,
  };
}

String aiDataSourceDescription(
  AppLocalizations localizations,
  AiDataSource source,
) {
  return switch (source) {
    AiDataSource.actionHistory =>
      localizations.aiDataSourceActionHistoryDescription,
    AiDataSource.frontmostApp =>
      localizations.aiDataSourceFrontmostAppDescription,
    AiDataSource.windowTitle =>
      localizations.aiDataSourceWindowTitleDescription,
    AiDataSource.calendar => localizations.aiDataSourceCalendarDescription,
    AiDataSource.idleState => localizations.aiDataSourceIdleStateDescription,
    AiDataSource.bluetooth => localizations.aiDataSourceBluetoothDescription,
    AiDataSource.network => localizations.aiDataSourceNetworkDescription,
  };
}

String aiDataSourceAvailabilityLabel(
  AppLocalizations localizations,
  AiDataSourceAvailability availability,
) {
  return switch (availability) {
    AiDataSourceAvailability.off => localizations.dataSourceStatusOff,
    AiDataSourceAvailability.on => localizations.dataSourceStatusOn,
    AiDataSourceAvailability.needsPermission =>
      localizations.dataSourceStatusNeedsPermission,
    AiDataSourceAvailability.unavailable =>
      localizations.dataSourceStatusUnavailable,
  };
}

String aiSignalLabel(AppLocalizations localizations, AiSignalType signal) {
  return switch (signal) {
    AiSignalType.timeOfDay => localizations.aiSignalTimeOfDay,
    AiSignalType.actionHistory => localizations.aiSignalActionHistory,
    AiSignalType.frontmostApp => localizations.aiSignalFrontmostApp,
    AiSignalType.windowTitle => localizations.aiSignalWindowTitle,
    AiSignalType.calendar => localizations.aiSignalCalendar,
    AiSignalType.idleState => localizations.aiSignalIdleState,
    AiSignalType.bluetooth => localizations.aiSignalBluetooth,
    AiSignalType.network => localizations.aiSignalNetwork,
  };
}

String aiTriggerLabel(AppLocalizations localizations, AiTriggerType trigger) {
  return switch (trigger) {
    AiTriggerType.focusEnded => localizations.aiTraceTriggerFocusEnded,
    AiTriggerType.workdayEnded => localizations.aiTraceTriggerWorkdayEnded,
    AiTriggerType.delayedLockRequested =>
      localizations.aiTraceTriggerDelayedLockRequested,
    AiTriggerType.calendarBoundary =>
      localizations.aiTraceTriggerCalendarBoundary,
    AiTriggerType.bluetoothChanged =>
      localizations.aiTraceTriggerBluetoothChanged,
    AiTriggerType.awayReturned => localizations.aiTraceTriggerAwayReturned,
    AiTriggerType.networkChanged => localizations.aiTraceTriggerNetworkChanged,
    AiTriggerType.appContextChanged =>
      localizations.aiTraceTriggerAppContextChanged,
    AiTriggerType.eveningWindDown =>
      localizations.aiTraceTriggerEveningWindDown,
  };
}

String aiDecisionTraceOutcomeLabel(
  AppLocalizations localizations,
  AiDecisionTraceOutcome outcome,
) {
  return switch (outcome) {
    AiDecisionTraceOutcome.suggested => localizations.aiTraceOutcomeSuggested,
    AiDecisionTraceOutcome.noSuggestion =>
      localizations.aiTraceOutcomeNoSuggestion,
    AiDecisionTraceOutcome.futureProtectionOnly =>
      localizations.aiTraceOutcomeFutureProtectionOnly,
    AiDecisionTraceOutcome.timedOut => localizations.aiTraceOutcomeTimedOut,
    AiDecisionTraceOutcome.requestFailed =>
      localizations.aiTraceOutcomeRequestFailed,
    AiDecisionTraceOutcome.invalidResponse =>
      localizations.aiTraceOutcomeInvalidResponse,
    AiDecisionTraceOutcome.blockedByConfig =>
      localizations.aiTraceOutcomeBlockedByConfig,
  };
}

String aiDecisionLabel(
  AppLocalizations localizations,
  AiDecisionType decision,
) {
  return switch (decision) {
    AiDecisionType.lockNow => localizations.aiTraceDecisionLockNow,
    AiDecisionType.laterTwoMinutes =>
      localizations.aiTraceDecisionLaterTwoMinutes,
    AiDecisionType.laterFiveMinutes =>
      localizations.aiTraceDecisionLaterFiveMinutes,
    AiDecisionType.notNow => localizations.aiTraceDecisionNotNow,
    AiDecisionType.dismissed => localizations.aiTraceDecisionDismissed,
    AiDecisionType.ignored => localizations.aiTraceDecisionIgnored,
  };
}

String memoryProfileSummary(
  AppLocalizations localizations,
  MemoryProfile profile,
) {
  if (profile.habits.isEmpty) {
    return localizations.aiMemorySummaryEmpty;
  }

  final summaries = localizedMemoryHabits(localizations, profile);
  return summaries.take(2).join(' ');
}

List<String> localizedMemoryHabits(
  AppLocalizations localizations,
  MemoryProfile profile,
) {
  final localized = <String>[];
  for (final habit in profile.habits) {
    switch (habit) {
      case 'prefers_buffer_after_focus':
        localized.add(localizations.aiMemoryHabitFocusBuffer);
      case 'prefers_runway_after_workday':
        localized.add(localizations.aiMemoryHabitWorkdayRunway);
      case 'responds_better_to_earlier_prompts':
        localized.add(localizations.aiMemoryHabitEarlierPrompts);
      default:
        if (profile.summary.isNotEmpty) {
          localized.add(profile.summary);
        }
    }
  }
  return localized.toSet().toList(growable: false);
}
