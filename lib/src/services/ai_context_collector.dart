import '../models/ai_models.dart';
import '../platform/lockbar_platform.dart';

abstract class AiContextCollector {
  Future<SystemContextSnapshot> collectSystemContext(Set<AiDataSource> sources);

  ContextSnapshot buildSnapshot({
    required AiTriggerType trigger,
    required String localeTag,
    required List<ActionHistoryEntry> actionHistory,
    required SystemContextSnapshot systemContext,
    required DateTime occurredAt,
    int? focusSessionMinutes,
    int? delayedLockSeconds,
    String? explicitAction,
  });

  List<AiTriggerType> detectEnvironmentTriggers({
    required SystemContextSnapshot? previous,
    required SystemContextSnapshot current,
    required DateTime now,
  });
}

class PlatformAiContextCollector implements AiContextCollector {
  PlatformAiContextCollector({required this.platform});

  final LockbarPlatform platform;

  static const awayReturnThresholdSeconds = 90.0;

  @override
  Future<SystemContextSnapshot> collectSystemContext(
    Set<AiDataSource> sources,
  ) {
    return platform.getSystemContextSnapshot(sources: sources);
  }

  @override
  ContextSnapshot buildSnapshot({
    required AiTriggerType trigger,
    required String localeTag,
    required List<ActionHistoryEntry> actionHistory,
    required SystemContextSnapshot systemContext,
    required DateTime occurredAt,
    int? focusSessionMinutes,
    int? delayedLockSeconds,
    String? explicitAction,
  }) {
    final recentActions = actionHistory
        .take(8)
        .map((entry) => entry.action)
        .toList(growable: false);

    return ContextSnapshot(
      trigger: trigger,
      occurredAt: occurredAt,
      localeTag: localeTag,
      hourOfDay: occurredAt.hour,
      weekday: occurredAt.weekday,
      recentActions: recentActions,
      systemContext: systemContext,
      focusSessionMinutes: focusSessionMinutes,
      delayedLockSeconds: delayedLockSeconds,
      explicitAction: explicitAction,
    );
  }

  @override
  List<AiTriggerType> detectEnvironmentTriggers({
    required SystemContextSnapshot? previous,
    required SystemContextSnapshot current,
    required DateTime now,
  }) {
    if (previous == null) {
      return const [];
    }

    final triggers = <AiTriggerType>[];

    if (previous.idleSeconds >= awayReturnThresholdSeconds &&
        current.idleSeconds < 12) {
      triggers.add(AiTriggerType.awayReturned);
    }

    return triggers;
  }
}
