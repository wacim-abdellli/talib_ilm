import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/islamic_quiz_models.dart';

/// Service to load and manage offline JSON question dumps.
/// Enables infinite offline expansion of the Islamic question bank from JSON dumps.
class QuizDumpService {
  QuizDumpService._();
  static final QuizDumpService instance = QuizDumpService._();

  static const String dumpAssetPath = 'assets/data/quiz_questions_dump.json';

  final Map<String, List<QuizQuestion>> _dumpQuestionsByLevel = {};
  final Map<String, List<QuizQuestion>> _dumpQuestionsByFan = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

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

  /// Loads questions directly from a JSON string. Returns count of loaded questions.
  int loadFromString(String jsonString) {
    try {
      final dynamic decoded = json.decode(jsonString);
      int loadedCount = 0;

      if (decoded is Map<String, dynamic>) {
        final questionsList = decoded['questions'] as List<dynamic>?;
        if (questionsList != null) {
          for (final qJson in questionsList) {
            if (qJson is Map<String, dynamic>) {
              final question = QuizQuestion.fromJson(qJson);
              final rawLevelId = question.levelId ?? qJson['levelId'] as String? ?? 'general';
              final levelId = normalizeLevelId(rawLevelId);
              final rawFan = question.fanId ?? qJson['fanId'] as String? ?? levelId.split('_').first;
              final fanId = normalizeFanId(rawFan);

              _dumpQuestionsByLevel
                  .putIfAbsent(levelId, () => [])
                  .add(question);
              _dumpQuestionsByFan
                  .putIfAbsent(fanId, () => [])
                  .add(question);
              loadedCount++;
            }
          }
        }
      }
      _isLoaded = true;
      return loadedCount;
    } catch (e) {
      debugPrint('QuizDumpService: parse error: $e');
      return 0;
    }
  }

  /// Loads the offline questions dump from assets/data/quiz_questions_dump.json
  Future<void> loadDump() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(dumpAssetPath);
      loadFromString(jsonString);
    } catch (e) {
      debugPrint('QuizDumpService: dump asset load note: $e');
      _isLoaded = true;
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
    _isLoaded = false;
  }

  int get totalDumpQuestionsCount =>
      _dumpQuestionsByLevel.values.fold(0, (sum, list) => sum + list.length);
}
