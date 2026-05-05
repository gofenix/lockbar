import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/desktop_coordinator.dart';
import 'package:lockbar/src/lockbar_controller.dart';
import 'package:lockbar/src/models/ai_models.dart';
import 'package:lockbar/src/models/command_panel_models.dart';
import 'package:lockbar/src/models/lockbar_models.dart';

import 'test_doubles.dart';

void main() {
  test('command panel shows active keep awake status and preset', () async {
    final trayClient = FakeTrayClient();
    final platform = FakeLockbarPlatform()
      ..permissionState = PermissionState.granted;
    final controller = LockbarController(
      platform: platform,
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

    final data = await coordinator.buildCommandPanelData();

    expect(data.statusText, 'Awake 30:00');
    expect(data.keepAwakeActive, isTrue);
    expect(data.keepAwakePreset, KeepAwakePreset.thirtyMinutes);
    expect(data.keepAwakeSubtitle, 'Keep-awake active: 30:00');
  });

  test(
    'command panel shows idle keep awake controls when no session is running',
    () async {
      final trayClient = FakeTrayClient();
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.granted;
      final controller = LockbarController(
        platform: platform,
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

      final data = await coordinator.buildCommandPanelData();

      expect(data.statusText, 'Ready');
      expect(data.keepAwakeActive, isFalse);
      expect(data.keepAwakePreset, isNull);
      expect(data.keepAwake30MinutesLabel, '30m');
      expect(data.keepAwake1HourLabel, '1h');
      expect(data.keepAwake2HoursLabel, '2h');
      expect(data.keepAwakeIndefinitelyLabel, '\u221e');
    },
  );

  test(
    'command panel shows three appearance options and current mode',
    () async {
      final trayClient = FakeTrayClient();
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.granted
        ..appearanceMode = AppearanceMode.automatic;
      final controller = LockbarController(
        platform: platform,
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

      final data = await coordinator.buildCommandPanelData();
      await coordinator.syncCommandMenuForTesting(force: true);

      expect(data.appearanceTitle, 'Appearance');
      expect(data.appearanceMode, AppearanceMode.automatic);
      expect(data.appearanceLightLabel, 'Light');
      expect(data.appearanceDarkLabel, 'Dark');
      expect(data.appearanceAutomaticLabel, 'Automatic');
      expect(
        trayClient.contextMenu
            ?.getMenuItem(CommandPanelAction.setAppearanceLight.storageKey)
            ?.checked,
        isFalse,
      );
      expect(
        trayClient.contextMenu
            ?.getMenuItem(CommandPanelAction.setAppearanceDark.storageKey)
            ?.checked,
        isFalse,
      );
      expect(
        trayClient.contextMenu
            ?.getMenuItem(CommandPanelAction.setAppearanceAutomatic.storageKey)
            ?.checked,
        isTrue,
      );
    },
  );

  test('command panel shows indefinite keep awake status and preset', () async {
    final trayClient = FakeTrayClient();
    final platform = FakeLockbarPlatform()
      ..permissionState = PermissionState.granted;
    final controller = LockbarController(
      platform: platform,
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

    final data = await coordinator.buildCommandPanelData();

    expect(data.statusText, 'Awake');
    expect(data.keepAwakeActive, isTrue);
    expect(data.keepAwakePreset, KeepAwakePreset.indefinite);
    expect(data.keepAwakeSubtitle, 'Keep-awake active: until you stop it.');
  });

  test(
    'command panel hides focus controls while tray title still uses focus countdown',
    () async {
      final trayClient = FakeTrayClient();
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.granted;
      final controller = LockbarController(
        platform: platform,
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

      final data = await coordinator.buildCommandPanelData();

      expect(data.statusText, 'Ready');
      expect(
        data.toMap().values.whereType<String>().join('|'),
        isNot(contains('Focus')),
      );
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

  test(
    'tray title hides idle ready state and shows active awake state',
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

      await coordinator.syncTrayTitleForTesting(force: true);
      expect(trayClient.title, '');
      expect(coordinator.buildTrayTitle(), 'Ready');

      await controller.startKeepAwakeIndefinitely();
      await coordinator.syncTrayTitleForTesting(force: true);
      expect(trayClient.title, 'Awake');
    },
  );

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

  test(
    'native command menu rebuild refreshes countdown before opening',
    () async {
      var now = DateTime(2026, 4, 5, 13, 0, 0);
      final trayClient = FakeTrayClient();
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.granted;
      final controller = LockbarController(
        platform: platform,
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
      await coordinator.showCommandPanelForTesting();

      expect(trayClient.contextMenu?.items?.first.label, 'Awake 30:00');

      now = now.add(const Duration(minutes: 10));
      await coordinator.showCommandPanelForTesting();

      expect(trayClient.setContextMenuCalls, 2);
      expect(trayClient.popUpContextMenuCalls, 2);
      expect(trayClient.contextMenu?.items?.first.label, 'Awake 20:00');
    },
  );

  test('right click opens the native context menu', () async {
    final trayClient = FakeTrayClient();
    final platform = FakeLockbarPlatform()
      ..permissionState = PermissionState.granted;
    final controller = LockbarController(
      platform: platform,
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
    await coordinator.syncCommandMenuForTesting(force: true);
    coordinator.onTrayIconRightMouseDown();
    await Future<void>.delayed(Duration.zero);

    expect(trayClient.setContextMenuCalls, 1);
    expect(trayClient.popUpContextMenuCalls, 1);
    expect(trayClient.contextMenu?.items?.first.label, 'Awake 30:00');
    expect(
      trayClient.contextMenu
          ?.getMenuItem(CommandPanelAction.keepAwake30Minutes.storageKey)
          ?.checked,
      isTrue,
    );
  });

  test(
    'right click opens the native context menu without accessibility permission or bluetooth wait',
    () async {
      final trayClient = FakeTrayClient();
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.denied
        ..bluetoothBatteryDevicesCompleter =
            Completer<List<BluetoothBatteryDevice>>();
      final controller = LockbarController(
        platform: platform,
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
      await coordinator.syncCommandMenuForTesting(force: true);
      coordinator.onTrayIconRightMouseDown();
      await Future<void>.delayed(Duration.zero);

      expect(platform.getBluetoothBatteryDevicesCalls, 1);
      expect(trayClient.setContextMenuCalls, 1);
      expect(trayClient.popUpContextMenuCalls, 1);
      expect(
        trayClient.contextMenu?.items?.first.label,
        'Accessibility is still off',
      );

      platform.bluetoothBatteryDevicesCompleter!.complete([
        const BluetoothBatteryDevice(name: 'MX Master 3', batteryLevel: 100),
      ]);
      await Future<void>.delayed(Duration.zero);
      await coordinator.syncCommandMenuForTesting(force: true);

      coordinator.onTrayIconRightMouseDown();
      await Future<void>.delayed(Duration.zero);

      expect(trayClient.setContextMenuCalls, 2);
      expect(
        trayClient.contextMenu?.toJson().toString(),
        contains('MX Master 3  100%'),
      );
    },
  );

  test(
    'command panel actions control keep awake and launch at login',
    () async {
      final trayClient = FakeTrayClient();
      final launchAtStartup = FakeLaunchAtStartupService();
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.granted;
      final controller = LockbarController(
        platform: platform,
        launchAtStartupService: launchAtStartup,
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

      await coordinator.handleCommandPanelActionForTesting(
        CommandPanelAction.keepAwake1Hour,
      );
      expect(controller.keepAwakeSession?.preset, KeepAwakePreset.oneHour);

      await coordinator.handleCommandPanelActionForTesting(
        CommandPanelAction.cancelKeepAwake,
      );
      expect(controller.keepAwakeSession, isNull);

      await coordinator.handleCommandPanelActionForTesting(
        CommandPanelAction.toggleLaunchAtLogin,
      );
      expect(controller.launchAtStartupEnabled, isTrue);
      expect(launchAtStartup.setEnabledCalls, 1);

      await coordinator.handleCommandPanelActionForTesting(
        CommandPanelAction.setAppearanceDark,
      );
      expect(platform.appearanceMode, AppearanceMode.dark);

      await coordinator.handleCommandPanelActionForTesting(
        CommandPanelAction.setAppearanceAutomatic,
      );
      expect(platform.appearanceMode, AppearanceMode.automatic);
      expect(platform.setAppearanceModeCalls, 2);
    },
  );

  test('command panel includes sorted bluetooth battery devices', () async {
    final platform = FakeLockbarPlatform()
      ..permissionState = PermissionState.granted
      ..bluetoothBatteryDevices = const [
        BluetoothBatteryDevice(name: 'MX Master 3S', batteryLevel: 82),
        BluetoothBatteryDevice(
          name: 'AirPods Pro',
          leftBatteryLevel: 76,
          rightBatteryLevel: 71,
          caseBatteryLevel: 54,
        ),
      ];
    final controller = LockbarController(
      platform: platform,
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
      trayClient: FakeTrayClient(),
    );

    await controller.initialize();

    final data = await coordinator.buildCommandPanelData();
    final payload = data.toMap();

    expect(data.bluetoothDevicesTitle, 'Bluetooth Devices');
    expect(data.bluetoothDevices.map((device) => device.name), [
      'AirPods Pro',
      'MX Master 3S',
    ]);
    expect(payload['bluetoothDevices'], [
      {
        'name': 'AirPods Pro',
        'batteryLevel': null,
        'leftBatteryLevel': 76,
        'rightBatteryLevel': 71,
        'caseBatteryLevel': 54,
      },
      {
        'name': 'MX Master 3S',
        'batteryLevel': 82,
        'leftBatteryLevel': null,
        'rightBatteryLevel': null,
        'caseBatteryLevel': null,
      },
    ]);
  });

  test(
    'command panel filters bluetooth devices with no battery data',
    () async {
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.granted
        ..bluetoothBatteryDevices = const [
          BluetoothBatteryDevice(name: 'Keyboard'),
        ];
      final controller = LockbarController(
        platform: platform,
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
        trayClient: FakeTrayClient(),
      );

      await controller.initialize();

      final data = await coordinator.buildCommandPanelData();

      expect(data.bluetoothDevices, isEmpty);
      expect(data.toMap()['bluetoothDevices'], isEmpty);
    },
  );

  test(
    'native command menu reflects bluetooth battery changes when reopened',
    () async {
      final platform = FakeLockbarPlatform()
        ..permissionState = PermissionState.granted
        ..bluetoothBatteryDevices = const [
          BluetoothBatteryDevice(name: 'MX Master 3S', batteryLevel: 82),
        ];
      final trayClient = FakeTrayClient();
      final controller = LockbarController(
        platform: platform,
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
      await coordinator.showCommandPanelForTesting();

      expect(
        trayClient.contextMenu?.toJson().toString(),
        contains('MX Master 3S  82%'),
      );

      platform.bluetoothBatteryDevices = const [
        BluetoothBatteryDevice(name: 'MX Master 3S', batteryLevel: 81),
      ];
      await coordinator.showCommandPanelForTesting();

      expect(
        trayClient.contextMenu?.toJson().toString(),
        contains('MX Master 3S  81%'),
      );
    },
  );
}
