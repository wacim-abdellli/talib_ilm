import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/islamic_quiz_catalog.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_dump_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_discipline_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quiz Dump Preload & Real Discipline Question Count Tests', () {
    setUp(() {
      QuizDumpService.instance.clear();
    });

    test('Initial un-loaded state defaults to 30 questions', () {
      expect(QuizDumpService.instance.isLoaded, isFalse);
      final aqidahFan = IslamicQuizCatalog.getFan('aqidah');
      expect(aqidahFan, isNotNull);
      expect(aqidahFan!.totalQuestions, equals(30));
    });

    test('loadFromString populates real question counts > 30 across disciplines', () {
      final dumpJson = jsonEncode({
        'version': '1.0.0',
        'questions': [
          for (int i = 0; i < 15; i++)
            {
              'id': 'aq_dump_$i',
              'levelId': 'aqidah_lvl_1',
              'fanId': 'aqidah',
              'question': 'سؤال عقيدة تجريبي $i',
              'options': ['خيار 1', 'خيار 2', 'خيار 3', 'خيار 4'],
              'correctIndex': 0,
              'lesson': 'درس',
              'evidence': 'دليل',
              'reference': 'مرجع',
            },
        ],
      });

      QuizDumpService.instance.loadFromString(dumpJson);
      expect(QuizDumpService.instance.isLoaded, isTrue);

      final aqidahFan = IslamicQuizCatalog.getFan('aqidah');
      expect(aqidahFan, isNotNull);
      // 30 base + 15 dump = 45 questions
      expect(aqidahFan!.totalQuestions, equals(45));

      // Test that IlmDisciplineSection immediately reflects 45 without needing navigation
      final aqidahDiscipline = IlmDisciplineSection.disciplines
          .firstWhere((d) => d.key == 'aqidah');
      expect(aqidahDiscipline.fan, isNotNull);
      expect(aqidahDiscipline.fan!.totalQuestions, equals(45));
    });

    test('Concurrent loadDump calls do not duplicate questions', () async {
      final sampleJson = jsonEncode({
        'version': '1.0.0',
        'questions': [
          {
            'id': 'dup_q1',
            'levelId': 'aqidah_lvl_1',
            'fanId': 'aqidah',
            'question': 'سؤال تجريبي',
            'options': ['1', '2', '3', '4'],
            'correctIndex': 0,
            'lesson': 'شرح',
            'evidence': 'دليل',
            'reference': 'مرجع',
          }
        ]
      });

      // Calling loadFromString twice should be idempotent
      QuizDumpService.instance.loadFromString(sampleJson);
      final countFirst = QuizDumpService.instance.totalDumpQuestionsCount;

      QuizDumpService.instance.loadFromString(sampleJson);
      final countSecond = QuizDumpService.instance.totalDumpQuestionsCount;

      expect(countFirst, equals(countSecond));
      expect(countSecond, equals(1));
    });
  });
}
