import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/islamic_quiz_catalog.dart';
import 'package:talib_ilm/features/ilm/data/models/islamic_quiz_models.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_dump_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Quiz Question Serialization & Model Tests', () {
    test('QuizQuestion fromJson and toJson preserves all scholarly fields', () {
      final jsonMap = {
        'id': 'test_q1',
        'levelId': 'aqidah_lvl_1',
        'fanId': 'aqidah',
        'question': 'ما هو التوحيد؟',
        'options': ['إفراد الله بالعبادة', 'الشرك', 'الشك', 'النفاق'],
        'correctIndex': 0,
        'lesson': 'التوحيد إفراد الله بما يختص به.',
        'evidence': 'وما خلقت الجن والإنس إلا ليعبدون',
        'reference': 'الذاريات: 56',
        'difficulty': 'easy',
      };

      final q = QuizQuestion.fromJson(jsonMap);
      expect(q.id, 'test_q1');
      expect(q.levelId, 'aqidah_lvl_1');
      expect(q.fanId, 'aqidah');
      expect(q.question, 'ما هو التوحيد؟');
      expect(q.options.length, 4);
      expect(q.correctIndex, 0);
      expect(q.evidence, contains('ليعبدون'));
      expect(q.reference, 'الذاريات: 56');

      final exported = q.toJson();
      expect(exported['id'], 'test_q1');
      expect(exported['options'], contains('إفراد الله بالعبادة'));
    });
  });

  group('QuizDumpService Offline Dump Tests', () {
    late QuizDumpService dumpService;

    setUp(() {
      dumpService = QuizDumpService.instance;
      dumpService.clear();
    });

    test('loadFromString successfully parses questions and filters by level', () {
      final sampleJson = jsonEncode({
        'version': '1.0.0',
        'questions': [
          {
            'id': 'dump_aq_1',
            'levelId': 'aqidah_lvl_1',
            'fanId': 'aqidah',
            'question': 'ما أعظم واجب على العبيد؟',
            'options': [
              'توحيد الله تعالى',
              'بناء المساجد',
              'التجارة والعمل',
              'السفر وطلب الرزق'
            ],
            'correctIndex': 0,
            'lesson': 'أعظم واجب فرض الله على العباد هو توحيده.',
            'evidence': 'فاعلم أنه لا إله إلا الله',
            'reference': 'محمد: 19',
            'difficulty': 'easy',
          },
          {
            'id': 'dump_fiqh_1',
            'levelId': 'fiqh_lvl_1',
            'fanId': 'fiqh',
            'question': 'ما هي شروط الصلاة؟',
            'options': [
              'تسعة شروط',
              'ثلاثة شروط',
              'عشرون شرطاً',
              'شرطان فقط'
            ],
            'correctIndex': 0,
            'lesson': 'شروط الصلاة تسعة.',
            'evidence': 'إن الصلاة كانت على المؤمنين كتاباً موقوتاً',
            'reference': 'النساء: 103',
            'difficulty': 'medium',
          }
        ]
      });

      final count = dumpService.loadFromString(sampleJson);
      expect(count, 2);
      expect(dumpService.isLoaded, isTrue);
      expect(dumpService.allQuestions.length, 2);

      final aqidahQuestions = dumpService.getQuestionsForLevel('aqidah_lvl_1');
      expect(aqidahQuestions.length, 1);
      expect(aqidahQuestions.first.id, 'dump_aq_1');

      final fiqhQuestions = dumpService.getQuestionsForLevel('fiqh_lvl_1');
      expect(fiqhQuestions.length, 1);
      expect(fiqhQuestions.first.id, 'dump_fiqh_1');
    });

    test('IslamicQuizCatalog merges dump questions seamlessly', () {
      final sampleJson = jsonEncode({
        'version': '1.0.0',
        'questions': [
          {
            'id': 'dump_aq_extra',
            'levelId': 'aqidah_lvl_1',
            'fanId': 'aqidah',
            'question': 'سؤال إضافي تجريبي في العقيدة',
            'options': ['خيار أ', 'خيار ب', 'خيار ج', 'خيار د'],
            'correctIndex': 0,
            'lesson': 'شرح',
            'evidence': 'دليل',
            'reference': 'مرجع',
            'difficulty': 'easy',
          }
        ]
      });

      final initialTotal = IslamicQuizCatalog.totalQuestionsCount;
      dumpService.loadFromString(sampleJson);

      final newTotal = IslamicQuizCatalog.totalQuestionsCount;
      expect(newTotal, initialTotal + 1);

      final level = IslamicQuizCatalog.getLevel('aqidah_l1');
      expect(level, isNotNull);
      expect(level!.questions.any((q) => q.id == 'dump_aq_extra'), isTrue);
    });
  });
}
