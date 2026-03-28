import 'dart:convert';
import 'dart:io';

import '../models/ai_models.dart';

enum AiServiceErrorCode { notConfigured, requestFailed, invalidResponse }

class AiServiceException implements Exception {
  const AiServiceException(this.code, this.message, {this.debug});

  final AiServiceErrorCode code;
  final String message;
  final AiInferenceExchangeDebug? debug;

  AiConnectionStatus get connectionStatus => switch (code) {
    AiServiceErrorCode.notConfigured => AiConnectionStatus.notConfigured,
    AiServiceErrorCode.requestFailed ||
    AiServiceErrorCode.invalidResponse => AiConnectionStatus.offline,
  };

  @override
  String toString() => 'AiServiceException($code): $message';
}

abstract class AiInferenceClient {
  String get model;

  Future<void> testConnection({required AiEndpointConfig config});

  Future<AiRecommendationResult> recommend({
    required String installId,
    required AiEndpointConfig config,
    required ContextSnapshot snapshot,
    required MemoryProfile memoryProfile,
    required bool allowLocalFallback,
  });

  Future<AiFeedbackResult> sendFeedback({
    required String installId,
    required AiEndpointConfig config,
    required DecisionEpisode episode,
    required MemoryProfile memoryProfile,
  });
}

class AdaptiveAiInferenceClient implements AiInferenceClient {
  AdaptiveAiInferenceClient({HttpClient? httpClient, String? model})
    : _httpClient = httpClient ?? HttpClient(),
      _model = (model ?? _defaultModel).trim().isEmpty
          ? _defaultModel
          : (model ?? _defaultModel).trim();

  static const _defaultModel = 'MiniMax-M2.7';

  final HttpClient _httpClient;
  final String _model;

  @override
  String get model => _model;

  @override
  Future<void> testConnection({required AiEndpointConfig config}) async {
    final exchange = await _postMessages(
      config: config,
      systemPrompt:
          'Return a tiny plain-text acknowledgement so the client can verify connectivity.',
      userPrompt: 'Reply with exactly: OK',
      maxTokens: 128,
    );
    final text = _extractTextContent(
      exchange.responseJson,
      debug: exchange.debug,
    );
    if (text.isEmpty) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI connection test returned empty text.',
        debug: exchange.debug,
      );
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
    final exchange = await _postMessages(
      config: config,
      systemPrompt: _recommendationSystemPrompt,
      userPrompt: _recommendationUserPrompt(
        installId: installId,
        snapshot: snapshot,
        memoryProfile: memoryProfile,
      ),
      maxTokens: 700,
    );
    final decoded = _decodeJsonObject(
      _extractTextContent(exchange.responseJson, debug: exchange.debug),
      debug: exchange.debug,
    );
    final shouldSuggest = decoded['shouldSuggest'] as bool? ?? false;
    final rawRecommendation =
        decoded['recommendation'] as Map<String, dynamic>?;
    final decisionReason = decoded['decisionReason'] as String?;

    return AiRecommendationResult(
      connectionStatus: AiConnectionStatus.online,
      recommendation: shouldSuggest
          ? _buildRecommendation(
              snapshot: snapshot,
              payload: rawRecommendation,
              responseId: exchange.responseJson['id'] as String?,
            )
          : null,
      memoryProfile: memoryProfile,
      exchangeDebug: exchange.debug.copyWith(parsedResponse: decoded),
      decisionReason: decisionReason,
    );
  }

  @override
  Future<AiFeedbackResult> sendFeedback({
    required String installId,
    required AiEndpointConfig config,
    required DecisionEpisode episode,
    required MemoryProfile memoryProfile,
  }) async {
    final nextMetrics = _bumpMetrics(
      memoryProfile.metrics,
      episode.trigger,
      episode.decision,
    );
    final exchange = await _postMessages(
      config: config,
      systemPrompt: _feedbackSystemPrompt,
      userPrompt: _feedbackUserPrompt(
        installId: installId,
        episode: episode,
        nextMetrics: nextMetrics,
        memoryProfile: memoryProfile,
      ),
      maxTokens: 400,
    );
    final decoded = _decodeJsonObject(
      _extractTextContent(exchange.responseJson, debug: exchange.debug),
      debug: exchange.debug,
    );
    final summary = decoded['summary'] as String?;
    final habits = (decoded['habits'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    if (summary == null) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI feedback omitted the required summary field.',
        debug: exchange.debug.copyWith(parsedResponse: decoded),
      );
    }

    return AiFeedbackResult(
      connectionStatus: AiConnectionStatus.online,
      memoryProfile: MemoryProfile(
        summary: summary,
        habits: habits,
        metrics: nextMetrics,
        updatedAt: episode.occurredAt,
      ),
      exchangeDebug: exchange.debug.copyWith(parsedResponse: decoded),
    );
  }

  Future<_AiMessageExchange> _postMessages({
    required AiEndpointConfig config,
    required String systemPrompt,
    required String userPrompt,
    required int maxTokens,
  }) async {
    final runtimeConfig = _AiRuntimeConfig.fromEndpointConfig(
      config,
      model: _model,
    ).requireConfigured();
    final uri = runtimeConfig.messagesUri;
    final requestBody = _buildRequestBody(
      model: runtimeConfig.model,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      maxTokens: maxTokens,
    );
    final request = await _httpClient.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.headers.set('x-api-key', runtimeConfig.apiKey);
    request.headers.set('anthropic-version', '2023-06-01');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.add(utf8.encode(jsonEncode(requestBody)));

    final response = await request.close().timeout(const Duration(seconds: 6));
    final body = await response.transform(utf8.decoder).join();
    final debug = AiInferenceExchangeDebug(
      model: runtimeConfig.model,
      baseUrl: runtimeConfig.baseUrl,
      requestBody: requestBody,
      rawResponseText: body,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiServiceException(
        AiServiceErrorCode.requestFailed,
        _extractErrorMessage(body, response.statusCode),
        debug: debug,
      );
    }

    if (body.isEmpty) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI response body was empty.',
        debug: debug,
      );
    }

    final decoded = _tryDecodeJson(body);
    if (decoded is! Map<String, dynamic>) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI response was not a JSON object.',
        debug: debug,
      );
    }
    return _AiMessageExchange(
      responseJson: decoded,
      debug: debug.copyWith(parsedResponse: decoded),
    );
  }

  AiRecommendation _buildRecommendation({
    required ContextSnapshot snapshot,
    required Map<String, dynamic>? payload,
    required String? responseId,
  }) {
    if (payload == null) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI said it had a suggestion but did not return one.',
      );
    }

    final headline = payload['headline'] as String?;
    final reason = payload['reason'] as String?;
    if (headline == null || reason == null) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI recommendation omitted the required headline or reason.',
      );
    }

    return AiRecommendation(
      id: responseId == null
          ? 'msg-${DateTime.now().millisecondsSinceEpoch}'
          : 'msg-$responseId',
      trigger: snapshot.trigger,
      headline: headline,
      reason: reason,
      confidence: _parseConfidence(payload['confidence']),
      usedSignals: _parseSignals(payload['usedSignals']),
      createdAt: snapshot.occurredAt,
      futureProtectionOnly: payload['futureProtectionOnly'] as bool? ?? false,
      preferredDelaySeconds: _parsePreferredDelaySeconds(
        payload['preferredDelaySeconds'],
      ),
    );
  }

  double _parseConfidence(Object? value) {
    final raw = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text),
      _ => null,
    };
    if (raw == null) {
      return 0.5;
    }
    if (raw < 0) {
      return 0;
    }
    if (raw > 1) {
      return 1;
    }
    return raw;
  }

  List<AiSignalType> _parseSignals(Object? rawSignals) {
    return (rawSignals as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(AiSignalType.fromStorageKey)
        .whereType<AiSignalType>()
        .where(
          (signal) =>
              signal == AiSignalType.timeOfDay ||
              signal == AiSignalType.actionHistory ||
              signal == AiSignalType.idleState,
        )
        .toList(growable: false);
  }

  int _parsePreferredDelaySeconds(Object? value) {
    final seconds = switch (value) {
      int integer => integer,
      num number => number.toInt(),
      String text => int.tryParse(text) ?? 120,
      _ => 120,
    };
    if (seconds >= 300) {
      return 300;
    }
    return seconds >= 120 ? 120 : 120;
  }

  String _extractTextContent(
    Map<String, dynamic> response, {
    AiInferenceExchangeDebug? debug,
  }) {
    final blocks = response['content'] as List<dynamic>? ?? const [];
    final buffer = StringBuffer();
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'text') {
        final text = block['text'] as String?;
        if (text != null) {
          buffer.write(text);
        }
      }
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI response did not contain any text content.',
        debug: debug,
      );
    }
    return text;
  }

  Map<String, dynamic> _decodeJsonObject(
    String text, {
    AiInferenceExchangeDebug? debug,
  }) {
    var candidate = text.trim();
    final fenced = RegExp(
      r'^```(?:json)?\s*([\s\S]*?)\s*```$',
    ).firstMatch(candidate);
    if (fenced != null) {
      candidate = fenced.group(1)!.trim();
    }

    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI response was not valid JSON.',
        debug: debug,
      );
    }

    final decoded = _tryDecodeJson(candidate.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) {
      throw AiServiceException(
        AiServiceErrorCode.invalidResponse,
        'AI response JSON was not an object.',
        debug: debug,
      );
    }
    return decoded;
  }

  Object? _tryDecodeJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required String model,
    required String systemPrompt,
    required String userPrompt,
    required int maxTokens,
  }) {
    return {
      'model': model,
      'max_tokens': maxTokens,
      'temperature': 0.2,
      'system': systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userPrompt},
          ],
        },
      ],
    };
  }

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'] as String?;
          if (message != null && message.isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // Fall back to a generic message below.
    }
    return 'AI request failed with status $statusCode.';
  }

  Map<String, int> _bumpMetrics(
    Map<String, int> current,
    AiTriggerType trigger,
    AiDecisionType decision,
  ) {
    final next = Map<String, int>.from(current);
    void bump(String key) {
      next[key] = (next[key] ?? 0) + 1;
    }

    bump(decision.storageKey);
    bump('${trigger.storageKey}.${decision.storageKey}');
    return next;
  }

  String _recommendationUserPrompt({
    required String installId,
    required ContextSnapshot snapshot,
    required MemoryProfile memoryProfile,
  }) {
    return '''
Install ID: $installId
Locale: ${snapshot.localeTag}

Return JSON only.

Snapshot:
${jsonEncode(snapshot.toJson())}

Current memory profile:
${jsonEncode(memoryProfile.toJson())}
''';
  }

  String _feedbackUserPrompt({
    required String installId,
    required DecisionEpisode episode,
    required Map<String, int> nextMetrics,
    required MemoryProfile memoryProfile,
  }) {
    return '''
Install ID: $installId
Locale: ${episode.contextSnapshot.localeTag}

Return JSON only.

Decision episode:
${jsonEncode(episode.toJson())}

Current memory profile:
${jsonEncode(memoryProfile.toJson())}

Metrics after applying this decision:
${jsonEncode(nextMetrics)}
''';
  }
}

class _AiRuntimeConfig {
  const _AiRuntimeConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  factory _AiRuntimeConfig.fromEndpointConfig(
    AiEndpointConfig config, {
    required String model,
  }) {
    return _AiRuntimeConfig(
      apiKey: config.apiKey.trim(),
      baseUrl: config.normalizedBaseUrl,
      model: model,
    );
  }

  _AiRuntimeConfig requireConfigured() {
    if (apiKey.isEmpty) {
      throw const AiServiceException(
        AiServiceErrorCode.notConfigured,
        'No AI API key was configured.',
      );
    }
    if (baseUrl.trim().isEmpty) {
      throw const AiServiceException(
        AiServiceErrorCode.notConfigured,
        'No AI base URL was configured.',
      );
    }
    return this;
  }

  Uri get messagesUri {
    final trimmed = baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/v1/messages')) {
      return Uri.parse(trimmed);
    }
    if (trimmed.endsWith('/v1')) {
      return Uri.parse('$trimmed/messages');
    }
    return Uri.parse('$trimmed/v1/messages');
  }
}

class _AiMessageExchange {
  const _AiMessageExchange({required this.responseJson, required this.debug});

  final Map<String, dynamic> responseJson;
  final AiInferenceExchangeDebug debug;
}

const _recommendationSystemPrompt = '''
You are LockBar Memory Coach.
Decide whether LockBar should show a lock suggestion for the provided context snapshot.
Return only valid JSON with this exact shape:
{
  "shouldSuggest": true,
  "decisionReason": "short localized explanation of the decision",
  "recommendation": {
    "headline": "short localized text",
    "reason": "one short localized explanation",
    "usedSignals": ["timeOfDay"],
    "futureProtectionOnly": false,
    "preferredDelaySeconds": 120,
    "confidence": 0.78
  }
}

Rules:
- Never output markdown.
- Use the same language as the provided locale.
- Keep headline concise and reason to one or two short sentences.
- decisionReason is always required, even if shouldSuggest is false.
- If the trigger is awayReturned or another after-the-fact trigger, do not suggest locking now. Set futureProtectionOnly to true.
- If no suggestion should be shown, return {"shouldSuggest": false, "decisionReason": "short localized explanation", "recommendation": null}.
- preferredDelaySeconds must be either 120 or 300.
- confidence must be a number between 0 and 1.
- usedSignals may only include: timeOfDay, actionHistory, idleState.
''';

const _feedbackSystemPrompt = '''
You are LockBar Memory Coach.
Update the user's memory summary after a decision episode.
Return only valid JSON with this exact shape:
{
  "summary": "short localized summary",
  "habits": ["prefers_buffer_after_focus"]
}

Rules:
- Never output markdown.
- Use the same language as the provided locale.
- habits may only include: prefers_buffer_after_focus, prefers_runway_after_workday, responds_better_to_earlier_prompts.
- Be conservative. If the evidence is weak, return an empty habits array.
- Keep the summary short and factual.
''';
