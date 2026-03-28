import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/desktop_coordinator.dart';
import 'src/lockbar_controller.dart';
import 'src/platform/lockbar_platform.dart';
import 'src/services/ai_context_collector.dart';
import 'src/services/ai_inference_client.dart';
import 'src/services/ai_memory_service.dart';
import 'src/services/ai_trace_store.dart';
import 'src/services/launch_at_startup_service.dart';
import 'src/services/locale_preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final platform = MethodChannelLockbarPlatform();
  final launchAtStartupService = PluginLaunchAtStartupService();
  final localePreferencesService = SharedPreferencesLocalePreferencesService();
  final aiMemoryService = SharedPreferencesAiMemoryService();
  final aiTraceStore = FileSystemAiTraceStore(
    applicationSupportDirectoryProvider: getApplicationSupportDirectory,
  );
  final aiInferenceClient = AdaptiveAiInferenceClient();
  final aiContextCollector = PlatformAiContextCollector(platform: platform);
  final controller = LockbarController(
    platform: platform,
    launchAtStartupService: launchAtStartupService,
    localePreferencesService: localePreferencesService,
    aiMemoryService: aiMemoryService,
    aiInferenceClient: aiInferenceClient,
    aiContextCollector: aiContextCollector,
    aiTraceStore: aiTraceStore,
    initialSystemLocale: WidgetsBinding.instance.platformDispatcher.locale,
    enableBackgroundContextPolling: true,
  );
  final coordinator = LockbarDesktopCoordinator(
    controller: controller,
    platform: platform,
  );

  final windowOptions = WindowOptions(
    size: Size(520, 560),
    minimumSize: Size(460, 500),
    center: true,
    backgroundColor: Color(0xFFF4F5F7),
    titleBarStyle: TitleBarStyle.normal,
    skipTaskbar: true,
    title: 'LockBar',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(true);
    if (!controller.isSettingsWindowVisible) {
      await windowManager.hide();
    }
  });

  runApp(LockbarApp(controller: controller, coordinator: coordinator));
}
