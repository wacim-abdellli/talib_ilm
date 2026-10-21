import '../../../../core/services/asset_service.dart';
import '../catalogs/mutun_curriculum_catalog.dart';
import '../catalogs/mutun_digital_catalog.dart';
import '../catalogs/turath_catalog.dart';
import '../models/mutun_models.dart';
import '../models/shamela_models.dart';
import '../models/sharh_model.dart';
import 'book_progress_service.dart';

class BookmarkEntry {
  final String bookId;
  final String title;
  final String subtitle;
  final int page;
  final int? totalPages;
  final String? note;
  final bool isBookmark;
  final String? sharhFile;
  final DateTime? date;

  const BookmarkEntry({
    this.bookId = '',
    required this.title,
    required this.subtitle,
    this.page = 1,
    this.totalPages,
    this.note,
    this.isBookmark = true,
    this.sharhFile,
    this.date,
  });

  BookmarkEntry copyWith({
    String? bookId,
    String? title,
    String? subtitle,
    int? page,
    int? totalPages,
    String? note,
    bool? isBookmark,
    String? sharhFile,
    DateTime? date,
  }) {
    return BookmarkEntry(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      note: note ?? this.note,
      isBookmark: isBookmark ?? this.isBookmark,
      sharhFile: sharhFile ?? this.sharhFile,
      date: date ?? this.date,
    );
  }
}

class BookmarkEntryLoader {
  static String resolveBookTitle({
    required String bookId,
    required String storedTitle,
    required Map<String, IlmBook> bookById,
  }) {
    // 1. If stored title is genuine Arabic and not a raw identifier
    final isRawId = storedTitle.isEmpty ||
        storedTitle == bookId ||
        storedTitle.startsWith('bk_') ||
        storedTitle.contains('_');
    if (!isRawId) {
      return storedTitle;
    }

    // 2. Curriculum syllabus mutun
    final curriculumBook = MutunCurriculumCatalog.getBook(bookId);
    if (curriculumBook != null && curriculumBook.title.isNotEmpty) {
      return curriculumBook.title;
    }

    // 3. Digital text catalog
    final digitalEntry = MutunDigitalCatalog.getEntry(bookId);
    if (digitalEntry != null && digitalEntry.title.isNotEmpty) {
      return digitalEntry.title;
    }

    // 4. Mutun program levels
    final programBook = bookById[bookId];
    if (programBook != null && programBook.title.isNotEmpty) {
      return programBook.title;
    }

    // 5. Turath books catalog
    try {
      final turath = TurathCatalog.books.cast<ShamelaBook?>().firstWhere(
        (b) => b != null && (b.id.toString() == bookId || b.title == bookId),
        orElse: () => null,
      );
      if (turath != null && turath.title.isNotEmpty) {
        return turath.title;
      }
    } catch (_) {}

    return storedTitle.isNotEmpty ? storedTitle : bookId;
  }

  static String _formatSubtitle({
    required String bookId,
    required int page,
    int? totalPages,
  }) {
    final curriculum = MutunCurriculumCatalog.getBook(bookId);
    if (curriculum != null) {
      final totalParas = curriculum.totalParagraphs;
      final tPages = totalPages ?? MutunDigitalCatalog.getEntry(bookId)?.totalPages ?? 1;
      final paraIndex = (tPages > 0 && totalParas > 0)
          ? (((page - 1) * totalParas) ~/ tPages) + 1
          : page;

      String? sectionTitle;
      for (final s in curriculum.sections) {
        if (s.paragraphs.any((p) => p.index == paraIndex)) {
          sectionTitle = s.title;
          break;
        }
      }
      if (sectionTitle != null && sectionTitle.isNotEmpty) {
        return sectionTitle;
      }
    }
    return '';
  }

  static Future<List<BookmarkEntry>> loadAll(
    BookProgressService progressService,
  ) async {
    final allProgress = await progressService.getAllProgress();
    final sharhBookmarks = await progressService.getAllSharhBookmarks();
    final sharhNotes = await progressService.getAllSharhNotes();
    final program = await AssetService.loadMutunProgram();

    final bookById = <String, IlmBook>{};
    final sharhByKey = <String, Sharh>{};
    for (final level in program.levels) {
      for (final book in level.books) {
        bookById[book.id] = book;
        for (final sharh in book.shuruh) {
          sharhByKey['${book.id}|${sharh.file}'] = sharh;
        }
      }
    }

    final entries = <BookmarkEntry>[];

    for (final progress in allProgress) {
      final bookTitle = resolveBookTitle(
        bookId: progress.bookId,
        storedTitle: progress.bookTitle,
        bookById: bookById,
      );

      final digitalEntry = MutunDigitalCatalog.getEntry(progress.bookId);
      final totalPages = (digitalEntry != null && digitalEntry.totalPages > 0)
          ? digitalEntry.totalPages
          : (progress.totalPages > 0 ? progress.totalPages : null);

      for (final page in progress.bookmarkedPages) {
        entries.add(
          BookmarkEntry(
            bookId: progress.bookId,
            title: bookTitle,
            subtitle: _formatSubtitle(
              bookId: progress.bookId,
              page: page,
              totalPages: totalPages,
            ),
            page: page,
            totalPages: totalPages,
            note: progress.notes[page],
            isBookmark: true,
            date: progress.lastReadDate,
          ),
        );
      }

      for (final noteItem in progress.notes.entries) {
        if (noteItem.value.trim().isEmpty) continue;
        final page = noteItem.key;
        final alreadyAdded = entries.any(
          (e) =>
              e.bookId == progress.bookId &&
              e.page == page &&
              e.sharhFile == null,
        );
        if (!alreadyAdded) {
          entries.add(
            BookmarkEntry(
              bookId: progress.bookId,
              title: bookTitle,
              subtitle: _formatSubtitle(
                bookId: progress.bookId,
                page: page,
                totalPages: totalPages,
              ),
              page: page,
              totalPages: totalPages,
              note: noteItem.value,
              isBookmark: progress.bookmarkedPages.contains(page),
              date: progress.lastReadDate,
            ),
          );
        }
      }
    }

    for (final entry in sharhBookmarks.entries) {
      final sharh = sharhByKey[entry.key];
      final parts = entry.key.split('|');
      final bookId = parts.isNotEmpty ? parts.first : entry.key;
      final sharhFile = parts.length > 1 ? parts[1] : null;
      final bookTitle = resolveBookTitle(
        bookId: bookId,
        storedTitle: '',
        bookById: bookById,
      );
      final sharhTitle = sharh?.title ?? 'شرح';
      final notes = sharhNotes[entry.key] ?? <int, String>{};

      for (final page in entry.value) {
        entries.add(
          BookmarkEntry(
            bookId: bookId,
            title: bookTitle,
            subtitle: sharhTitle,
            page: page,
            note: notes[page],
            isBookmark: true,
            sharhFile: sharhFile,
          ),
        );
      }
    }

    for (final entry in sharhNotes.entries) {
      final sharh = sharhByKey[entry.key];
      final parts = entry.key.split('|');
      final bookId = parts.isNotEmpty ? parts.first : entry.key;
      final sharhFile = parts.length > 1 ? parts[1] : null;
      final bookTitle = resolveBookTitle(
        bookId: bookId,
        storedTitle: '',
        bookById: bookById,
      );
      final sharhTitle = sharh?.title ?? 'شرح';
      final bookmarkedList = sharhBookmarks[entry.key] ?? <int>[];

      for (final noteItem in entry.value.entries) {
        if (noteItem.value.trim().isEmpty) continue;
        final page = noteItem.key;
        if (!bookmarkedList.contains(page)) {
          entries.add(
            BookmarkEntry(
              bookId: bookId,
              title: bookTitle,
              subtitle: sharhTitle,
              page: page,
              note: noteItem.value,
              isBookmark: false,
              sharhFile: sharhFile,
            ),
          );
        }
      }
    }

    return entries;
  }
}
