import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/desktop_coordinator.dart';
import 'package:lockbar/src/lockbar_controller.dart';
import 'package:lockbar/src/models/ai_models.dart';

import 'test_doubles.dart';

void main() {
  test('keep awake submenu shows active status and checked preset', () async {
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
}
