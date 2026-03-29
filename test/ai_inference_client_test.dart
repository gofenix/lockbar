import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/models/ai_models.dart';
import 'package:lockbar/src/services/ai_inference_client.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test(
    'recommend uses Anthropic messages payload and parses a suggestion',
    () async {
      server.listen((request) async {
        expect(request.uri.path, '/anthropic/v1/messages');
        expect(request.headers.value('x-api-key'), 'test-key');
        expect(request.headers.value('anthropic-version'), '2023-06-01');

        final rawBody = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(rawBody) as Map<String, dynamic>;
        expect(payload['model'], 'MiniMax-M2.7');
        expect(payload['messages'], isNotEmpty);

        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'id': 'msg_123',
            'content': [
              {
                'type': 'text',
                'text':
                    '{"shouldSuggest":true,"decisionReason":"The focus session just ended and your recent actions suggest a lock window.","recommendation":{"headline":"Ready to lock?","reason":"You just wrapped a focus block.","usedSignals":["timeOfDay","actionHistory"],"futureProtectionOnly":false,"preferredDelaySeconds":120,"confidence":0.78}}',
              },
            ],
          }),
        );
        await request.response.close();
      });

      final client = AdaptiveAiInferenceClient(model: 'MiniMax-M2.7');

      final result = await client.recommend(
        installId: 'install-1',
        config: AiEndpointConfig(
          baseUrl: 'http://127.0.0.1:${server.port}/anthropic',
          apiKey: 'test-key',
        ),
        snapshot: ContextSnapshot(
          trigger: AiTriggerType.focusEnded,
          occurredAt: DateTime(2026, 1, 1, 10),
          localeTag: 'en',
          hourOfDay: 10,
          weekday: DateTime.thursday,
          recentActions: const ['focus.end.25m'],
          systemContext: SystemContextSnapshot(
            collectedAt: DateTime(2026, 1, 1, 10),
            idleSeconds: 12,
            bluetoothDevices: const [],
            networkReachable: true,
          ),
          focusSessionMinutes: 25,
        ),
        memoryProfile: MemoryProfile.empty(),
        allowLocalFallback: false,
      );

      expect(result.connectionStatus, AiConnectionStatus.online);
      expect(result.recommendation, isNotNull);
      expect(result.recommendation!.headline, 'Ready to lock?');
      expect(result.recommendation!.usedSignals, [
        AiSignalType.timeOfDay,
        AiSignalType.actionHistory,
      ]);
      expect(
        result.decisionReason,
        'The focus session just ended and your recent actions suggest a lock window.',
      );
      expect(result.exchangeDebug?.requestBody['model'], 'MiniMax-M2.7');
      expect(
        jsonEncode(result.exchangeDebug?.requestBody),
        isNot(contains('test-key')),
      );
      expect(result.exchangeDebug?.parsedResponse, isA<Map<String, dynamic>>());
    },
  );

  test('sendFeedback updates memory summary from AI output', () async {
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'id': 'msg_456',
          'content': [
            {
              'type': 'text',
              'text':
                  '{"summary":"You usually leave a short buffer after focus blocks.","habits":["prefers_buffer_after_focus"]}',
            },
          ],
        }),
      );
      await request.response.close();
    });

    final client = AdaptiveAiInferenceClient();

    final feedback = await client.sendFeedback(
      installId: 'install-2',
      config: AiEndpointConfig(
        baseUrl: 'http://127.0.0.1:${server.port}/anthropic',
        apiKey: 'test-key',
      ),
      episode: DecisionEpisode(
        recommendationId: 'rec-1',
        trigger: AiTriggerType.focusEnded,
        decision: AiDecisionType.laterTwoMinutes,
        occurredAt: DateTime(2026, 1, 1, 11),
        contextSnapshot: ContextSnapshot(
          trigger: AiTriggerType.focusEnded,
          occurredAt: DateTime(2026, 1, 1, 11),
          localeTag: 'en',
          hourOfDay: 11,
          weekday: DateTime.thursday,
          recentActions: const ['focus.end.25m'],
          systemContext: SystemContextSnapshot(
            collectedAt: DateTime(2026, 1, 1, 11),
            idleSeconds: 0,
            bluetoothDevices: const [],
            networkReachable: true,
          ),
        ),
      ),
      memoryProfile: MemoryProfile.empty(),
    );

    expect(feedback.connectionStatus, AiConnectionStatus.online);
    expect(
      feedback.memoryProfile?.summary,
      'You usually leave a short buffer after focus blocks.',
    );
    expect(
      feedback.memoryProfile?.habits,
      contains('prefers_buffer_after_focus'),
    );
    expect(feedback.memoryProfile?.metrics['laterTwoMinutes'], 1);
    expect(feedback.memoryProfile?.metrics['focusEnded.laterTwoMinutes'], 1);
    expect(
      jsonEncode(feedback.exchangeDebug?.requestBody),
      isNot(contains('test-key')),
    );
    expect(feedback.exchangeDebug?.parsedResponse, isA<Map<String, dynamic>>());
  });

  test(
    'testConnection sends a real Anthropic-compatible messages request',
    () async {
      server.listen((request) async {
        expect(request.uri.path, '/anthropic/v1/messages');
        expect(request.headers.value('x-api-key'), 'test-key');

        final rawBody = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(rawBody) as Map<String, dynamic>;
        expect(payload['model'], 'MiniMax-M2.7');
        expect(payload['max_tokens'], 128);

        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'id': 'msg_test',
            'content': [
              {'type': 'text', 'text': 'OK'},
            ],
          }),
        );
        await request.response.close();
      });

      final client = AdaptiveAiInferenceClient();

      await client.testConnection(
        config: AiEndpointConfig(
          baseUrl: 'http://127.0.0.1:${server.port}/anthropic',
          apiKey: 'test-key',
        ),
      );
    },
  );

  test('testConnection maps HTTP failures to requestFailed', () async {
    server.listen((request) async {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'error': {'message': 'Invalid API key.'},
        }),
      );
      await request.response.close();
    });

    final client = AdaptiveAiInferenceClient();

    expect(
      () => client.testConnection(
        config: AiEndpointConfig(
          baseUrl: 'http://127.0.0.1:${server.port}/anthropic',
          apiKey: 'bad-key',
        ),
      ),
      throwsA(
        isA<AiServiceException>()
            .having(
              (error) => error.code,
              'code',
              AiServiceErrorCode.requestFailed,
            )
            .having(
              (error) => error.message,
              'message',
              contains('Invalid API key.'),
            ),
      ),
    );
  });

  test(
    'recommend maps slow responses to timedOut and preserves request debug data',
    () async {
      server.listen((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'id': 'msg_slow',
            'content': [
              {
                'type': 'text',
                'text':
                    '{"shouldSuggest":false,"decisionReason":"Too slow to matter.","recommendation":null}',
              },
            ],
          }),
        );
        await request.response.close();
      });

      final client = AdaptiveAiInferenceClient(
        recommendationTimeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        () => client.recommend(
          installId: 'install-slow',
          config: AiEndpointConfig(
            baseUrl: 'http://127.0.0.1:${server.port}/anthropic',
            apiKey: 'test-key',
          ),
          snapshot: ContextSnapshot(
            trigger: AiTriggerType.awayReturned,
            occurredAt: DateTime(2026, 1, 1, 21),
            localeTag: 'en',
            hourOfDay: 21,
            weekday: DateTime.thursday,
            recentActions: const ['lock.now.primary'],
            systemContext: SystemContextSnapshot(
              collectedAt: DateTime(2026, 1, 1, 21),
              idleSeconds: 90,
              bluetoothDevices: const [],
              networkReachable: true,
            ),
          ),
          memoryProfile: MemoryProfile.empty(),
          allowLocalFallback: false,
        ),
        throwsA(
          isA<AiServiceException>()
              .having(
                (error) => error.code,
                'code',
                AiServiceErrorCode.timedOut,
              )
              .having(
                (error) => error.message,
                'message',
                contains('timed out'),
              )
              .having(
                (error) => error.debug?.requestBody['model'],
                'request model',
                'MiniMax-M2.7',
              )
              .having(
                (error) => error.debug?.rawResponseText,
                'rawResponseText',
                isNull,
              )
              .having(
                (error) => error.debug?.errorMessage,
                'errorMessage',
                contains('timed out'),
              ),
        ),
      );
    },
  );

  test(
    'testConnection attaches sanitized debug payload on invalid response',
    () async {
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'id': 'msg_test', 'content': []}));
        await request.response.close();
      });

      final client = AdaptiveAiInferenceClient();

      await expectLater(
        () => client.testConnection(
          config: AiEndpointConfig(
            baseUrl: 'http://127.0.0.1:${server.port}/anthropic',
            apiKey: 'test-key',
          ),
        ),
        throwsA(
          isA<AiServiceException>()
              .having(
                (error) => error.code,
                'code',
                AiServiceErrorCode.invalidResponse,
              )
              .having(
                (error) => jsonEncode(error.debug?.requestBody),
                'requestBody',
                isNot(contains('test-key')),
              )
              .having(
                (error) => error.debug?.rawResponseText,
                'rawResponseText',
                contains('"content":[]'),
              ),
        ),
      );
    },
  );

  test(
    'missing API key raises a configuration error instead of falling back',
    () async {
      final client = AdaptiveAiInferenceClient();

      expect(
        () => client.recommend(
          installId: 'install-3',
          config: AiEndpointConfig(
            baseUrl: 'http://127.0.0.1:${server.port}/anthropic',
            apiKey: '',
          ),
          snapshot: ContextSnapshot(
            trigger: AiTriggerType.workdayEnded,
            occurredAt: DateTime(2026, 1, 1, 18),
            localeTag: 'en',
            hourOfDay: 18,
            weekday: DateTime.thursday,
            recentActions: const ['workday.end'],
            systemContext: SystemContextSnapshot(
              collectedAt: DateTime(2026, 1, 1, 18),
              idleSeconds: 0,
              bluetoothDevices: const [],
              networkReachable: true,
            ),
          ),
          memoryProfile: MemoryProfile.empty(),
          allowLocalFallback: false,
        ),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.code,
            'code',
            AiServiceErrorCode.notConfigured,
          ),
        ),
      );
    },
  );
}
