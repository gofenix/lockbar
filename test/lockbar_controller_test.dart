import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/l10n/locale_support.dart';
import 'package:lockbar/src/lockbar_controller.dart';
import 'package:lockbar/src/models/lockbar_models.dart';

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
        'LockBar needs Accessibility access before it can lock your Mac. Enable it in System Settings, then try again.',
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
}
