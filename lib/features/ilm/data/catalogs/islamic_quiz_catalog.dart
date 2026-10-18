import 'dart:math';

import '../models/islamic_quiz_models.dart';
import 'quiz_adab_catalog.dart';
import 'quiz_aqidah_catalog.dart';
import 'quiz_arabic_catalog.dart';
import 'quiz_fiqh_catalog.dart';
import 'quiz_hadith_catalog.dart';
import 'quiz_prophets_catalog.dart';
import 'quiz_quran_catalog.dart';
import 'quiz_seerah_catalog.dart';

/// The master catalog aggregating all authentic Islamic disciplines, levels, and questions.
class IslamicQuizCatalog {
  IslamicQuizCatalog._();

  static List<FanQuiz> get founoun => [
        QuizAqidahCatalog.aqidahFan,
        QuizFiqhCatalog.fiqhFan,
        QuizHadithCatalog.hadithFan,
        QuizQuranCatalog.quranFan,
        QuizSeerahCatalog.seerahFan,
        QuizProphetsCatalog.prophetsNamesFan,
        QuizAdabCatalog.adabFan,
        QuizArabicCatalog.arabicFan,
      ];

  static FanQuiz? getFan(String id) {
    for (final fan in founoun) {
      if (fan.id == id) return fan;
    }
    return null;
  }

  static QuizLevel? getLevel(String levelId) {
    for (final fan in founoun) {
      for (final level in fan.levels) {
        if (level.id == levelId) return level;
      }
    }
    return null;
  }

  static FanQuiz? getFanForLevel(String levelId) {
    for (final fan in founoun) {
      for (final level in fan.levels) {
        if (level.id == levelId) return fan;
      }
    }
    return null;
  }

  static int get totalQuestionsCount =>
      founoun.fold(0, (sum, fan) => sum + fan.totalQuestions);

  static int get totalLevelsCount =>
      founoun.fold(0, (sum, fan) => sum + fan.levels.length);

  /// Generates a curated, balanced 10-question daily competition across all Islamic sciences.
  static List<QuizQuestion> getDailyChallengeQuestions({int count = 10}) {
    final allQuestions = <QuizQuestion>[];
    for (final fan in founoun) {
      for (final level in fan.levels) {
        allQuestions.addAll(level.questions);
      }
    }

    if (allQuestions.isEmpty) return [];

    // Seeded by day of year so all students get the same competitive daily challenge today
    final now = DateTime.now();
    final seed = now.year * 1000 + now.month * 100 + now.day;
    final random = Random(seed);

    final shuffled = List<QuizQuestion>.from(allQuestions)..shuffle(random);
    return shuffled.take(count.clamp(1, allQuestions.length)).toList();
  }
}
