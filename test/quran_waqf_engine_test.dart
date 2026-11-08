import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/models/quran_waqf_analysis.dart';
import 'package:talib_ilm/features/quran/data/services/quran_tafsir_service.dart';
import 'package:talib_ilm/features/quran/data/services/quran_waqf_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/ayah_waqf_tab_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    QuranWaqfService().setHttpClient(null);
    QuranTafsirService.resetHttpClient();
    QuranTafsirService.clearMemoryCache();
  });

  group('Quran Waqf Models Serialization', () {
    test('WaqfScholar parses and serializes correctly', () {
      final jsonMap = {
        'id': 'dani',
        'short': 'الداني',
        'title': 'المكتفى في الوقف والابتدا',
        'death': 444,
      };

      final scholar = WaqfScholar.fromJson(jsonMap);
      expect(scholar.id, 'dani');
      expect(scholar.shortName, 'الداني');
      expect(scholar.bookTitle, 'المكتفى في الوقف والابتدا');
      expect(scholar.deathYear, 444);

      final serialized = scholar.toJson();
      expect(serialized['id'], 'dani');
      expect(serialized['death'], 444);
    });

    test('WaqfJudgment parses Wahy list and json map', () {
      final list = [
        'dani',
        'w',
        'كاف',
        'كاف',
        'kafi',
        'لتمام معنى الحمد وانقطاع ما بعده عما قبله لفظاً.',
        '',
        'ص 18',
      ];

      final j = WaqfJudgment.fromWahyList(list);
      expect(j.scholarId, 'dani');
      expect(j.label, 'كاف');
      expect(j.grade, 'kafi');
      expect(j.isKafi, isTrue);
      expect(j.isTam, isFalse);
      expect(j.page, 'ص 18');

      final serialized = j.toJson();
      final fromJson = WaqfJudgment.fromJson(serialized);
      expect(fromJson.scholarId, 'dani');
      expect(fromJson.grade, 'kafi');
      expect(fromJson.page, 'ص 18');
    });

    test('AyahWaqfAnalysis roundtrip serialization', () {
      final analysis = AyahWaqfAnalysis(
        surah: 1,
        ayah: 2,
        verseText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        firstGlobalWordId: 2,
        scholars: const [
          WaqfScholar(
            id: 'dani',
            shortName: 'الداني',
            bookTitle: 'المكتفى',
            deathYear: 444,
          ),
        ],
        words: const [
          WaqfWord(
            wordIndex: 4,
            word: 'الْعَالَمِينَ',
            judgments: [
              WaqfJudgment(
                scholarId: 'dani',
                type: 'w',
                label: 'تام',
                longLabel: 'تام',
                grade: 'tam',
                explanation: 'رأس آية تام.',
                note: '',
                page: 'ص 18',
              ),
            ],
          ),
        ],
      );

      expect(analysis.isEmpty, isFalse);
      final jsonMap = analysis.toJson();
      final deserialized = AyahWaqfAnalysis.fromJson(jsonMap);

      expect(deserialized.surah, 1);
      expect(deserialized.ayah, 2);
      expect(deserialized.words.length, 1);
      expect(deserialized.words.first.word, 'الْعَالَمِينَ');
      expect(deserialized.words.first.judgments.first.isTam, isTrue);
    });
  });

  group('QuranWaqfService API & Fallback', () {
    test('fetches and parses Wahy Waqf endpoint correctly', () async {
      final mockData = {
        'text': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        'first': 2,
        'books': [
          {
            'id': 'dani',
            'short': 'الداني',
            'title': 'المكتفى',
            'death': 444,
          },
          {
            'id': 'sajawandi',
            'short': 'السجاوندي',
            'title': 'علل الوقوف',
            'death': 560,
          },
        ],
        'words': {
          '2': [
            ['sajawandi', 'w', 'ج', 'جائز', 'jaiz', 'لتمام الوصف', '', 'ص 22'],
          ],
          '4': [
            ['dani', 'w', 'تام', 'تام', 'tam', 'رأس آية', '', 'ص 18'],
          ],
        },
      };

      final client = MockClient((request) async {
        if (request.url.path.contains('/api/waqf/1/2')) {
          return http.Response(
            json.encode(mockData),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = QuranWaqfService();
      service.setHttpClient(client);

      final result = await service.getAyahWaqf(1, 2);
      expect(result.surah, 1);
      expect(result.ayah, 2);
      expect(result.scholars.length, 2);
      expect(result.words.length, 2);

      // Verify word 2 has Sajawandi
      final word2 = result.words.firstWhere((w) => w.wordIndex == 2);
      expect(word2.hasScholar('sajawandi'), isTrue);
      expect(word2.judgments.first.grade, 'jaiz');

      // Verify word 4 has Dani
      final word4 = result.words.firstWhere((w) => w.wordIndex == 4);
      expect(word4.hasScholar('dani'), isTrue);
      expect(word4.judgments.first.isTam, isTrue);
    });

    test('gracefully returns offline fallback on network failure', () async {
      final client = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = QuranWaqfService();
      service.setHttpClient(client);

      final result = await service.getAyahWaqf(1, 1);
      expect(result.surah, 1);
      expect(result.ayah, 1);
      expect(result.words.isNotEmpty, isTrue);
      expect(result.words.first.judgments.first.isTam, isTrue);
    });
  });

  group('Hidayat al-Quran in QuranTafsirService', () {
    test('fetches Wahy Source 191 for Hidayat al-Quran', () async {
      final source191Map = {
        '1': {'t': 'فوائد في الاستعاذة والبسملة وعظمة سورة الفاتحة.'},
        '2': {'t': 'الحمد ثناء على الله بصفات الكمال، وتوجيه العباد لحمده.'},
      };

      final client = MockClient((request) async {
        if (request.url.path.contains('/api/source/191/1')) {
          return http.Response(
            json.encode(source191Map),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      QuranTafsirService.setHttpClient(client);

      final text = await QuranTafsirService.getTafsir(
        surahNumber: 1,
        ayahNumber: 2,
        scholar: TafsirScholar.hidayat,
      );

      expect(text, contains('الحمد ثناء على الله بصفات الكمال'));
      expect(QuranTafsirService.getScholarName(TafsirScholar.hidayat), 'هدايات القرآن الكريم');
      expect(QuranTafsirService.getScholarAuthor(TafsirScholar.hidayat), 'مركز تفسير للدراسات القرآنية');
    });
  });

  group('AyahWaqfTabView Widget Tests', () {
    Widget buildTestWidget({double textScale = 1.0}) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQueryData(
                size: const Size(390, 844),
                textScaler: TextScaler.linear(textScale),
              ),
              child: const AyahWaqfTabView(
                surahNumber: 1,
                ayahNumber: 2,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders Waqf scholars and word cards across text scales', (tester) async {
      final mockData = {
        'text': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        'first': 2,
        'books': [
          {
            'id': 'dani',
            'short': 'الداني',
            'title': 'المكتفى',
            'death': 444,
          },
        ],
        'words': {
          '4': [
            ['dani', 'w', 'تام', 'تام', 'tam', 'رأس آية تام حسن الوقف والابتداء بما بعده.', '', 'ص 18'],
          ],
        },
      };

      final client = MockClient((request) async {
        return http.Response(
          json.encode(mockData),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      QuranWaqfService().setHttpClient(client);

      // Scale 1.0
      await tester.pumpWidget(buildTestWidget(textScale: 1.0));
      await tester.pumpAndSettle();

      expect(find.text('جميع الأئمة الخمسة'), findsOneWidget);
      expect(find.text('الداني (444هـ)'), findsOneWidget);
      expect(find.textContaining('الْعَالَمِينَ'), findsAtLeastNWidgets(1));
      expect(find.text('تام'), findsAtLeastNWidgets(1));

      // Tap scholar chip
      await tester.tap(find.text('الداني (444هـ)'));
      await tester.pumpAndSettle();

      // Scale 2.0 without overflow
      await tester.pumpWidget(buildTestWidget(textScale: 2.0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
