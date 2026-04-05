import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/l10n/locale_support.dart';
import 'package:lockbar/src/lockbar_controller.dart';
import 'package:lockbar/src/models/ai_models.dart';
import 'package:lockbar/src/models/lockbar_models.dart';
import 'package:lockbar/src/services/ai_inference_client.dart';

import 'test_doubles.dart';

void main() {
  test(
    'tray click locks immediately when permission is already granted',
    () async {
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.granted
        ..lockResult = const LockResult(status: LockResultStatus.success);
      final controller = LockbarController(
        platform: platform,
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      final outcome = await controller.handlePrimaryTrayAction();

      expect(outcome, TrayPrimaryActionOutcome.locked);
      expect(platform.lockCalls, 1);
      expect(controller.hasError, isFalse);
      expect(
        statusMessageText(
          localizationsForLocale(controller.effectiveLocale),
          controller.statusMessage,
        ),
        'Lock command sent.',
      );
    },
  );

  test(
    'tray click requests permission and asks for settings when access is missing',
    () async {
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.notDetermined
        ..permissionRequestResult = PermissionRequestResult.denied;
      final controller = LockbarController(
        platform: platform,
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      final outcome = await controller.handlePrimaryTrayAction();

      expect(outcome, TrayPrimaryActionOutcome.needsSettings);
      expect(platform.requestPermissionCalls, 1);
      expect(controller.permissionState, PermissionState.denied);
      expect(controller.hasError, isTrue);
      expect(
        statusMessageText(
          localizationsForLocale(controller.effectiveLocale),
          controller.statusMessage,
        ),
        'LockBar needs Accessibility access before it can lock your Mac. Enable it in System Settings, then try again. If you just enabled it and it still does not work, quit and reopen LockBar.',
      );
    },
  );

  test(
    'tray click does not request permission again after access was denied',
    () async {
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.denied
        ..permissionRequestResult = PermissionRequestResult.denied;
      final controller = LockbarController(
        platform: platform,
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      final outcome = await controller.handlePrimaryTrayAction();

      expect(outcome, TrayPrimaryActionOutcome.needsSettings);
      expect(platform.requestPermissionCalls, 0);
      expect(platform.lockCalls, 0);
      expect(controller.permissionState, PermissionState.denied);
      expect(controller.hasError, isTrue);
      expect(
        statusMessageText(
          localizationsForLocale(controller.effectiveLocale),
          controller.statusMessage,
        ),
        'LockBar still needs Accessibility permission before it can lock your Mac.',
      );
    },
  );

  test('locale preference persists and overrides system language', () async {
    final localePreferences = FakeLocalePreferencesService();
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: localePreferences,
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('zh'),
    );

    await controller.initialize();

    expect(controller.localePreference, AppLocalePreference.system);
    expect(controller.effectiveLocale, simplifiedChineseAppLocale);

    await controller.setLocalePreference(AppLocalePreference.english);

    expect(controller.localePreference, AppLocalePreference.english);
    expect(controller.effectiveLocale, englishAppLocale);
    expect(localePreferences.preference, AppLocalePreference.english);
    expect(localePreferences.saveCalls, 1);

    await controller.setLocalePreference(AppLocalePreference.system);

    expect(controller.localePreference, AppLocalePreference.system);
    expect(controller.effectiveLocale, simplifiedChineseAppLocale);
    expect(localePreferences.preference, AppLocalePreference.system);
    expect(localePreferences.saveCalls, 2);
  });

  test('lock failures map native error codes to localized messages', () async {
    final platform = FakeLockbarPlatform()
      ..permissionState = PermissionState.granted
      ..lockResult = const LockResult(
        status: LockResultStatus.failure,
        failureCode: LockFailureCode.eventSourceUnavailable,
      );
    final controller = LockbarController(
      platform: platform,
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await controller.initialize();
    await controller.lockNowFromSettings();

    expect(controller.hasError, isTrue);
    expect(
      statusMessageText(
        localizationsForLocale(controller.effectiveLocale),
        controller.statusMessage,
      ),
      'LockBar could not create the system keyboard event source.',
    );
  });

  test('keep awake session starts for one hour and can be cancelled', () async {
    final platform = FakeLockbarPlatform();
    final controller = LockbarController(
      platform: platform,
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => DateTime(2026, 4, 5, 13, 0),
    );

    await controller.initialize();
    await controller.startKeepAwakeSession(const Duration(hours: 1));

    expect(platform.startKeepAwakeCalls, 1);
    expect(platform.lastKeepAwakeDuration, const Duration(hours: 1));
    expect(controller.keepAwakeSession, isNotNull);
    expect(
      statusMessageText(
        localizationsForLocale(controller.effectiveLocale),
        controller.statusMessage,
      ),
      'Display will stay awake for the next hour.',
    );

    await controller.cancelKeepAwakeSession();

    expect(controller.keepAwakeSession, isNull);
    expect(platform.stopKeepAwakeCalls, 1);
    expect(
      statusMessageText(
        localizationsForLocale(controller.effectiveLocale),
        controller.statusMessage,
      ),
      'Keep-awake session stopped.',
    );
  });

  test('starting keep awake clears an existing delayed lock', () async {
    final platform = FakeLockbarPlatform();
    final controller = LockbarController(
      platform: platform,
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await controller.initialize();
    await controller.scheduleDelayedLock(const Duration(minutes: 2));
    expect(controller.delayedLock, isNotNull);

    await controller.startKeepAwakeSession(const Duration(hours: 1));

    expect(controller.delayedLock, isNull);
    expect(controller.keepAwakeSession, isNotNull);
    expect(platform.startKeepAwakeCalls, 1);
  });

  test('keep awake can run indefinitely until manually stopped', () async {
    final platform = FakeLockbarPlatform();
    final controller = LockbarController(
      platform: platform,
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => DateTime(2026, 4, 5, 13, 0),
    );

    await controller.initialize();
    await controller.startKeepAwakeIndefinitely();

    expect(platform.startKeepAwakeIndefinitelyCalls, 1);
    expect(controller.keepAwakeSession, isNotNull);
    expect(controller.keepAwakeSession!.isIndefinite, isTrue);
    expect(
      statusMessageText(
        localizationsForLocale(controller.effectiveLocale),
        controller.statusMessage,
      ),
      'Display will stay awake until you stop it.',
    );
  });

  test(
    'failed keep awake start leaves delayed lock intact and surfaces an error',
    () async {
      final platform = FakeLockbarPlatform()..keepAwakeStartSucceeds = false;
      final controller = LockbarController(
        platform: platform,
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      await controller.scheduleDelayedLock(const Duration(minutes: 2));

      await controller.startKeepAwakeSession(const Duration(hours: 1));

      expect(controller.delayedLock, isNotNull);
      expect(controller.keepAwakeSession, isNull);
      expect(controller.hasError, isTrue);
      expect(
        statusMessageText(
          localizationsForLocale(controller.effectiveLocale),
          controller.statusMessage,
        ),
        'Could not start the keep-awake session.',
      );
    },
  );

  test(
    'AI stays off and does not poll context until explicitly enabled',
    () async {
      final aiMemory = FakeAiMemoryService();
      final aiContext = FakeAiContextCollector();
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: aiContext,
        initialSystemLocale: const Locale('en'),
        enableBackgroundContextPolling: true,
      );

      await controller.initialize();

      expect(controller.aiSuggestionsEnabled, isFalse);
      expect(aiContext.collectCalls, 0);
    },
  );

  test(
    'workday wrap-up surfaces an AI suggestion panel when AI is enabled',
    () async {
      const endpointConfig = AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'test-key',
      );
      final aiClient = FakeAiInferenceClient()
        ..recommendationResult = AiRecommendationResult(
          connectionStatus: AiConnectionStatus.online,
          recommendation: AiRecommendation(
            id: 'sg-1',
            trigger: AiTriggerType.workdayEnded,
            headline: 'Workday looks wrapped.',
            reason: 'A suggestion is ready.',
            confidence: 0.8,
            usedSignals: const [AiSignalType.timeOfDay],
            createdAt: DateTime(2025, 1, 1),
          ),
        );
      final aiMemory = FakeAiMemoryService()
        ..settings = AiSettings.recommendedEnabled()
        ..savedConnection = AiSavedConnection(
          baseUrl: endpointConfig.baseUrl,
          apiKey: endpointConfig.apiKey,
          model: aiClient.model,
          verifiedAt: DateTime(2026, 1, 1, 9),
          lastHealthyAt: DateTime(2026, 1, 1, 9),
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
        now: () => DateTime(2026, 3, 28, 12, 0),
      );

      await controller.initialize();
      await controller.triggerWorkdayWrapUp();

      expect(aiClient.recommendCalls, 1);
      expect(controller.activeSuggestion?.headline, 'Workday looks wrapped.');
      expect(controller.isSuggestionPanelVisible, isTrue);
    },
  );

  test(
    'AI trace records collected context, exchange debug, and user decision',
    () async {
      const endpointConfig = AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'test-key',
      );
      final traceStore = FakeAiTraceStore();
      final aiClient = FakeAiInferenceClient()
        ..recommendationResult = AiRecommendationResult(
          connectionStatus: AiConnectionStatus.online,
          recommendation: AiRecommendation(
            id: 'sg-trace',
            trigger: AiTriggerType.workdayEnded,
            headline: 'Wrap up and lock?',
            reason: 'You just ended the workday ritual.',
            confidence: 0.84,
            usedSignals: const [
              AiSignalType.actionHistory,
              AiSignalType.timeOfDay,
            ],
            createdAt: DateTime(2026, 3, 28, 18),
            preferredDelaySeconds: 300,
          ),
          exchangeDebug: const AiInferenceExchangeDebug(
            model: 'MiniMax-M2.7',
            baseUrl: 'https://api.minimaxi.com/anthropic',
            requestBody: {
              'model': 'MiniMax-M2.7',
              'messages': [
                {'role': 'user', 'content': 'hello'},
              ],
            },
            rawResponseText: '{"ok":true}',
            parsedResponse: {'ok': true},
          ),
          decisionReason: 'Stage boundary matched a strong lock signal.',
        );
      final aiMemory = FakeAiMemoryService()
        ..settings = AiSettings.recommendedEnabled()
        ..savedConnection = AiSavedConnection(
          baseUrl: endpointConfig.baseUrl,
          apiKey: endpointConfig.apiKey,
          model: aiClient.model,
          verifiedAt: DateTime(2026, 3, 28, 9),
          lastHealthyAt: DateTime(2026, 3, 28, 9),
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: FakeAiContextCollector(),
        aiTraceStore: traceStore,
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      await controller.triggerWorkdayWrapUp();

      expect(controller.decisionTraces, hasLength(1));
      final trace = controller.decisionTraces.single;
      expect(trace.outcome, AiDecisionTraceOutcome.suggested);
      expect(
        trace.outcomeReason,
        'Stage boundary matched a strong lock signal.',
      );
      expect(trace.collectedContext, isNotNull);
      expect(trace.contextSnapshot, isNotNull);
      expect(trace.exchangeDebug?.requestBody['model'], 'MiniMax-M2.7');
      expect(trace.recommendation?.headline, 'Wrap up and lock?');
      expect(trace.userDecision, isNull);

      await controller.acceptActiveSuggestionLater();

      final updatedTrace = controller.decisionTraces.single;
      expect(updatedTrace.userDecision, AiDecisionType.laterFiveMinutes);
      expect(updatedTrace.userDecisionAt, isNotNull);
      expect(
        traceStore.traces.single.userDecision,
        AiDecisionType.laterFiveMinutes,
      );
    },
  );

  test('AI trace records noSuggestion outcomes with request details', () async {
    const endpointConfig = AiEndpointConfig(
      baseUrl: 'https://api.minimaxi.com/anthropic',
      apiKey: 'test-key',
    );
    final traceStore = FakeAiTraceStore();
    final aiClient = FakeAiInferenceClient()
      ..recommendationResult = AiRecommendationResult(
        connectionStatus: AiConnectionStatus.online,
        exchangeDebug: const AiInferenceExchangeDebug(
          model: 'MiniMax-M2.7',
          baseUrl: 'https://api.minimaxi.com/anthropic',
          requestBody: {'model': 'MiniMax-M2.7'},
          rawResponseText: '{"shouldSuggest":false}',
          parsedResponse: {'shouldSuggest': false},
        ),
        decisionReason: 'No suggestion because the signal mix was weak.',
      );
    final aiMemory = FakeAiMemoryService()
      ..settings = AiSettings.recommendedEnabled()
      ..savedConnection = AiSavedConnection(
        baseUrl: endpointConfig.baseUrl,
        apiKey: endpointConfig.apiKey,
        model: aiClient.model,
        verifiedAt: DateTime(2026, 3, 28, 9),
        lastHealthyAt: DateTime(2026, 3, 28, 9),
      );
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: aiMemory,
      aiInferenceClient: aiClient,
      aiContextCollector: FakeAiContextCollector(),
      aiTraceStore: traceStore,
      initialSystemLocale: const Locale('en'),
    );

    await controller.initialize();
    await controller.triggerWorkdayWrapUp();

    expect(controller.decisionTraces, hasLength(1));
    final trace = controller.decisionTraces.single;
    expect(trace.outcome, AiDecisionTraceOutcome.noSuggestion);
    expect(
      trace.outcomeReason,
      'No suggestion because the signal mix was weak.',
    );
    expect(trace.exchangeDebug?.rawResponseText, '{"shouldSuggest":false}');
    expect(trace.recommendation, isNull);
    expect(controller.activeSuggestion, isNull);
  });

  test(
    'AI trace is recorded when trigger is blocked by configuration',
    () async {
      final traceStore = FakeAiTraceStore();
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        aiTraceStore: traceStore,
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      await controller.triggerWorkdayWrapUp();

      expect(controller.decisionTraces, hasLength(1));
      expect(
        controller.decisionTraces.single.outcome,
        AiDecisionTraceOutcome.blockedByConfig,
      );
      expect(
        controller.decisionTraces.single.outcomeReason,
        'AI suggestions are off.',
      );
    },
  );

  test(
    'disabling a data source strips it from the AI context snapshot',
    () async {
      const endpointConfig = AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'test-key',
      );
      final aiClient = FakeAiInferenceClient();
      final aiContext = FakeAiContextCollector()
        ..systemContext = SystemContextSnapshot(
          collectedAt: DateTime(2025, 1, 1),
          frontmostAppName: 'Xcode',
          frontmostWindowTitle: 'Editor',
          idleSeconds: 12,
          networkName: 'Office Wi-Fi',
          networkReachable: true,
          bluetoothDevices: const ['Keyboard'],
        );
      final aiMemory = FakeAiMemoryService()
        ..settings = AiSettings(
          mode: AiMode.on,
          dataSources: {for (final source in AiDataSource.values) source: true},
        )
        ..savedConnection = AiSavedConnection(
          baseUrl: endpointConfig.baseUrl,
          apiKey: endpointConfig.apiKey,
          model: aiClient.model,
          verifiedAt: DateTime(2026, 1, 1, 9),
          lastHealthyAt: DateTime(2026, 1, 1, 9),
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: aiContext,
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      await controller.setAiDataSourceEnabled(AiDataSource.network, false);
      await controller.triggerWorkdayWrapUp();

      expect(aiClient.lastSnapshot, isNotNull);
      expect(aiContext.lastSources.contains(AiDataSource.network), isFalse);
    },
  );

  test(
    'accepting a later suggestion queues delayed lock and records feedback',
    () async {
      const endpointConfig = AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'test-key',
      );
      final aiClient = FakeAiInferenceClient()
        ..recommendationResult = AiRecommendationResult(
          connectionStatus: AiConnectionStatus.online,
          recommendation: AiRecommendation(
            id: 'sg-2',
            trigger: AiTriggerType.workdayEnded,
            headline: 'Take a short runway.',
            reason: 'Use a small delay before locking.',
            confidence: 0.75,
            usedSignals: const [AiSignalType.actionHistory],
            createdAt: DateTime(2025, 1, 1),
            preferredDelaySeconds: 300,
          ),
        );
      final aiMemory = FakeAiMemoryService()
        ..settings = AiSettings.recommendedEnabled()
        ..savedConnection = AiSavedConnection(
          baseUrl: endpointConfig.baseUrl,
          apiKey: endpointConfig.apiKey,
          model: aiClient.model,
          verifiedAt: DateTime(2026, 1, 1, 9),
          lastHealthyAt: DateTime(2026, 1, 1, 9),
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
        now: () => DateTime(2026, 3, 28, 12, 0),
      );

      await controller.initialize();
      await controller.triggerWorkdayWrapUp();
      await controller.acceptActiveSuggestionLater();

      expect(aiClient.feedbackCalls, 1);
      expect(aiClient.lastEpisode?.decision, AiDecisionType.laterFiveMinutes);
      expect(controller.delayedLock, isNotNull);
      expect(controller.activeSuggestion, isNull);
    },
  );

  test('only the two supported AI inputs are exposed', () async {
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await controller.initialize();

    expect(controller.aiDataSources, const [
      AiDataSource.actionHistory,
      AiDataSource.idleState,
    ]);
  });

  test('AI cannot be enabled until a saved connection exists', () async {
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await controller.initialize();
    await controller.enableAiSuggestionsWithDefaults();

    expect(controller.aiSuggestionsEnabled, isFalse);
    expect(controller.aiConnectionStatus, AiConnectionStatus.notConfigured);
    expect(
      statusMessageText(
        localizationsForLocale(controller.effectiveLocale),
        controller.statusMessage,
      ),
      'AI is on, but the base URL or API key is missing. Open Settings and save the AI connection first.',
    );
  });

  test('legacy unverified draft is surfaced as draft-only state', () async {
    final aiMemory = FakeAiMemoryService()
      ..draftEndpointConfig = const AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'draft-key',
      );
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: aiMemory,
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await controller.initialize();

    expect(controller.savedAiConnection, isNull);
    expect(controller.hasLegacyAiConnectionDraft, isTrue);
    expect(
      controller.aiConnectionDraftDefaults.normalizedBaseUrl,
      'https://api.minimaxi.com/anthropic',
    );
    expect(controller.aiConnectionStatus, AiConnectionStatus.ready);
    expect(controller.canEnableAi, isFalse);
  });

  test(
    'clearing AI history only clears trace files and in-memory traces',
    () async {
      final trace = AiDecisionTrace(
        id: 'trace-1',
        occurredAt: DateTime(2026, 3, 28, 10),
        trigger: AiTriggerType.workdayEnded,
        localeTag: 'en',
        enabledDataSources: const [AiDataSource.actionHistory],
        outcome: AiDecisionTraceOutcome.noSuggestion,
      );
      final traceStore = FakeAiTraceStore()..traces = [trace];
      final aiMemory = FakeAiMemoryService()
        ..savedConnection = AiSavedConnection(
          baseUrl: 'https://api.minimaxi.com/anthropic',
          apiKey: 'test-key',
          model: 'MiniMax-M2.7',
          verifiedAt: DateTime(2026, 3, 28, 9, 30),
          lastHealthyAt: DateTime(2026, 3, 28, 9, 30),
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        aiTraceStore: traceStore,
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      expect(controller.decisionTraces, hasLength(1));

      await controller.clearAiDecisionHistory();

      expect(traceStore.clearCalls, 1);
      expect(controller.decisionTraces, isEmpty);
      expect(
        aiMemory.savedConnection?.baseUrl,
        'https://api.minimaxi.com/anthropic',
      );
    },
  );

  test('testing a draft does not persist it until save is called', () async {
    final aiMemory = FakeAiMemoryService();
    final aiClient = FakeAiInferenceClient();
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: aiMemory,
      aiInferenceClient: aiClient,
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => DateTime(2026, 3, 28, 12, 0),
    );

    await controller.initialize();
    final result = await controller.testAiConnectionDraft(
      const AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'test-key',
      ),
    );

    expect(aiClient.testConnectionCalls, 1);
    expect(result.isSuccess, isTrue);
    expect(controller.savedAiConnection, isNull);
    expect(controller.canEnableAi, isFalse);
  });

  test(
    'saving a tested draft persists the connection and unlocks AI mode',
    () async {
      final aiMemory = FakeAiMemoryService();
      final aiClient = FakeAiInferenceClient();
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
        now: () => DateTime(2026, 3, 28, 12, 0),
      );

      await controller.initialize();
      final draft = const AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'test-key',
      );
      final result = await controller.testAiConnectionDraft(draft);
      await controller.saveVerifiedAiConnection(draft, result);

      expect(controller.savedAiConnection, isNotNull);
      expect(
        controller.savedAiConnection?.normalizedBaseUrl,
        'https://api.minimaxi.com/anthropic',
      );
      expect(controller.aiConnectionStatus, AiConnectionStatus.online);
      expect(
        controller.aiSavedConnectionState,
        AiSavedConnectionState.verifiedHealthy,
      );
      expect(controller.canEnableAi, isTrue);
      expect(controller.lastVerifiedAt, DateTime(2026, 3, 28, 12, 0));
      expect(aiMemory.savedConnection, isNotNull);
    },
  );

  test(
    'failed draft test does not overwrite the current saved connection',
    () async {
      final existingConnection = AiSavedConnection(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'good-key',
        model: 'MiniMax-M2.7',
        verifiedAt: DateTime(2026, 3, 28, 9, 30),
        lastHealthyAt: DateTime(2026, 3, 28, 9, 30),
      );
      final aiMemory = FakeAiMemoryService()
        ..savedConnection = existingConnection;
      final aiClient = FakeAiInferenceClient()
        ..testConnectionError = const AiServiceException(
          AiServiceErrorCode.requestFailed,
          'Invalid API key.',
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      final result = await controller.testAiConnectionDraft(
        const AiEndpointConfig(
          baseUrl: 'https://api.minimaxi.com/anthropic',
          apiKey: 'bad-key',
        ),
      );

      expect(result.state, AiConnectionDraftTestState.failure);
      expect(result.errorMessage, 'Invalid API key.');
      expect(controller.savedAiConnection?.apiKey, 'good-key');
      expect(
        controller.aiSavedConnectionState,
        AiSavedConnectionState.verifiedHealthy,
      );
      expect(controller.canEnableAi, isTrue);
    },
  );

  test(
    'clearAiConnection removes the saved connection and disables AI',
    () async {
      final aiMemory = FakeAiMemoryService()
        ..settings = AiSettings.recommendedEnabled()
        ..savedConnection = AiSavedConnection(
          baseUrl: 'https://api.minimaxi.com/anthropic',
          apiKey: 'test-key',
          model: 'MiniMax-M2.7',
          verifiedAt: DateTime(2026, 3, 28, 9, 30),
          lastHealthyAt: DateTime(2026, 3, 28, 9, 30),
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      await controller.clearAiConnection();

      expect(controller.savedAiConnection, isNull);
      expect(controller.aiSuggestionsEnabled, isFalse);
      expect(controller.canEnableAi, isFalse);
      expect(aiMemory.savedConnection, isNull);
    },
  );

  test('AI cannot be enabled with only an unverified local draft', () async {
    final aiMemory = FakeAiMemoryService()
      ..draftEndpointConfig = const AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'test-key',
      );
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: aiMemory,
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await controller.initialize();
    await controller.enableAiSuggestionsWithDefaults();

    expect(controller.aiSuggestionsEnabled, isFalse);
    expect(controller.savedAiConnection, isNull);
    expect(controller.aiConnectionStatus, AiConnectionStatus.ready);
    expect(
      statusMessageText(
        localizationsForLocale(controller.effectiveLocale),
        controller.statusMessage,
      ),
      'AI is on, but the base URL or API key is missing. Open Settings and save the AI connection first.',
    );
  });

  test('saved connection restores healthy state on startup', () async {
    final aiMemory = FakeAiMemoryService()
      ..savedConnection = AiSavedConnection(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'test-key',
        model: 'MiniMax-M2.7',
        verifiedAt: DateTime(2026, 3, 28, 9, 30),
        lastHealthyAt: DateTime(2026, 3, 28, 10, 0),
      );
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: aiMemory,
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await controller.initialize();

    expect(controller.aiConnectionStatus, AiConnectionStatus.online);
    expect(
      controller.aiSavedConnectionState,
      AiSavedConnectionState.verifiedHealthy,
    );
    expect(controller.canEnableAi, isTrue);
    expect(controller.lastVerifiedAt, DateTime(2026, 3, 28, 9, 30));
  });

  test(
    'runtime request failure degrades the saved connection but keeps it available',
    () async {
      final aiClient = FakeAiInferenceClient()
        ..recommendError = const AiServiceException(
          AiServiceErrorCode.requestFailed,
          'Endpoint rejected the request.',
        );
      final aiMemory = FakeAiMemoryService()
        ..settings = AiSettings.recommendedEnabled()
        ..savedConnection = AiSavedConnection(
          baseUrl: 'https://api.minimaxi.com/anthropic',
          apiKey: 'test-key',
          model: 'MiniMax-M2.7',
          verifiedAt: DateTime(2026, 3, 28, 9, 30),
          lastHealthyAt: DateTime(2026, 3, 28, 9, 30),
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      await controller.triggerWorkdayWrapUp();

      expect(controller.aiConnectionStatus, AiConnectionStatus.offline);
      expect(
        controller.aiSavedConnectionState,
        AiSavedConnectionState.verifiedDegraded,
      );
      expect(controller.canEnableAi, isTrue);
      expect(controller.savedAiConnection, isNotNull);
      expect(controller.aiConnectionDetail, 'Endpoint rejected the request.');
      expect(
        aiMemory.savedConnection?.lastErrorMessage,
        'Endpoint rejected the request.',
      );
    },
  );

  test(
    'runtime AI timeout degrades the saved connection and records a timedOut trace',
    () async {
      final aiClient = FakeAiInferenceClient()
        ..recommendError = const AiServiceException(
          AiServiceErrorCode.timedOut,
          'AI request timed out after 20 seconds.',
        );
      final aiMemory = FakeAiMemoryService()
        ..settings = AiSettings.recommendedEnabled()
        ..savedConnection = AiSavedConnection(
          baseUrl: 'https://api.minimaxi.com/anthropic',
          apiKey: 'test-key',
          model: 'MiniMax-M2.7',
          verifiedAt: DateTime(2026, 3, 28, 9, 30),
          lastHealthyAt: DateTime(2026, 3, 28, 9, 30),
        );
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );

      await controller.initialize();
      await controller.triggerWorkdayWrapUp();

      expect(controller.aiConnectionStatus, AiConnectionStatus.offline);
      expect(
        controller.aiSavedConnectionState,
        AiSavedConnectionState.verifiedDegraded,
      );
      expect(controller.canEnableAi, isTrue);
      expect(
        controller.aiConnectionDetail,
        'AI request timed out after 20 seconds.',
      );
      expect(
        controller.decisionTraces.single.outcome,
        AiDecisionTraceOutcome.timedOut,
      );
    },
  );

  test(
    'saving a new verified connection keeps AI enabled until the new config is saved',
    () async {
      final aiMemory = FakeAiMemoryService()
        ..settings = AiSettings.recommendedEnabled()
        ..savedConnection = AiSavedConnection(
          baseUrl: 'https://api.minimaxi.com/anthropic',
          apiKey: 'old-key',
          model: 'MiniMax-M2.7',
          verifiedAt: DateTime(2026, 3, 28, 9, 30),
          lastHealthyAt: DateTime(2026, 3, 28, 9, 30),
        );
      final aiClient = FakeAiInferenceClient();
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: aiMemory,
        aiInferenceClient: aiClient,
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
        now: () => DateTime(2026, 3, 28, 12, 0),
      );

      await controller.initialize();
      final draft = const AiEndpointConfig(
        baseUrl: 'https://api.minimaxi.com/anthropic',
        apiKey: 'new-key',
      );
      final result = await controller.testAiConnectionDraft(draft);

      expect(controller.aiSuggestionsEnabled, isTrue);
      expect(controller.savedAiConnection?.apiKey, 'old-key');

      await controller.saveVerifiedAiConnection(draft, result);

      expect(controller.aiSuggestionsEnabled, isTrue);
      expect(controller.savedAiConnection?.apiKey, 'new-key');
      expect(
        controller.aiSavedConnectionState,
        AiSavedConnectionState.verifiedHealthy,
      );
    },
  );
}
