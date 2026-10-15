import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/asset_service.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_lessons_catalog.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/book_lessons_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Mutun Program Data Enrichment Tests', () {
    test('All 18 mutun books are enriched with non-empty shuruh and video playlists', () async {
      final program = await AssetService.loadMutunProgram();
      expect(program.levels, isNotEmpty);

      int totalBooks = 0;
      for (final level in program.levels) {
        for (final book in level.books) {
          totalBooks++;
          // 1. Playlist ID must be valid and non-empty
          expect(
            book.playlistId,
            isNotNull,
            reason: '${book.id} must have a video_playlist defined',
          );
          expect(
            book.playlistId!.isNotEmpty,
            isTrue,
            reason: '${book.id} playlistId should not be empty',
          );

          // 2. Shuruh list must be non-empty and well-populated
          expect(
            book.shuruh,
            isNotEmpty,
            reason: '${book.id} must have at least one sharh',
          );

          for (final sharh in book.shuruh) {
            expect(sharh.title.isNotEmpty, isTrue);
            expect(sharh.scholar.isNotEmpty, isTrue);
            expect(
              sharh.file,
              isNot(contains('needs_review')),
              reason: '${book.id} sharh ${sharh.title} should not be needs_review',
            );
            expect(
              sharh.shamelaId,
              isNotNull,
              reason: '${book.id} sharh ${sharh.title} must have a verified shamelaId',
            );
          }

          // 3. Lessons Catalog must have curated lecture series
          final lessons = MutunLessonsCatalog.getLessonsForBook(book.id);
          expect(
            lessons,
            isNotEmpty,
            reason: '${book.id} must have curated lessons in MutunLessonsCatalog',
          );
          expect(lessons.length, greaterThanOrEqualTo(5));
          expect(lessons.first.title.isNotEmpty, isTrue);
          expect(lessons.first.scholar, isNotNull);
        }
      }

      expect(totalBooks, 18, reason: 'Curriculum must contain exactly 18 books');
    });

    testWidgets('BookLessonsTab renders curriculum header and lessons list properly', (tester) async {
      final lessons = MutunLessonsCatalog.getLessonsForBook('bk_adhkar_adab');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookLessonsTab(
              bookId: 'bk_adhkar_adab',
              bookTitle: 'الآداب والأذكار',
              lessons: lessons,
              onGoToMutn: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header info
      expect(find.textContaining('الشيخ عبد الرزاق البدر'), findsWidgets);
      expect(find.textContaining('درساً'), findsWidgets);

      // Check lesson cards
      expect(find.text(lessons[0].title), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsWidgets);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsWidgets);
    });
  });
}
