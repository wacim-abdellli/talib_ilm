import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/adhkar/data/adhkar_models.dart';
import 'package:talib_ilm/features/adhkar/presentation/adhkar_session_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/widgets/adhkar_fahras_sheet.dart';

void main() {
  group('Adhkar Fahras (Table of Contents) Tests', () {
    final testItems = [
      const AthkarItem(
        id: 'dhikr_1',
        arabic: 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
        transliteration: '',
        meaning: '',
        target: 1,
        countDescription: 'دَعْوَةُ ذِي النُّونِ عَلَيْهِ السَّلَامُ',
        fadl: 'دعوة لم يدع بها مسلم قط إلا استجاب الله له',
        source: 'الترمذي',
        audio: '',
        hadithText: '',
        hadithExplanation: '',
        order: 1,
        type: 0,
      ),
      const AthkarItem(
        id: 'dhikr_2',
        arabic: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
        transliteration: '',
        meaning: '',
        target: 3,
        countDescription: 'ثلاث مرات',
        fadl: 'مغفرة الذنوب',
        source: 'مسلم',
        audio: '',
        hadithText: '',
        hadithExplanation: '',
        order: 2,
        type: 0,
      ),
      const AthkarItem(
        id: 'dhikr_3',
        arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
        transliteration: '',
        meaning: '',
        target: 100,
        countDescription: 'مائة مرة',
        fadl: 'حُطت خطاياه وإن كانت مثل زبد البحر',
        source: 'البخاري',
        audio: '',
        hadithText: '',
        hadithExplanation: '',
        order: 3,
        type: 0,
      ),
    ];

    testWidgets('AdhkarFahrasSheet renders all items with titles and excerpts', (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedIndex = await showAdhkarFahrasSheet(
                      context: context,
                      categoryTitle: 'أذكار الكرب والهم',
                      items: testItems,
                      currentIndex: 0,
                      counts: {'dhikr_1': 1, 'dhikr_2': 1, 'dhikr_3': 0},
                      favoriteIdFor: (it) => it.id,
                      repeatFor: (items, idx) => items[idx].target,
                    );
                  },
                  child: const Text('Open Fahras'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to open sheet
      await tester.tap(find.text('Open Fahras'));
      await tester.pumpAndSettle();

      // Verify sheet title and header
      expect(find.text('فهرس الأذكار'), findsOneWidget);
      expect(find.text('أذكار الكرب والهم'), findsOneWidget);
      expect(find.text('مكتمل 1 من 3'), findsOneWidget);

      // Verify items are rendered
      expect(find.text('دَعْوَةُ ذِي النُّونِ عَلَيْهِ السَّلَامُ'), findsOneWidget);
      expect(find.textContaining('لَا إِلَهَ إِلَّا أَنْتَ'), findsOneWidget);
      expect(find.textContaining('أَسْتَغْفِرُ اللَّهَ'), findsOneWidget);
      expect(find.textContaining('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ'), findsOneWidget);

      // Tap the second item (index 1)
      await tester.tap(find.textContaining('أَسْتَغْفِرُ اللَّهَ'));
      await tester.pumpAndSettle();

      // Verify returning selected index 1
      expect(selectedIndex, equals(1));
    });

    testWidgets('AdhkarFahrasSheet search filters items dynamically', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAdhkarFahrasSheet(
                      context: context,
                      categoryTitle: 'أذكار الكرب',
                      items: testItems,
                      currentIndex: 0,
                      counts: const {},
                      favoriteIdFor: (it) => it.id,
                      repeatFor: (items, idx) => items[idx].target,
                    );
                  },
                  child: const Text('Open Search Fahras'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Search Fahras'));
      await tester.pumpAndSettle();

      // Enter search query "النون"
      await tester.enterText(find.byType(TextField), 'النون');
      await tester.pumpAndSettle();

      // Should only match dhikr 1
      expect(find.text('دَعْوَةُ ذِي النُّونِ عَلَيْهِ السَّلَامُ'), findsOneWidget);
      expect(find.textContaining('أَسْتَغْفِرُ اللَّهَ'), findsNothing);
      expect(find.textContaining('سُبْحَانَ اللَّهِ'), findsNothing);
    });

    testWidgets('AdhkarSessionPage has Fahras list button in app bar', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final categoryData = AthkarCategoryData(
        id: 'distress',
        title: 'أذكار الكرب والهم',
        subtitle: '',
        items: testItems,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdhkarSessionPage(
            category: AdhkarCategory.distress,
            categoryData: categoryData,
          ),
        ),
      );

      await tester.pump();
      await tester.idle();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Fahras icon button is present in AppBar
      expect(find.byTooltip('فهرس الأذكار'), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);

      // Tap the Fahras button in the AppBar
      await tester.tap(find.byTooltip('فهرس الأذكار'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Fahras sheet opened
      expect(find.text('فهرس الأذكار'), findsOneWidget);
      expect(find.text('أذكار الكرب والهم'), findsNWidgets(2));
    });
  });
}
