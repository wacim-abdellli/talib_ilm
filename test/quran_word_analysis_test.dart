import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/models/quran_word_analysis.dart';
import 'package:talib_ilm/features/quran/data/services/quran_word_analysis_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuranWordAnalysis Model Tests', () {
    test('JSON serialization roundtrip', () {
      const analysis = QuranWordAnalysis(
        globalWordId: 77413,
        wordIndexInAyah: 1,
        word: 'قُلْ',
        qiraat: 'ورش بالنقل وصلاً',
        irab: 'فعل أمر مبني على السكون',
        meaning: 'تكلم',
        sarf: 'أصله اقوُل على وزن افعُل',
      );

      final jsonMap = analysis.toJson();
      final revived = QuranWordAnalysis.fromJson(jsonMap);

      expect(revived.globalWordId, 77413);
      expect(revived.wordIndexInAyah, 1);
      expect(revived.word, 'قُلْ');
      expect(revived.qiraat, 'ورش بالنقل وصلاً');
      expect(revived.irab, 'فعل أمر مبني على السكون');
      expect(revived.meaning, 'تكلم');
      expect(revived.sarf, 'أصله اقوُل على وزن افعُل');
      expect(revived.hasQiraat, isTrue);
      expect(revived.hasIrab, isTrue);
      expect(revived.hasMeaning, isTrue);
      expect(revived.hasSarf, isTrue);
    });

    test('parses Wahy 4-element array into 4-tier model', () {
      final wahyArray = [
        'لا خلاف بين القراء',
        'فعل أمر مبني على السكون',
        'النطق باللسان',
        'ثلاثي مجرد من باب نصر ينصر',
      ];

      final item = QuranWordAnalysis.fromWahyList(
        globalWordId: 101,
        wordIndexInAyah: 1,
        word: 'قُلْ',
        list: wahyArray,
      );

      expect(item.globalWordId, 101);
      expect(item.irab, 'فعل أمر مبني على السكون');
      expect(item.meaning, 'النطق باللسان');
      expect(item.sarf, contains('باب نصر'));
    });
  });

  group('QuranWordAnalysisService Online & Offline Tests', () {
    test('fetches page tokens and word analyses with mock HTTP client', () async {
      final service = QuranWordAnalysisService();

      final mockPageJson = {
        'p': 604,
        'lines': [
          [
            't',
            [
              ['ﮀ', 114, 1, 0, 77413],
              ['ﮁ', 114, 1, 0, 77414],
              ['ﮅ', 114, 1, 1], // End of ayah
            ]
          ]
        ]
      };

      final mockWordsJson = {
        '77413': [
          'قراءة ورش بالنقل',
          'فعل أمر مبني على السكون',
          'تكلم واصدع بالحق',
          'ثلاثي مجرد معتل أجوف واوي',
        ],
        '77414': [
          'تحقيق الهمز',
          'فعل مضارع مرفوع',
          'ألجأ وأعتصم',
          'ثلاثي مزيد بحرف الهمزة',
        ]
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/mushaf/hafs/')) {
          return http.Response(json.encode(mockPageJson), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/words/114')) {
          return http.Response(json.encode(mockWordsJson), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      service.setHttpClient(mockClient);

      final list = await service.getAyahWordAnalyses(114, 1);
      expect(list.length, 2);
      expect(list[0].wordIndexInAyah, 1);
      expect(list[0].globalWordId, 77413);
      expect(list[0].irab, contains('فعل أمر'));
      expect(list[0].sarf, contains('أجوف واوي'));
      expect(list[1].globalWordId, 77414);
      expect(list[1].meaning, contains('ألجأ'));
    });

    test('offline fallback generates clean models without crashing', () async {
      final service = QuranWordAnalysisService();
      final mockClient = MockClient((request) async {
        return http.Response('Network Error', 500);
      });

      service.setHttpClient(mockClient);
      final list = await service.getAyahWordAnalyses(1, 1);
      expect(list.isNotEmpty, isTrue);
      expect(list.first.word, isNotEmpty);
      expect(list.first.irab, isNotEmpty);
    });

    test('3:6 extracts exactly 13 words without waqf mark shift', () async {
      final service = QuranWordAnalysisService();
      final mockClient = MockClient((request) async {
        return http.Response('Network Error', 500);
      });

      service.setHttpClient(mockClient);
      final list = await service.getAyahWordAnalyses(3, 6);
      expect(list.length, 13);
      expect(list[11].word, contains('عَزِيز'));
      expect(list[11].wordIndexInAyah, 12);
      expect(list[12].word, contains('حَكِيم'));
      expect(list[12].wordIndexInAyah, 13);
    });
  });
}

