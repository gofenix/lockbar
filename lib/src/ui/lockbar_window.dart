import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_support.dart';
import '../lockbar_controller.dart';
import '../models/ai_models.dart';
import '../models/lockbar_models.dart';

class LockbarWindow extends StatelessWidget {
  const LockbarWindow({super.key, required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final localizations = AppLocalizations.of(context);
        final bannerMessage = statusMessageText(
          localizations,
          controller.statusMessage,
        );

        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                child: Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    children: [
                      Text(
                        'LockBar',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        localizations.settingsSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (bannerMessage != null) ...[
                        _StatusBanner(
                          message: bannerMessage,
                          isError: controller.hasError,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _LockingSection(controller: controller),
                      const SizedBox(height: 16),
                      _AiSuggestionsSection(controller: controller),
                      const SizedBox(height: 16),
                      _PrivacySection(controller: controller),
                      const SizedBox(height: 16),
                      _AboutSection(controller: controller),
                    ],
                  ),
                ),
              ),
              if (controller.isLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.86),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 14),
                          Text(localizations.preparingLockBar),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LockingSection extends StatelessWidget {
  const _LockingSection({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return _SectionCard(
      title: localizations.lockingSectionTitle,
      child: Column(
        children: [
          if (controller.showPrimaryActionTip) ...[
            _PrimaryActionTip(controller: controller),
            const SizedBox(height: 12),
          ],
          _SettingRow(
            title: localizations.primaryActionTitle,
            description: localizations.primaryActionDescription,
            trailing: FilledButton.tonal(
              onPressed: controller.isBusy
                  ? null
                  : controller.lockNowFromSettings,
              child: Text(localizations.lockNow),
            ),
          ),
          const Divider(height: 20),
          _SettingRow(
            title: localizations.launchAtLogin,
            description: localizations.launchAtLoginDescription,
            trailing: Switch.adaptive(
              value: controller.launchAtStartupEnabled,
              onChanged: controller.isBusy
                  ? null
                  : controller.setLaunchAtStartup,
            ),
          ),
          const Divider(height: 20),
          _SettingRow(
            title: localizations.languageTitle,
            description: localizations.languageDescription,
            trailing: DropdownButton<AppLocalePreference>(
              value: controller.localePreference,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) {
                  controller.setLocalePreference(value);
                }
              },
              items: AppLocalePreference.values
                  .map(
                    (preference) => DropdownMenuItem<AppLocalePreference>(
                      value: preference,
                      child: Text(preferenceLabel(localizations, preference)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const Divider(height: 20),
          _ManualActions(controller: controller),
        ],
      ),
    );
  }
}

class _PrimaryActionTip extends StatelessWidget {
  const _PrimaryActionTip({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.primaryActionTipTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.primaryActionTipDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer.withValues(
                      alpha: 0.82,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: controller.dismissPrimaryActionTip,
            child: Text(localizations.gotItAction),
          ),
        ],
      ),
    );
  }
}

class _ManualActions extends StatelessWidget {
  const _ManualActions({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final focusSession = controller.focusSession;
    final delayedLock = controller.delayedLock;
    final keepAwakeSession = controller.keepAwakeSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.manualActionsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: controller.isBusy
                  ? null
                  : controller.lockNowFromSettings,
              child: Text(localizations.lockNow),
            ),
            if (focusSession == null) ...[
              OutlinedButton(
                onPressed: () =>
                    controller.startFocusSession(const Duration(minutes: 25)),
                child: Text(localizations.aiFocusPreset25),
              ),
              OutlinedButton(
                onPressed: () =>
                    controller.startFocusSession(const Duration(minutes: 50)),
                child: Text(localizations.aiFocusPreset50),
              ),
            ] else
              OutlinedButton(
                onPressed: controller.cancelFocusSession,
                child: Text(localizations.aiCancelFocusAction),
              ),
            if (delayedLock == null)
              OutlinedButton(
                onPressed: () =>
                    controller.scheduleDelayedLock(const Duration(minutes: 2)),
                child: Text(localizations.aiLockIn2Minutes),
              )
            else
              OutlinedButton(
                onPressed: controller.cancelDelayedLock,
                child: Text(localizations.aiCancelDelayedLockAction),
              ),
            _KeepAwakeActionButton(
              label: localizations.keepAwakeFor30MinutesAction,
              selected:
                  keepAwakeSession?.preset == KeepAwakePreset.thirtyMinutes,
              onPressed: () =>
                  controller.startKeepAwakeSession(const Duration(minutes: 30)),
            ),
            _KeepAwakeActionButton(
              label: localizations.keepAwakeForOneHourAction,
              selected: keepAwakeSession?.preset == KeepAwakePreset.oneHour,
              onPressed: () =>
                  controller.startKeepAwakeSession(const Duration(hours: 1)),
            ),
            _KeepAwakeActionButton(
              label: localizations.keepAwakeForTwoHoursAction,
              selected: keepAwakeSession?.preset == KeepAwakePreset.twoHours,
              onPressed: () =>
                  controller.startKeepAwakeSession(const Duration(hours: 2)),
            ),
            _KeepAwakeActionButton(
              label: localizations.keepAwakeIndefinitelyAction,
              selected: keepAwakeSession?.preset == KeepAwakePreset.indefinite,
              onPressed: controller.startKeepAwakeIndefinitely,
            ),
            if (controller.isKeepAwakeActive)
              OutlinedButton(
                onPressed: controller.cancelKeepAwakeSession,
                child: Text(localizations.cancelKeepAwakeAction),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          focusStatusLabel(
            localizations,
            focusSession,
            controller.focusRemaining,
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          delayedLock != null
              ? localizations.aiDelayedLockRunningLabel(
                  _formatDuration(localizations, delayedLock.durationSeconds),
                )
              : localizations.aiDelayedLockIdleLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          keepAwakeStatusLabel(
            localizations,
            keepAwakeSession,
            controller.keepAwakeRemaining,
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatDuration(AppLocalizations localizations, int seconds) {
    if (seconds >= 60) {
      return localizations.durationMinutesLabel(seconds ~/ 60);
    }
    return localizations.durationSecondsLabel(seconds);
  }
}

class _KeepAwakeActionButton extends StatelessWidget {
  const _KeepAwakeActionButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton.tonal(onPressed: onPressed, child: Text(label));
    }
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class _AiSuggestionsSection extends StatelessWidget {
  const _AiSuggestionsSection({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SectionCard(
      title: localizations.aiSectionTitle,
      child: controller.aiSuggestionsEnabled
          ? _AiEnabledState(controller: controller)
          : _AiDisabledState(controller: controller),
    );
  }
}

class _AiDisabledState extends StatelessWidget {
  const _AiDisabledState({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final lastSuggestion = controller.lastSuggestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingRow(
          title: localizations.aiConnectionTitle,
          description: _connectionDescription(context, controller),
          trailing: _AiConnectionActions(
            controller: controller,
            onConfigure: () => _showAiConfigurationDialog(context),
          ),
        ),
        const Divider(height: 20),
        Text(localizations.aiSuggestionsDisabledDescription),
        const SizedBox(height: 14),
        FilledButton.tonal(
          onPressed: controller.canEnableAi
              ? controller.enableAiSuggestionsWithDefaults
              : null,
          child: Text(localizations.aiEnableAction),
        ),
        const Divider(height: 20),
        _SettingRow(
          title: localizations.aiCurrentMemoryLabel,
          description: memoryProfileSummary(
            localizations,
            controller.memoryProfile,
          ),
        ),
        if (lastSuggestion != null) ...[
          const Divider(height: 20),
          _AiLatestSuggestionPanel(suggestion: lastSuggestion),
        ],
        const Divider(height: 20),
        _AiDecisionHistoryPanel(controller: controller),
      ],
    );
  }

  Future<void> _showAiConfigurationDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AiConfigurationDialog(
        controller: controller,
        initialConfig: controller.aiConnectionDraftDefaults,
      ),
    );
  }
}

class _AiEnabledState extends StatelessWidget {
  const _AiEnabledState({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final lastSuggestion = controller.lastSuggestion;

    return Column(
      children: [
        _SettingRow(
          title: localizations.aiConnectionTitle,
          description: _connectionDescription(context, controller),
          trailing: _AiConnectionActions(
            controller: controller,
            onConfigure: () => _showAiConfigurationDialog(context),
          ),
        ),
        const Divider(height: 20),
        _SettingRow(
          title: localizations.aiSuggestionsToggle,
          description: localizations.aiSuggestionsEnabledDescription,
          trailing: Switch.adaptive(
            value: controller.aiSuggestionsEnabled,
            onChanged: controller.isBusy ? null : controller.setAiMode,
          ),
        ),
        const Divider(height: 20),
        _SettingRow(
          title: localizations.aiCurrentMemoryLabel,
          description: memoryProfileSummary(
            localizations,
            controller.memoryProfile,
          ),
        ),
        if (lastSuggestion != null) ...[
          const Divider(height: 20),
          _AiLatestSuggestionPanel(suggestion: lastSuggestion),
        ],
        const Divider(height: 20),
        _AiDecisionHistoryPanel(controller: controller),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.resetAiMemory,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(localizations.aiResetMemoryAction),
          ),
        ),
      ],
    );
  }

  Future<void> _showAiConfigurationDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AiConfigurationDialog(
        controller: controller,
        initialConfig: controller.aiConnectionDraftDefaults,
      ),
    );
  }
}

class _AiLatestSuggestionPanel extends StatelessWidget {
  const _AiLatestSuggestionPanel({required this.suggestion});

  final AiRecommendation suggestion;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(localizations.aiRecentSuggestionTitle),
        subtitle: Text(suggestion.headline),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(suggestion.reason),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              localizations.aiWhyInlineTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          ...suggestion.usedSignals.map(
            (signal) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• ${aiSignalLabel(localizations, signal)}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiDecisionHistoryPanel extends StatelessWidget {
  const _AiDecisionHistoryPanel({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final traces = controller.decisionTraces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.aiDecisionHistoryTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          localizations.aiDecisionHistoryDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Text('• ${localizations.aiInspectorStoredLocally}'),
        Text('• ${localizations.aiInspectorRawContextNotice}'),
        Text('• ${localizations.aiInspectorNoCredentialsNotice}'),
        const SizedBox(height: 12),
        if (traces.isEmpty)
          Text(localizations.aiDecisionHistoryEmpty)
        else
          ..._buildTraceTiles(traces),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: traces.isEmpty ? null : controller.clearAiDecisionHistory,
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(localizations.aiClearHistoryAction),
        ),
      ],
    );
  }

  List<Widget> _buildTraceTiles(List<AiDecisionTrace> traces) {
    final widgets = <Widget>[];
    for (var index = 0; index < traces.length; index += 1) {
      widgets.add(_AiDecisionTraceTile(trace: traces[index]));
      if (index != traces.length - 1) {
        widgets.add(const Divider(height: 20));
      }
    }
    return widgets;
  }
}

class _AiDecisionTraceTile extends StatelessWidget {
  const _AiDecisionTraceTile({required this.trace});

  final AiDecisionTrace trace;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final timestamp = DateFormat.yMd(
      localeTag,
    ).add_Hms().format(trace.occurredAt.toLocal());
    final outcomeLabel = aiDecisionTraceOutcomeLabel(
      localizations,
      trace.outcome,
    );
    final titleText =
        '$timestamp · ${aiTriggerLabel(localizations, trace.trigger)}';
    final subtitleText = trace.recommendation != null
        ? '$outcomeLabel · ${trace.recommendation!.headline}'
        : outcomeLabel;
    final reasonText =
        trace.outcomeReason ??
        trace.recommendation?.reason ??
        aiDecisionTraceOutcomeLabel(localizations, trace.outcome);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(titleText),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitleText),
            if (reasonText.isNotEmpty) Text(reasonText),
          ],
        ),
        children: [
          _TraceJsonSection(
            title: localizations.aiTraceCollectedSection,
            payload: _collectedTracePayload(localizations, trace),
          ),
          const SizedBox(height: 12),
          _TraceJsonSection(
            title: localizations.aiTraceSentSection,
            payload: _sentTracePayload(localizations, trace),
          ),
          const SizedBox(height: 12),
          _TraceJsonSection(
            title: localizations.aiTraceReturnedSection,
            payload: _returnedTracePayload(localizations, trace),
          ),
          const SizedBox(height: 12),
          _TraceJsonSection(
            title: localizations.aiTraceOutcomeSection,
            payload: _outcomeTracePayload(localizations, trace),
          ),
        ],
      ),
    );
  }
}

class _TraceJsonSection extends StatelessWidget {
  const _TraceJsonSection({required this.title, required this.payload});

  final String title;
  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(payload),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'Menlo'),
          ),
        ),
      ],
    );
  }
}

class _AiConnectionActions extends StatelessWidget {
  const _AiConnectionActions({
    required this.controller,
    required this.onConfigure,
  });

  final LockbarController controller;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        TextButton(
          onPressed: onConfigure,
          child: Text(localizations.aiConfigureAction),
        ),
        if (controller.hasSavedAiConnection)
          TextButton(
            onPressed: controller.clearAiConnection,
            child: Text(localizations.aiClearConnectionAction),
          ),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SectionCard(
      title: localizations.privacySectionTitle,
      child: Column(
        children: [
          _SettingRow(
            title: _permissionTitle(localizations),
            description: _permissionDescription(localizations),
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: controller.isBusy
                      ? null
                      : controller.permissionState == PermissionState.granted
                      ? controller.refreshPermissionState
                      : controller.requestPermission,
                  child: Text(
                    controller.permissionState == PermissionState.granted
                        ? localizations.refreshStatus
                        : localizations.requestPermission,
                  ),
                ),
                TextButton(
                  onPressed: controller.isBusy
                      ? null
                      : controller.openAccessibilitySettings,
                  child: Text(localizations.openSystemSettings),
                ),
              ],
            ),
          ),
          if (controller.aiSuggestionsEnabled) ...[
            const Divider(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                localizations.aiDataSourcesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            ..._buildDataSourceRows(context),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDataSourceRows(BuildContext context) {
    final widgets = <Widget>[];
    for (final source in controller.aiDataSources) {
      widgets.add(_AiDataSourceRow(controller: controller, source: source));
      if (source != controller.aiDataSources.last) {
        widgets.add(const Divider(height: 20));
      }
    }
    return widgets;
  }

  String _permissionTitle(AppLocalizations localizations) {
    return switch (controller.permissionState) {
      PermissionState.granted => localizations.permissionGrantedTitle,
      PermissionState.denied => localizations.permissionDeniedTitle,
      PermissionState.notDetermined =>
        localizations.permissionNotDeterminedTitle,
    };
  }

  String _permissionDescription(AppLocalizations localizations) {
    return switch (controller.permissionState) {
      PermissionState.granted => localizations.permissionGrantedDescription,
      PermissionState.denied => localizations.permissionDeniedDescription,
      PermissionState.notDetermined =>
        localizations.permissionNotDeterminedDescription,
    };
  }
}

class _AiDataSourceRow extends StatelessWidget {
  const _AiDataSourceRow({required this.controller, required this.source});

  final LockbarController controller;
  final AiDataSource source;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final availability = controller.dataSourceAvailability(source);

    return _SettingRow(
      title: aiDataSourceLabel(localizations, source),
      description:
          '${aiDataSourceDescription(localizations, source)}\n'
          '${localizations.aiDataSourceStatusLine(aiDataSourceAvailabilityLabel(localizations, availability))}',
      trailing: Switch.adaptive(
        value: controller.aiSettings.isEnabled(source),
        onChanged: (value) => _handleToggle(context, value),
      ),
    );
  }

  Future<void> _handleToggle(BuildContext context, bool value) async {
    final localizations = AppLocalizations.of(context);
    if (!value) {
      await controller.setAiDataSourceEnabled(source, false);
      return;
    }

    if (source == AiDataSource.calendar &&
        controller.calendarPermissionState != PermissionState.granted) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.calendarAccessDialogTitle),
          content: Text(localizations.calendarAccessDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(localizations.continueAction),
            ),
          ],
        ),
      );
      if (accepted == true && await controller.requestCalendarAccess()) {
        await controller.setAiDataSourceEnabled(source, true);
      }
      return;
    }

    if (source == AiDataSource.windowTitle &&
        controller.permissionState != PermissionState.granted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.windowTitleAccessDialogTitle),
          content: Text(localizations.windowTitleAccessDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancelAction),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.openAccessibilitySettings();
              },
              child: Text(localizations.openSystemSettings),
            ),
          ],
        ),
      );
      return;
    }

    await controller.setAiDataSourceEnabled(source, true);
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.controller});

  final LockbarController controller;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SectionCard(
      title: localizations.aboutTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.aboutDescription),
          const SizedBox(height: 12),
          Text(
            controller.appInfo.shortLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiConfigurationDialog extends StatefulWidget {
  const _AiConfigurationDialog({
    required this.controller,
    required this.initialConfig,
  });

  final LockbarController controller;
  final AiEndpointConfig initialConfig;

  @override
  State<_AiConfigurationDialog> createState() => _AiConfigurationDialogState();
}

class _AiConfigurationDialogState extends State<_AiConfigurationDialog> {
  static const _defaultBaseUrl = 'https://api.minimaxi.com/anthropic';

  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  String? _baseUrlError;
  String? _apiKeyError;
  String? _saveError;
  bool _isSaving = false;
  AiConnectionDraftTestResult? _testResult;

  bool get _isTesting =>
      _effectiveDraftTestResult.state == AiConnectionDraftTestState.testing;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: widget.initialConfig.normalizedBaseUrl.isEmpty
          ? _defaultBaseUrl
          : widget.initialConfig.normalizedBaseUrl,
    );
    _apiKeyController = TextEditingController(
      text: widget.initialConfig.apiKey,
    );
    _baseUrlController.addListener(_handleDraftChanged);
    _apiKeyController.addListener(_handleDraftChanged);
  }

  @override
  void dispose() {
    _baseUrlController.removeListener(_handleDraftChanged);
    _apiKeyController.removeListener(_handleDraftChanged);
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(localizations.aiConfigDialogTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.aiConfigDialogDescription),
              const SizedBox(height: 12),
              Text(
                localizations.aiOnboardingDefaultsTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('• ${localizations.aiDataSourceActionHistory}'),
              Text('• ${localizations.aiDataSourceIdleState}'),
              const SizedBox(height: 10),
              Text(localizations.aiOnboardingPrivacyFootnote),
              const SizedBox(height: 16),
              TextField(
                controller: _baseUrlController,
                decoration: InputDecoration(
                  labelText: localizations.aiConfigBaseUrlLabel,
                  errorText: _baseUrlError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.aiConfigApiKeyLabel,
                  errorText: _apiKeyError,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.aiConfigModelLine(widget.controller.aiModelLabel),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _AiDraftTestStatus(
                result: _effectiveDraftTestResult,
                draft: _currentDraft,
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancelAction),
        ),
        FilledButton.tonal(
          onPressed: (_isSaving || _isTesting) ? null : _handleTest,
          child: Text(
            _isTesting
                ? localizations.aiTestingConnectionAction
                : localizations.aiTestConnectionAction,
          ),
        ),
        FilledButton(
          onPressed: _canSave ? _handleSave : null,
          child: Text(localizations.aiSaveConnectionAction),
        ),
      ],
    );
  }

  AiEndpointConfig get _currentDraft => AiEndpointConfig(
    baseUrl: _baseUrlController.text.trim(),
    apiKey: _apiKeyController.text.trim(),
  );

  AiConnectionDraftTestResult get _effectiveDraftTestResult =>
      _testResult ??
      AiConnectionDraftTestResult(
        state: AiConnectionDraftTestState.idle,
        draftFingerprint: _currentDraft.fingerprintForModel(
          widget.controller.aiModelLabel,
        ),
        model: widget.controller.aiModelLabel,
      );

  bool get _canSave =>
      !_isSaving &&
      _effectiveDraftTestResult.isSuccess &&
      _effectiveDraftTestResult.matchesDraft(_currentDraft);

  void _handleDraftChanged() {
    final currentDraft = _currentDraft;
    if (_testResult != null && !_testResult!.matchesDraft(currentDraft)) {
      setState(() {
        _testResult = null;
        _saveError = null;
      });
    }
  }

  bool _validateRequiredFields() {
    final localizations = AppLocalizations.of(context);
    final draft = _currentDraft;
    setState(() {
      _baseUrlError = draft.baseUrl.isEmpty
          ? localizations.aiBaseUrlRequired
          : null;
      _apiKeyError = draft.apiKey.isEmpty
          ? localizations.aiApiKeyRequired
          : null;
      _saveError = null;
    });
    return _baseUrlError == null && _apiKeyError == null;
  }

  Future<void> _handleTest() async {
    if (!_validateRequiredFields()) {
      return;
    }

    final localizations = AppLocalizations.of(context);
    setState(() {
      _testResult = AiConnectionDraftTestResult(
        state: AiConnectionDraftTestState.testing,
        draftFingerprint: _currentDraft.fingerprintForModel(
          widget.controller.aiModelLabel,
        ),
        model: widget.controller.aiModelLabel,
      );
    });
    final result = await widget.controller.testAiConnectionDraft(_currentDraft);
    if (!mounted) {
      return;
    }
    setState(() {
      _testResult = result;
      if (result.state == AiConnectionDraftTestState.failure &&
          (result.errorMessage == null || result.errorMessage!.isEmpty)) {
        _saveError = localizations.statusAiConnectionTestFailed;
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_validateRequiredFields()) {
      return;
    }

    final testResult = _testResult;
    if (testResult == null || !_canSave) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.controller.saveVerifiedAiConnection(
        _currentDraft,
        testResult,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveError = AppLocalizations.of(context).statusAiSettingsSaveFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _AiDraftTestStatus extends StatelessWidget {
  const _AiDraftTestStatus({required this.result, required this.draft});

  final AiConnectionDraftTestResult result;
  final AiEndpointConfig draft;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final lines = <String>[
      localizations.aiConfigDraftStatusLine(
        aiDraftTestStateLabel(localizations, result.state),
      ),
    ];

    if (result.state == AiConnectionDraftTestState.success &&
        result.matchesDraft(draft) &&
        result.testedAt != null) {
      lines.add(
        localizations.aiConnectionVerifiedAtLine(
          DateFormat.yMd(localeTag).add_Hm().format(result.testedAt!.toLocal()),
        ),
      );
    }
    if (result.state == AiConnectionDraftTestState.failure &&
        result.errorMessage != null &&
        result.errorMessage!.isNotEmpty) {
      lines.add(result.errorMessage!);
    }
    if (result.state == AiConnectionDraftTestState.idle) {
      lines.add(localizations.aiConfigDraftNeedsTestHint);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.aiConfigDraftStatusTitle,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: textTheme.bodySmall),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

String _connectionDescription(
  BuildContext context,
  LockbarController controller,
) {
  final localizations = AppLocalizations.of(context);
  final lines = <String>[];
  final savedConnection = controller.savedAiConnection;

  if (savedConnection != null) {
    lines.add(
      localizations.aiConnectionConfiguredDescription(
        savedConnection.normalizedBaseUrl,
        savedConnection.maskedApiKey,
      ),
    );
    lines.add(localizations.aiConnectionModelLine(savedConnection.model));
  } else {
    lines.add(localizations.aiConnectionMissingDescription);
  }

  lines.add(
    localizations.aiConnectionStatusLine(
      aiSavedConnectionStateLabel(
        localizations,
        controller.aiSavedConnectionState,
      ),
    ),
  );

  final lastVerifiedAt = controller.lastVerifiedAt;
  if (lastVerifiedAt != null) {
    lines.add(
      localizations.aiConnectionVerifiedAtLine(
        _formatVerificationTime(context, lastVerifiedAt),
      ),
    );
  }

  final detail = controller.aiConnectionDetail;
  if (detail != null && detail.isNotEmpty) {
    lines.add(localizations.aiConnectionLastErrorLine(detail));
  }

  if (controller.hasLegacyAiConnectionDraft) {
    lines.add(localizations.aiConnectionPendingDraftHint);
  }

  return lines.join('\n');
}

String _formatVerificationTime(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMd(locale).add_Hm().format(value.toLocal());
}

Map<String, dynamic> _collectedTracePayload(
  AppLocalizations localizations,
  AiDecisionTrace trace,
) {
  final snapshot = trace.contextSnapshot;
  return {
    localizations.aiTraceEnabledSourcesLabel: trace.enabledDataSources
        .map((source) => aiDataSourceLabel(localizations, source))
        .toList(growable: false),
    'collectedContext': trace.collectedContext?.toJson(),
    'recentActions': snapshot?.recentActions,
    'focusSessionMinutes': snapshot?.focusSessionMinutes,
    'delayedLockSeconds': snapshot?.delayedLockSeconds,
    'explicitAction': snapshot?.explicitAction,
  };
}

Map<String, dynamic> _sentTracePayload(
  AppLocalizations localizations,
  AiDecisionTrace trace,
) {
  return {
    'model': trace.exchangeDebug?.model,
    'baseUrl': trace.exchangeDebug?.baseUrl,
    localizations.aiTraceContextSnapshotLabel: trace.contextSnapshot?.toJson(),
    localizations.aiTraceMemorySnapshotLabel: trace.memoryProfileSnapshot
        ?.toJson(),
    localizations.aiTraceRequestBodyLabel: trace.exchangeDebug?.requestBody,
  };
}

Map<String, dynamic> _returnedTracePayload(
  AppLocalizations localizations,
  AiDecisionTrace trace,
) {
  return {
    localizations.aiTraceRawResponseLabel: trace.exchangeDebug?.rawResponseText,
    localizations.aiTraceParsedResponseLabel:
        trace.exchangeDebug?.parsedResponse,
    localizations.aiTraceErrorLabel: trace.exchangeDebug?.errorMessage,
    localizations.aiTraceRecommendationLabel: trace.recommendation?.toJson(),
  };
}

Map<String, dynamic> _outcomeTracePayload(
  AppLocalizations localizations,
  AiDecisionTrace trace,
) {
  return {
    'outcome': aiDecisionTraceOutcomeLabel(localizations, trace.outcome),
    'outcomeReason': trace.outcomeReason,
    'userDecision': trace.userDecision == null
        ? null
        : aiDecisionLabel(localizations, trace.userDecision!),
    'userDecisionAt': trace.userDecisionAt?.toIso8601String(),
    'usedSignals': trace.recommendation?.usedSignals
        .map((signal) => aiSignalLabel(localizations, signal))
        .toList(growable: false),
    'confidence': trace.recommendation?.confidence,
    'futureProtectionOnly': trace.recommendation?.futureProtectionOnly,
    'preferredDelaySeconds': trace.recommendation?.preferredDelaySeconds,
  };
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.description,
    this.trailing,
  });

  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 16),
          Flexible(
            child: Align(alignment: Alignment.topRight, child: trailing!),
          ),
        ],
      ],
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
    final background = isError
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = isError
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
