import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'l10n/locale_support.dart';
import 'models/ai_models.dart';
import 'models/lockbar_models.dart';
import 'platform/lockbar_platform.dart';
import 'services/ai_context_collector.dart';
import 'services/ai_inference_client.dart';
import 'services/ai_memory_service.dart';
import 'services/ai_trace_store.dart';
import 'services/launch_at_startup_service.dart';
import 'services/locale_preferences_service.dart';

class LockbarController extends ChangeNotifier {
  static const List<AiDataSource> supportedAiDataSources = [
    AiDataSource.actionHistory,
    AiDataSource.idleState,
  ];
  static const Set<AiTriggerType> supportedAiTriggers = {
    AiTriggerType.focusEnded,
    AiTriggerType.workdayEnded,
    AiTriggerType.delayedLockRequested,
    AiTriggerType.awayReturned,
  };

  LockbarController({
    required this.platform,
    required this.launchAtStartupService,
    required this.localePreferencesService,
    required this.aiMemoryService,
    required this.aiInferenceClient,
    required this.aiContextCollector,
    AiTraceStore? aiTraceStore,
    required Locale initialSystemLocale,
    this.enableBackgroundContextPolling = false,
    DateTime Function()? now,
    Duration? aiPollInterval,
  }) : _systemLocale = resolveSupportedLocale(initialSystemLocale),
       aiTraceStore = aiTraceStore ?? InMemoryAiTraceStore(),
       _now = now ?? DateTime.now,
       _aiPollInterval = aiPollInterval ?? const Duration(seconds: 45);

  final LockbarPlatform platform;
  final LaunchAtStartupService launchAtStartupService;
  final LocalePreferencesService localePreferencesService;
  final AiMemoryService aiMemoryService;
  final AiInferenceClient aiInferenceClient;
  final AiContextCollector aiContextCollector;
  final AiTraceStore aiTraceStore;
  final bool enableBackgroundContextPolling;

  final DateTime Function() _now;
  final Duration _aiPollInterval;

  PermissionState _permissionState = PermissionState.notDetermined;
  PermissionState _calendarPermissionState = PermissionState.notDetermined;
  bool _launchAtStartupEnabled = false;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _didInitialize = false;
  bool _isPollingContext = false;
  bool _settingsWindowVisible = false;
  bool _suggestionPanelVisible = false;
  bool _showPrimaryActionTip = false;
  AppLocalePreference _localePreference = AppLocalePreference.system;
  StatusMessage? _statusMessage;
  Locale _systemLocale = englishAppLocale;
  AppInfo _appInfo = const AppInfo(
    name: 'LockBar',
    version: '1.0.0',
    buildNumber: '1',
  );

  AiSettings _aiSettings = AiSettings.defaults();
  AiSavedConnection? _savedAiConnection;
  AiEndpointConfig _aiConnectionDraftDefaults = const AiEndpointConfig();
  bool _hasLegacyAiConnectionDraft = false;
  MemoryProfile _memoryProfile = MemoryProfile.empty();
  String _installId = '';
  List<ActionHistoryEntry> _actionHistory = const [];
  FocusSessionState? _focusSession;
  DelayedLockState? _delayedLock;
  AiRecommendation? _activeSuggestion;
  AiRecommendation? _lastSuggestion;
  ContextSnapshot? _activeSuggestionSnapshot;
  String? _activeSuggestionTraceId;
  SystemContextSnapshot? _lastSystemContext;
  List<AiDecisionTrace> _decisionTraces = const [];
  int _traceSequence = 0;
  final Map<AiTriggerType, DateTime> _lastTriggerTimes = {};
  DateTime? _lastEveningSuggestionDay;
  Timer? _focusTimer;
  Timer? _delayedLockTimer;
  Timer? _pollTimer;

  PermissionState get permissionState => _permissionState;
  PermissionState get calendarPermissionState => _calendarPermissionState;
  bool get launchAtStartupEnabled => _launchAtStartupEnabled;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  bool get hasError => _statusMessage?.isError ?? false;
  StatusMessage? get statusMessage => _statusMessage;
  AppInfo get appInfo => _appInfo;
  AppLocalePreference get localePreference => _localePreference;
  Locale get effectiveLocale =>
      localeForPreference(_localePreference, _systemLocale);
  bool get canLockNow =>
      _permissionState == PermissionState.granted && !_isBusy;
  AiSettings get aiSettings => _aiSettings;
  AiSavedConnection? get savedAiConnection => _savedAiConnection;
  AiEndpointConfig get aiConnectionDraftDefaults =>
      _savedAiConnection?.endpointConfig ?? _aiConnectionDraftDefaults;
  bool get aiSuggestionsEnabled => _aiSettings.mode == AiMode.on;
  bool get hasSavedAiConnection => _savedAiConnection != null;
  bool get hasLegacyAiConnectionDraft =>
      !hasSavedAiConnection && _hasLegacyAiConnectionDraft;
  MemoryProfile get memoryProfile => _memoryProfile;
  AiSavedConnectionState get aiSavedConnectionState =>
      _savedAiConnection?.state ?? AiSavedConnectionState.missing;
  AiConnectionStatus get aiConnectionStatus => switch (aiSavedConnectionState) {
    AiSavedConnectionState.missing
        when hasLegacyAiConnectionDraft ||
            aiConnectionDraftDefaults.isComplete =>
      AiConnectionStatus.ready,
    AiSavedConnectionState.missing => AiConnectionStatus.notConfigured,
    AiSavedConnectionState.verifiedHealthy => AiConnectionStatus.online,
    AiSavedConnectionState.verifiedDegraded => AiConnectionStatus.offline,
  };
  String? get aiConnectionDetail => _savedAiConnection?.lastErrorMessage;
  bool get canEnableAi => hasSavedAiConnection;
  DateTime? get lastVerifiedAt => _savedAiConnection?.verifiedAt;
  DateTime? get lastHealthyAt => _savedAiConnection?.lastHealthyAt;
  String get aiModelLabel =>
      _savedAiConnection?.model ?? aiInferenceClient.model;
  FocusSessionState? get focusSession => _focusSession;
  DelayedLockState? get delayedLock => _delayedLock;
  AiRecommendation? get activeSuggestion => _activeSuggestion;
  AiRecommendation? get lastSuggestion => _lastSuggestion;
  bool get hasActiveSuggestion => _activeSuggestion != null;
  bool get hasSuggestionIndicator => _activeSuggestion != null;
  bool get isSettingsWindowVisible => _settingsWindowVisible;
  bool get isSuggestionPanelVisible => _suggestionPanelVisible;
  bool get showPrimaryActionTip => _showPrimaryActionTip;
  List<AiDataSource> get aiDataSources => supportedAiDataSources;
  List<AiDecisionTrace> get decisionTraces => _decisionTraces;

  Future<void> initialize() async {
    if (_didInitialize) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final permissionFuture = platform.getPermissionState();
      final calendarPermissionFuture = platform.getCalendarPermissionState();
      final launchAtLoginFuture = launchAtStartupService.isEnabled();
      final appInfoFuture = platform.getAppInfo();
      final localePreferenceFuture = localePreferencesService.loadPreference();
      final aiSettingsFuture = aiMemoryService.loadSettings();
      final savedConnectionFuture = aiMemoryService.loadSavedConnection();
      final connectionDraftDefaultsFuture = aiMemoryService
          .loadConnectionDraftDefaults();
      final decisionTracesFuture = aiTraceStore.loadTraces();
      final memoryProfileFuture = aiMemoryService.loadMemoryProfile();
      final actionHistoryFuture = aiMemoryService.loadActionHistory();
      final installIdFuture = aiMemoryService.loadInstallId();
      final primaryActionTipSeenFuture = aiMemoryService
          .loadPrimaryActionTipSeen();

      _permissionState = await permissionFuture;
      _calendarPermissionState = await calendarPermissionFuture;
      _launchAtStartupEnabled = await launchAtLoginFuture;
      _appInfo = await appInfoFuture;
      _localePreference = await localePreferenceFuture;
      _aiSettings = await aiSettingsFuture;
      _aiSettings = _sanitizeAiSettings(_aiSettings);
      _savedAiConnection = await savedConnectionFuture;
      _aiConnectionDraftDefaults = await connectionDraftDefaultsFuture;
      _hasLegacyAiConnectionDraft =
          _savedAiConnection == null && _aiConnectionDraftDefaults.isComplete;
      _decisionTraces = await _sanitizeDecisionTraces(
        await decisionTracesFuture,
      );
      _memoryProfile = await memoryProfileFuture;
      _actionHistory = await actionHistoryFuture.recentFirst();
      _installId = await installIdFuture;

      if (_aiSettings.mode == AiMode.on && !hasSavedAiConnection) {
        _aiSettings = _aiSettings.copyWith(mode: AiMode.off);
        await aiMemoryService.saveSettings(_aiSettings);
      }

      final hasSeenPrimaryActionTip = await primaryActionTipSeenFuture;
      if (!hasSeenPrimaryActionTip) {
        _showPrimaryActionTip = true;
        _settingsWindowVisible = true;
        await aiMemoryService.savePrimaryActionTipSeen(true);
      }

      _setStatusKey(
        _permissionState == PermissionState.granted
            ? StatusMessageKey.trayReady
            : StatusMessageKey.permissionNeededOnce,
      );

      if (enableBackgroundContextPolling && aiSuggestionsEnabled) {
        _startBackgroundPolling();
      }
    } catch (_) {
      _setErrorKey(StatusMessageKey.startupFailed);
    } finally {
      _didInitialize = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPermissionState() async {
    final previousState = _permissionState;
    try {
      _permissionState = await platform.getPermissionState();
      if (_permissionState == PermissionState.granted &&
          previousState != PermissionState.granted) {
        _setStatusKey(StatusMessageKey.permissionGranted);
      }
    } catch (_) {
      _setErrorKey(StatusMessageKey.permissionRefreshFailed);
    }
    notifyListeners();
  }

  Future<void> refreshCalendarPermissionState() async {
    _calendarPermissionState = await platform.getCalendarPermissionState();
    notifyListeners();
  }

  Future<TrayPrimaryActionOutcome> handlePrimaryTrayAction() async {
    if (_isBusy) {
      return TrayPrimaryActionOutcome.failed;
    }

    _isBusy = true;
    notifyListeners();

    try {
      _permissionState = await platform.getPermissionState();
      if (_permissionState == PermissionState.notDetermined) {
        await _requestPermissionInternal();
        return TrayPrimaryActionOutcome.needsSettings;
      }
      if (_permissionState == PermissionState.denied) {
        _setErrorKey(StatusMessageKey.permissionStillNeeded);
        return TrayPrimaryActionOutcome.needsSettings;
      }

      final result = await platform.lockNow();
      switch (result.status) {
        case LockResultStatus.success:
          _setStatusKey(StatusMessageKey.lockCommandSent);
          await _recordAction('lock.now.primary');
          await _recordActiveSuggestionDecisionIfUnset(AiDecisionType.ignored);
          _clearSuggestionState();
          return TrayPrimaryActionOutcome.locked;
        case LockResultStatus.permissionDenied:
          _permissionState = PermissionState.denied;
          _setErrorKey(StatusMessageKey.permissionStillNeeded);
          return TrayPrimaryActionOutcome.needsSettings;
        case LockResultStatus.failure:
          _setErrorKey(_messageKeyForFailure(result.failureCode));
          return TrayPrimaryActionOutcome.failed;
      }
    } catch (_) {
      _setErrorKey(StatusMessageKey.trayActionFailed);
      return TrayPrimaryActionOutcome.failed;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> lockNowFromSettings() async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    notifyListeners();

    try {
      _permissionState = await platform.getPermissionState();
      if (_permissionState == PermissionState.notDetermined) {
        await _requestPermissionInternal();
        return;
      }
      if (_permissionState == PermissionState.denied) {
        _setErrorKey(StatusMessageKey.accessibilityStillOff);
        return;
      }

      final result = await platform.lockNow();
      switch (result.status) {
        case LockResultStatus.success:
          _setStatusKey(StatusMessageKey.lockCommandSent);
          await _recordAction('lock.now.settings');
          await _recordActiveSuggestionDecisionIfUnset(AiDecisionType.ignored);
          _clearSuggestionState();
          break;
        case LockResultStatus.permissionDenied:
          _permissionState = PermissionState.denied;
          _setErrorKey(StatusMessageKey.accessibilityStillOff);
          break;
        case LockResultStatus.failure:
          _setErrorKey(_messageKeyForFailure(result.failureCode));
          break;
      }
    } catch (_) {
      _setErrorKey(StatusMessageKey.lockServiceUnavailable);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    notifyListeners();

    try {
      await _requestPermissionInternal();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await platform.openAccessibilitySettings();
      _setStatusKey(StatusMessageKey.openedSystemSettings);
    } catch (_) {
      _setErrorKey(StatusMessageKey.openSystemSettingsFailed);
    }
    notifyListeners();
  }

  Future<void> setLaunchAtStartup(bool enabled) async {
    if (_isBusy) {
      return;
    }

    final previousValue = _launchAtStartupEnabled;
    _launchAtStartupEnabled = enabled;
    _isBusy = true;
    notifyListeners();

    try {
      await launchAtStartupService.setEnabled(enabled);
      _launchAtStartupEnabled = await launchAtStartupService.isEnabled();
      _setStatusKey(
        _launchAtStartupEnabled
            ? StatusMessageKey.launchAtLoginEnabled
            : StatusMessageKey.launchAtLoginDisabled,
      );
    } catch (_) {
      _launchAtStartupEnabled = previousValue;
      _setErrorKey(StatusMessageKey.launchAtLoginFailed);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> setLocalePreference(AppLocalePreference preference) async {
    if (_localePreference == preference) {
      return;
    }

    final previousPreference = _localePreference;
    _localePreference = preference;
    notifyListeners();

    try {
      await localePreferencesService.savePreference(preference);
    } catch (_) {
      _localePreference = previousPreference;
      _setErrorKey(StatusMessageKey.localePreferenceFailed);
      notifyListeners();
    }
  }

  Future<void> enableAiSuggestionsWithDefaults() async {
    if (!hasSavedAiConnection) {
      _setErrorKey(StatusMessageKey.aiConfigurationMissing);
      notifyListeners();
      return;
    }
    if (!canEnableAi) {
      _setErrorKey(StatusMessageKey.aiConnectionVerificationRequired);
      notifyListeners();
      return;
    }
    await _saveAiSettings(
      AiSettings.recommendedEnabled(),
      StatusMessageKey.aiModeEnabled,
    );
    if (enableBackgroundContextPolling) {
      _startBackgroundPolling();
    }
  }

  Future<void> setAiMode(bool enabled) async {
    if (enabled) {
      if (!hasSavedAiConnection) {
        _setErrorKey(StatusMessageKey.aiConfigurationMissing);
        notifyListeners();
        return;
      }
      if (!canEnableAi) {
        _setErrorKey(StatusMessageKey.aiConnectionVerificationRequired);
        notifyListeners();
        return;
      }
    }
    final nextSettings = _aiSettings.copyWith(
      mode: enabled ? AiMode.on : AiMode.off,
    );
    await _saveAiSettings(
      nextSettings,
      enabled
          ? StatusMessageKey.aiModeEnabled
          : StatusMessageKey.aiModeDisabled,
    );
    if (!enabled) {
      await _recordActiveSuggestionDecisionIfUnset(AiDecisionType.ignored);
      _stopBackgroundPolling();
      _clearSuggestionState();
      return;
    }
    if (enableBackgroundContextPolling) {
      _startBackgroundPolling();
    }
  }

  Future<AiConnectionDraftTestResult> testAiConnectionDraft(
    AiEndpointConfig config,
  ) async {
    final normalized = AiEndpointConfig(
      baseUrl: config.normalizedBaseUrl,
      apiKey: config.apiKey.trim(),
    );
    final fingerprint = normalized.fingerprintForModel(aiInferenceClient.model);
    if (!normalized.isComplete) {
      return AiConnectionDraftTestResult(
        state: AiConnectionDraftTestState.failure,
        draftFingerprint: fingerprint,
        model: aiInferenceClient.model,
        errorMessage: 'Base URL and API key are required.',
      );
    }
    try {
      await aiInferenceClient.testConnection(config: normalized);
      return AiConnectionDraftTestResult(
        state: AiConnectionDraftTestState.success,
        draftFingerprint: fingerprint,
        model: aiInferenceClient.model,
        testedAt: _now(),
      );
    } on AiServiceException catch (error) {
      return AiConnectionDraftTestResult(
        state: AiConnectionDraftTestState.failure,
        draftFingerprint: fingerprint,
        model: aiInferenceClient.model,
        errorMessage: error.message,
      );
    } catch (_) {
      return AiConnectionDraftTestResult(
        state: AiConnectionDraftTestState.failure,
        draftFingerprint: fingerprint,
        model: aiInferenceClient.model,
      );
    }
  }

  Future<void> saveVerifiedAiConnection(
    AiEndpointConfig config,
    AiConnectionDraftTestResult testResult,
  ) async {
    final normalized = AiEndpointConfig(
      baseUrl: config.normalizedBaseUrl,
      apiKey: config.apiKey.trim(),
    );
    if (!testResult.isSuccess || !testResult.matchesDraft(normalized)) {
      throw StateError('The current draft must be tested successfully first.');
    }

    final savedConnection = AiSavedConnection(
      baseUrl: normalized.normalizedBaseUrl,
      apiKey: normalized.apiKey.trim(),
      model: testResult.model,
      verifiedAt: testResult.testedAt ?? _now(),
      lastHealthyAt: testResult.testedAt ?? _now(),
    );

    final previousConnection = _savedAiConnection;
    final previousDraftDefaults = _aiConnectionDraftDefaults;
    _savedAiConnection = savedConnection;
    _aiConnectionDraftDefaults = savedConnection.endpointConfig;
    _hasLegacyAiConnectionDraft = false;
    notifyListeners();

    try {
      await aiMemoryService.saveSavedConnection(savedConnection);
      _setStatusKey(StatusMessageKey.aiConfigurationSaved);
    } catch (_) {
      _savedAiConnection = previousConnection;
      _aiConnectionDraftDefaults = previousDraftDefaults;
      _setErrorKey(StatusMessageKey.aiSettingsSaveFailed);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> clearAiConnection() async {
    final previousConnection = _savedAiConnection;
    final previousDraftDefaults = _aiConnectionDraftDefaults;
    final previousLegacyDraftState = _hasLegacyAiConnectionDraft;
    final previousSettings = _aiSettings;
    _savedAiConnection = null;
    _aiConnectionDraftDefaults = const AiEndpointConfig();
    _hasLegacyAiConnectionDraft = false;
    if (_aiSettings.mode == AiMode.on) {
      _aiSettings = _aiSettings.copyWith(mode: AiMode.off);
    }
    await _recordActiveSuggestionDecisionIfUnset(AiDecisionType.ignored);
    _clearSuggestionState(notify: false);
    _stopBackgroundPolling();
    notifyListeners();

    try {
      await aiMemoryService.clearSavedConnection();
      if (previousSettings.mode == AiMode.on) {
        await aiMemoryService.saveSettings(_aiSettings);
      }
    } catch (_) {
      _savedAiConnection = previousConnection;
      _aiConnectionDraftDefaults = previousDraftDefaults;
      _hasLegacyAiConnectionDraft = previousLegacyDraftState;
      _aiSettings = previousSettings;
      _setErrorKey(StatusMessageKey.aiSettingsSaveFailed);
      notifyListeners();
      return;
    }

    notifyListeners();
  }

  Future<void> setAiDataSourceEnabled(AiDataSource source, bool enabled) async {
    if (enabled) {
      if (source == AiDataSource.calendar &&
          _calendarPermissionState != PermissionState.granted) {
        notifyListeners();
        return;
      }
      if (source == AiDataSource.windowTitle &&
          _permissionState != PermissionState.granted) {
        notifyListeners();
        return;
      }
    }

    final nextSources = Map<AiDataSource, bool>.from(_aiSettings.dataSources)
      ..[source] = enabled;
    await _saveAiSettings(_aiSettings.copyWith(dataSources: nextSources), null);
  }

  Future<bool> requestCalendarAccess() async {
    final result = await platform.requestCalendarAccess();
    _calendarPermissionState = await platform.getCalendarPermissionState();
    notifyListeners();
    return result == PermissionRequestResult.granted ||
        _calendarPermissionState == PermissionState.granted;
  }

  AiDataSourceAvailability dataSourceAvailability(AiDataSource source) {
    if (!_aiSettings.isEnabled(source)) {
      return AiDataSourceAvailability.off;
    }

    return switch (source) {
      AiDataSource.calendar
          when _calendarPermissionState != PermissionState.granted =>
        AiDataSourceAvailability.needsPermission,
      AiDataSource.windowTitle
          when _permissionState != PermissionState.granted =>
        AiDataSourceAvailability.needsPermission,
      _ => AiDataSourceAvailability.on,
    };
  }

  Future<void> resetAiMemory() async {
    try {
      await aiMemoryService.resetMemory();
      _memoryProfile = MemoryProfile.empty();
      _actionHistory = const [];
      _setStatusKey(StatusMessageKey.aiMemoryReset);
    } catch (_) {
      _setErrorKey(StatusMessageKey.aiMemoryResetFailed);
    }
    notifyListeners();
  }

  Future<void> clearAiDecisionHistory() async {
    try {
      await aiTraceStore.clearTraces();
      _decisionTraces = const [];
    } catch (_) {
      // Keep existing history if clearing fails.
    }
    notifyListeners();
  }

  Future<void> startFocusSession(Duration duration) async {
    _focusTimer?.cancel();
    final now = _now();
    _focusSession = FocusSessionState(
      startedAt: now,
      endsAt: now.add(duration),
      durationMinutes: duration.inMinutes,
    );
    _focusTimer = Timer(duration, () {
      unawaited(_onFocusSessionFinished());
    });
    await _recordAction('focus.start.${duration.inMinutes}m');
    _setStatusKey(StatusMessageKey.focusSessionStarted);
    notifyListeners();
  }

  Future<void> cancelFocusSession() async {
    _focusTimer?.cancel();
    _focusSession = null;
    await _recordAction('focus.cancel');
    _setStatusKey(StatusMessageKey.focusSessionCancelled);
    notifyListeners();
  }

  Future<void> triggerWorkdayWrapUp() async {
    await _recordAction('workday.end');
    _setStatusKey(StatusMessageKey.workdayReviewStarted);
    await _evaluateAiTrigger(
      AiTriggerType.workdayEnded,
      explicitAction: 'endWorkday',
    );
  }

  Future<void> scheduleDelayedLock(Duration duration) async {
    _delayedLockTimer?.cancel();
    final now = _now();
    _delayedLock = DelayedLockState(
      scheduledAt: now,
      endsAt: now.add(duration),
      durationSeconds: duration.inSeconds,
    );
    _delayedLockTimer = Timer(duration, () {
      unawaited(_completeDelayedLock());
    });
    await _recordAction('lock.later.${duration.inSeconds}s');
    _setStatusKey(StatusMessageKey.delayedLockScheduled);
    notifyListeners();
  }

  Future<void> cancelDelayedLock() async {
    _delayedLockTimer?.cancel();
    _delayedLock = null;
    await _recordAction('lock.later.cancel');
    _setStatusKey(StatusMessageKey.delayedLockCancelled);
    notifyListeners();
  }

  Future<void> acceptActiveSuggestionLockNow() async {
    if (_activeSuggestion == null) {
      return;
    }
    await _submitSuggestionDecision(AiDecisionType.lockNow);
    await lockNowFromSettings();
    _clearSuggestionState();
  }

  Future<void> acceptActiveSuggestionLater() async {
    final suggestion = _activeSuggestion;
    if (suggestion == null) {
      return;
    }

    final useFiveMinutes = suggestion.preferredDelaySeconds >= 300;
    await _submitSuggestionDecision(
      useFiveMinutes
          ? AiDecisionType.laterFiveMinutes
          : AiDecisionType.laterTwoMinutes,
    );
    await scheduleDelayedLock(Duration(seconds: useFiveMinutes ? 300 : 120));
    _clearSuggestionState();
  }

  Future<void> dismissActiveSuggestionNotNow() async {
    if (_activeSuggestion == null) {
      return;
    }
    await _submitSuggestionDecision(AiDecisionType.notNow);
    _clearSuggestionState();
  }

  void reopenActiveSuggestionCard() {
    if (_activeSuggestion == null) {
      return;
    }
    _suggestionPanelVisible = true;
    notifyListeners();
  }

  void handleSuggestionPanelHidden() {
    if (!_suggestionPanelVisible) {
      return;
    }
    _suggestionPanelVisible = false;
    unawaited(_recordActiveSuggestionDecisionIfUnset(AiDecisionType.dismissed));
    notifyListeners();
  }

  void openSettingsWindow() {
    _settingsWindowVisible = true;
    _suggestionPanelVisible = false;
    notifyListeners();
  }

  void hideWindow() {
    _settingsWindowVisible = false;
    notifyListeners();
  }

  void handleWindowClosed() {
    _settingsWindowVisible = false;
    notifyListeners();
  }

  void dismissPrimaryActionTip() {
    if (!_showPrimaryActionTip) {
      return;
    }
    _showPrimaryActionTip = false;
    notifyListeners();
  }

  void updateSystemLocale(Locale locale) {
    final nextLocale = resolveSupportedLocale(locale);
    if (nextLocale == _systemLocale) {
      return;
    }

    final previousEffectiveLocale = effectiveLocale;
    _systemLocale = nextLocale;
    if (_localePreference == AppLocalePreference.system &&
        previousEffectiveLocale != effectiveLocale) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _delayedLockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissionInternal() async {
    final requestResult = await platform.requestPermission();
    _permissionState = await platform.getPermissionState();

    if (requestResult == PermissionRequestResult.granted ||
        _permissionState == PermissionState.granted) {
      _setStatusKey(StatusMessageKey.permissionGrantedClickTrayAgain);
      return;
    }

    _setErrorKey(StatusMessageKey.permissionEnableThenRetry);
  }

  StatusMessageKey _messageKeyForFailure(LockFailureCode? failureCode) {
    return switch (failureCode) {
      LockFailureCode.eventSourceUnavailable =>
        StatusMessageKey.lockFailureEventSource,
      LockFailureCode.eventSequenceUnavailable =>
        StatusMessageKey.lockFailureEventSequence,
      LockFailureCode.unknown || null => StatusMessageKey.lockFailureGeneric,
    };
  }

  void _setStatusKey(StatusMessageKey key) {
    _statusMessage = StatusMessage.status(key);
  }

  void _setErrorKey(StatusMessageKey key) {
    _statusMessage = StatusMessage.error(key);
  }

  Future<void> _saveAiSettings(
    AiSettings settings,
    StatusMessageKey? successMessage,
  ) async {
    final previous = _aiSettings;
    _aiSettings = _sanitizeAiSettings(settings);
    notifyListeners();

    try {
      await aiMemoryService.saveSettings(settings);
      if (successMessage != null) {
        _setStatusKey(successMessage);
      }
    } catch (_) {
      _aiSettings = previous;
      _setErrorKey(StatusMessageKey.aiSettingsSaveFailed);
    }
    notifyListeners();
  }

  Future<void> _recordAction(String action) async {
    final nextEntries = [
      ActionHistoryEntry(action: action, occurredAt: _now()),
      ..._actionHistory,
    ].take(24).toList(growable: false);
    _actionHistory = nextEntries;
    await aiMemoryService.saveActionHistory(_actionHistory);
  }

  void _startBackgroundPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_aiPollInterval, (_) {
      unawaited(_pollSystemContext());
    });
    unawaited(_pollSystemContext());
  }

  void _stopBackgroundPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _lastSystemContext = null;
  }

  Set<AiDataSource> _enabledSystemDataSources() {
    final sources = <AiDataSource>{};
    for (final source in supportedAiDataSources) {
      if (source == AiDataSource.actionHistory) {
        continue;
      }
      if (_aiSettings.isEnabled(source)) {
        sources.add(source);
      }
    }
    return sources;
  }

  Future<void> _pollSystemContext() async {
    if (!aiSuggestionsEnabled || _isPollingContext) {
      return;
    }

    _isPollingContext = true;
    try {
      final current = await aiContextCollector.collectSystemContext(
        _enabledSystemDataSources(),
      );
      final triggers = aiContextCollector.detectEnvironmentTriggers(
        previous: _lastSystemContext,
        current: current,
        now: _now(),
      );
      _lastSystemContext = current;

      for (final trigger in triggers) {
        if (!_shouldRunEnvironmentTrigger(trigger)) {
          continue;
        }
        await _evaluateAiTrigger(
          trigger,
          allowLocalFallback: trigger.isStageBoundary,
          systemContextOverride: current,
        );
      }
    } finally {
      _isPollingContext = false;
    }
  }

  bool _shouldRunEnvironmentTrigger(AiTriggerType trigger) {
    final now = _now();
    final lastTime = _lastTriggerTimes[trigger];
    if (lastTime != null && now.difference(lastTime).inMinutes < 20) {
      return false;
    }

    if (trigger == AiTriggerType.eveningWindDown &&
        _lastEveningSuggestionDay != null &&
        _isSameDay(_lastEveningSuggestionDay!, now)) {
      return false;
    }
    return true;
  }

  Future<void> _onFocusSessionFinished() async {
    final session = _focusSession;
    _focusSession = null;
    notifyListeners();
    if (session == null) {
      return;
    }

    await _recordAction('focus.end.${session.durationMinutes}m');
    await _evaluateAiTrigger(
      AiTriggerType.focusEnded,
      focusSessionMinutes: session.durationMinutes,
      explicitAction: 'focusEnded',
    );
  }

  Future<void> _completeDelayedLock() async {
    _delayedLock = null;
    notifyListeners();
    await lockNowFromSettings();
  }

  Future<void> _evaluateAiTrigger(
    AiTriggerType trigger, {
    bool? allowLocalFallback,
    int? focusSessionMinutes,
    int? delayedLockSeconds,
    String? explicitAction,
    SystemContextSnapshot? systemContextOverride,
  }) async {
    final now = _now();
    var trace = _newDecisionTrace(
      trigger: trigger,
      occurredAt: now,
      enabledDataSources: _enabledTraceDataSources(),
    );

    if (!aiSuggestionsEnabled) {
      trace = trace.copyWith(
        outcome: AiDecisionTraceOutcome.blockedByConfig,
        outcomeReason: _blockedReasonForCurrentAiState(),
      );
      await _persistDecisionTrace(trace);
      notifyListeners();
      return;
    }

    if (!hasSavedAiConnection || !canEnableAi) {
      trace = trace.copyWith(
        outcome: AiDecisionTraceOutcome.blockedByConfig,
        outcomeReason: _blockedReasonForCurrentAiState(),
      );
      await _persistDecisionTrace(trace);
      notifyListeners();
      return;
    }

    _lastTriggerTimes[trigger] = now;
    if (trigger == AiTriggerType.eveningWindDown) {
      _lastEveningSuggestionDay = now;
    }

    try {
      final systemContext =
          systemContextOverride ??
          await aiContextCollector.collectSystemContext(
            _enabledSystemDataSources(),
          );
      _lastSystemContext = systemContext;
      final snapshot = aiContextCollector.buildSnapshot(
        trigger: trigger,
        localeTag: effectiveLocale.toLanguageTag(),
        actionHistory: _aiSettings.isEnabled(AiDataSource.actionHistory)
            ? _actionHistory
            : const [],
        systemContext: systemContext,
        occurredAt: now,
        focusSessionMinutes: focusSessionMinutes,
        delayedLockSeconds: delayedLockSeconds,
        explicitAction: explicitAction,
      );
      trace = trace.copyWith(
        collectedContext: systemContext,
        contextSnapshot: snapshot,
        memoryProfileSnapshot: _memoryProfile,
      );
      await _persistDecisionTrace(trace);

      final result = await aiInferenceClient.recommend(
        installId: _installId,
        config: _savedAiConnection!.endpointConfig,
        snapshot: snapshot,
        memoryProfile: _memoryProfile,
        allowLocalFallback: allowLocalFallback ?? trigger.isStageBoundary,
      );

      await _markAiRequestSucceeded();
      if (result.memoryProfile != null && !result.memoryProfile!.isEmpty) {
        _memoryProfile = result.memoryProfile!;
        await aiMemoryService.saveMemoryProfile(_memoryProfile);
      }

      final recommendation = result.recommendation;
      trace = trace.copyWith(
        exchangeDebug: result.exchangeDebug,
        recommendation: recommendation,
        outcome: recommendation == null
            ? AiDecisionTraceOutcome.noSuggestion
            : recommendation.futureProtectionOnly
            ? AiDecisionTraceOutcome.futureProtectionOnly
            : AiDecisionTraceOutcome.suggested,
        outcomeReason:
            result.decisionReason ??
            recommendation?.reason ??
            _defaultOutcomeReason(
              recommendation == null
                  ? AiDecisionTraceOutcome.noSuggestion
                  : recommendation.futureProtectionOnly
                  ? AiDecisionTraceOutcome.futureProtectionOnly
                  : AiDecisionTraceOutcome.suggested,
            ),
      );
      await _persistDecisionTrace(trace);

      if (recommendation == null) {
        notifyListeners();
        return;
      }

      await _recordActiveSuggestionDecisionIfUnset(AiDecisionType.ignored);
      _activeSuggestion = recommendation;
      _lastSuggestion = recommendation;
      _activeSuggestionSnapshot = snapshot;
      _activeSuggestionTraceId = trace.id;
      _suggestionPanelVisible = !_settingsWindowVisible;
      notifyListeners();
    } on AiServiceException catch (error) {
      await _markAiRequestFailed(error.message);
      trace = trace.copyWith(
        exchangeDebug: error.debug,
        outcome: switch (error.code) {
          AiServiceErrorCode.notConfigured =>
            AiDecisionTraceOutcome.blockedByConfig,
          AiServiceErrorCode.timedOut => AiDecisionTraceOutcome.timedOut,
          AiServiceErrorCode.requestFailed =>
            AiDecisionTraceOutcome.requestFailed,
          AiServiceErrorCode.invalidResponse =>
            AiDecisionTraceOutcome.invalidResponse,
        },
        outcomeReason: error.message,
      );
      await _persistDecisionTrace(trace);
      _setErrorKey(switch (error.code) {
        AiServiceErrorCode.notConfigured =>
          StatusMessageKey.aiConfigurationMissing,
        AiServiceErrorCode.timedOut => StatusMessageKey.aiRequestTimedOut,
        AiServiceErrorCode.requestFailed => StatusMessageKey.aiRequestFailed,
        AiServiceErrorCode.invalidResponse =>
          StatusMessageKey.aiInvalidResponse,
      });
      notifyListeners();
    } catch (_) {
      await _markAiRequestFailed(null);
      trace = trace.copyWith(
        outcome: AiDecisionTraceOutcome.requestFailed,
        outcomeReason: _defaultOutcomeReason(
          AiDecisionTraceOutcome.requestFailed,
        ),
      );
      await _persistDecisionTrace(trace);
      _setErrorKey(StatusMessageKey.aiRequestFailed);
      notifyListeners();
    }
  }

  Future<void> _submitSuggestionDecision(AiDecisionType decision) async {
    final suggestion = _activeSuggestion;
    final snapshot = _activeSuggestionSnapshot;
    final traceId = _activeSuggestionTraceId;
    if (suggestion == null || snapshot == null || traceId == null) {
      return;
    }

    final decisionAt = _now();
    final episode = DecisionEpisode(
      recommendationId: suggestion.id,
      trigger: suggestion.trigger,
      decision: decision,
      occurredAt: decisionAt,
      contextSnapshot: snapshot,
    );
    await _recordTraceDecision(
      traceId,
      decision,
      decisionAt: decisionAt,
      overwriteExisting: true,
    );

    try {
      final feedback = await aiInferenceClient.sendFeedback(
        installId: _installId,
        config: _savedAiConnection!.endpointConfig,
        episode: episode,
        memoryProfile: _memoryProfile,
      );
      await _markAiRequestSucceeded();
      if (feedback.memoryProfile != null) {
        _memoryProfile = feedback.memoryProfile!;
        await aiMemoryService.saveMemoryProfile(_memoryProfile);
      }

      await _recordAction('ai.${decision.storageKey}');
    } on AiServiceException catch (error) {
      await _markAiRequestFailed(error.message);
      _setErrorKey(switch (error.code) {
        AiServiceErrorCode.notConfigured =>
          StatusMessageKey.aiConfigurationMissing,
        AiServiceErrorCode.timedOut => StatusMessageKey.aiRequestTimedOut,
        AiServiceErrorCode.requestFailed => StatusMessageKey.aiRequestFailed,
        AiServiceErrorCode.invalidResponse =>
          StatusMessageKey.aiInvalidResponse,
      });
      notifyListeners();
    } catch (_) {
      await _markAiRequestFailed(null);
      _setErrorKey(StatusMessageKey.aiRequestFailed);
      notifyListeners();
    }
  }

  void _clearSuggestionState({bool notify = true}) {
    _activeSuggestion = null;
    _activeSuggestionSnapshot = null;
    _activeSuggestionTraceId = null;
    _suggestionPanelVisible = false;
    if (notify) {
      notifyListeners();
    }
  }

  AiDecisionTrace _newDecisionTrace({
    required AiTriggerType trigger,
    required DateTime occurredAt,
    required List<AiDataSource> enabledDataSources,
  }) {
    _traceSequence += 1;
    return AiDecisionTrace(
      id: 'trace-${occurredAt.microsecondsSinceEpoch}-$_traceSequence',
      occurredAt: occurredAt,
      trigger: trigger,
      localeTag: effectiveLocale.toLanguageTag(),
      enabledDataSources: enabledDataSources,
      outcome: AiDecisionTraceOutcome.blockedByConfig,
    );
  }

  List<AiDataSource> _enabledTraceDataSources() {
    return supportedAiDataSources
        .where(_aiSettings.isEnabled)
        .toList(growable: false);
  }

  String _blockedReasonForCurrentAiState() {
    if (_aiSettings.mode == AiMode.off) {
      return 'AI suggestions are off.';
    }
    if (!hasSavedAiConnection) {
      return 'AI connection has not been saved.';
    }
    if (!canEnableAi) {
      return 'AI connection is not ready yet.';
    }
    return 'AI request was blocked before inference.';
  }

  String _defaultOutcomeReason(AiDecisionTraceOutcome outcome) {
    return switch (outcome) {
      AiDecisionTraceOutcome.suggested => 'AI produced a suggestion.',
      AiDecisionTraceOutcome.noSuggestion =>
        'AI returned shouldSuggest = false.',
      AiDecisionTraceOutcome.futureProtectionOnly =>
        'AI returned a future-protection-only suggestion.',
      AiDecisionTraceOutcome.timedOut => 'The AI request timed out.',
      AiDecisionTraceOutcome.requestFailed => 'The AI request failed.',
      AiDecisionTraceOutcome.invalidResponse =>
        'The AI response could not be parsed.',
      AiDecisionTraceOutcome.blockedByConfig =>
        'The trigger did not reach AI inference.',
    };
  }

  Future<void> _persistDecisionTrace(AiDecisionTrace trace) async {
    final nextTraces = [..._decisionTraces];
    final existingIndex = nextTraces.indexWhere((item) => item.id == trace.id);
    if (existingIndex == -1) {
      nextTraces.add(trace);
    } else {
      nextTraces[existingIndex] = trace;
    }
    nextTraces.sort(
      (left, right) => right.occurredAt.compareTo(left.occurredAt),
    );
    _decisionTraces = List.unmodifiable(nextTraces);
    try {
      await aiTraceStore.saveTrace(trace);
    } catch (_) {
      // Keep the in-memory trace even if the on-disk write failed.
    }
  }

  AiSettings _sanitizeAiSettings(AiSettings settings) {
    return settings.copyWith(
      dataSources: {
        for (final source in supportedAiDataSources)
          source: settings.isEnabled(source),
      },
    );
  }

  Future<List<AiDecisionTrace>> _sanitizeDecisionTraces(
    List<AiDecisionTrace> traces,
  ) async {
    var changed = false;
    final sanitized = <AiDecisionTrace>[];

    for (final trace in traces) {
      if (!supportedAiTriggers.contains(trace.trigger)) {
        changed = true;
        continue;
      }

      final filteredSources = trace.enabledDataSources
          .where((source) => supportedAiDataSources.contains(source))
          .toList(growable: false);
      final sanitizedTrace = trace.copyWith(
        enabledDataSources: filteredSources,
        collectedContext: _sanitizeSystemContext(trace.collectedContext),
        contextSnapshot: _sanitizeContextSnapshot(trace.contextSnapshot),
        recommendation: _sanitizeRecommendation(trace.recommendation),
      );

      if (!_traceSemanticallyEqual(trace, sanitizedTrace)) {
        changed = true;
      }
      sanitized.add(sanitizedTrace);
    }

    if (changed) {
      await aiTraceStore.clearTraces();
      for (final trace in sanitized) {
        await aiTraceStore.saveTrace(trace);
      }
    }

    sanitized.sort(
      (left, right) => right.occurredAt.compareTo(left.occurredAt),
    );
    return List.unmodifiable(sanitized);
  }

  SystemContextSnapshot? _sanitizeSystemContext(
    SystemContextSnapshot? snapshot,
  ) {
    if (snapshot == null) {
      return null;
    }

    return SystemContextSnapshot(
      collectedAt: snapshot.collectedAt,
      idleSeconds: snapshot.idleSeconds,
      accessibilityTrusted: snapshot.accessibilityTrusted,
      frontmostAppName: null,
      frontmostBundleId: null,
      frontmostWindowTitle: null,
      currentCalendarEvent: null,
      nextCalendarEvent: null,
      networkName: null,
      networkReachable: false,
      bluetoothDevices: const [],
    );
  }

  ContextSnapshot? _sanitizeContextSnapshot(ContextSnapshot? snapshot) {
    if (snapshot == null) {
      return null;
    }

    return ContextSnapshot(
      trigger: snapshot.trigger,
      occurredAt: snapshot.occurredAt,
      localeTag: snapshot.localeTag,
      hourOfDay: snapshot.hourOfDay,
      weekday: snapshot.weekday,
      recentActions: snapshot.recentActions,
      systemContext: _sanitizeSystemContext(snapshot.systemContext)!,
      focusSessionMinutes: snapshot.focusSessionMinutes,
      delayedLockSeconds: snapshot.delayedLockSeconds,
      explicitAction: snapshot.explicitAction,
    );
  }

  AiRecommendation? _sanitizeRecommendation(AiRecommendation? recommendation) {
    if (recommendation == null) {
      return null;
    }

    return recommendation.copyWith(
      usedSignals: recommendation.usedSignals
          .where(
            (signal) =>
                signal == AiSignalType.timeOfDay ||
                signal == AiSignalType.actionHistory ||
                signal == AiSignalType.idleState,
          )
          .toList(growable: false),
    );
  }

  bool _traceSemanticallyEqual(AiDecisionTrace left, AiDecisionTrace right) {
    return left.toJson().toString() == right.toJson().toString();
  }

  AiDecisionTrace? _traceById(String id) {
    for (final trace in _decisionTraces) {
      if (trace.id == id) {
        return trace;
      }
    }
    return null;
  }

  Future<void> _recordActiveSuggestionDecisionIfUnset(
    AiDecisionType decision,
  ) async {
    final traceId = _activeSuggestionTraceId;
    if (traceId == null) {
      return;
    }
    await _recordTraceDecision(
      traceId,
      decision,
      decisionAt: _now(),
      overwriteExisting: false,
    );
  }

  Future<void> _recordTraceDecision(
    String traceId,
    AiDecisionType decision, {
    required DateTime decisionAt,
    required bool overwriteExisting,
  }) async {
    final trace = _traceById(traceId);
    if (trace == null) {
      return;
    }
    if (!overwriteExisting && trace.userDecision != null) {
      return;
    }

    await _persistDecisionTrace(
      trace.copyWith(userDecision: decision, userDecisionAt: decisionAt),
    );
  }

  Future<void> _markAiRequestSucceeded() async {
    final savedConnection = _savedAiConnection;
    if (savedConnection == null) {
      return;
    }

    final updated = savedConnection.copyWith(
      lastHealthyAt: _now(),
      lastErrorMessage: null,
      lastErrorAt: null,
    );
    _savedAiConnection = updated;
    try {
      await aiMemoryService.saveSavedConnection(updated);
    } catch (_) {
      // Keep the in-memory state even if persistence fails.
    }
  }

  Future<void> _markAiRequestFailed(String? detail) async {
    final savedConnection = _savedAiConnection;
    if (savedConnection == null) {
      return;
    }

    final normalizedDetail = detail?.trim();
    final updated = savedConnection.copyWith(
      lastErrorMessage: normalizedDetail?.isEmpty ?? true
          ? null
          : normalizedDetail,
      lastErrorAt: _now(),
    );
    _savedAiConnection = updated;
    try {
      await aiMemoryService.saveSavedConnection(updated);
    } catch (_) {
      // Keep the in-memory state even if persistence fails.
    }
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

extension on Future<List<ActionHistoryEntry>> {
  Future<List<ActionHistoryEntry>> recentFirst() async {
    final entries = await this;
    final sorted = [...entries]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return sorted;
  }
}
