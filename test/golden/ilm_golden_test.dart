import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'package:talib_ilm/features/ilm/data/models/progress_models.dart';
import 'package:talib_ilm/features/ilm/data/services/motivation_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/book_card.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_daily_progress_card.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/motivation_widgets.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/sharh_card.dart';
import 'golden_test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Ilm Widgets Golden Tests', () {
    final sampleBook = IlmBook(
      id: 'book1',
      title: 'الأصول الثلاثة وأدلتها',
      author: 'محمد بن عبد الوهاب',
      level: '1',
      subject: 'عقيدة',
      description: 'شرح الأصول الثلاثة',
      totalPages: 30,
      shuruh: [],
    );

    final sampleProgress = BookProgress(
      bookId: 'book1',
      status: BookProgressStatus.inProgress,
      completedLessons: 5,
      totalLessons: 10,
    );

    testWidgets('BookCard - light 1.0 and dark 1.5', (tester) async {
      final widget = BookCard(
        book: sampleBook,
        progress: sampleProgress,
        onTap: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/ilm_book_card_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/ilm_book_card_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('SharhCard - light 1.0 and dark 1.5', (tester) async {
      final widget = SharhCard(
        title: 'شرح الأصول الثلاثة',
        scholar: 'ابن عثيمين',
        difficulty: 'مبتدئ',
        totalPages: 150,
        currentPage: 50,
        onTap: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/ilm_sharh_card_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/ilm_sharh_card_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('IlmDailyProgressCard - light 1.0 and dark 1.5', (tester) async {
      final widget = IlmDailyProgressCard(
        dailyGoal: 5,
        pagesReadToday: 3,
        lastReadDate: DateTime.now(),
        onGoalChanged: (goal) async {},
        onStartFresh: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/ilm_daily_progress_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/ilm_daily_progress_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });

    testWidgets('DailyMotivationCard - light 1.0 and dark 1.5', (tester) async {
      final quote = DailyQuote(
        text: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ',
        source: 'صحيح مسلم',
        type: QuoteType.hadith,
      );

      final widget = DailyMotivationCard(
        quote: quote,
        onReload: () {},
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/ilm_motivation_light_1_0',
        isDark: false,
        textScale: 1.0,
      );

      await testGoldenWidget(
        tester: tester,
        widget: widget,
        fileName: 'goldens/ilm_motivation_dark_1_5',
        isDark: true,
        textScale: 1.5,
      );
    });
  });
}
