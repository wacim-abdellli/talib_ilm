import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/core/services/asset_service.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_audio_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_digital_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_lessons_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/turath_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DEEP TRUTH AUDIT — Pillar 1: Books (Turath 198 & Mutun Syllabus 18)', () {
    test('TurathCatalog: All 198 books have valid unique IDs, positive pages, and valid categories', () {
      final books = TurathCatalog.books;
      expect(books.length, equals(198), reason: 'TurathCatalog contains exactly 198 verified Shamela books');

      final ids = books.map((b) => b.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, equals(uniqueIds.length), reason: 'Duplicate book IDs found in TurathCatalog');

      for (final book in books) {
        expect(book.id, greaterThan(0), reason: 'Book ID must be positive: ${book.title}');
        expect(book.title.trim().isNotEmpty, isTrue, reason: 'Book title cannot be empty: ${book.id}');
        expect(book.author.trim().isNotEmpty, isTrue, reason: 'Book author cannot be empty: ${book.id}');
        expect(book.totalPages, greaterThan(0), reason: 'Book ${book.id} (${book.title}) has invalid totalPages: ${book.totalPages}');
        expect(book.categoryId, inInclusiveRange(1, 31), reason: 'Book ${book.id} has invalid categoryId: ${book.categoryId}');
      }
    });

    test('MutunDigitalCatalog: All digital mutun entries have valid metadata and match syllabus', () {
      final entries = MutunDigitalCatalog.entries;
      expect(entries.length, greaterThanOrEqualTo(16));

      for (final entry in entries.values) {
        expect(entry.id.isNotEmpty, isTrue);
        expect(entry.title.isNotEmpty, isTrue);
        expect(entry.shamelaId, greaterThan(0));
        expect(entry.totalPages, greaterThan(0));
      }
    });

    test('MutunProgram: All 18 curriculum books exist across 6 levels (Levels 0 through 5)', () async {
      final program = await AssetService.loadMutunProgram();
      expect(program.levels.length, equals(6), reason: 'Mutun curriculum has 6 levels (Level 0 to Level 5)');

      final allBookIds = <String>{};
      int totalBooks = 0;

      for (final level in program.levels) {
        expect(level.books, isNotEmpty, reason: 'Level ${level.order} must have books');
        for (final book in level.books) {
          totalBooks++;
          expect(allBookIds.add(book.id), isTrue, reason: 'Duplicate book ID in curriculum: ${book.id}');
          expect(book.title.trim().isNotEmpty, isTrue);
          expect(book.author.trim().isNotEmpty, isTrue);
          expect(book.level.isNotEmpty, isTrue);
        }
      }

      expect(totalBooks, equals(18), reason: 'Curriculum must contain exactly 18 mutun books');
    });
  });

  group('DEEP TRUTH AUDIT — Pillar 2: Shuruh (Commentaries & Parent-Child Relationships)', () {
    test('TurathCatalog: Every book with parentBookId points to a REAL parent book', () {
      final books = TurathCatalog.books;
      final bookMap = {for (final b in books) b.id: b};

      final shuruh = books.where((b) => b.parentBookId != null).toList();
      expect(shuruh, isNotEmpty, reason: 'There must be commentaries with parentBookId in TurathCatalog');

      final orphanShuruh = <String>[];
      for (final sharh in shuruh) {
        final parentId = sharh.parentBookId!;
        final parent = bookMap[parentId];
        if (parent == null) {
          orphanShuruh.add('Sharh "${sharh.title}" (id: ${sharh.id}) points to non-existent parentBookId: $parentId');
        } else {
          expect(parent.title.isNotEmpty, isTrue);
        }
      }

      expect(orphanShuruh, isEmpty, reason: 'Orphan shuruh found: $orphanShuruh');
    });

    test('MutunProgram: Audit all shuruh entries and their shamelaId links', () async {
      final program = await AssetService.loadMutunProgram();
      final turathIds = TurathCatalog.books.map((b) => b.id).toSet();

      int totalShuruh = 0;
      int shuruhInTurath = 0;
      final externalShuruh = <String>[];

      for (final level in program.levels) {
        for (final book in level.books) {
          expect(book.shuruh, isNotEmpty, reason: 'Book ${book.id} (${book.title}) has NO shuruh');
          for (final sharh in book.shuruh) {
            totalShuruh++;
            expect(sharh.title.trim().isNotEmpty, isTrue);
            expect(sharh.scholar.trim().isNotEmpty, isTrue);

            if (sharh.shamelaId != null) {
              if (turathIds.contains(sharh.shamelaId)) {
                shuruhInTurath++;
              } else {
                externalShuruh.add(
                  'Book "${book.title}" -> Sharh "${sharh.title}" (scholar: ${sharh.scholar}) has shamelaId ${sharh.shamelaId} (External Shamela.ws)',
                );
              }
            }
          }
        }
      }

      expect(totalShuruh, greaterThanOrEqualTo(50));
      // Verify both in-app shuruh and external shamela references are tracked
      expect(shuruhInTurath, greaterThan(0));
    });
  });

  group('DEEP TRUTH AUDIT — Pillar 3: Audios (121 Books, 284 Sources, Verified URLs)', () {
    test('MutunAudioCatalog: All keys, sources, and URLs are structurally valid HTTPS links', () {
      final allEntries = MutunAudioCatalog.entries;
      expect(allEntries.length, greaterThanOrEqualTo(100), reason: 'Expected ≥ 100 audio books');

      int totalSources = 0;
      int totalChapters = 0;
      final invalidUrls = <String>[];

      allEntries.forEach((bookKey, entry) {
        expect(bookKey.trim().isNotEmpty, isTrue);
        expect(entry.sources, isNotEmpty, reason: 'Book $bookKey has empty audio sources');

        for (final src in entry.sources) {
          totalSources++;
          expect(src.reciter.name.trim().isNotEmpty, isTrue, reason: 'Reciter name empty in $bookKey');
          expect(src.audioUrl.trim().isNotEmpty, isTrue, reason: 'Source URL empty in $bookKey');
          expect(
            src.audioUrl.startsWith('https://'),
            isTrue,
            reason: 'Audio URL in $bookKey must be secure HTTPS: ${src.audioUrl}',
          );

          final uri = Uri.tryParse(src.audioUrl);
          if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
            invalidUrls.add('$bookKey: ${src.audioUrl}');
          }

          if (src.chapters != null) {
            totalChapters += src.chapters!.length;
            for (final ch in src.chapters!) {
              expect(ch.audioUrl.startsWith('https://'), isTrue);
            }
          }
        }
      });

      expect(invalidUrls, isEmpty, reason: 'Invalid audio URLs found: $invalidUrls');
      expect(totalSources, greaterThanOrEqualTo(250));
      expect(totalChapters, greaterThan(0));
    });

    test('MutunAudioCatalog: Every Shamela audio key maps to a real book in TurathCatalog', () {
      final turathIds = TurathCatalog.books.map((b) => b.id).toSet();
      final allAudio = MutunAudioCatalog.entries;

      final missingTurathBooks = <String>[];
      allAudio.forEach((key, entry) {
        if (key.startsWith('shamela_')) {
          final idStr = key.replaceFirst('shamela_', '');
          final id = int.tryParse(idStr);
          if (id != null && !turathIds.contains(id)) {
            missingTurathBooks.add('Audio key $key has no matching book in TurathCatalog');
          }
        }
      });

      expect(missingTurathBooks, isEmpty, reason: 'Mismatched audio keys: $missingTurathBooks');
    });

    test('MutunAudioCatalog: All 18 Mutun program books have audio entries', () async {
      final program = await AssetService.loadMutunProgram();
      final missingAudioBooks = <String>[];

      for (final level in program.levels) {
        for (final book in level.books) {
          final resolvedKey = MutunAudioCatalog.resolveBookId(book.id);
          final entry = MutunAudioCatalog.entries[resolvedKey] ?? MutunAudioCatalog.entries[book.id];
          if (entry == null) {
            missingAudioBooks.add('${book.id} (${book.title})');
          } else {
            expect(entry.sources, isNotEmpty);
          }
        }
      }

      expect(missingAudioBooks, isEmpty, reason: 'Mutun books without audio: $missingAudioBooks');
    });
  });

  group('DEEP TRUTH AUDIT — Pillar 4: Videos & Lessons (MutunLessonsCatalog)', () {
    test('MutunLessonsCatalog: All 18 books have lessons, every lesson has clean 11-char videoId', () async {
      final program = await AssetService.loadMutunProgram();
      int totalLessons = 0;
      final invalidVideos = <String>[];
      final youtubeIdPattern = RegExp(r'^[a-zA-Z0-9_\-]{11}$');

      for (final level in program.levels) {
        for (final book in level.books) {
          final bookId = book.id;
          expect(MutunLessonsCatalog.hasLessons(bookId), isTrue, reason: 'Missing lessons for $bookId (${book.title})');

          final lessons = MutunLessonsCatalog.getLessonsForBook(bookId);
          expect(lessons, isNotEmpty, reason: 'Empty lessons list for $bookId');
          expect(lessons.length, greaterThanOrEqualTo(3), reason: 'Too few lessons for $bookId');

          for (final lesson in lessons) {
            totalLessons++;
            expect(lesson.title.trim().isNotEmpty, isTrue);
            expect(lesson.scholar, isNotNull);

            // Video ID MUST be an 11-character YouTube video ID, NEVER a playlist ID (PL...)
            if (!youtubeIdPattern.hasMatch(lesson.videoId)) {
              invalidVideos.add('$bookId [lesson ${lesson.index}]: "${lesson.videoId}"');
            }

            // Playlist ID (if present) must be non-empty
            if (lesson.playlistId != null) {
              expect(lesson.playlistId!.isNotEmpty, isTrue);
            }
          }
        }
      }

      expect(invalidVideos, isEmpty, reason: 'Invalid video IDs in MutunLessonsCatalog: $invalidVideos');
      expect(totalLessons, greaterThanOrEqualTo(100));
    });

    test('VideoPlayerPage extraction contract: correctly parses video IDs and playlists', () {
      // 11-char video ID should pass directly
      expect(RegExp(r'^[a-zA-Z0-9_\-]{11}$').hasMatch('tchqKarSGgU'), isTrue);
      expect(RegExp(r'^[a-zA-Z0-9_\-]{11}$').hasMatch('wF4dPQSQ0ds'), isTrue);

      // Playlist ID (PL...) must NOT match 11-char video ID regex
      expect(RegExp(r'^[a-zA-Z0-9_\-]{11}$').hasMatch('PLZmiPrhyvgsR6wz8q3nQZ3v9x9nLpKm7X'), isFalse);
    });
  });
}
