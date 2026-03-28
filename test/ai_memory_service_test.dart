import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/services/ai_memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migrates a legacy verified connection into the saved connection document',
    () async {
      SharedPreferences.setMockInitialValues({
        'lockbar.ai.endpoint.baseUrl': 'https://api.minimaxi.com/anthropic',
        'lockbar.ai.endpoint.apiKey': 'legacy-key',
        'lockbar.ai.endpoint.verification': jsonEncode({
          'configFingerprint': 'legacy-fingerprint',
          'verifiedAt': '2026-03-28T09:30:00.000',
        }),
      });
      final service = SharedPreferencesAiMemoryService();

      final savedConnection = await service.loadSavedConnection();
      final preferences = await SharedPreferences.getInstance();

      expect(savedConnection, isNotNull);
      expect(
        savedConnection?.normalizedBaseUrl,
        'https://api.minimaxi.com/anthropic',
      );
      expect(savedConnection?.apiKey, 'legacy-key');
      expect(savedConnection?.model, 'MiniMax-M2.7');
      expect(savedConnection?.verifiedAt, DateTime(2026, 3, 28, 9, 30));
      expect(savedConnection?.lastHealthyAt, DateTime(2026, 3, 28, 9, 30));
      expect(preferences.getString('lockbar.ai.connection'), isNotNull);
      expect(preferences.getString('lockbar.ai.endpoint.baseUrl'), isNull);
      expect(preferences.getString('lockbar.ai.endpoint.apiKey'), isNull);
      expect(preferences.getString('lockbar.ai.endpoint.verification'), isNull);
    },
  );

  test('legacy unverified config is used only as draft defaults', () async {
    SharedPreferences.setMockInitialValues({
      'lockbar.ai.endpoint.baseUrl': 'https://api.minimaxi.com/anthropic',
      'lockbar.ai.endpoint.apiKey': 'draft-key',
    });
    final service = SharedPreferencesAiMemoryService();

    final savedConnection = await service.loadSavedConnection();
    final draftDefaults = await service.loadConnectionDraftDefaults();

    expect(savedConnection, isNull);
    expect(
      draftDefaults.normalizedBaseUrl,
      'https://api.minimaxi.com/anthropic',
    );
    expect(draftDefaults.apiKey, 'draft-key');
  });
}
