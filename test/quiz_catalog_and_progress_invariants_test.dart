import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_dump_service.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T12 / C23 — QuizDumpService Atomic Loading & Schema Invariants', () {
    late QuizDumpService dumpService;

    setUp(() {
      dumpService = QuizDumpService.instance;
      dumpService.clear();
    });

    test('Malformed item after a valid item aborts atomically without publishing partial cache', () {
      final corruptDump = jsonEncode({
        'version': '1.0.0',
        'questions': [
          {
            'id': 'valid_q1',
            'levelId': 'aqidah_l1',
            'fanId': 'aqidah',
            'question': 'سؤال صحيح أول',
            'options': ['أ', 'ب', 'ج', 'د'],
            'correctIndex': 0,
            'lesson': 'شرح',
            'evidence': 'دليل',
            'reference': 'مرجع',
          },
          {
            'id': 'corrupt_q2',
            'levelId': 'aqidah_l1',
            'fanId': 'aqidah',
            'question': '', // Invalid: blank question
            'options': ['أ', 'ب'],
            'correctIndex': 5, // Invalid: out of bounds
          },
        ],
      });

      final loadedCount = dumpService.loadFromString(corruptDump);

      expect(loadedCount, 0);
      expect(dumpService.isLoaded, isFalse);
      expect(dumpService.hasFailed, isTrue);
      expect(dumpService.loadStatus, QuizDumpLoadStatus.failed);
      // Crucial: valid_q1 must NOT be in the catalog (zero partial publication)
      expect(dumpService.getAllDumpQuestions(), isEmpty);
      expect(dumpService.getQuestionsForLevel('aqidah_l1'), isEmpty);
    });

    test('Wrong top-level schema safely transitions to failed status without uncaught exceptions', () {
      expect(dumpService.loadFromString('{"not_questions": []}'), 0);
      expect(dumpService.loadStatus, QuizDumpLoadStatus.failed);

      expect(dumpService.loadFromString('["an", "array"]'), 0);
      expect(dumpService.loadStatus, QuizDumpLoadStatus.failed);

      expect(dumpService.loadFromString('invalid json {{{'), 0);
      expect(dumpService.loadStatus, QuizDumpLoadStatus.failed);
    });

    test('Duplicate question IDs within dump are deduplicated safely', () {
      final duplicateIdDump = jsonEncode({
        'version': '1.0.0',
        'questions': [
          {
            'id': 'dup_id_1',
            'levelId': 'fiqh_l1',
            'fanId': 'fiqh',
            'question': 'سؤال أول',
            'options': ['أ', 'ب'],
            'correctIndex': 0,
          },
          {
            'id': 'dup_id_1', // Duplicate ID
            'levelId': 'fiqh_l1',
            'fanId': 'fiqh',
            'question': 'سؤال مكرر الهوية',
            'options': ['أ', 'ب'],
            'correctIndex': 1,
          },
        ],
      });

      final loadedCount = dumpService.loadFromString(duplicateIdDump);
      expect(loadedCount, 1);
      expect(dumpService.isLoaded, isTrue);
      expect(dumpService.getAllDumpQuestions().length, 1);
      expect(dumpService.getAllDumpQuestions().first.question, 'سؤال أول');
    });

    test('Missing dump asset preserves retryable failed state and does not mark isLoaded true', () async {
      // Calling loadDump with missing asset triggers catch
      await dumpService.loadDump(assetPath: 'assets/non_existent_dump.json');

      // In pre-fix code: _isLoaded was set to true in catch, permanently breaking retries
      // In post-fix code: _isLoaded must be false and loadStatus must be failed
      expect(dumpService.isLoaded, isFalse);
      expect(dumpService.hasFailed, isTrue);
      expect(dumpService.loadStatus, QuizDumpLoadStatus.failed);

      // Verify retryability: calling loadDump again with valid asset succeeds
      await dumpService.loadDump(assetPath: QuizDumpService.dumpAssetPath);
      expect(dumpService.isLoaded, isTrue);
      expect(dumpService.loadStatus, QuizDumpLoadStatus.success);
      expect(dumpService.totalDumpQuestionsCount, greaterThan(0));
    });

    test('clear resets state to unloaded and empties all collections', () {
      final validDump = jsonEncode({
        'version': '1.0.0',
        'questions': [
          {
            'id': 'valid_q1',
            'levelId': 'aqidah_l1',
            'fanId': 'aqidah',
            'question': 'سؤال صحيح',
            'options': ['أ', 'ب'],
            'correctIndex': 0,
          },
        ],
      });

      dumpService.loadFromString(validDump);
      expect(dumpService.isLoaded, isTrue);
      expect(dumpService.totalDumpQuestionsCount, 1);

      dumpService.clear();
      expect(dumpService.isLoaded, isFalse);
      expect(dumpService.loadStatus, QuizDumpLoadStatus.unloaded);
      expect(dumpService.totalDumpQuestionsCount, 0);
    });
  });

  group('T12 / C23 — QuizProgressService Bounds & Idempotency Invariants', () {
    late SharedPreferences prefs;
    late QuizProgressService progressService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      progressService = QuizProgressService(prefs);
    });

    test('Negative, impossible, and zero-question bounds are clamped safely', () async {
      // 1. Zero total questions
      final zeroResult = await progressService.recordLevelResult(
        levelId: 'aqidah_l1',
        correctCount: 5,
        totalQuestions: 0,
        maxStreak: 2,
      );
      expect(zeroResult.earnedXp, 0);
      expect(zeroResult.scorePercentage, 0.0);
      expect(zeroResult.hasPassed, isFalse);

      // 2. Negative correct count and max streak
      final negativeResult = await progressService.recordLevelResult(
        levelId: 'aqidah_l1',
        correctCount: -5,
        totalQuestions: 10,
        maxStreak: -2,
      );
      expect(negativeResult.scorePercentage, 0.0);
      expect(negativeResult.earnedXp, 0);

      // 3. Excess correct count clamped to totalQuestions
      final excessResult = await progressService.recordLevelResult(
        levelId: 'aqidah_l1',
        correctCount: 99,
        totalQuestions: 10,
        maxStreak: 50,
      );
      expect(excessResult.scorePercentage, 100.0);
      expect(excessResult.earnedStars, 3);
      expect(excessResult.hasPassed, isTrue);
    });

    test('Session completion idempotency prevents duplicate XP and counter increments', () async {
      const levelId = 'aqidah_l1';
      const sessionId = 'session_token_12345';

      // First completion call
      final firstResult = await progressService.recordLevelResult(
        levelId: levelId,
        correctCount: 10,
        totalQuestions: 10,
        maxStreak: 10,
        sessionCompletionId: sessionId,
      );

      final xpFirst = prefs.getInt('quiz_total_xp') ?? 0;
      final quizzesFirst = prefs.getInt('quiz_total_quizzes') ?? 0;
      final questionsFirst = prefs.getInt('quiz_total_questions_answered') ?? 0;
      final correctFirst = prefs.getInt('quiz_total_correct') ?? 0;

      expect(firstResult.earnedXp, greaterThan(0));
      expect(xpFirst, greaterThan(0));
      expect(quizzesFirst, 1);
      expect(questionsFirst, 10);
      expect(correctFirst, 10);

      // Duplicate completion call with identical sessionCompletionId (e.g. double-click or retry)
      final duplicateResult = await progressService.recordLevelResult(
        levelId: levelId,
        correctCount: 10,
        totalQuestions: 10,
        maxStreak: 10,
        sessionCompletionId: sessionId,
      );

      final xpSecond = prefs.getInt('quiz_total_xp') ?? 0;
      final quizzesSecond = prefs.getInt('quiz_total_quizzes') ?? 0;
      final questionsSecond = prefs.getInt('quiz_total_questions_answered') ?? 0;
      final correctSecond = prefs.getInt('quiz_total_correct') ?? 0;

      // Idempotency: second call must NOT re-award XP or increment counters
      expect(duplicateResult.earnedXp, 0);
      expect(xpSecond, xpFirst);
      expect(quizzesSecond, quizzesFirst);
      expect(questionsSecond, questionsFirst);
      expect(correctSecond, correctFirst);
    });

    test('Daily challenge completion cannot be awarded more than once on the same day', () async {
      await progressService.markDailyChallengeCompleted(5, 5);
      final xpAfterFirst = prefs.getInt('quiz_total_xp') ?? 0;
      expect(xpAfterFirst, greaterThan(0));

      // Attempting same-day completion again
      await progressService.markDailyChallengeCompleted(5, 5);
      final xpAfterSecond = prefs.getInt('quiz_total_xp') ?? 0;
      expect(xpAfterSecond, xpAfterFirst);
    });

    test('Concurrent recordLevelResult calls are serialized safely via AsyncLock', () async {
      final futures = [
        progressService.recordLevelResult(
          levelId: 'aqidah_l1',
          correctCount: 10,
          totalQuestions: 10,
          maxStreak: 3,
          sessionCompletionId: 'concurrent_sess_1',
        ),
        progressService.recordLevelResult(
          levelId: 'fiqh_l1',
          correctCount: 10,
          totalQuestions: 10,
          maxStreak: 3,
          sessionCompletionId: 'concurrent_sess_2',
        ),
        progressService.recordLevelResult(
          levelId: 'hadith_l1',
          correctCount: 10,
          totalQuestions: 10,
          maxStreak: 3,
          sessionCompletionId: 'concurrent_sess_3',
        ),
      ];

      await Future.wait(futures);

      expect(prefs.getInt('quiz_total_quizzes'), 3);
      expect(prefs.getInt('quiz_total_questions_answered'), 30);
      expect(prefs.getInt('quiz_total_correct'), 30);
    });

    test('Corrupt active session JSON is safely purged and returns null without throwing', () {
      const sessionId = 'corrupt_session_id';
      prefs.setString('quiz_active_session_$sessionId', 'not-valid-json{{{{');

      final session = progressService.getActiveSession(sessionId);
      expect(session, isNull);
      // Verify corrupt key was purged
      expect(prefs.getString('quiz_active_session_$sessionId'), isNull);
    });

    test('Active session supports schema versioning and resume across catalog versions', () async {
      const sessionId = 'resumed_session';
      final session = QuizActiveSession(
        currentIndex: 3,
        correctAnswers: 2,
        currentStreak: 1,
        maxStreak: 2,
        userAnswers: const [0, 1, 0],
        sessionId: sessionId,
        catalogVersion: 1,
      );

      await progressService.saveActiveSession(sessionId, session);

      final retrieved = progressService.getActiveSession(sessionId);
      expect(retrieved, isNotNull);
      expect(retrieved!.currentIndex, 3);
      expect(retrieved.catalogVersion, 1);
      expect(retrieved.sessionId, sessionId);
    });
  });
}
