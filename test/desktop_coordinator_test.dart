import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/desktop_coordinator.dart';
import 'package:lockbar/src/lockbar_controller.dart';
import 'package:lockbar/src/models/ai_models.dart';

import 'test_doubles.dart';

void main() {
  test('keep awake submenu shows active status and checked preset', () async {
    final trayClient = FakeTrayClient();
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => DateTime(2026, 4, 5, 13, 0, 0),
    );
    final coordinator = LockbarDesktopCoordinator(
      controller: controller,
      platform: controller.platform,
      trayClient: trayClient,
    );

    await controller.initialize();
    await controller.startKeepAwakeSession(const Duration(minutes: 30));

    final menu = coordinator.buildContextMenu();
    final keepAwakeMenu = menu.getMenuItem('keepAwake');
    final submenuItems = keepAwakeMenu?.submenu?.items;

    expect(keepAwakeMenu, isNotNull);
    expect(submenuItems, isNotNull);
    expect(submenuItems!.first.label, 'Current: keep awake, 30:00 remaining');
    expect(submenuItems.first.disabled, isTrue);
    expect(
      keepAwakeMenu?.submenu?.getMenuItem('keepAwake30Minutes')?.checked,
      isTrue,
    );
    expect(menu.getMenuItem('cancelKeepAwake'), isNotNull);
  });

  test(
    'keep awake submenu hides active controls when no session is running',
    () async {
      final trayClient = FakeTrayClient();
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
      );
      final coordinator = LockbarDesktopCoordinator(
        controller: controller,
        platform: controller.platform,
        trayClient: trayClient,
      );

      await controller.initialize();

      final menu = coordinator.buildContextMenu();
      final keepAwakeMenu = menu.getMenuItem('keepAwake');
      final submenuItems = keepAwakeMenu?.submenu?.items;

      expect(keepAwakeMenu, isNotNull);
      expect(submenuItems, isNotNull);
      expect(submenuItems!.first.label, '30 Minutes');
      expect(submenuItems.first.disabled, isFalse);
      expect(menu.getMenuItem('cancelKeepAwake'), isNull);
    },
  );

  test(
    'indefinite keep awake menu shows indefinite status and checked preset',
    () async {
      final trayClient = FakeTrayClient();
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
        now: () => DateTime(2026, 4, 5, 13, 0, 0),
      );
      final coordinator = LockbarDesktopCoordinator(
        controller: controller,
        platform: controller.platform,
        trayClient: trayClient,
      );

      await controller.initialize();
      await controller.startKeepAwakeIndefinitely();

      final menu = coordinator.buildContextMenu();
      final keepAwakeMenu = menu.getMenuItem('keepAwake');
      final submenuItems = keepAwakeMenu?.submenu?.items;

      expect(submenuItems, isNotNull);
      expect(submenuItems!.first.label, 'Current: keep awake until stopped');
      expect(
        keepAwakeMenu?.submenu?.getMenuItem('keepAwakeIndefinitely')?.checked,
        isTrue,
      );
      expect(menu.getMenuItem('cancelKeepAwake'), isNotNull);
    },
  );

  test(
    'focus menu shows live status and tray title uses focus countdown',
    () async {
      final trayClient = FakeTrayClient();
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
        now: () => DateTime(2026, 4, 5, 13, 0, 0),
      );
      final coordinator = LockbarDesktopCoordinator(
        controller: controller,
        platform: controller.platform,
        trayClient: trayClient,
      );

      await controller.initialize();
      await controller.startFocusSession(const Duration(minutes: 25));
      await coordinator.syncTrayTitleForTesting(force: true);

      final menu = coordinator.buildContextMenu();

      expect(menu.items!.first.label, 'Current: focus, 25:00 remaining');
      expect(menu.items!.first.disabled, isTrue);
      expect(menu.getMenuItem('cancelFocus'), isNotNull);
      expect(trayClient.title, 'Focus 25:00');
    },
  );

  test('tray title prefers the earlier finite session', () async {
    final trayClient = FakeTrayClient();
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => DateTime(2026, 4, 5, 13, 0, 0),
    );
    final coordinator = LockbarDesktopCoordinator(
      controller: controller,
      platform: controller.platform,
      trayClient: trayClient,
    );

    await controller.initialize();
    await controller.startFocusSession(const Duration(minutes: 50));
    await controller.startKeepAwakeSession(const Duration(minutes: 30));
    await coordinator.syncTrayTitleForTesting(force: true);

    expect(trayClient.title, 'Awake 30:00');
  });

  test('tray title prefers focus when finite sessions end together', () async {
    final trayClient = FakeTrayClient();
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => DateTime(2026, 4, 5, 13, 0, 0),
    );
    final coordinator = LockbarDesktopCoordinator(
      controller: controller,
      platform: controller.platform,
      trayClient: trayClient,
    );

    await controller.initialize();
    await controller.startFocusSession(const Duration(minutes: 30));
    await controller.startKeepAwakeSession(const Duration(minutes: 30));
    await coordinator.syncTrayTitleForTesting(force: true);

    expect(trayClient.title, 'Focus 30:00');
  });

  test('tray title falls back to awake and ready states', () async {
    final trayClient = FakeTrayClient();
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => DateTime(2026, 4, 5, 13, 0, 0),
    );
    final coordinator = LockbarDesktopCoordinator(
      controller: controller,
      platform: controller.platform,
      trayClient: trayClient,
    );

    await controller.initialize();

    await coordinator.syncTrayTitleForTesting(force: true);
    expect(trayClient.title, 'Ready');

    await controller.startKeepAwakeIndefinitely();
    await coordinator.syncTrayTitleForTesting(force: true);
    expect(trayClient.title, 'Awake');
  });

  test('tray title localizes to Chinese', () async {
    final trayClient = FakeTrayClient();
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('zh'),
      now: () => DateTime(2026, 4, 5, 13, 0, 0),
    );
    final coordinator = LockbarDesktopCoordinator(
      controller: controller,
      platform: controller.platform,
      trayClient: trayClient,
    );

    await controller.initialize();
    await controller.startFocusSession(const Duration(minutes: 25));
    await coordinator.syncTrayTitleForTesting(force: true);

    expect(trayClient.title, '专注 25:00');
  });

  test('context menu sync skips countdown-only ticks', () async {
    var now = DateTime(2026, 4, 5, 13, 0, 0);
    final trayClient = FakeTrayClient();
    final controller = LockbarController(
      platform: FakeLockbarPlatform(),
      launchAtStartupService: FakeLaunchAtStartupService(),
      localePreferencesService: FakeLocalePreferencesService(),
      aiMemoryService: FakeAiMemoryService(),
      aiInferenceClient: FakeAiInferenceClient(),
      aiContextCollector: FakeAiContextCollector(),
      initialSystemLocale: const Locale('en'),
      now: () => now,
    );
    final coordinator = LockbarDesktopCoordinator(
      controller: controller,
      platform: controller.platform,
      trayClient: trayClient,
    );

    await controller.initialize();
    await controller.startKeepAwakeSession(const Duration(minutes: 30));
    await coordinator.syncContextMenuForTesting(force: true);

    expect(trayClient.setContextMenuCalls, 1);

    now = now.add(const Duration(seconds: 1));
    await coordinator.syncContextMenuForTesting();

    expect(trayClient.setContextMenuCalls, 1);
  });

  test(
    'right click force-refreshes the current countdown before showing menu',
    () async {
      var now = DateTime(2026, 4, 5, 13, 0, 0);
      final trayClient = FakeTrayClient();
      final controller = LockbarController(
        platform: FakeLockbarPlatform(),
        launchAtStartupService: FakeLaunchAtStartupService(),
        localePreferencesService: FakeLocalePreferencesService(),
        aiMemoryService: FakeAiMemoryService(),
        aiInferenceClient: FakeAiInferenceClient(),
        aiContextCollector: FakeAiContextCollector(),
        initialSystemLocale: const Locale('en'),
        now: () => now,
      );
      final coordinator = LockbarDesktopCoordinator(
        controller: controller,
        platform: controller.platform,
        trayClient: trayClient,
      );

      await controller.initialize();
      await controller.startKeepAwakeSession(const Duration(minutes: 30));
      await coordinator.showContextMenuForTesting();

      var keepAwakeMenu = trayClient.contextMenu!.getMenuItem('keepAwake')!;
      expect(
        keepAwakeMenu.submenu!.items!.first.label,
        'Current: keep awake, 30:00 remaining',
      );
      expect(trayClient.popUpContextMenuCalls, 1);

      now = now.add(const Duration(minutes: 10));
      await coordinator.showContextMenuForTesting();

      keepAwakeMenu = trayClient.contextMenu!.getMenuItem('keepAwake')!;
      expect(
        keepAwakeMenu.submenu!.items!.first.label,
        'Current: keep awake, 20:00 remaining',
      );
      expect(trayClient.popUpContextMenuCalls, 2);
    },
  );
}
