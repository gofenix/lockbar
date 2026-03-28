import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_models.dart';

abstract class AiMemoryService {
  Future<String> loadInstallId();

  Future<AiSettings> loadSettings();

  Future<void> saveSettings(AiSettings settings);

  Future<MemoryProfile> loadMemoryProfile();

  Future<void> saveMemoryProfile(MemoryProfile profile);

  Future<List<ActionHistoryEntry>> loadActionHistory();

  Future<void> saveActionHistory(List<ActionHistoryEntry> entries);

  Future<bool> loadPrimaryActionTipSeen();

  Future<void> savePrimaryActionTipSeen(bool seen);

  Future<AiSavedConnection?> loadSavedConnection();

  Future<void> saveSavedConnection(AiSavedConnection connection);

  Future<void> clearSavedConnection();

  Future<AiEndpointConfig> loadConnectionDraftDefaults();

  Future<AiEndpointConfig> loadEndpointConfig();

  Future<void> saveEndpointConfig(AiEndpointConfig config);

  Future<void> clearEndpointConfig();

  Future<AiConnectionVerification?> loadConnectionVerification();

  Future<void> saveConnectionVerification(
    AiConnectionVerification verification,
  );

  Future<void> clearConnectionVerification();

  Future<void> resetMemory();
}

class SharedPreferencesAiMemoryService implements AiMemoryService {
  static const _installIdKey = 'lockbar.ai.installId';
  static const _settingsKey = 'lockbar.ai.settings';
  static const _memoryProfileKey = 'lockbar.ai.memoryProfile';
  static const _actionHistoryKey = 'lockbar.ai.actionHistory';
  static const _primaryActionTipSeenKey = 'lockbar.app.primaryActionTipSeen';
  static const _savedConnectionKey = 'lockbar.ai.connection';
  static const _endpointBaseUrlKey = 'lockbar.ai.endpoint.baseUrl';
  static const _endpointApiKeyKey = 'lockbar.ai.endpoint.apiKey';
  static const _connectionVerificationKey = 'lockbar.ai.endpoint.verification';
  static const _defaultAiModel = 'MiniMax-M2.7';

  @override
  Future<String> loadInstallId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_installIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateInstallId();
    await preferences.setString(_installIdKey, generated);
    return generated;
  }

  @override
  Future<AiSettings> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return AiSettings.defaults();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AiSettings.fromJson(decoded);
  }

  @override
  Future<void> saveSettings(AiSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<MemoryProfile> loadMemoryProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_memoryProfileKey);
    if (raw == null || raw.isEmpty) {
      return MemoryProfile.empty();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return MemoryProfile.fromJson(decoded);
  }

  @override
  Future<void> saveMemoryProfile(MemoryProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _memoryProfileKey,
      jsonEncode(profile.toJson()),
    );
  }

  @override
  Future<List<ActionHistoryEntry>> loadActionHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_actionHistoryKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ActionHistoryEntry.fromJson)
        .toList();
  }

  @override
  Future<void> saveActionHistory(List<ActionHistoryEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    final normalized = entries
        .take(40)
        .map((entry) => entry.toJson())
        .toList(growable: false);
    await preferences.setString(_actionHistoryKey, jsonEncode(normalized));
  }

  @override
  Future<bool> loadPrimaryActionTipSeen() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_primaryActionTipSeenKey) ?? false;
  }

  @override
  Future<void> savePrimaryActionTipSeen(bool seen) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_primaryActionTipSeenKey, seen);
  }

  @override
  Future<AiSavedConnection?> loadSavedConnection() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_savedConnectionKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AiSavedConnection.fromJson(decoded);
    }

    final migrated = await _migrateLegacySavedConnection(preferences);
    return migrated;
  }

  @override
  Future<void> saveSavedConnection(AiSavedConnection connection) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _savedConnectionKey,
      jsonEncode(connection.toJson()),
    );
    await _clearLegacyConnectionKeys(preferences);
  }

  @override
  Future<void> clearSavedConnection() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_savedConnectionKey);
    await _clearLegacyConnectionKeys(preferences);
  }

  @override
  Future<AiEndpointConfig> loadConnectionDraftDefaults() async {
    final savedConnection = await loadSavedConnection();
    if (savedConnection != null) {
      return savedConnection.endpointConfig;
    }

    final preferences = await SharedPreferences.getInstance();
    final baseUrl = preferences.getString(_endpointBaseUrlKey) ?? '';
    final apiKey = preferences.getString(_endpointApiKeyKey) ?? '';
    return AiEndpointConfig(baseUrl: baseUrl, apiKey: apiKey);
  }

  @override
  Future<AiEndpointConfig> loadEndpointConfig() async {
    return loadConnectionDraftDefaults();
  }

  @override
  Future<void> saveEndpointConfig(AiEndpointConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_endpointBaseUrlKey, config.normalizedBaseUrl);
    await preferences.setString(_endpointApiKeyKey, config.apiKey.trim());
  }

  @override
  Future<void> clearEndpointConfig() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_endpointBaseUrlKey);
    await preferences.remove(_endpointApiKeyKey);
  }

  @override
  Future<AiConnectionVerification?> loadConnectionVerification() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_connectionVerificationKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AiConnectionVerification.fromJson(decoded);
  }

  @override
  Future<void> saveConnectionVerification(
    AiConnectionVerification verification,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _connectionVerificationKey,
      jsonEncode(verification.toJson()),
    );
  }

  @override
  Future<void> clearConnectionVerification() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_connectionVerificationKey);
  }

  @override
  Future<void> resetMemory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_memoryProfileKey);
    await preferences.remove(_actionHistoryKey);
  }

  String _generateInstallId() {
    final random = Random.secure();
    final entropy = List<int>.generate(8, (_) => random.nextInt(256));
    final suffix = entropy
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'lb-${DateTime.now().millisecondsSinceEpoch}-$suffix';
  }

  Future<AiSavedConnection?> _migrateLegacySavedConnection(
    SharedPreferences preferences,
  ) async {
    final baseUrl = preferences.getString(_endpointBaseUrlKey) ?? '';
    final apiKey = preferences.getString(_endpointApiKeyKey) ?? '';
    if (baseUrl.trim().isEmpty || apiKey.trim().isEmpty) {
      return null;
    }

    final rawVerification = preferences.getString(_connectionVerificationKey);
    final verification = rawVerification == null || rawVerification.isEmpty
        ? null
        : AiConnectionVerification.fromJson(
            jsonDecode(rawVerification) as Map<String, dynamic>,
          );
    if (verification == null) {
      return null;
    }

    final migrated = AiSavedConnection(
      baseUrl: baseUrl.trim(),
      apiKey: apiKey.trim(),
      model: _defaultAiModel,
      verifiedAt: verification.verifiedAt,
      lastHealthyAt: verification.verifiedAt,
    );
    await preferences.setString(
      _savedConnectionKey,
      jsonEncode(migrated.toJson()),
    );
    await _clearLegacyConnectionKeys(preferences);
    return migrated;
  }

  Future<void> _clearLegacyConnectionKeys(SharedPreferences preferences) async {
    await preferences.remove(_endpointBaseUrlKey);
    await preferences.remove(_endpointApiKeyKey);
    await preferences.remove(_connectionVerificationKey);
  }
}
