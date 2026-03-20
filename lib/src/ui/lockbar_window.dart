import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_support.dart';
import '../lockbar_controller.dart';
import '../models/lockbar_models.dart';

class LockbarWindow extends StatelessWidget {
  const LockbarWindow({super.key, required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final localizations = AppLocalizations.of(context);
        final bannerMessage = statusMessageText(
          localizations,
          controller.statusMessage,
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0F13),
                  const Color(0xFF111A1E),
                  scheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    children: [
                      _HeroCard(controller: controller),
                      const SizedBox(height: 16),
                      if (bannerMessage != null)
                        _StatusBanner(
                          message: bannerMessage,
                          isError: controller.hasError,
                        ),
                      if (bannerMessage != null) const SizedBox(height: 16),
                      _PermissionCard(controller: controller),
                      const SizedBox(height: 16),
                      _ControlsCard(controller: controller),
                      const SizedBox(height: 16),
                      _AboutCard(controller: controller),
                    ],
                  ),
                  if (controller.isLoading)
                    Positioned.fill(
                      child: ColoredBox(
                        color: const Color(0xB30B1014),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 14),
                              Text(
                                localizations.preparingLockBar,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A232C),
            scheme.surfaceContainerHighest.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.16),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.lock_outline_rounded,
                color: scheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.heroTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              localizations.heroDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFB6C3CB),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Pill(
                  icon: Icons.mouse_rounded,
                  label: localizations.leftClickLocks,
                ),
                _Pill(
                  icon: Icons.settings_rounded,
                  label: localizations.rightClickOpensMenu,
                ),
                _Pill(
                  icon: Icons.desktop_mac_rounded,
                  label: controller.appInfo.shortLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context);
    final permissionCopy = _permissionCopy(
      localizations,
      controller.permissionState,
    );
    final isGranted = controller.permissionState == PermissionState.granted;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(permissionCopy.icon, color: permissionCopy.color(scheme)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  permissionCopy.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            permissionCopy.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB6C3CB),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: controller.isBusy
                    ? null
                    : isGranted
                    ? controller.refreshPermissionState
                    : controller.requestPermission,
                icon: Icon(
                  isGranted ? Icons.refresh_rounded : Icons.security_rounded,
                ),
                label: Text(
                  isGranted
                      ? localizations.refreshStatus
                      : localizations.requestPermission,
                ),
              ),
              OutlinedButton.icon(
                onPressed: controller.isBusy
                    ? null
                    : controller.openAccessibilitySettings,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(localizations.openSystemSettings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.controlsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: controller.launchAtStartupEnabled,
            onChanged: controller.isBusy ? null : controller.setLaunchAtStartup,
            title: Text(localizations.launchAtLogin),
            subtitle: Text(localizations.launchAtLoginDescription),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.languageTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.languageDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB6C3CB),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppLocalePreference>(
            initialValue: controller.localePreference,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            items: AppLocalePreference.values
                .map(
                  (preference) => DropdownMenuItem<AppLocalePreference>(
                    value: preference,
                    child: Text(preferenceLabel(localizations, preference)),
                  ),
                )
                .toList(),
            onChanged: controller.isBusy
                ? null
                : (value) {
                    if (value != null) {
                      controller.setLocalePreference(value);
                    }
                  },
          ),
          const SizedBox(height: 10),
          Text(
            localizations.currentLanguageLabel(
              localeLabel(localizations, controller.effectiveLocale),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB6C3CB),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.canLockNow
                  ? controller.lockNowFromSettings
                  : null,
              icon: const Icon(Icons.lock_rounded),
              label: Text(localizations.lockNow),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.aboutTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(controller.appInfo.shortLabel, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            localizations.aboutDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB6C3CB),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isError ? scheme.tertiary : scheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isError
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: accent,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFB6C3CB)),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

({
  IconData icon,
  String title,
  String description,
  Color Function(ColorScheme scheme) color,
})
_permissionCopy(AppLocalizations localizations, PermissionState state) {
  switch (state) {
    case PermissionState.granted:
      return (
        icon: Icons.verified_user_rounded,
        title: localizations.permissionGrantedTitle,
        description: localizations.permissionGrantedDescription,
        color: (scheme) => scheme.primary,
      );
    case PermissionState.denied:
      return (
        icon: Icons.gpp_maybe_rounded,
        title: localizations.permissionDeniedTitle,
        description: localizations.permissionDeniedDescription,
        color: (scheme) => scheme.tertiary,
      );
    case PermissionState.notDetermined:
      return (
        icon: Icons.shield_outlined,
        title: localizations.permissionNotDeterminedTitle,
        description: localizations.permissionNotDeterminedDescription,
        color: (scheme) => scheme.secondary,
      );
  }
}
