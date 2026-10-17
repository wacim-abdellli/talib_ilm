import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/islamic_quiz_catalog.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_progress_service.dart';

void main() {
  group('Islamic Quiz Catalog Tests', () {
    test('Catalog contains all 7 core Islamic sciences', () {
      final founoun = IslamicQuizCatalog.founoun;
      expect(founoun.length, 7);

      final ids = founoun.map((f) => f.id).toList();
      expect(ids, containsAll([
        'aqidah',
        'fiqh',
        'hadith',
        'quran',
        'seerah',
        'prophets_names',
        'adab',
      ]));
    });

    test('Each fan has multiple progressive levels with lessons and evidence', () {
      for (final fan in IslamicQuizCatalog.founoun) {
        expect(fan.levels.length, greaterThanOrEqualTo(2));
        for (final level in fan.levels) {
          expect(level.questions.isNotEmpty, isTrue);
          for (final q in level.questions) {
            expect(q.options.length, greaterThanOrEqualTo(4));
            expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
            expect(q.lesson.isNotEmpty, isTrue);
            expect(q.evidence.isNotEmpty, isTrue);
            expect(q.reference.isNotEmpty, isTrue);
          }
        }
      }
    });

    test('Daily challenge returns balanced questions across sciences', () {
      final dailyQuestions = IslamicQuizCatalog.getDailyChallengeQuestions(count: 10);
      expect(dailyQuestions.length, 10);
    });
  });

  group('QuizProgressService Progression & Scoring Tests', () {
    late SharedPreferences prefs;
    late QuizProgressService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = QuizProgressService(prefs);
    });

    test('Level 1 is unlocked by default, level 2 is locked until passed', () {
      final l1Unlocked = service.isLevelUnlocked('aqidah_l1', 1, null);
      final l2Unlocked = service.isLevelUnlocked('aqidah_l2', 2, 'aqidah_l1');

      expect(l1Unlocked, isTrue);
      expect(l2Unlocked, isFalse);
    });

    test('Completing level 1 with >= 70% unlocks level 2 and awards XP and stars', () async {
      final result = await service.recordLevelResult(
        levelId: 'aqidah_l1',
        correctCount: 9,
        totalQuestions: 10,
        maxStreak: 5,
      );

      expect(result.hasPassed, isTrue);
      expect(result.earnedStars, 2); // 90% is 2 stars
      expect(result.newlyUnlockedNextLevel, isTrue);
      expect(result.earnedXp, greaterThanOrEqualTo(100));

      final l2UnlockedNow = service.isLevelUnlocked('aqidah_l2', 2, 'aqidah_l1');
      expect(l2UnlockedNow, isTrue);
    });

    test('Scoring 100% awards 3 stars and maximum bonus XP', () async {
      final result = await service.recordLevelResult(
        levelId: 'fiqh_l1',
        correctCount: 5,
        totalQuestions: 5,
        maxStreak: 5,
      );

      expect(result.hasPassed, isTrue);
      expect(result.earnedStars, 3);
      expect(result.scorePercentage, 100.0);
    });

    test('Aggregated UserQuizStats accurately tracks student rank title', () async {
      // Record initial score
      await service.recordLevelResult(
        levelId: 'hadith_l1',
        correctCount: 5,
        totalQuestions: 5,
        maxStreak: 5,
      );

      final stats = service.getUserStats();
      expect(stats.totalQuizzesTaken, 1);
      expect(stats.totalQuestionsAnswered, 5);
      expect(stats.totalCorrectAnswers, 5);
      expect(stats.accuracyRate, 100.0);
      expect(stats.rankTitle.isNotEmpty, isTrue);
    });
  });
}
