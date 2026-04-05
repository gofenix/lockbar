import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/app.dart';
import 'package:lockbar/src/lockbar_controller.dart';
import 'package:lockbar/src/models/ai_models.dart';
import 'package:lockbar/src/models/lockbar_models.dart';

import 'test_doubles.dart';

void main() {
  testWidgets('settings window renders English copy by default', (
    WidgetTester tester,
  ) async {
    final platform = FakeLockbarPlatform()
      ..permissionState = PermissionState.denied;
    final launchAtStartup = FakeLaunchAtStartupService()..enabled = true;
    final controller = LockbarController(
      platform: platform,
      launchAtStartupService: launchAtStartup,
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await tester.pumpWidget(LockbarApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('LockBar'), findsOneWidget);
    expect(find.text('Locking'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Launch at Login'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Privacy'),
      240,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Accessibility is still off'), findsOneWidget);
    final requestPermission = find.text('Request Permission');
    await tester.ensureVisible(requestPermission);
    await tester.pumpAndSettle();
    await tester.tap(requestPermission, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(platform.requestPermissionCalls, 1);
    expect(find.text('Turn On Smart Suggestions'), findsOneWidget);
    expect(find.text('Configure…'), findsOneWidget);
    expect(find.text('Decision History'), findsOneWidget);
  });

  testWidgets('settings window renders Simplified Chinese when system is zh', (
    WidgetTester tester,
  ) async {
    final controller = LockbarController(
      platform: FakeLockbarPlatform()..permissionState = PermissionState.denied,
      launchAtStartupService: FakeLaunchAtStartupService()..enabled = true,
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('zh'),
    );

    await tester.pumpWidget(LockbarApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('LockBar'), findsOneWidget);
    expect(find.text('锁屏'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('登录时启动'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('隐私'),
      240,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('辅助功能权限仍未开启'), findsOneWidget);
    expect(find.text('开启智能建议'), findsOneWidget);
    expect(find.text('配置…'), findsOneWidget);
    expect(find.text('决策历史'), findsOneWidget);
  });

  testWidgets('AI configuration happens inside the dialog', (
    WidgetTester tester,
  ) async {
    final controller = LockbarController(
      platform: FakeLockbarPlatform()..permissionState = PermissionState.denied,
      launchAtStartupService: FakeLaunchAtStartupService()..enabled = true,
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
    );

    await tester.pumpWidget(LockbarApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Configure…'),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configure…'));
    await tester.pumpAndSettle();

    expect(find.text('Configure AI Connection'), findsOneWidget);
    expect(find.text('Draft test status'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('AI history renders the latest trace details in settings', (
    WidgetTester tester,
  ) async {
    final traceStore = FakeAiTraceStore()
      ..traces = [
        AiDecisionTrace(
          id: 'trace-1',
          occurredAt: DateTime(2026, 3, 28, 18),
          trigger: AiTriggerType.workdayEnded,
          localeTag: 'en',
          enabledDataSources: const [
            AiDataSource.actionHistory,
            AiDataSource.idleState,
          ],
          collectedContext: SystemContextSnapshot(
            collectedAt: DateTime(2026, 3, 28, 18),
            idleSeconds: 18,
            bluetoothDevices: const ['Keyboard'],
            networkReachable: true,
          ),
          exchangeDebug: const AiInferenceExchangeDebug(
            model: 'MiniMax-M2.7',
            baseUrl: 'https://api.minimaxi.com/anthropic',
            requestBody: {'model': 'MiniMax-M2.7'},
            rawResponseText: '{"shouldSuggest":false}',
            parsedResponse: {'shouldSuggest': false},
          ),
          outcome: AiDecisionTraceOutcome.noSuggestion,
          outcomeReason: 'No suggestion because the signal mix was weak.',
        ),
      ];
    final controller = LockbarController(
      platform: FakeLockbarPlatform()..permissionState = PermissionState.denied,
      launchAtStartupService: FakeLaunchAtStartupService()..enabled = true,
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      aiTraceStore: traceStore,
      initialSystemLocale: const Locale('en'),
    );

    await tester.pumpWidget(LockbarApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Decision History'),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('Decision History'), findsOneWidget);
    expect(find.text('No suggestion'), findsWidgets);
    expect(
      find.text('No suggestion because the signal mix was weak.'),
      findsOneWidget,
    );

    await tester.tap(find.textContaining('Workday').first);
    await tester.pumpAndSettle();

    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('Sent to AI'), findsOneWidget);
    expect(find.text('AI Returned'), findsOneWidget);
    expect(find.text('Outcome'), findsOneWidget);
  });

  testWidgets('settings window shows keep-awake controls and live countdown', (
    WidgetTester tester,
  ) async {
    var now = DateTime(2026, 4, 5, 13, 0, 0);
    final controller = LockbarController(
      platform: FakeLockbarPlatform()..permissionState = PermissionState.denied,
      launchAtStartupService: FakeLaunchAtStartupService()..enabled = true,
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => now,
    );

    await tester.pumpWidget(LockbarApp(controller: controller));
    await tester.pumpAndSettle();
    await controller.startKeepAwakeSession(const Duration(minutes: 30));
    await tester.pump();

    expect(find.text('30 Minutes'), findsOneWidget);
    expect(find.text('1 Hour'), findsOneWidget);
    expect(find.text('2 Hours'), findsOneWidget);
    expect(find.text('Until Stopped'), findsOneWidget);
    expect(find.text('Stop Keeping Awake'), findsOneWidget);
    expect(find.text('Keep-awake active: 30:00'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Keep-awake active: 29:59'), findsOneWidget);
  });

  testWidgets('settings window shows indefinite and idle keep-awake states', (
    WidgetTester tester,
  ) async {
    final controller = LockbarController(
      platform: FakeLockbarPlatform()..permissionState = PermissionState.denied,
      launchAtStartupService: FakeLaunchAtStartupService()..enabled = true,
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => DateTime(2026, 4, 5, 13, 0, 0),
    );

    await tester.pumpWidget(LockbarApp(controller: controller));
    await tester.pumpAndSettle();
    await controller.startKeepAwakeIndefinitely();
    await tester.pump();

    expect(find.text('Keep-awake active: until you stop it.'), findsOneWidget);
    expect(find.text('Stop Keeping Awake'), findsOneWidget);

    await tester.ensureVisible(find.text('Stop Keeping Awake'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop Keeping Awake'));
    await tester.pumpAndSettle();

    expect(find.text('Keep-awake is off.'), findsOneWidget);
  });
}
