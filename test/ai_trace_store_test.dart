import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockbar/src/models/ai_models.dart';
import 'package:lockbar/src/services/ai_trace_store.dart';

void main() {
  test(
    'file system trace store persists traces as individual JSON files',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'lockbar-traces-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final store = FileSystemAiTraceStore(
        applicationSupportDirectoryProvider: () async => tempDirectory,
      );
      final olderTrace = AiDecisionTrace(
        id: 'trace-older',
        occurredAt: DateTime(2026, 3, 28, 9),
        trigger: AiTriggerType.focusEnded,
        localeTag: 'en',
        enabledDataSources: const [AiDataSource.actionHistory],
        outcome: AiDecisionTraceOutcome.noSuggestion,
      );
      final newerTrace = AiDecisionTrace(
        id: 'trace-newer',
        occurredAt: DateTime(2026, 3, 28, 10),
        trigger: AiTriggerType.workdayEnded,
        localeTag: 'en',
        enabledDataSources: const [AiDataSource.actionHistory],
        outcome: AiDecisionTraceOutcome.suggested,
        recommendation: AiRecommendation(
          id: 'rec-1',
          trigger: AiTriggerType.workdayEnded,
          headline: 'Ready to lock?',
          reason: 'The workday just ended.',
          confidence: 0.8,
          usedSignals: const [AiSignalType.timeOfDay],
          createdAt: DateTime(2026, 3, 28, 10),
        ),
      );

      await store.saveTrace(olderTrace);
      await store.saveTrace(newerTrace);

      final loaded = await store.loadTraces();
      expect(loaded.map((trace) => trace.id), ['trace-newer', 'trace-older']);

      final traceDirectory = Directory(
        '${tempDirectory.path}/LockBar/ai-traces',
      );
      expect(await traceDirectory.exists(), isTrue);
      expect(
        await File('${traceDirectory.path}/trace-newer.json').exists(),
        isTrue,
      );
      expect(
        await File('${traceDirectory.path}/trace-older.json').exists(),
        isTrue,
      );
    },
  );
}
