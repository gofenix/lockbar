import 'dart:convert';

enum AiMode { on, off }

enum AiConnectionStatus { notConfigured, ready, testing, online, offline }

enum AiSavedConnectionState { missing, verifiedHealthy, verifiedDegraded }

enum AiConnectionDraftTestState { idle, testing, success, failure }

class AiEndpointConfig {
  const AiEndpointConfig({this.baseUrl = '', this.apiKey = ''});

  final String baseUrl;
  final String apiKey;

  bool get isComplete => baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  String get normalizedBaseUrl => baseUrl.trim();

  String fingerprintForModel(String model) {
    final payload =
        '${normalizedBaseUrl.trim()}\n${apiKey.trim()}\n${model.trim()}';
    var hash = 0x811C9DC5;
    for (final unit in utf8.encode(payload)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String get maskedApiKey {
    final value = apiKey.trim();
    if (value.isEmpty) {
      return '';
    }
    if (value.length <= 8) {
      return '${value.substring(0, 2)}••••';
    }
    return '${value.substring(0, 4)}••••${value.substring(value.length - 4)}';
  }

  AiEndpointConfig copyWith({String? baseUrl, String? apiKey}) {
    return AiEndpointConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

class AiSavedConnection {
  const AiSavedConnection({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.verifiedAt,
    this.lastHealthyAt,
    this.lastErrorMessage,
    this.lastErrorAt,
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final DateTime verifiedAt;
  final DateTime? lastHealthyAt;
  final String? lastErrorMessage;
  final DateTime? lastErrorAt;

  String get normalizedBaseUrl => baseUrl.trim();

  AiEndpointConfig get endpointConfig =>
      AiEndpointConfig(baseUrl: baseUrl, apiKey: apiKey);

  String get maskedApiKey => endpointConfig.maskedApiKey;

  AiSavedConnectionState get state {
    final lastErrorAt = this.lastErrorAt;
    if (lastErrorAt == null) {
      return AiSavedConnectionState.verifiedHealthy;
    }
    final lastHealthyAt = this.lastHealthyAt;
    if (lastHealthyAt == null || lastErrorAt.isAfter(lastHealthyAt)) {
      return AiSavedConnectionState.verifiedDegraded;
    }
    return AiSavedConnectionState.verifiedHealthy;
  }

  AiSavedConnection copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    DateTime? verifiedAt,
    Object? lastHealthyAt = _copySentinel,
    Object? lastErrorMessage = _copySentinel,
    Object? lastErrorAt = _copySentinel,
  }) {
    return AiSavedConnection(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      lastHealthyAt: identical(lastHealthyAt, _copySentinel)
          ? this.lastHealthyAt
          : lastHealthyAt as DateTime?,
      lastErrorMessage: identical(lastErrorMessage, _copySentinel)
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
      lastErrorAt: identical(lastErrorAt, _copySentinel)
          ? this.lastErrorAt
          : lastErrorAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseUrl': normalizedBaseUrl,
    'apiKey': apiKey.trim(),
    'model': model,
    'verifiedAt': verifiedAt.toIso8601String(),
    'lastHealthyAt': lastHealthyAt?.toIso8601String(),
    'lastErrorMessage': lastErrorMessage,
    'lastErrorAt': lastErrorAt?.toIso8601String(),
  };

  static AiSavedConnection? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final baseUrl = json['baseUrl'] as String?;
    final apiKey = json['apiKey'] as String?;
    final model = json['model'] as String?;
    final verifiedAt = DateTime.tryParse(json['verifiedAt'] as String? ?? '');
    if (baseUrl == null ||
        baseUrl.trim().isEmpty ||
        apiKey == null ||
        apiKey.trim().isEmpty ||
        model == null ||
        model.trim().isEmpty ||
        verifiedAt == null) {
      return null;
    }

    return AiSavedConnection(
      baseUrl: baseUrl.trim(),
      apiKey: apiKey.trim(),
      model: model.trim(),
      verifiedAt: verifiedAt,
      lastHealthyAt: DateTime.tryParse(json['lastHealthyAt'] as String? ?? ''),
      lastErrorMessage:
          (json['lastErrorMessage'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['lastErrorMessage'] as String?)?.trim(),
      lastErrorAt: DateTime.tryParse(json['lastErrorAt'] as String? ?? ''),
    );
  }
}

class AiConnectionVerification {
  const AiConnectionVerification({
    required this.configFingerprint,
    required this.verifiedAt,
  });

  final String configFingerprint;
  final DateTime verifiedAt;

  bool get isValid => configFingerprint.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'configFingerprint': configFingerprint,
    'verifiedAt': verifiedAt.toIso8601String(),
  };

  static AiConnectionVerification? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final fingerprint = json['configFingerprint'] as String?;
    final verifiedAt = DateTime.tryParse(json['verifiedAt'] as String? ?? '');
    if (fingerprint == null ||
        fingerprint.trim().isEmpty ||
        verifiedAt == null) {
      return null;
    }

    return AiConnectionVerification(
      configFingerprint: fingerprint.trim(),
      verifiedAt: verifiedAt,
    );
  }
}

class AiConnectionDraftTestResult {
  const AiConnectionDraftTestResult({
    required this.state,
    required this.draftFingerprint,
    required this.model,
    this.testedAt,
    this.errorMessage,
  });

  final AiConnectionDraftTestState state;
  final String draftFingerprint;
  final String model;
  final DateTime? testedAt;
  final String? errorMessage;

  bool get isSuccess => state == AiConnectionDraftTestState.success;

  bool matchesDraft(AiEndpointConfig draft) =>
      draft.fingerprintForModel(model) == draftFingerprint;

  AiConnectionDraftTestResult copyWith({
    AiConnectionDraftTestState? state,
    String? draftFingerprint,
    String? model,
    Object? testedAt = _copySentinel,
    Object? errorMessage = _copySentinel,
  }) {
    return AiConnectionDraftTestResult(
      state: state ?? this.state,
      draftFingerprint: draftFingerprint ?? this.draftFingerprint,
      model: model ?? this.model,
      testedAt: identical(testedAt, _copySentinel)
          ? this.testedAt
          : testedAt as DateTime?,
      errorMessage: identical(errorMessage, _copySentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

enum AiDataSource {
  actionHistory,
  frontmostApp,
  windowTitle,
  calendar,
  idleState,
  bluetooth,
  network;

  String get storageKey => switch (this) {
    AiDataSource.actionHistory => 'actionHistory',
    AiDataSource.frontmostApp => 'frontmostApp',
    AiDataSource.windowTitle => 'windowTitle',
    AiDataSource.calendar => 'calendar',
    AiDataSource.idleState => 'idleState',
    AiDataSource.bluetooth => 'bluetooth',
    AiDataSource.network => 'network',
  };

  static AiDataSource? fromStorageKey(String value) {
    for (final source in values) {
      if (source.storageKey == value) {
        return source;
      }
    }
    return null;
  }
}

enum AiTriggerType {
  focusEnded,
  workdayEnded,
  delayedLockRequested,
  calendarBoundary,
  bluetoothChanged,
  awayReturned,
  networkChanged,
  appContextChanged,
  eveningWindDown;

  String get storageKey => switch (this) {
    AiTriggerType.focusEnded => 'focusEnded',
    AiTriggerType.workdayEnded => 'workdayEnded',
    AiTriggerType.delayedLockRequested => 'delayedLockRequested',
    AiTriggerType.calendarBoundary => 'calendarBoundary',
    AiTriggerType.bluetoothChanged => 'bluetoothChanged',
    AiTriggerType.awayReturned => 'awayReturned',
    AiTriggerType.networkChanged => 'networkChanged',
    AiTriggerType.appContextChanged => 'appContextChanged',
    AiTriggerType.eveningWindDown => 'eveningWindDown',
  };

  bool get isStageBoundary => switch (this) {
    AiTriggerType.focusEnded ||
    AiTriggerType.workdayEnded ||
    AiTriggerType.delayedLockRequested ||
    AiTriggerType.calendarBoundary ||
    AiTriggerType.bluetoothChanged => true,
    AiTriggerType.awayReturned ||
    AiTriggerType.networkChanged ||
    AiTriggerType.appContextChanged ||
    AiTriggerType.eveningWindDown => false,
  };

  static AiTriggerType? fromStorageKey(String value) {
    for (final trigger in values) {
      if (trigger.storageKey == value) {
        return trigger;
      }
    }
    return null;
  }
}

enum AiSignalType {
  timeOfDay,
  actionHistory,
  frontmostApp,
  windowTitle,
  calendar,
  idleState,
  bluetooth,
  network;

  String get storageKey => switch (this) {
    AiSignalType.timeOfDay => 'timeOfDay',
    AiSignalType.actionHistory => 'actionHistory',
    AiSignalType.frontmostApp => 'frontmostApp',
    AiSignalType.windowTitle => 'windowTitle',
    AiSignalType.calendar => 'calendar',
    AiSignalType.idleState => 'idleState',
    AiSignalType.bluetooth => 'bluetooth',
    AiSignalType.network => 'network',
  };

  static AiSignalType? fromStorageKey(String value) {
    for (final signal in values) {
      if (signal.storageKey == value) {
        return signal;
      }
    }
    return null;
  }
}

enum AiDecisionType {
  lockNow,
  laterTwoMinutes,
  laterFiveMinutes,
  notNow,
  dismissed,
  ignored;

  String get storageKey => switch (this) {
    AiDecisionType.lockNow => 'lockNow',
    AiDecisionType.laterTwoMinutes => 'laterTwoMinutes',
    AiDecisionType.laterFiveMinutes => 'laterFiveMinutes',
    AiDecisionType.notNow => 'notNow',
    AiDecisionType.dismissed => 'dismissed',
    AiDecisionType.ignored => 'ignored',
  };

  static AiDecisionType? fromStorageKey(String value) {
    for (final decision in values) {
      if (decision.storageKey == value) {
        return decision;
      }
    }
    return null;
  }
}

enum AiDecisionTraceOutcome {
  suggested,
  noSuggestion,
  futureProtectionOnly,
  timedOut,
  requestFailed,
  invalidResponse,
  blockedByConfig;

  String get storageKey => switch (this) {
    AiDecisionTraceOutcome.suggested => 'suggested',
    AiDecisionTraceOutcome.noSuggestion => 'noSuggestion',
    AiDecisionTraceOutcome.futureProtectionOnly => 'futureProtectionOnly',
    AiDecisionTraceOutcome.timedOut => 'timedOut',
    AiDecisionTraceOutcome.requestFailed => 'requestFailed',
    AiDecisionTraceOutcome.invalidResponse => 'invalidResponse',
    AiDecisionTraceOutcome.blockedByConfig => 'blockedByConfig',
  };

  static AiDecisionTraceOutcome? fromStorageKey(String value) {
    for (final outcome in values) {
      if (outcome.storageKey == value) {
        return outcome;
      }
    }
    return null;
  }
}

class FocusSessionState {
  const FocusSessionState({
    required this.startedAt,
    required this.endsAt,
    required this.durationMinutes,
  });

  final DateTime startedAt;
  final DateTime endsAt;
  final int durationMinutes;
}

enum KeepAwakePreset {
  thirtyMinutes(duration: Duration(minutes: 30)),
  oneHour(duration: Duration(hours: 1)),
  twoHours(duration: Duration(hours: 2)),
  indefinite(duration: null);

  const KeepAwakePreset({required this.duration});

  final Duration? duration;

  bool get isIndefinite => duration == null;

  static KeepAwakePreset fromDuration(Duration duration) {
    return switch (duration.inMinutes) {
      30 => KeepAwakePreset.thirtyMinutes,
      60 => KeepAwakePreset.oneHour,
      120 => KeepAwakePreset.twoHours,
      _ => throw ArgumentError.value(
        duration,
        'duration',
        'Unsupported keep-awake duration.',
      ),
    };
  }
}

class DelayedLockState {
  const DelayedLockState({
    required this.scheduledAt,
    required this.endsAt,
    required this.durationSeconds,
  });

  final DateTime scheduledAt;
  final DateTime endsAt;
  final int durationSeconds;
}

class KeepAwakeSessionState {
  const KeepAwakeSessionState({
    required this.startedAt,
    required this.preset,
    this.endsAt,
    this.durationMinutes,
  });

  final DateTime startedAt;
  final KeepAwakePreset preset;
  final DateTime? endsAt;
  final int? durationMinutes;

  bool get isIndefinite => endsAt == null;
}

class ActionHistoryEntry {
  const ActionHistoryEntry({required this.action, required this.occurredAt});

  final String action;
  final DateTime occurredAt;

  Map<String, dynamic> toJson() => {
    'action': action,
    'occurredAt': occurredAt.toIso8601String(),
  };

  static ActionHistoryEntry fromJson(Map<String, dynamic> json) {
    return ActionHistoryEntry(
      action: json['action'] as String? ?? 'unknown',
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class CalendarEventSummary {
  const CalendarEventSummary({
    required this.title,
    required this.startAt,
    required this.endAt,
  });

  final String title;
  final DateTime startAt;
  final DateTime endAt;

  Map<String, dynamic> toJson() => {
    'title': title,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
  };

  static CalendarEventSummary? fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return null;
    }

    final title = map['title'] as String?;
    final startAt = DateTime.tryParse(map['startAt'] as String? ?? '');
    final endAt = DateTime.tryParse(map['endAt'] as String? ?? '');
    if (title == null || startAt == null || endAt == null) {
      return null;
    }

    return CalendarEventSummary(title: title, startAt: startAt, endAt: endAt);
  }
}

class SystemContextSnapshot {
  const SystemContextSnapshot({
    required this.collectedAt,
    required this.idleSeconds,
    required this.bluetoothDevices,
    required this.networkReachable,
    this.frontmostAppName,
    this.frontmostBundleId,
    this.frontmostWindowTitle,
    this.networkName,
    this.currentCalendarEvent,
    this.nextCalendarEvent,
    this.accessibilityTrusted = false,
  });

  final DateTime collectedAt;
  final String? frontmostAppName;
  final String? frontmostBundleId;
  final String? frontmostWindowTitle;
  final double idleSeconds;
  final String? networkName;
  final bool networkReachable;
  final List<String> bluetoothDevices;
  final CalendarEventSummary? currentCalendarEvent;
  final CalendarEventSummary? nextCalendarEvent;
  final bool accessibilityTrusted;

  Map<String, dynamic> toJson() => {
    'collectedAt': collectedAt.toIso8601String(),
    'frontmostAppName': frontmostAppName,
    'frontmostBundleId': frontmostBundleId,
    'frontmostWindowTitle': frontmostWindowTitle,
    'idleSeconds': idleSeconds,
    'networkName': networkName,
    'networkReachable': networkReachable,
    'bluetoothDevices': bluetoothDevices,
    'currentCalendarEvent': currentCalendarEvent?.toJson(),
    'nextCalendarEvent': nextCalendarEvent?.toJson(),
    'accessibilityTrusted': accessibilityTrusted,
  };

  static SystemContextSnapshot fromMap(Map<dynamic, dynamic>? map) {
    final payload = map ?? const <dynamic, dynamic>{};
    return SystemContextSnapshot(
      collectedAt:
          DateTime.tryParse(payload['collectedAt'] as String? ?? '') ??
          DateTime.now(),
      frontmostAppName: payload['frontmostAppName'] as String?,
      frontmostBundleId: payload['frontmostBundleId'] as String?,
      frontmostWindowTitle: payload['frontmostWindowTitle'] as String?,
      idleSeconds: (payload['idleSeconds'] as num?)?.toDouble() ?? 0,
      networkName: payload['networkName'] as String?,
      networkReachable: payload['networkReachable'] as bool? ?? false,
      bluetoothDevices:
          (payload['bluetoothDevices'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
      currentCalendarEvent: CalendarEventSummary.fromMap(
        payload['currentCalendarEvent'] as Map<dynamic, dynamic>?,
      ),
      nextCalendarEvent: CalendarEventSummary.fromMap(
        payload['nextCalendarEvent'] as Map<dynamic, dynamic>?,
      ),
      accessibilityTrusted: payload['accessibilityTrusted'] as bool? ?? false,
    );
  }
}

class AiSettings {
  const AiSettings({required this.mode, required this.dataSources});

  final AiMode mode;
  final Map<AiDataSource, bool> dataSources;

  static const supportedDataSources = {
    AiDataSource.actionHistory,
    AiDataSource.idleState,
  };

  factory AiSettings.defaults() =>
      AiSettings(mode: AiMode.off, dataSources: _recommendedDataSources());

  factory AiSettings.recommendedEnabled() =>
      AiSettings(mode: AiMode.on, dataSources: _recommendedDataSources());

  bool isEnabled(AiDataSource source) =>
      dataSources[source] ?? _recommendedDataSources()[source] ?? false;

  AiSettings copyWith({AiMode? mode, Map<AiDataSource, bool>? dataSources}) {
    return AiSettings(
      mode: mode ?? this.mode,
      dataSources: _normalizedDataSources(dataSources ?? this.dataSources),
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'dataSources': {
      for (final entry in dataSources.entries)
        entry.key.storageKey: entry.value,
    },
  };

  static AiSettings fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AiSettings.defaults();
    }

    final rawDataSources = json['dataSources'] as Map<String, dynamic>? ?? {};
    final values = _recommendedDataSources();
    for (final entry in rawDataSources.entries) {
      final source = AiDataSource.fromStorageKey(entry.key);
      if (source != null && supportedDataSources.contains(source)) {
        values[source] = entry.value as bool? ?? values[source] ?? false;
      }
    }

    return AiSettings(
      mode: json['mode'] == 'off' ? AiMode.off : AiMode.on,
      dataSources: _normalizedDataSources(values),
    );
  }

  static Map<AiDataSource, bool> _recommendedDataSources() => {
    AiDataSource.actionHistory: true,
    AiDataSource.idleState: true,
  };

  static Map<AiDataSource, bool> _normalizedDataSources(
    Map<AiDataSource, bool> values,
  ) {
    return {
      for (final source in supportedDataSources)
        source: values[source] ?? _recommendedDataSources()[source] ?? false,
    };
  }
}

class ContextSnapshot {
  const ContextSnapshot({
    required this.trigger,
    required this.occurredAt,
    required this.localeTag,
    required this.hourOfDay,
    required this.weekday,
    required this.recentActions,
    required this.systemContext,
    this.focusSessionMinutes,
    this.delayedLockSeconds,
    this.explicitAction,
  });

  final AiTriggerType trigger;
  final DateTime occurredAt;
  final String localeTag;
  final int hourOfDay;
  final int weekday;
  final List<String> recentActions;
  final SystemContextSnapshot systemContext;
  final int? focusSessionMinutes;
  final int? delayedLockSeconds;
  final String? explicitAction;

  Map<String, dynamic> toJson() => {
    'trigger': trigger.storageKey,
    'occurredAt': occurredAt.toIso8601String(),
    'localeTag': localeTag,
    'hourOfDay': hourOfDay,
    'weekday': weekday,
    'recentActions': recentActions,
    'systemContext': systemContext.toJson(),
    'focusSessionMinutes': focusSessionMinutes,
    'delayedLockSeconds': delayedLockSeconds,
    'explicitAction': explicitAction,
  };

  static ContextSnapshot? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final trigger = AiTriggerType.fromStorageKey(
      json['trigger'] as String? ?? '',
    );
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');
    final localeTag = json['localeTag'] as String?;
    final hourOfDay = (json['hourOfDay'] as num?)?.toInt();
    final weekday = (json['weekday'] as num?)?.toInt();
    final systemContextJson = json['systemContext'] as Map<dynamic, dynamic>?;
    if (trigger == null ||
        occurredAt == null ||
        localeTag == null ||
        hourOfDay == null ||
        weekday == null ||
        systemContextJson == null) {
      return null;
    }

    return ContextSnapshot(
      trigger: trigger,
      occurredAt: occurredAt,
      localeTag: localeTag,
      hourOfDay: hourOfDay,
      weekday: weekday,
      recentActions: (json['recentActions'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      systemContext: SystemContextSnapshot.fromMap(systemContextJson),
      focusSessionMinutes: (json['focusSessionMinutes'] as num?)?.toInt(),
      delayedLockSeconds: (json['delayedLockSeconds'] as num?)?.toInt(),
      explicitAction: json['explicitAction'] as String?,
    );
  }
}

class AiRecommendation {
  const AiRecommendation({
    required this.id,
    required this.trigger,
    required this.headline,
    required this.reason,
    required this.confidence,
    required this.usedSignals,
    required this.createdAt,
    this.futureProtectionOnly = false,
    this.preferredDelaySeconds = 120,
  });

  final String id;
  final AiTriggerType trigger;
  final String headline;
  final String reason;
  final double confidence;
  final List<AiSignalType> usedSignals;
  final DateTime createdAt;
  final bool futureProtectionOnly;
  final int preferredDelaySeconds;

  AiRecommendation copyWith({
    String? id,
    AiTriggerType? trigger,
    String? headline,
    String? reason,
    double? confidence,
    List<AiSignalType>? usedSignals,
    DateTime? createdAt,
    bool? futureProtectionOnly,
    int? preferredDelaySeconds,
  }) {
    return AiRecommendation(
      id: id ?? this.id,
      trigger: trigger ?? this.trigger,
      headline: headline ?? this.headline,
      reason: reason ?? this.reason,
      confidence: confidence ?? this.confidence,
      usedSignals: usedSignals ?? this.usedSignals,
      createdAt: createdAt ?? this.createdAt,
      futureProtectionOnly: futureProtectionOnly ?? this.futureProtectionOnly,
      preferredDelaySeconds:
          preferredDelaySeconds ?? this.preferredDelaySeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trigger': trigger.storageKey,
    'headline': headline,
    'reason': reason,
    'confidence': confidence,
    'usedSignals': usedSignals.map((signal) => signal.storageKey).toList(),
    'createdAt': createdAt.toIso8601String(),
    'futureProtectionOnly': futureProtectionOnly,
    'preferredDelaySeconds': preferredDelaySeconds,
  };

  static AiRecommendation? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final trigger = AiTriggerType.fromStorageKey(
      json['trigger'] as String? ?? '',
    );
    final id = json['id'] as String?;
    final headline = json['headline'] as String?;
    final reason = json['reason'] as String?;
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (trigger == null ||
        id == null ||
        headline == null ||
        reason == null ||
        createdAt == null) {
      return null;
    }

    return AiRecommendation(
      id: id,
      trigger: trigger,
      headline: headline,
      reason: reason,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      usedSignals: (json['usedSignals'] as List<dynamic>? ?? const [])
          .map((value) => AiSignalType.fromStorageKey(value as String))
          .whereType<AiSignalType>()
          .toList(),
      createdAt: createdAt,
      futureProtectionOnly: json['futureProtectionOnly'] as bool? ?? false,
      preferredDelaySeconds: json['preferredDelaySeconds'] as int? ?? 120,
    );
  }
}

enum AiDataSourceAvailability { off, on, needsPermission, unavailable }

enum SuggestionPanelAction { lockNow, later, notNow, hide }

class SuggestionPanelData {
  const SuggestionPanelData({
    required this.title,
    required this.headline,
    required this.reason,
    required this.lockNowLabel,
    required this.laterLabel,
    required this.notNowLabel,
    required this.whyActionLabel,
    required this.whySectionTitle,
    required this.usedSignalLabels,
  });

  final String title;
  final String headline;
  final String reason;
  final String lockNowLabel;
  final String laterLabel;
  final String notNowLabel;
  final String whyActionLabel;
  final String whySectionTitle;
  final List<String> usedSignalLabels;

  Map<String, dynamic> toMap() => {
    'title': title,
    'headline': headline,
    'reason': reason,
    'lockNowLabel': lockNowLabel,
    'laterLabel': laterLabel,
    'notNowLabel': notNowLabel,
    'whyActionLabel': whyActionLabel,
    'whySectionTitle': whySectionTitle,
    'usedSignalLabels': usedSignalLabels,
  };
}

class DecisionEpisode {
  const DecisionEpisode({
    required this.recommendationId,
    required this.trigger,
    required this.decision,
    required this.occurredAt,
    required this.contextSnapshot,
  });

  final String recommendationId;
  final AiTriggerType trigger;
  final AiDecisionType decision;
  final DateTime occurredAt;
  final ContextSnapshot contextSnapshot;

  Map<String, dynamic> toJson() => {
    'recommendationId': recommendationId,
    'trigger': trigger.storageKey,
    'decision': decision.storageKey,
    'occurredAt': occurredAt.toIso8601String(),
    'contextSnapshot': contextSnapshot.toJson(),
  };
}

class AiInferenceExchangeDebug {
  const AiInferenceExchangeDebug({
    required this.model,
    required this.baseUrl,
    required this.requestBody,
    this.rawResponseText,
    this.parsedResponse,
    this.errorMessage,
  });

  final String model;
  final String baseUrl;
  final Map<String, dynamic> requestBody;
  final String? rawResponseText;
  final Object? parsedResponse;
  final String? errorMessage;

  AiInferenceExchangeDebug copyWith({
    String? model,
    String? baseUrl,
    Map<String, dynamic>? requestBody,
    Object? rawResponseText = _copySentinel,
    Object? parsedResponse = _copySentinel,
    Object? errorMessage = _copySentinel,
  }) {
    return AiInferenceExchangeDebug(
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
      requestBody: requestBody ?? this.requestBody,
      rawResponseText: identical(rawResponseText, _copySentinel)
          ? this.rawResponseText
          : rawResponseText as String?,
      parsedResponse: identical(parsedResponse, _copySentinel)
          ? this.parsedResponse
          : parsedResponse,
      errorMessage: identical(errorMessage, _copySentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'baseUrl': baseUrl,
    'requestBody': requestBody,
    'rawResponseText': rawResponseText,
    'parsedResponse': parsedResponse,
    'errorMessage': errorMessage,
  };

  static AiInferenceExchangeDebug? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final model = json['model'] as String?;
    final baseUrl = json['baseUrl'] as String?;
    final requestBody = json['requestBody'] as Map<String, dynamic>?;
    if (model == null || baseUrl == null || requestBody == null) {
      return null;
    }

    return AiInferenceExchangeDebug(
      model: model,
      baseUrl: baseUrl,
      requestBody: requestBody,
      rawResponseText: json['rawResponseText'] as String?,
      parsedResponse: json['parsedResponse'],
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class AiDecisionTrace {
  const AiDecisionTrace({
    required this.id,
    required this.occurredAt,
    required this.trigger,
    required this.localeTag,
    required this.enabledDataSources,
    required this.outcome,
    this.collectedContext,
    this.contextSnapshot,
    this.memoryProfileSnapshot,
    this.exchangeDebug,
    this.outcomeReason,
    this.recommendation,
    this.userDecision,
    this.userDecisionAt,
  });

  final String id;
  final DateTime occurredAt;
  final AiTriggerType trigger;
  final String localeTag;
  final List<AiDataSource> enabledDataSources;
  final SystemContextSnapshot? collectedContext;
  final ContextSnapshot? contextSnapshot;
  final MemoryProfile? memoryProfileSnapshot;
  final AiInferenceExchangeDebug? exchangeDebug;
  final AiDecisionTraceOutcome outcome;
  final String? outcomeReason;
  final AiRecommendation? recommendation;
  final AiDecisionType? userDecision;
  final DateTime? userDecisionAt;

  AiDecisionTrace copyWith({
    String? id,
    DateTime? occurredAt,
    AiTriggerType? trigger,
    String? localeTag,
    List<AiDataSource>? enabledDataSources,
    Object? collectedContext = _copySentinel,
    Object? contextSnapshot = _copySentinel,
    Object? memoryProfileSnapshot = _copySentinel,
    Object? exchangeDebug = _copySentinel,
    AiDecisionTraceOutcome? outcome,
    Object? outcomeReason = _copySentinel,
    Object? recommendation = _copySentinel,
    Object? userDecision = _copySentinel,
    Object? userDecisionAt = _copySentinel,
  }) {
    return AiDecisionTrace(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      trigger: trigger ?? this.trigger,
      localeTag: localeTag ?? this.localeTag,
      enabledDataSources: enabledDataSources ?? this.enabledDataSources,
      collectedContext: identical(collectedContext, _copySentinel)
          ? this.collectedContext
          : collectedContext as SystemContextSnapshot?,
      contextSnapshot: identical(contextSnapshot, _copySentinel)
          ? this.contextSnapshot
          : contextSnapshot as ContextSnapshot?,
      memoryProfileSnapshot: identical(memoryProfileSnapshot, _copySentinel)
          ? this.memoryProfileSnapshot
          : memoryProfileSnapshot as MemoryProfile?,
      exchangeDebug: identical(exchangeDebug, _copySentinel)
          ? this.exchangeDebug
          : exchangeDebug as AiInferenceExchangeDebug?,
      outcome: outcome ?? this.outcome,
      outcomeReason: identical(outcomeReason, _copySentinel)
          ? this.outcomeReason
          : outcomeReason as String?,
      recommendation: identical(recommendation, _copySentinel)
          ? this.recommendation
          : recommendation as AiRecommendation?,
      userDecision: identical(userDecision, _copySentinel)
          ? this.userDecision
          : userDecision as AiDecisionType?,
      userDecisionAt: identical(userDecisionAt, _copySentinel)
          ? this.userDecisionAt
          : userDecisionAt as DateTime?,
    );
  }

  String get summaryHeadline =>
      recommendation?.headline ??
      switch (outcome) {
        AiDecisionTraceOutcome.noSuggestion => 'No suggestion',
        AiDecisionTraceOutcome.futureProtectionOnly => 'Future protection cue',
        AiDecisionTraceOutcome.timedOut => 'Request timed out',
        AiDecisionTraceOutcome.requestFailed => 'Request failed',
        AiDecisionTraceOutcome.invalidResponse => 'Invalid AI response',
        AiDecisionTraceOutcome.blockedByConfig => 'Blocked by configuration',
        AiDecisionTraceOutcome.suggested => 'Suggestion',
      };

  Map<String, dynamic> toJson() => {
    'id': id,
    'occurredAt': occurredAt.toIso8601String(),
    'trigger': trigger.storageKey,
    'localeTag': localeTag,
    'enabledDataSources': enabledDataSources
        .map((source) => source.storageKey)
        .toList(growable: false),
    'collectedContext': collectedContext?.toJson(),
    'contextSnapshot': contextSnapshot?.toJson(),
    'memoryProfileSnapshot': memoryProfileSnapshot?.toJson(),
    'exchangeDebug': exchangeDebug?.toJson(),
    'outcome': outcome.storageKey,
    'outcomeReason': outcomeReason,
    'recommendation': recommendation?.toJson(),
    'userDecision': userDecision?.storageKey,
    'userDecisionAt': userDecisionAt?.toIso8601String(),
  };

  static AiDecisionTrace? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final id = json['id'] as String?;
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');
    final trigger = AiTriggerType.fromStorageKey(
      json['trigger'] as String? ?? '',
    );
    final localeTag = json['localeTag'] as String?;
    final outcome = AiDecisionTraceOutcome.fromStorageKey(
      json['outcome'] as String? ?? '',
    );
    if (id == null ||
        occurredAt == null ||
        trigger == null ||
        localeTag == null ||
        outcome == null) {
      return null;
    }

    return AiDecisionTrace(
      id: id,
      occurredAt: occurredAt,
      trigger: trigger,
      localeTag: localeTag,
      enabledDataSources:
          (json['enabledDataSources'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .map(AiDataSource.fromStorageKey)
              .whereType<AiDataSource>()
              .toList(growable: false),
      collectedContext: json['collectedContext'] == null
          ? null
          : SystemContextSnapshot.fromMap(
              json['collectedContext'] as Map<dynamic, dynamic>?,
            ),
      contextSnapshot: ContextSnapshot.fromJson(
        json['contextSnapshot'] as Map<String, dynamic>?,
      ),
      memoryProfileSnapshot: json['memoryProfileSnapshot'] == null
          ? null
          : MemoryProfile.fromJson(
              json['memoryProfileSnapshot'] as Map<String, dynamic>?,
            ),
      exchangeDebug: AiInferenceExchangeDebug.fromJson(
        json['exchangeDebug'] as Map<String, dynamic>?,
      ),
      outcome: outcome,
      outcomeReason: json['outcomeReason'] as String?,
      recommendation: AiRecommendation.fromJson(
        json['recommendation'] as Map<String, dynamic>?,
      ),
      userDecision: AiDecisionType.fromStorageKey(
        json['userDecision'] as String? ?? '',
      ),
      userDecisionAt: DateTime.tryParse(
        json['userDecisionAt'] as String? ?? '',
      ),
    );
  }
}

const _copySentinel = Object();

class MemoryProfile {
  const MemoryProfile({
    required this.summary,
    required this.habits,
    required this.metrics,
    this.updatedAt,
  });

  final String summary;
  final List<String> habits;
  final Map<String, int> metrics;
  final DateTime? updatedAt;

  factory MemoryProfile.empty() =>
      const MemoryProfile(summary: '', habits: [], metrics: {});

  bool get isEmpty =>
      summary.isEmpty &&
      habits.isEmpty &&
      metrics.values.every((value) => value == 0);

  MemoryProfile copyWith({
    String? summary,
    List<String>? habits,
    Map<String, int>? metrics,
    DateTime? updatedAt,
  }) {
    return MemoryProfile(
      summary: summary ?? this.summary,
      habits: habits ?? this.habits,
      metrics: metrics ?? this.metrics,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'habits': habits,
    'metrics': metrics,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static MemoryProfile fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MemoryProfile.empty();
    }

    return MemoryProfile(
      summary: json['summary'] as String? ?? '',
      habits: (json['habits'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      metrics: (json['metrics'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) =>
            MapEntry(key, value is int ? value : (value as num?)?.toInt() ?? 0),
      ),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class AiRecommendationResult {
  const AiRecommendationResult({
    required this.connectionStatus,
    this.recommendation,
    this.memoryProfile,
    this.exchangeDebug,
    this.decisionReason,
  });

  final AiConnectionStatus connectionStatus;
  final AiRecommendation? recommendation;
  final MemoryProfile? memoryProfile;
  final AiInferenceExchangeDebug? exchangeDebug;
  final String? decisionReason;
}

class AiFeedbackResult {
  const AiFeedbackResult({
    required this.connectionStatus,
    this.memoryProfile,
    this.exchangeDebug,
  });

  final AiConnectionStatus connectionStatus;
  final MemoryProfile? memoryProfile;
  final AiInferenceExchangeDebug? exchangeDebug;
}

String encodeJsonList(List<Map<String, dynamic>> value) => jsonEncode(value);
