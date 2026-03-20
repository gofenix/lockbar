import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/app.dart';
import 'package:lockbar/src/lockbar_controller.dart';
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
      initialSystemLocale: const Locale('en'),
    );

    await tester.pumpWidget(LockbarApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('One click. Screen locked.'), findsOneWidget);
    expect(find.text('Accessibility is still off'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Launch at Login'),
      240,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Launch at Login'), findsOneWidget);

    await tester.tap(find.text('Request Permission'));
    await tester.pumpAndSettle();

    expect(platform.requestPermissionCalls, 1);
  });

  testWidgets('settings window renders Simplified Chinese when system is zh', (
    WidgetTester tester,
  ) async {
    final controller = LockbarController(
      platform: FakeLockbarPlatform()..permissionState = PermissionState.denied,
      launchAtStartupService: FakeLaunchAtStartupService()..enabled = true,
      localePreferencesService: FakeLocalePreferencesService(),
      initialSystemLocale: const Locale('zh'),
    );

    await tester.pumpWidget(LockbarApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('一键锁屏，立即生效。'), findsOneWidget);
    expect(find.text('辅助功能权限仍未开启'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('登录时启动'),
      240,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('登录时启动'), findsOneWidget);
  });
}
