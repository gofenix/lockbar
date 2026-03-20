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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final baseScheme = ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF8FE86B),
          primary: const Color(0xFF8FE86B),
          surface: const Color(0xFF151A1F),
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
            brightness: Brightness.dark,
            colorScheme: baseScheme.copyWith(
              secondary: const Color(0xFF7BD7F0),
              tertiary: const Color(0xFFFFC870),
              surfaceContainerHighest: const Color(0xFF222A31),
            ),
            scaffoldBackgroundColor: const Color(0xFF0B1014),
            textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: const Color(0xFFF2F6F8),
              displayColor: const Color(0xFFF2F6F8),
            ),
          ),
          home: LockbarWindow(controller: widget.controller),
        );
      },
    );
  }
}
