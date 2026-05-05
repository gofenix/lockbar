import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_support.dart';
import 'desktop_coordinator.dart';
import 'lockbar_controller.dart';
import 'ui/lockbar_window.dart';

class LockbarApp extends StatefulWidget {
  const LockbarApp({super.key, required this.controller, this.coordinator});

  final LockbarController controller;
  final LockbarDesktopCoordinator? coordinator;

  @override
  State<LockbarApp> createState() => _LockbarAppState();
}

class _LockbarAppState extends State<LockbarApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await widget.controller.initialize();
    await widget.coordinator?.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.coordinator?.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (locales != null && locales.isNotEmpty) {
      widget.controller.updateSystemLocale(locales.first);
    }
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final baseScheme = ColorScheme.fromSeed(
          brightness: platformBrightness,
          seedColor: const Color(0xFF3B82F6),
          primary: const Color(0xFF3B82F6),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LockBar',
          locale: widget.controller.effectiveLocale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (locale, supportedLocales) {
            return resolveSupportedLocale(
              locale ?? widget.controller.effectiveLocale,
            );
          },
          theme: ThemeData(
            useMaterial3: true,
            brightness: platformBrightness,
            colorScheme: baseScheme.copyWith(
              surfaceContainerHighest: platformBrightness == Brightness.dark
                  ? const Color(0xFF2A2C31)
                  : const Color(0xFFE7E9EE),
            ),
            scaffoldBackgroundColor: baseScheme.surface,
          ),
          home: LockbarWindow(controller: widget.controller),
        );
      },
    );
  }
}
