import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
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

class _LevelBooksPageState extends State<LevelBooksPage> {
  final ProgressService _progressService = ProgressService();

  Future<LevelProgress> _loadLevelProgress() async {
    final all = await _progressService.getAllProgress();
    final bookIds = widget.level.books.map((b) => b.id).toSet();

    final completed = all
        .where(
          (p) =>
              bookIds.contains(p.bookId) &&
              p.status == BookProgressStatus.completed,
        )
        .length;

    final hasProgress = all.any(
      (p) =>
          bookIds.contains(p.bookId) &&
          (p.status != BookProgressStatus.notStarted ||
              p.completedLessons > 0),
    );

    return LevelProgress(completed, widget.level.books.length, hasProgress);
  }

  Future<void> _openFirstBook() async {
    if (widget.level.books.isEmpty) return;
    final book = widget.level.books.first;
    await Navigator.push(
      context,
      buildFadeRoute(
        page: BookViewPage(book: book),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PrimaryAppBar(
        title: widget.level.title,
        showBack: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<LevelProgress>(
              future: _loadLevelProgress(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 24);
                }

                final progress = snapshot.data!;
                final completed = progress.completed;
                final total = progress.total;

                final progressValue = total == 0 ? 0.0 : completed / total;

                if (!progress.hasProgress) {
                  return EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'لم تبدأ هذه المرحلة بعد',
                    message: 'ابدأ بأول كتاب لتسير مع العلم خطوة بخطوة.',
                    actionLabel: 'ابدأ الآن',
                    onAction: _openFirstBook,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تقدم المرحلة', style: AppText.heading),
                    const SizedBox(height: 8),
                    Text(
                      '$completed / $total كتب مكتملة',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: progressValue),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            color: AppColors.primary,
                            backgroundColor:
                                AppColors.textPrimary.withValues(alpha: 0.08),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: widget.level.books.length,
                separatorBuilder: (context, _) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final book = widget.level.books[index];

                  return FutureBuilder<BookProgress?>(
                    future: _progressService.getProgress(book.id),
                    builder: (context, snapshot) {
                      final progress = snapshot.data ??
                          BookProgress(
                            bookId: book.id,
                            status: BookProgressStatus.notStarted,
                            completedLessons: 0,
                            totalLessons: 0,
                          );

                      return BookCard(
                        book: book,
                        progress: progress,
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await Navigator.push<bool>(
                            context,
                            buildFadeRoute(
                              page: BookViewPage(book: book),
                            ),
                          );

                          if (mounted) {
                            setState(() {});
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
