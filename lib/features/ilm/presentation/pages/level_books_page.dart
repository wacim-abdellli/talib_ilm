import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/mutun_models.dart';
import '../../../../core/services/progress_service.dart';
import '../../../ilm/data/models/progress_models.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../widgets/book_card.dart';
import 'book_view_page.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_app_bar.dart';

class LevelBooksPage extends StatefulWidget {
  final IlmLevel level;

  const LevelBooksPage({super.key, required this.level});

  @override
  State<LevelBooksPage> createState() => _LevelBooksPageState();
}

enum _BooksFilter { all, inProgress, completed }

class _LevelBooksPageState extends State<LevelBooksPage> {
  final ProgressService _progressService = ProgressService();

  bool _loading = true;
  Map<String, BookProgress> _progressByBookId = {};
  _BooksFilter _filter = _BooksFilter.all;

  @override
  void initState() {
    super.initState();
    _warmLoad();
  }

  Future<void> _warmLoad() async {
    final all = await _progressService.getAllProgress();

    final map = <String, BookProgress>{};
    for (final p in all) {
      map[p.bookId] = p;
    }

    if (!mounted) return;
    setState(() {
      _progressByBookId = map;
      _loading = false;
    });
  }

  BookProgress _progressOf(String bookId) {
    return _progressByBookId[bookId] ??
        BookProgress(
          bookId: bookId,
          status: BookProgressStatus.notStarted,
          completedLessons: 0,
          totalLessons: 0,
        );
  }

  LevelProgress _levelProgress() {
    final bookIds = widget.level.books.map((b) => b.id).toSet();

    int completed = 0;
    bool hasProgress = false;

    for (final id in bookIds) {
      final p = _progressOf(id);

      if (p.status == BookProgressStatus.completed) {
        completed += 1;
      }

      final started = p.status != BookProgressStatus.notStarted ||
          (p.completedLessons > 0);
      if (started) hasProgress = true;
    }

    return LevelProgress(completed, widget.level.books.length, hasProgress);
  }

  List<BookWithProgress> _filteredBooks() {
    final items = widget.level.books
        .map((b) => BookWithProgress(book: b, progress: _progressOf(b.id)))
        .toList();

    switch (_filter) {
      case _BooksFilter.all:
        return items;

      case _BooksFilter.inProgress:
        return items.where((x) {
          final p = x.progress;
          if (p.status == BookProgressStatus.completed) return false;
          if (p.status != BookProgressStatus.notStarted) return true;
          return p.completedLessons > 0;
        }).toList();

      case _BooksFilter.completed:
        return items
            .where((x) => x.progress.status == BookProgressStatus.completed)
            .toList();
    }
  }

  Future<void> _openBook(IlmBook book) async {
    HapticFeedback.selectionClick();
    await Navigator.push<bool>(
      context,
      buildFadeRoute(page: BookViewPage(book: book)),
    );
    if (!mounted) return;
    await _warmLoad(); // refresh progress after returning
  }

  Future<void> _openFirstBook() async {
    if (widget.level.books.isEmpty) return;
    await _openBook(widget.level.books.first);
  }

  Future<void> _openContinueBook() async {
    // Simple logic: first book that is started but not completed.
    for (final b in widget.level.books) {
      final p = _progressOf(b.id);
      final started = p.status != BookProgressStatus.notStarted ||
          p.completedLessons > 0;
      final done = p.status == BookProgressStatus.completed;

      if (started && !done) {
        await _openBook(b);
        return;
      }
    }

    // fallback: open first
    await _openFirstBook();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _levelProgress();
    final completed = progress.completed;
    final total = progress.total;
    final progressValue = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    final books = _filteredBooks();

    return Scaffold(
      appBar: UnifiedAppBar(
        title: widget.level.title,
        showBack: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Padding(
          padding: AppUi.screenPaddingCompact,
          child: Column(
          children: [
            // ---------- HERO HEADER ----------
            Container(
              padding: const EdgeInsets.all(AppUi.gapLG),
              decoration: BoxDecoration(
                gradient: AppColors.surfaceElevatedGradient,
                borderRadius: BorderRadius.circular(AppUi.radiusLG),
                border: Border.all(
                  color: AppColors.stroke,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.levelProgressTitle, style: AppText.heading),
                  const SizedBox(height: AppUi.gapSM),
                  Text(
                    AppStrings.levelCompletedSummary(completed, total),
                    style: AppText.bodyMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppUi.gapMD),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppUi.radiusPill),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: AppUi.progressBarHeight,
                      color: AppColors.primary,
                      backgroundColor:
                          AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(height: AppUi.gapLG),

                  // actions
                  Row(
                    children: [
                      Expanded(
                        child: _PrimaryMiniButton(
                          label: AppStrings.actionStartNow,
                          onTap: _openFirstBook,
                        ),
                      ),
                      const SizedBox(width: AppUi.gapMD),
                      Expanded(
                        child: _SecondaryMiniButton(
                          label: 'متابعة',
                          onTap: _openContinueBook,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppUi.gapLG),

            // ---------- FILTER CHIPS ----------
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: _filter == _BooksFilter.all,
                    onTap: () => setState(() => _filter = _BooksFilter.all),
                  ),
                  const SizedBox(width: AppUi.gapSM),
                  _FilterChip(
                    label: 'قيد التقدم',
                    selected: _filter == _BooksFilter.inProgress,
                    onTap: () => setState(() => _filter = _BooksFilter.inProgress),
                  ),
                  const SizedBox(width: AppUi.gapSM),
                  _FilterChip(
                    label: 'مكتمل',
                    selected: _filter == _BooksFilter.completed,
                    onTap: () => setState(() => _filter = _BooksFilter.completed),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppUi.gapLG),

            // ---------- CONTENT ----------
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (!progress.hasProgress && widget.level.books.isNotEmpty)
                      ? EmptyState(
                          icon: Icons.flag_outlined,
                          title: AppStrings.levelNotStartedTitle,
                          message: AppStrings.levelNotStartedMessage,
                          actionLabel: AppStrings.actionStartNow,
                          onAction: _openFirstBook,
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: books.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppUi.gapLG),
                          itemBuilder: (context, index) {
                            final item = books[index];
                            return BookCard(
                              book: item.book,
                              progress: item.progress,
                              onTap: () => _openBook(item.book),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class BookWithProgress {
  final IlmBook book;
  final BookProgress progress;

  BookWithProgress({required this.book, required this.progress});
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppUi.radiusPill),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppUi.gapLG,
          vertical: AppUi.gapSM,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.18) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppUi.radiusPill),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.textPrimary.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: selected ? AppText.body : AppText.bodyMuted,
        ),
      ),
    );
  }
}

class _PrimaryMiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryMiniButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppUi.radiusPill),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppUi.gapMD),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppUi.radiusPill),
        ),
        child: Text(label, style: AppText.button),
      ),
    );
  }
}

class _SecondaryMiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryMiniButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppUi.radiusPill),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppUi.gapMD),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppUi.radiusPill),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Text(label, style: AppText.body),
      ),
    );
  }
}

/// Simple helper model (NO Dart records)
class LevelProgress {
  final int completed;
  final int total;
  final bool hasProgress;

  LevelProgress(this.completed, this.total, this.hasProgress);
}
