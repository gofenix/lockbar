import 'package:lockbar/src/desktop_coordinator.dart';
import 'package:lockbar/src/models/ai_models.dart';
import 'package:lockbar/src/models/command_panel_models.dart';
import 'package:lockbar/src/models/lockbar_models.dart';
import 'package:lockbar/src/platform/lockbar_platform.dart';
import 'package:lockbar/src/services/ai_context_collector.dart';
import 'package:lockbar/src/services/ai_inference_client.dart';
import 'package:lockbar/src/services/ai_memory_service.dart';
import 'package:lockbar/src/services/ai_trace_store.dart';
import 'package:lockbar/src/services/launch_at_startup_service.dart';
import 'package:lockbar/src/services/locale_preferences_service.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:async';
import 'dart:ui';

class FakeLockbarPlatform implements LockbarPlatform {
  PermissionState permissionState = PermissionState.notDetermined;
  PermissionRequestResult permissionRequestResult =
      PermissionRequestResult.denied;
  LockResult lockResult = const LockResult(status: LockResultStatus.success);
  AppInfo info = const AppInfo(
    name: 'LockBar',
    version: '1.0.0',
    buildNumber: '1',
  );

  int requestPermissionCalls = 0;
  int lockCalls = 0;
  int openSettingsCalls = 0;
  int activateAppCalls = 0;
  int quitAppCalls = 0;
  int requestCalendarAccessCalls = 0;
  int startKeepAwakeCalls = 0;
  int startKeepAwakeIndefinitelyCalls = 0;
  int stopKeepAwakeCalls = 0;
  int getKeepAwakeStateCalls = 0;
  int showSuggestionPanelCalls = 0;
  int updateSuggestionPanelCalls = 0;
  int hideSuggestionPanelCalls = 0;
  int showCommandPanelCalls = 0;
  int updateCommandPanelCalls = 0;
  int hideCommandPanelCalls = 0;
  bool keepAwakeStartSucceeds = true;
  bool keepAwakeNativeActive = false;
  String? lastNativeLocaleTag;
  Duration? lastKeepAwakeDuration;
  PermissionState calendarPermissionState = PermissionState.notDetermined;
  SuggestionPanelData? lastSuggestionPanelData;
  CommandPanelData? lastCommandPanelData;
  Set<AiDataSource> lastRequestedSources = const <AiDataSource>{};
  SystemContextSnapshot systemContext = SystemContextSnapshot(
    collectedAt: DateTime(2025),
    idleSeconds: 0,
    bluetoothDevices: const [],
    networkReachable: true,
  );
  List<BluetoothBatteryDevice> bluetoothBatteryDevices = const [];
  final StreamController<SuggestionPanelAction>
  suggestionPanelActionsController =
      StreamController<SuggestionPanelAction>.broadcast();
  final StreamController<CommandPanelAction> commandPanelActionsController =
      StreamController<CommandPanelAction>.broadcast();

  @override
  Future<void> activateApp() async {
    activateAppCalls += 1;
  }

  @override
  Future<AppInfo> getAppInfo() async => info;

  @override
  Future<PermissionState> getCalendarPermissionState() async =>
      calendarPermissionState;

  @override
  Future<PermissionState> getPermissionState() async => permissionState;

  @override
  Future<void> hideSuggestionPanel() async {
    hideSuggestionPanelCalls += 1;
  }

  @override
  Future<void> hideCommandPanel() async {
    hideCommandPanelCalls += 1;
  }

  @override
  Future<LockResult> lockNow() async {
    lockCalls += 1;
    return lockResult;
  }

  @override
  Future<void> openAccessibilitySettings() async {
    openSettingsCalls += 1;
  }

  @override
  Future<void> quitApp() async {
    quitAppCalls += 1;
  }

  @override
  Future<PermissionRequestResult> requestCalendarAccess() async {
    requestCalendarAccessCalls += 1;
    if (calendarPermissionState != PermissionState.granted) {
      calendarPermissionState = PermissionState.denied;
    }
    return calendarPermissionState == PermissionState.granted
        ? PermissionRequestResult.granted
        : PermissionRequestResult.denied;
  }

  @override
  Future<PermissionRequestResult> requestPermission() async {
    requestPermissionCalls += 1;
    if (permissionRequestResult == PermissionRequestResult.granted) {
      permissionState = PermissionState.granted;
    } else if (permissionState != PermissionState.granted) {
      permissionState = PermissionState.denied;
    }
    return permissionRequestResult;
  }

  @override
  Future<void> setNativeLocale(Locale locale) async {
    lastNativeLocaleTag = locale.toLanguageTag();
  }

  @override
  Future<void> startKeepAwake(Duration duration) async {
    startKeepAwakeCalls += 1;
    lastKeepAwakeDuration = duration;
    if (!keepAwakeStartSucceeds) {
      throw Exception('startKeepAwake failed');
    }
    keepAwakeNativeActive = true;
  }

  @override
  Future<void> startKeepAwakeIndefinitely() async {
    startKeepAwakeIndefinitelyCalls += 1;
    lastKeepAwakeDuration = null;
    if (!keepAwakeStartSucceeds) {
      throw Exception('startKeepAwakeIndefinitely failed');
    }
    keepAwakeNativeActive = true;
  }

  @override
  Future<KeepAwakePlatformState> getKeepAwakeState() async {
    getKeepAwakeStateCalls += 1;
    return KeepAwakePlatformState(
      isActive: keepAwakeNativeActive,
      assertionCount: keepAwakeNativeActive ? 2 : 0,
    );
  }

  @override
  Future<KeepAwakePlatformState> stopKeepAwake() async {
    stopKeepAwakeCalls += 1;
    final wasActive = keepAwakeNativeActive;
    keepAwakeNativeActive = false;
    return KeepAwakePlatformState(
      isActive: keepAwakeNativeActive,
      assertionCount: 0,
      releasedCount: wasActive ? 2 : 0,
    );
  }

  @override
  Future<SystemContextSnapshot> getSystemContextSnapshot({
    Set<AiDataSource> sources = const <AiDataSource>{},
  }) async {
    lastRequestedSources = sources;
    return systemContext;
  }

  @override
  Future<List<BluetoothBatteryDevice>> getBluetoothBatteryDevices() async =>
      bluetoothBatteryDevices;

  @override
  Future<void> showSuggestionPanel(SuggestionPanelData data) async {
    showSuggestionPanelCalls += 1;
    lastSuggestionPanelData = data;
  }

  @override
  Stream<SuggestionPanelAction> get suggestionPanelActions =>
      suggestionPanelActionsController.stream;

  @override
  Stream<CommandPanelAction> get commandPanelActions =>
      commandPanelActionsController.stream;

  @override
  Future<void> updateSuggestionPanel(SuggestionPanelData data) async {
    updateSuggestionPanelCalls += 1;
    lastSuggestionPanelData = data;
  }

  @override
  Future<void> showCommandPanel(CommandPanelData data) async {
    showCommandPanelCalls += 1;
    lastCommandPanelData = data;
  }

  @override
  Future<void> updateCommandPanel(CommandPanelData data) async {
    updateCommandPanelCalls += 1;
    lastCommandPanelData = data;
  }
}

class FakeLaunchAtStartupService implements LaunchAtStartupService {
  bool enabled = false;
  int setEnabledCalls = 0;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    setEnabledCalls += 1;
    this.enabled = enabled;
  }
}

class FakeTrayClient implements LockbarTrayClient {
  final List<TrayListener> listeners = [];
  String? iconPath;
  int? iconSize;
  bool? isTemplate;
  String? toolTip;
  String? title;
  int destroyCalls = 0;

  @override
  void addListener(TrayListener listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(TrayListener listener) {
    listeners.remove(listener);
  }

  @override
  Future<void> destroy() async {
    destroyCalls += 1;
  }

  @override
  Future<void> setIcon(
    String path, {
    required int iconSize,
    required bool isTemplate,
  }) async {
    iconPath = path;
    this.iconSize = iconSize;
    this.isTemplate = isTemplate;
  }

  @override
  Future<void> setTitle(String title) async {
    this.title = title;
  }

  @override
  Future<void> setToolTip(String toolTip) async {
    this.toolTip = toolTip;
  }
}

class FakeLocalePreferencesService implements LocalePreferencesService {
  FakeLocalePreferencesService({this.preference = AppLocalePreference.system});

  AppLocalePreference preference;
  int saveCalls = 0;

  @override
  Future<AppLocalePreference> loadPreference() async => preference;

  @override
  Future<void> savePreference(AppLocalePreference preference) async {
    saveCalls += 1;
    this.preference = preference;
  }
}

class FakeAiMemoryService implements AiMemoryService {
  String installId = 'lb-test-install';
  AiSettings settings = AiSettings.defaults();
  AiSavedConnection? savedConnection;
  AiEndpointConfig draftEndpointConfig = const AiEndpointConfig();
  AiEndpointConfig endpointConfig = const AiEndpointConfig();
  AiConnectionVerification? connectionVerification;
  MemoryProfile profile = MemoryProfile.empty();
  List<ActionHistoryEntry> actionHistory = const [];
  bool primaryActionTipSeen = true;

  int saveSettingsCalls = 0;
  int saveProfileCalls = 0;
  int saveActionHistoryCalls = 0;
  int resetCalls = 0;

  @override
  Future<List<ActionHistoryEntry>> loadActionHistory() async => actionHistory;

  @override
  Future<String> loadInstallId() async => installId;

  @override
  Future<MemoryProfile> loadMemoryProfile() async => profile;

  @override
  Future<AiSettings> loadSettings() async => settings;

  @override
  Future<AiSavedConnection?> loadSavedConnection() async => savedConnection;

  @override
  Future<void> saveSavedConnection(AiSavedConnection connection) async {
    savedConnection = connection;
    draftEndpointConfig = connection.endpointConfig;
  }

  @override
  Future<void> clearSavedConnection() async {
    savedConnection = null;
    draftEndpointConfig = const AiEndpointConfig();
  }

  @override
  Future<AiEndpointConfig> loadConnectionDraftDefaults() async {
    if (savedConnection != null) {
      return savedConnection!.endpointConfig;
    }
    return draftEndpointConfig.isComplete
        ? draftEndpointConfig
        : endpointConfig;
  }

  @override
  Future<AiEndpointConfig> loadEndpointConfig() async => endpointConfig;

  @override
  Future<AiConnectionVerification?> loadConnectionVerification() async =>
      connectionVerification;

  @override
  Future<bool> loadPrimaryActionTipSeen() async => primaryActionTipSeen;

  @override
  Future<void> resetMemory() async {
    resetCalls += 1;
    profile = MemoryProfile.empty();
    actionHistory = const [];
  }

  @override
  Future<void> saveActionHistory(List<ActionHistoryEntry> entries) async {
    saveActionHistoryCalls += 1;
    actionHistory = entries;
  }

  @override
  Future<void> saveMemoryProfile(MemoryProfile profile) async {
    saveProfileCalls += 1;
    this.profile = profile;
  }

  @override
  Future<void> saveEndpointConfig(AiEndpointConfig config) async {
    endpointConfig = config;
    draftEndpointConfig = config;
  }

  @override
  Future<void> saveConnectionVerification(
    AiConnectionVerification verification,
  ) async {
    connectionVerification = verification;
  }

  @override
  Future<void> savePrimaryActionTipSeen(bool seen) async {
    primaryActionTipSeen = seen;
  }

  @override
  Future<void> saveSettings(AiSettings settings) async {
    saveSettingsCalls += 1;
    this.settings = settings;
  }

  @override
  Future<void> clearEndpointConfig() async {
    endpointConfig = const AiEndpointConfig();
    draftEndpointConfig = const AiEndpointConfig();
  }

  @override
  Future<void> clearConnectionVerification() async {
    connectionVerification = null;
  }
}

class FakeAiInferenceClient implements AiInferenceClient {
  @override
  String get model => _model;

  String _model = 'MiniMax-M2.7';
  AiRecommendationResult recommendationResult = const AiRecommendationResult(
    connectionStatus: AiConnectionStatus.online,
  );
  AiFeedbackResult feedbackResult = const AiFeedbackResult(
    connectionStatus: AiConnectionStatus.online,
  );
  Object? testConnectionError;
  Object? recommendError;
  Object? feedbackError;

  int recommendCalls = 0;
  int feedbackCalls = 0;
  int testConnectionCalls = 0;
  ContextSnapshot? lastSnapshot;
  DecisionEpisode? lastEpisode;

  set modelName(String value) {
    _model = value;
  }

  @override
  Future<void> testConnection({required AiEndpointConfig config}) async {
    testConnectionCalls += 1;
    if (testConnectionError != null) {
      throw testConnectionError!;
    }
  }

  @override
  Future<AiRecommendationResult> recommend({
    required String installId,
    required AiEndpointConfig config,
    required ContextSnapshot snapshot,
    required MemoryProfile memoryProfile,
    required bool allowLocalFallback,
  }) async {
    recommendCalls += 1;
    lastSnapshot = snapshot;
    if (recommendError != null) {
      throw recommendError!;
    }
    return recommendationResult;
  }

  @override
  Future<AiFeedbackResult> sendFeedback({
    required String installId,
    required AiEndpointConfig config,
    required DecisionEpisode episode,
    required MemoryProfile memoryProfile,
  }) async {
    feedbackCalls += 1;
    lastEpisode = episode;
    if (feedbackError != null) {
      throw feedbackError!;
    }
    return feedbackResult;
  }
}

class FakeAiTraceStore implements AiTraceStore {
  List<AiDecisionTrace> traces = const [];
  int clearCalls = 0;
  int saveCalls = 0;

  @override
  Future<void> clearTraces() async {
    clearCalls += 1;
    traces = const [];
  }

  @override
  Future<List<AiDecisionTrace>> loadTraces() async => traces;

  @override
  Future<void> saveTrace(AiDecisionTrace trace) async {
    saveCalls += 1;
    final next = [...traces];
    final index = next.indexWhere((item) => item.id == trace.id);
    if (index == -1) {
      next.add(trace);
    } else {
      next[index] = trace;
    }
    next.sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
    traces = next;
  }
}

class FakeAiContextCollector implements AiContextCollector {
  SystemContextSnapshot systemContext = SystemContextSnapshot(
    collectedAt: DateTime(2025),
    idleSeconds: 0,
    bluetoothDevices: const [],
    networkReachable: true,
  );
  List<AiTriggerType> triggers = const [];
  int collectCalls = 0;
  Set<AiDataSource> lastSources = const <AiDataSource>{};

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
    return ContextSnapshot(
      trigger: trigger,
      occurredAt: occurredAt,
      localeTag: localeTag,
      hourOfDay: occurredAt.hour,
      weekday: occurredAt.weekday,
      recentActions: actionHistory.map((entry) => entry.action).toList(),
      systemContext: systemContext,
      focusSessionMinutes: focusSessionMinutes,
      delayedLockSeconds: delayedLockSeconds,
      explicitAction: explicitAction,
    );
  }

  @override
  Future<SystemContextSnapshot> collectSystemContext(
    Set<AiDataSource> sources,
  ) async {
    collectCalls += 1;
    lastSources = sources;
    return systemContext;
  }

  @override
  List<AiTriggerType> detectEnvironmentTriggers({
    required SystemContextSnapshot? previous,
    required SystemContextSnapshot current,
    required DateTime now,
  }) {
    return triggers;
  }
}
