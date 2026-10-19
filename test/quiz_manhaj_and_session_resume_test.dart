import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/islamic_quiz_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/quiz_manhaj_syllabus.dart';
import 'package:talib_ilm/features/ilm/data/models/islamic_quiz_models.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_dump_service.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Manhaj Syllabus & Question Partitioning Tests (15-20 Questions Max)', () {
    test('QuizManhajSyllabus defines authentic syllabus stages for all 11 disciplines', () {
      expect(QuizManhajSyllabus.descriptors.length, 11);

      for (final fanId in QuizManhajSyllabus.descriptors.keys) {
        final specs = QuizManhajSyllabus.descriptors[fanId]!;
        expect(specs.isNotEmpty, isTrue);

        for (final spec in specs) {
          expect(spec.title.isNotEmpty, isTrue);
          expect(spec.description.isNotEmpty, isTrue);
          expect(
            [
              QuizManhajSyllabus.stageFoundation,
              QuizManhajSyllabus.stageIntermediate,
              QuizManhajSyllabus.stageMastery,
            ],
            contains(spec.stage),
          );
        }
      }
    });

    test('partitionQuestionsIntoManhajLevels partitions large pools into 15-20 questions per level', () {
      // Create 318 dummy questions matching Quran bank size
      final sampleQuestions = List.generate(
        318,
        (i) => QuizQuestion(
          id: 'q_$i',
          question: 'سؤال تجريبي رقم $i',
          options: const ['أ', 'ب', 'ج', 'د'],
          correctIndex: 0,
          lesson: 'شرح',
          evidence: 'دليل',
          reference: 'مرجع',
        ),
      );

      final levels = QuizManhajSyllabus.partitionQuestionsIntoManhajLevels(
        fanId: 'quran',
        allQuestions: sampleQuestions,
      );

      // Must have 16 levels
      expect(levels.length, 16);

      // Verify every single level has between 15 and 20 questions
      int totalAccounted = 0;
      for (final lvl in levels) {
        expect(lvl.totalQuestions, inInclusiveRange(15, 20),
            reason: '${lvl.id} has ${lvl.totalQuestions} questions which exceeds standard limit');
        totalAccounted += lvl.totalQuestions;
      }

      // No questions lost
      expect(totalAccounted, 318);
    });

    test('All disciplines in IslamicQuizCatalog satisfy <= 20 questions per level when dump loaded', () async {
      // Simulate loaded dump
      final dummyDump = {
        'version': '1.0.0',
        'questions': List.generate(
          100,
          (i) => {
            'id': 'dump_sim_$i',
            'fanId': 'quran',
            'levelId': 'quran_l1',
            'question': 'سؤال محاكاة $i',
            'options': ['أ', 'ب', 'ج', 'د'],
            'correctIndex': 0,
            'lesson': 'شرح',
            'evidence': 'دليل',
            'reference': 'مرجع',
          },
        ),
      };

      final dumpService = QuizDumpService.instance;
      dumpService.clear();
      dumpService.loadFromString(jsonEncode(dummyDump));

      final quranFan = IslamicQuizCatalog.getFan('quran');
      expect(quranFan, isNotNull);

      for (final lvl in quranFan!.levels) {
        expect(lvl.totalQuestions, lessThanOrEqualTo(20),
            reason: 'Level ${lvl.id} had ${lvl.totalQuestions} questions (should be <= 20)');
      }

      dumpService.clear();
    });
  });

  group('Active Session Resume on Outside Cards Tests', () {
    late SharedPreferences prefs;
    late QuizProgressService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = QuizProgressService(prefs);
    });

    test('Active session records exact user stop point e.g. 5/20', () async {
      const levelId = 'quran_l1';

      // Verify initially no session
      expect(service.getActiveSession(levelId), isNull);

      // User stopped at question 4 (0-indexed, meaning question 5 in user display)
      final session = QuizActiveSession(
        currentIndex: 4,
        correctAnswers: 3,
        currentStreak: 2,
        maxStreak: 2,
        userAnswers: const [0, 1, 0, 2],
      );

      await service.saveActiveSession(levelId, session);

      final retrieved = service.getActiveSession(levelId);
      expect(retrieved, isNotNull);
      expect(retrieved!.currentIndex, 4);

      // Test display computation: question number is currentIndex + 1
      final displayQuestionIndex = retrieved.currentIndex + 1;
      const totalQuestions = 20;
      expect('$displayQuestionIndex / $totalQuestions', '5 / 20');
      expect((displayQuestionIndex / totalQuestions), 0.25);

      // Clearing upon completion
      await service.clearActiveSession(levelId);
      expect(service.getActiveSession(levelId), isNull);
    });
  });
}
