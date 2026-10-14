import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';

void main() {
  group('LearningPulseCard Safe Progress Tests', () {
    final testBook = IlmBook(
      id: 'book_adab',
      title: 'الآداب والأذكار',
      author: 'الشيخ عبد الرزاق البدر',
      subject: 'الآداب والأذكار',
      level: '1',
      description: 'متن في الآداب والأذكار الشرعية',
      totalPages: 100,
      shuruh: const [],
    );

    Widget buildTestHarness(Widget child) {
      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: child,
          ),
        ),
      );
    }

    testWidgets('renders 0% مكتمل and never null% when progressPercent and page are null', (tester) async {
      final continueData = ContinueData(
        book: testBook,
        tab: 'mutn',
        page: null,
        total: null,
        progressPercent: null,
      );

      await tester.pumpWidget(
        buildTestHarness(LearningPulseCard(data: continueData)),
      );

      expect(find.textContaining('null%'), findsNothing);
      expect(find.text('0% مكتمل'), findsOneWidget);
      expect(find.text('متابعة القراءة'), findsOneWidget);
      expect(find.text('الآداب والأذكار'), findsNWidgets(2)); // Subject and title
    });

    testWidgets('calculates percentage dynamically when progressPercent is null but page/total present', (tester) async {
      final continueData = ContinueData(
        book: testBook,
        tab: 'mutn',
        page: 25,
        total: 100,
        progressPercent: null,
      );

      await tester.pumpWidget(
        buildTestHarness(LearningPulseCard(data: continueData)),
      );

      expect(find.textContaining('null%'), findsNothing);
      expect(find.text('25% مكتمل'), findsOneWidget);
      expect(find.text('صفحة 25'), findsOneWidget);
    });

    testWidgets('renders explicit progressPercent correctly', (tester) async {
      final continueData = ContinueData(
        book: testBook,
        tab: 'mutn',
        page: 50,
        total: 100,
        progressPercent: 50,
      );

      await tester.pumpWidget(
        buildTestHarness(LearningPulseCard(data: continueData)),
      );

      expect(find.text('50% مكتمل'), findsOneWidget);
      expect(find.text('صفحة 50'), findsOneWidget);
    });

    testWidgets('renders empty state when data is null without error', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(const LearningPulseCard(data: null)),
      );

      expect(find.text('ابدأ رحلة طلب العلم'), findsOneWidget);
      expect(find.text('المستوى الأول'), findsOneWidget);
      expect(find.textContaining('null%'), findsNothing);
    });
  });
}
