import 'dart:math';

import '../models/islamic_quiz_models.dart';
import 'quiz_adab_catalog.dart';
import 'quiz_aqidah_catalog.dart';
import 'quiz_arabic_catalog.dart';
import 'quiz_fiqh_catalog.dart';
import 'quiz_hadith_catalog.dart';
import 'quiz_prophets_catalog.dart';
import 'quiz_quran_catalog.dart';
import 'quiz_sahaba_catalog.dart';
import 'quiz_seerah_catalog.dart';
import 'quiz_tajweed_catalog.dart';
import 'quiz_usul_catalog.dart';

import '../services/quiz_dump_service.dart';

/// The master catalog aggregating all authentic Islamic disciplines, levels, and questions.
class IslamicQuizCatalog {
  IslamicQuizCatalog._();

  static List<FanQuiz> get _baseFounoun => [
        QuizAqidahCatalog.aqidahFan,
        QuizFiqhCatalog.fiqhFan,
        QuizUsulCatalog.usulFan,
        QuizHadithCatalog.hadithFan,
        QuizQuranCatalog.quranFan,
        QuizTajweedCatalog.tajweedFan,
        QuizSeerahCatalog.seerahFan,
        QuizSahabaCatalog.sahabaFan,
        QuizProphetsCatalog.prophetsNamesFan,
        QuizAdabCatalog.adabFan,
        QuizArabicCatalog.arabicFan,
      ];

  static List<FanQuiz> get founoun {
    final dumpService = QuizDumpService.instance;
    return _baseFounoun.map((fan) {
      final updatedLevels = fan.levels.map((level) {
        final dumpQuestions = dumpService.getQuestionsForLevel(level.id);
        if (dumpQuestions.isEmpty) return level;
        return QuizLevel(
          id: level.id,
          levelNumber: level.levelNumber,
          title: level.title,
          description: level.description,
          questions: [...level.questions, ...dumpQuestions],
          passingPercentage: level.passingPercentage,
        );
      }).toList();

      return FanQuiz(
        id: fan.id,
        title: fan.title,
        subtitle: fan.subtitle,
        icon: fan.icon,
        levels: updatedLevels,
      );
    }).toList();
  }

  static FanQuiz? getFan(String id) {
    for (final fan in founoun) {
      if (fan.id == id) return fan;
    }
    return null;
  }

  static QuizLevel? getLevel(String levelId) {
    for (final fan in founoun) {
      for (final level in fan.levels) {
        if (level.id == levelId) {
          return level;
        }
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

  /// Generates a curated, non-repeating rotating daily challenge across all Islamic disciplines.
  /// Uses a deterministic rolling window across the whole bank (~1,113 questions) so questions
  /// mathematically NEVER repeat within a rolling timeline of over 110 days.
  static List<QuizQuestion> getDailyChallengeQuestions({int count = 10}) {
    final allQuestions = <QuizQuestion>[];
    for (final fan in founoun) {
      for (final level in fan.levels) {
        allQuestions.addAll(level.questions);
      }
    }

    if (allQuestions.isEmpty) return [];

    // Deterministically permute with a fixed scholarly seed once so every day gets a balanced
    // mixture across different disciplines (Aqidah, Fiqh, Hadith, Seerah, etc.)
    final mixedPool = List<QuizQuestion>.from(allQuestions)
      ..sort((a, b) => a.id.compareTo(b.id));
    mixedPool.shuffle(Random(13579));

    // Calculate elapsed days from a fixed epoch (Jan 1 2025)
    final now = DateTime.now();
    final epoch = DateTime(2025, 1, 1);
    final dayIndex = now.difference(epoch).inDays.abs();

    final safeCount = count.clamp(1, mixedPool.length);
    final total = mixedPool.length;

    // Rolling window step of `safeCount` per day
    final startIndex = (dayIndex * safeCount) % total;

    final selected = <QuizQuestion>[];
    for (int i = 0; i < safeCount; i++) {
      selected.add(mixedPool[(startIndex + i) % total]);
    }

    return selected;
  }
}
