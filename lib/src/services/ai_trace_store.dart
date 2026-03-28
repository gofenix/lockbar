import 'dart:convert';
import 'dart:io';

import '../models/ai_models.dart';

abstract class AiTraceStore {
  Future<List<AiDecisionTrace>> loadTraces();

  Future<void> saveTrace(AiDecisionTrace trace);

  Future<void> clearTraces();
}

class InMemoryAiTraceStore implements AiTraceStore {
  List<AiDecisionTrace> _traces = const [];

  @override
  Future<void> clearTraces() async {
    _traces = const [];
  }

  @override
  Future<List<AiDecisionTrace>> loadTraces() async => _traces;

  @override
  Future<void> saveTrace(AiDecisionTrace trace) async {
    final next = [..._traces];
    final existingIndex = next.indexWhere((item) => item.id == trace.id);
    if (existingIndex == -1) {
      next.add(trace);
    } else {
      next[existingIndex] = trace;
    }
    next.sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
    _traces = List.unmodifiable(next);
  }
}

class FileSystemAiTraceStore implements AiTraceStore {
  FileSystemAiTraceStore({
    required Future<Directory> Function() applicationSupportDirectoryProvider,
  }) : _applicationSupportDirectoryProvider =
           applicationSupportDirectoryProvider;

  final Future<Directory> Function() _applicationSupportDirectoryProvider;

  @override
  Future<List<AiDecisionTrace>> loadTraces() async {
    final directory = await _traceDirectory();
    if (!await directory.exists()) {
      return const [];
    }

    final traces = <AiDecisionTrace>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }

      try {
        final raw = await entity.readAsString();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final trace = AiDecisionTrace.fromJson(decoded);
        if (trace != null) {
          traces.add(trace);
        }
      } catch (_) {
        // Ignore malformed trace files and continue loading the rest.
      }
    }

    traces.sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
    return traces;
  }

  @override
  Future<void> saveTrace(AiDecisionTrace trace) async {
    final directory = await _traceDirectory();
    await directory.create(recursive: true);
    final file = File('${directory.path}/${_safeFileName(trace.id)}.json');
    await file.writeAsString(jsonEncode(trace.toJson()));
  }

  @override
  Future<void> clearTraces() async {
    final directory = await _traceDirectory();
    if (!await directory.exists()) {
      return;
    }

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.json')) {
        await entity.delete();
      }
    }
  }

  Future<Directory> _traceDirectory() async {
    final supportDirectory = await _applicationSupportDirectoryProvider();
    return Directory('${supportDirectory.path}/LockBar/ai-traces');
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}
