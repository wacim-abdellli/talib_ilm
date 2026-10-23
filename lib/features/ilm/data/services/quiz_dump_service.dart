import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/islamic_quiz_models.dart';

/// Loading status for the offline questions dump.
enum QuizDumpLoadStatus {
  unloaded,
  loading,
  success,
  failed,
  empty,
}

/// Service to load and manage offline JSON question dumps.
/// Enables infinite offline expansion of the Islamic question bank from JSON dumps.
class QuizDumpService {
  QuizDumpService._();
  static final QuizDumpService instance = QuizDumpService._();

  static const String dumpAssetPath = 'assets/data/quiz_questions_dump.json';

  final Map<String, List<QuizQuestion>> _dumpQuestionsByLevel = {};
  final Map<String, List<QuizQuestion>> _dumpQuestionsByFan = {};
  QuizDumpLoadStatus _status = QuizDumpLoadStatus.unloaded;
  Future<void>? _loadingFuture;

  /// Whether a valid questions dump is currently loaded and available.
  bool get isLoaded =>
      _status == QuizDumpLoadStatus.success || _status == QuizDumpLoadStatus.empty;

  /// Current loading status.
  QuizDumpLoadStatus get loadStatus => _status;

  /// Whether the last dump load operation failed and can be retried.
  bool get hasFailed => _status == QuizDumpLoadStatus.failed;

  /// Normalizes level IDs like 'aqidah_lvl_1' to the canonical catalog format 'aqidah_l1'.
  static String normalizeLevelId(String levelId) {
    return levelId
        .replaceAll('_lvl_', '_l')
        .replaceAll('_level_', '_l')
        .replaceAll('_level', '_l')
        .replaceAll('_lvl', '_l');
  }

  /// Normalizes fan IDs
  static String normalizeFanId(String fanId) {
    if (fanId == 'taj') return 'tajweed';
    if (fanId == 'prophets') return 'prophets_names';
    return fanId;
  }

  /// Loads questions directly from a JSON string with atomic validation and publication.
  /// If parsing fails or the schema is invalid, existing loaded caches are untouched.
  int loadFromString(String jsonString) {
    if (_status == QuizDumpLoadStatus.success && totalDumpQuestionsCount > 0) {
      return totalDumpQuestionsCount;
    }
    try {
      final dynamic decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        if (_status != QuizDumpLoadStatus.success) {
          _status = QuizDumpLoadStatus.failed;
        }
        return 0;
      }

      final questionsList = decoded['questions'];
      if (questionsList is! List<dynamic>) {
        if (_status != QuizDumpLoadStatus.success) {
          _status = QuizDumpLoadStatus.failed;
        }
        return 0;
      }

      final tempByLevel = <String, List<QuizQuestion>>{};
      final tempByFan = <String, List<QuizQuestion>>{};
      final seenIds = <String>{};
      int loadedCount = 0;

      for (final qJson in questionsList) {
        if (qJson is! Map<String, dynamic>) {
          throw const FormatException('Item in questions array is not a JSON object');
        }

        // Schema validation: verify presence and sanity of essential fields
        final qText = qJson['question'];
        final options = qJson['options'];
        final correctIndex = qJson['correctIndex'];
        if (qText is! String || qText.trim().isEmpty) {
          throw const FormatException('Question text is missing or blank');
        }
        if (options is! List || options.isEmpty) {
          throw const FormatException('Question options list is empty or invalid');
        }
        if (correctIndex is! int || correctIndex < 0 || correctIndex >= options.length) {
          throw const FormatException('Question correctIndex is out of options bounds');
        }

        final question = QuizQuestion.fromJson(qJson);
        // ID deduplication: skip duplicates within the dump without crashing
        if (!seenIds.add(question.id)) {
          continue;
        }

        final rawLevelId = question.levelId ?? qJson['levelId'] as String? ?? 'general';
        final levelId = normalizeLevelId(rawLevelId);
        final rawFan = question.fanId ?? qJson['fanId'] as String? ?? levelId.split('_').first;
        final fanId = normalizeFanId(rawFan);

        tempByLevel.putIfAbsent(levelId, () => []).add(question);
        tempByFan.putIfAbsent(fanId, () => []).add(question);
        loadedCount++;
      }

      // ATOMIC PUBLICATION: only replace active caches after complete validation
      _dumpQuestionsByLevel.clear();
      _dumpQuestionsByFan.clear();
      tempByLevel.forEach((k, v) => _dumpQuestionsByLevel[k] = List.unmodifiable(v));
      tempByFan.forEach((k, v) => _dumpQuestionsByFan[k] = List.unmodifiable(v));

      _status = loadedCount > 0 ? QuizDumpLoadStatus.success : QuizDumpLoadStatus.empty;
      return loadedCount;
    } catch (e) {
      debugPrint('QuizDumpService: parse error: $e');
      if (_status != QuizDumpLoadStatus.success) {
        _status = QuizDumpLoadStatus.failed;
      }
      return 0;
    }
  }

  /// Loads the offline questions dump from assets/data/quiz_questions_dump.json (or custom [assetPath]).
  /// Concurrent calls join the same in-flight Future.
  Future<void> loadDump({String assetPath = dumpAssetPath}) async {
    if (_status == QuizDumpLoadStatus.success && assetPath == dumpAssetPath) return;
    if (_loadingFuture != null) return _loadingFuture!;

    _loadingFuture = _doLoadDump(assetPath);
    return _loadingFuture!;
  }

  Future<void> _doLoadDump(String assetPath) async {
    _status = QuizDumpLoadStatus.loading;
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      loadFromString(jsonString);
    } catch (e) {
      debugPrint('QuizDumpService: dump asset load note: $e');
      // On asset load error, mark as failed so future retries are possible
      _status = QuizDumpLoadStatus.failed;
    } finally {
      _loadingFuture = null;
    }
  }

  /// Returns supplemental dump questions for a specific level.
  List<QuizQuestion> getQuestionsForLevel(String levelId) {
    final norm = normalizeLevelId(levelId);
    return _dumpQuestionsByLevel[norm] ?? _dumpQuestionsByLevel[levelId] ?? const [];
  }

  /// Returns supplemental dump questions for an entire discipline.
  List<QuizQuestion> getQuestionsForFan(String fanId) {
    final norm = normalizeFanId(fanId);
    return _dumpQuestionsByFan[norm] ?? _dumpQuestionsByFan[fanId] ?? const [];
  }

  /// Returns all supplemental dump questions across all disciplines.
  List<QuizQuestion> getAllDumpQuestions() {
    final all = <QuizQuestion>[];
    for (final list in _dumpQuestionsByLevel.values) {
      all.addAll(list);
    }
    return all;
  }

  List<QuizQuestion> get allQuestions => getAllDumpQuestions();

  /// Clears cache (useful for testing or reloading).
  void clear() => clearForTest();

  void clearForTest() {
    _dumpQuestionsByLevel.clear();
    _dumpQuestionsByFan.clear();
    _status = QuizDumpLoadStatus.unloaded;
    _loadingFuture = null;
  }

  int get totalDumpQuestionsCount =>
      _dumpQuestionsByLevel.values.fold(0, (sum, list) => sum + list.length);
}
