import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/models/mutashabih_card.dart';
import 'package:talib_ilm/features/quran/data/services/quran_mutashabihat_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/ayah_similar_tab_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Quran Mutashabihat Models & Service', () {
    tearDown(() {
      QuranMutashabihatService.resetHttpClient();
    });

    test('MutashabihCard and MutashabihPlace parse correctly from json', () {
      final sampleJson = {
        'id': 101,
        'places': [
          {
            's': 2,
            'a': 10,
            'f': 1,
            't': 3,
            'text': 'فِي قُلُوبِهِم مَّرَضٌ',
          },
          {
            's': 3,
            'a': 7,
            'f': 1,
            't': 3,
            'text': 'فَأَمَّا الَّذِينَ فِي قُلُوبِهِمْ زَيْغٌ',
          },
        ],
        'd': 'موضع آل عمران وحيد (في قلوبهم زيغ)',
        'w': 'الزيغ هو الميل والانحراف عن الحق',
        'r': 'ربط المتشابهات: ص 110',
      };

      final card = MutashabihCard.fromJson(sampleJson);
      expect(card.id, 101);
      expect(card.places.length, 2);
      expect(card.places[0].surah, 2);
      expect(card.places[0].ayah, 10);
      expect(card.places[0].fromWord, 1);
      expect(card.places[0].toWord, 3);
      expect(card.rule, contains('في قلوبهم زيغ'));
      expect(card.rhetoric, contains('الزيغ هو الميل'));
      expect(card.source, contains('ص 110'));

      final encoded = card.toJson();
      expect(encoded['id'], 101);
      expect((encoded['places'] as List).length, 2);
      expect(encoded['d'], contains('زيغ'));
    });

    test('QuranMutashabihatService parses mock API response', () async {
      final mockData = {
        'cards': [
          {
            'id': 1,
            'places': [
              {
                's': 1,
                'a': 2,
                'f': 1,
                't': 2,
                'text': 'ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ',
              },
              {
                's': 6,
                'a': 1,
                'f': 1,
                't': 2,
                'text': 'ٱلۡحَمۡدُ لِلَّهِ ٱلَّذِي خَلَقَ ٱلسَّمَٰوَٰتِ',
              },
            ],
            'd': 'ضابط الفاتحة والأنعام',
          }
        ]
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      QuranMutashabihatService.setHttpClient(mockClient);

      final cards = await QuranMutashabihatService.getSimilarVerses(
        surah: 1,
        ayah: 2,
      );

      expect(cards.length, 1);
      expect(cards[0].places.length, 2);
      expect(cards[0].rule, 'ضابط الفاتحة والأنعام');
    });

    test('QuranMutashabihatService falls back gracefully when network fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      QuranMutashabihatService.setHttpClient(mockClient);

      final cards = await QuranMutashabihatService.getSimilarVerses(
        surah: 114,
        ayah: 1,
      );

      // Should complete gracefully without crashing or throwing
      expect(cards, isNotNull);
    });
  });

  group('AyahSimilarTabView Widget Tests', () {
    tearDown(() {
      QuranMutashabihatService.resetHttpClient();
    });

    testWidgets('renders similar cards and calls navigation callback',
        (tester) async {
      final mockData = {
        'cards': [
          {
            'id': 42,
            'places': [
              {
                's': 2,
                'a': 10,
                'f': 1,
                't': 2,
                'text': 'فِي قُلُوبِهِم مَّرَضٌ',
              },
              {
                's': 3,
                'a': 7,
                'f': 1,
                't': 2,
                'text': 'فِي قُلُوبِهِمْ زَيْغٌ',
              },
            ],
            'd': 'قاعدة الحصر والتمييز',
            'w': 'سر التعبير بالمرض مقابل الزيغ',
            'r': 'ملاك التأويل',
          }
        ]
      };

      QuranMutashabihatService.setHttpClient(
        MockClient((_) async => http.Response(
              json.encode(mockData),
              200,
              headers: {'content-type': 'application/json'},
            )),
      );

      int? navigatedSurah;
      int? navigatedAyah;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AyahSimilarTabView(
              surahNumber: 2,
              ayahNumber: 10,
              onNavigateToVerse: (s, a) {
                navigatedSurah = s;
                navigatedAyah = a;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // Check Header
      expect(find.textContaining('مواضع المتشابهات'), findsOneWidget);

      // Check Places
      expect(find.text('هذه الآية'), findsOneWidget);
      expect(find.text('انتقال'), findsOneWidget);

      // Check Rule & Rhetoric & Ref
      expect(find.text('الضابط الحفظي للتمييز:'), findsOneWidget);
      expect(find.text('قاعدة الحصر والتمييز'), findsOneWidget);
      expect(find.text('سر اختلاف اللفظ والتوجيه البلاغي:'), findsOneWidget);
      expect(find.text('ملاك التأويل'), findsOneWidget);

      // Tap on navigation tile
      await tester.tap(find.text('انتقال'));
      await tester.pump();

      expect(navigatedSurah, 3);
      expect(navigatedAyah, 7);
    });

    testWidgets('renders empty state when no similar cards exist',
        (tester) async {
      QuranMutashabihatService.setHttpClient(
        MockClient((_) async => http.Response(
              json.encode({'cards': []}),
              200,
              headers: {'content-type': 'application/json'},
            )),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AyahSimilarTabView(
              surahNumber: 114,
              ayahNumber: 6,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('آية فريدة في سياقها القرآني'), findsOneWidget);
    });
  });
}
