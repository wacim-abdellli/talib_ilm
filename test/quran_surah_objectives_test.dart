import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/models/surah_objectives_card.dart';
import 'package:talib_ilm/features/quran/data/services/quran_surah_objectives_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/surah_objectives_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    QuranSurahObjectivesService().setHttpClient(null);
  });

  group('Surah Objectives Models Serialization', () {
    test('SurahThematicSection serializes and deserializes', () {
      const section = SurahThematicSection(
        title: 'افتتاح السورة بالحمد',
        startAyah: 1,
        endAyah: 4,
        description: 'بيان محامد الله وصفات كماله.',
      );

      final jsonMap = section.toJson();
      final fromJson = SurahThematicSection.fromJson(jsonMap);

      expect(fromJson.title, 'افتتاح السورة بالحمد');
      expect(fromJson.startAyah, 1);
      expect(fromJson.endAyah, 4);
      expect(fromJson.description, 'بيان محامد الله وصفات كماله.');
    });

    test('SurahObjectivesCard roundtrip serialization', () {
      const card = SurahObjectivesCard(
        surahNumber: 1,
        name: 'الفاتحة',
        vocalizedName: 'الفَاتِحَة',
        englishName: 'Al-Faatiha',
        englishMeaning: 'The Opening',
        revelationPlace: 'مكية',
        revelationOrder: 5,
        versesCount: 7,
        startPage: 1,
        otherNames: ['أم الكتاب', 'السبع المثاني'],
        mainObjective: 'تحقيق العبودية الخالصة لله تعالى.',
        namingReason: 'لافتتاح المصحف بها.',
        thematicSections: [
          SurahThematicSection(
            title: 'الثناء على الله',
            startAyah: 1,
            endAyah: 4,
            description: '',
          ),
        ],
        virtues: ['أعظم سورة في كتاب الله'],
        connectionWithPrevious: 'فاتحة كتاب الله وأم القرآن.',
      );

      final jsonMap = card.toJson();
      final deserialized = SurahObjectivesCard.fromJson(jsonMap);

      expect(deserialized.surahNumber, 1);
      expect(deserialized.name, 'الفاتحة');
      expect(deserialized.isMakki, isTrue);
      expect(deserialized.otherNames.length, 2);
      expect(deserialized.thematicSections.length, 1);
      expect(deserialized.virtues.length, 1);
    });
  });

  group('QuranSurahObjectivesService API & Fallback', () {
    test('fetches and extracts Markaz Tafsir purpose from Source 65', () async {
      final mockData = {
        '1': {
          't': '* من مقاصد السورة:\nتحقيق العبودية الخالصة لله تعالى.\n* التفسير:\nباسم الله أبدأ قراءة القرآن...',
        },
      };

      final client = MockClient((request) async {
        if (request.url.path.contains('/api/source/65/1')) {
          return http.Response(
            json.encode(mockData),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = QuranSurahObjectivesService();
      service.setHttpClient(client);

      final result = await service.getSurahObjectives(1);
      expect(result.surahNumber, 1);
      expect(result.name, 'الفاتحة');
      expect(result.mainObjective, 'تحقيق العبودية الخالصة لله تعالى.');
      expect(result.revelationOrder, 5);
      expect(result.revelationPlace, 'مكية');
      expect(result.thematicSections.length, 3);
      expect(result.otherNames, contains('السبع المثاني'));
    });

    test('returns authentic bundled data on network failure', () async {
      final client = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = QuranSurahObjectivesService();
      service.setHttpClient(client);

      final result = await service.getSurahObjectives(2);
      expect(result.surahNumber, 2);
      expect(result.name, 'البقرة');
      expect(result.isMakki, isFalse);
      expect(result.revelationOrder, 87);
      expect(result.mainObjective, contains('الاستخلاف في الأرض'));
      expect(result.thematicSections.length, 6);
    });
  });

  group('SurahObjectivesSheet Widget Tests', () {
    Widget buildTestWidget({
      double textScale = 1.0,
      void Function(int surah, int ayah)? onNavigate,
    }) {
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
              child: SurahObjectivesSheet(
                surahNumber: 1,
                onNavigateToVerse: onNavigate,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders all identity, objective, and thematic cards across text scales', (tester) async {
      int? navigatedSurah;
      int? navigatedAyah;

      await tester.pumpWidget(
        buildTestWidget(
          textScale: 1.0,
          onNavigate: (s, a) {
            navigatedSurah = s;
            navigatedAyah = a;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Header and identity
      expect(find.textContaining('الفاتحة'), findsAtLeastNWidgets(1));
      expect(find.text('مكان النزول'), findsOneWidget);
      expect(find.text('ترتيب النزول'), findsOneWidget);
      expect(find.text('المقصد الرئيس للسورة'), findsOneWidget);

      // Thematic section tap
      final firstSection = find.textContaining('1. الثناء والتمجيد لله تعالى');
      expect(firstSection, findsOneWidget);

      await tester.tap(firstSection);
      await tester.pumpAndSettle();

      expect(navigatedSurah, 1);
      expect(navigatedAyah, 1);

      // Test text scaling 2.0 without overflow
      await tester.pumpWidget(buildTestWidget(textScale: 2.0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

