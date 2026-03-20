import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/desktop_coordinator.dart';
import 'src/lockbar_controller.dart';
import 'src/platform/lockbar_platform.dart';
import 'src/services/launch_at_startup_service.dart';
import 'src/services/locale_preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final platform = MethodChannelLockbarPlatform();
  final launchAtStartupService = PluginLaunchAtStartupService();
  final localePreferencesService = SharedPreferencesLocalePreferencesService();
  final controller = LockbarController(
    platform: platform,
    launchAtStartupService: launchAtStartupService,
    localePreferencesService: localePreferencesService,
    initialSystemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
  final coordinator = LockbarDesktopCoordinator(
    controller: controller,
    platform: platform,
  );

  final windowOptions = WindowOptions(
    size: Size(460, 560),
    minimumSize: Size(430, 520),
    center: true,
    backgroundColor: Color(0x00000000),
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: true,
    title: 'LockBar',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(true);
    await windowManager.hide();
  });

  runApp(LockbarApp(controller: controller, coordinator: coordinator));
}
