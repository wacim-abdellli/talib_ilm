import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';

/// Clean, scholarly bottom sheet presenting the student's in-progress and completed books.
/// Follows Calm Scholar design system strictly.
class IlmReadingTrackerSheet extends StatefulWidget {
  final List<BookProgress> inProgressBooks;
  final List<BookProgress> completedBooks;
  final int totalLibraryBooks;
  final Map<String, IlmBook> bookCatalog;
  final void Function(String bookId) onOpenBook;

  const IlmReadingTrackerSheet({
    super.key,
    required this.inProgressBooks,
    required this.completedBooks,
    required this.totalLibraryBooks,
    required this.bookCatalog,
    required this.onOpenBook,
  });

  static Future<void> show({
    required BuildContext context,
    required List<BookProgress> inProgressBooks,
    required List<BookProgress> completedBooks,
    required int totalLibraryBooks,
    required Map<String, IlmBook> bookCatalog,
    required void Function(String bookId) onOpenBook,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IlmReadingTrackerSheet(
        inProgressBooks: inProgressBooks,
        completedBooks: completedBooks,
        totalLibraryBooks: totalLibraryBooks,
        bookCatalog: bookCatalog,
        onOpenBook: onOpenBook,
      ),
    );
  }

  @override
  State<IlmReadingTrackerSheet> createState() => _IlmReadingTrackerSheetState();
}

class _IlmReadingTrackerSheetState extends State<IlmReadingTrackerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTab = widget.inProgressBooks.isEmpty &&
            widget.completedBooks.isNotEmpty
        ? 1
        : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatLastRead(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'منذ دقيقة' : 'منذ $mins دقيقة';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1
          ? 'منذ ساعة'
          : hours == 2
              ? 'منذ ساعتين'
              : 'منذ $hours ساعات';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1
          ? 'أمس'
          : days == 2
              ? 'منذ يومين'
              : 'منذ $days أيام';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    final completionPercent = widget.totalLibraryBooks > 0
        ? ((widget.completedBooks.length / widget.totalLibraryBooks) * 100)
            .toInt()
        : 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border.all(color: palette.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Drag Handle ──
              Center(
                child: Container(
                  margin: const EdgeInsetsDirectional.only(
                    top: AppSpace.md,
                    bottom: AppSpace.xs,
                  ),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),

              // ── Header Title & Dismiss ──
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.xl,
                  AppSpace.sm,
                  AppSpace.xl,
                  AppSpace.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Icon(
                        Icons.collections_bookmark_rounded,
                        color: palette.primary,
                        size: AppIcon.md,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سجل المدارسة والإنجاز',
                            style: textTheme.titleSmall.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'متابعة المتون والكتب التي تواصل مدارستها',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'إغلاق',
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: palette.textMuted,
                          size: AppIcon.md,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'إغلاق',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stat Summary Cards ──
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        palette: palette,
                        icon: Icons.menu_book_rounded,
                        accentColor: palette.primary,
                        accentSoft: palette.primarySoft,
                        label: 'قيد المدارسة',
                        value: '${widget.inProgressBooks.length}',
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        palette: palette,
                        icon: Icons.check_circle_outline_rounded,
                        accentColor: palette.gold,
                        accentSoft: palette.goldSoft,
                        label: 'المنجز',
                        value:
                            '${widget.completedBooks.length}/${widget.totalLibraryBooks}',
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        palette: palette,
                        icon: Icons.auto_graph_rounded,
                        accentColor: palette.primary,
                        accentSoft: palette.primarySoft,
                        label: 'نسبة الإنجاز',
                        value: '$completionPercent%',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              // ── Navigation Tabs ──
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.xs,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border, width: 0.8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: palette.surfaceRaised,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: palette.border, width: 0.8),
                    ),
                    labelColor: palette.primary,
                    unselectedLabelColor: palette.textMuted,
                    labelStyle: textTheme.label.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: textTheme.label,
                    tabs: [
                      Tab(
                        text: 'قيد المتابعة (${widget.inProgressBooks.length})',
                      ),
                      Tab(
                        text: 'المنجز (${widget.completedBooks.length})',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              // ── Tab View Content ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── 1. In-Progress Books List ──
                    _buildInProgressList(context, palette, textTheme),

                    // ── 2. Completed Books List ──
                    _buildCompletedList(context, palette, textTheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMetricCard(
    BuildContext context, {
    required AppPalette palette,
    required IconData icon,
    required Color accentColor,
    required Color accentSoft,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: palette.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, color: accentColor, size: AppIcon.sm),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  label,
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            value,
            style: context.text.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInProgressList(
    BuildContext context,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    if (widget.inProgressBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: AppIcon.hero,
                color: palette.textMuted,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لا توجد متون قيد المدارسة حالياً',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'اختر متناً أو كتاباً مباركاً من المكتبة للبدء في مدارسته وقراءته',
                style: textTheme.bodySmall.copyWith(
                  color: palette.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsetsDirectional.all(AppSpace.xl),
      itemCount: widget.inProgressBooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpace.md),
      itemBuilder: (context, index) {
        final progress = widget.inProgressBooks[index];
        final book = widget.bookCatalog[progress.bookId];
        final title = book?.title ?? progress.bookTitle;
        final author = book?.author ?? 'علم شرعي';
        final total = progress.totalPages > 0 ? progress.totalPages : 1;
        final current = progress.currentPage.clamp(1, total);
        final ratio = (current / total).clamp(0.0, 1.0);
        final percentText = '${(ratio * 100).toInt()}%';

        return Material(
          color: palette.surface,
          borderRadius: AppRadius.lgRadius,
          child: InkWell(
            borderRadius: AppRadius.lgRadius,
            onTap: () {
              Navigator.of(context).pop();
              widget.onOpenBook(progress.bookId);
            },
            child: Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: palette.border, width: 0.9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.titleSmall.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpace.xxs),
                            Text(
                              author,
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          percentText,
                          style: textTheme.caption.copyWith(
                            color: palette.onPrimarySoft,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: palette.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpace.sm),

                  // Footer info and action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_outline_rounded,
                            size: AppIcon.xs,
                            color: palette.textMuted,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'صفحة $current من $total',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Text(
                            '• ${_formatLastRead(progress.lastReadDate)}',
                            style: textTheme.caption.copyWith(
                              color: palette.textSubtle,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'متابعة',
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: AppIcon.xs,
                            color: palette.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedList(
    BuildContext context,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    if (widget.completedBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: AppIcon.hero,
                color: palette.textMuted,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لم تكتمل أي متون بعد',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'واصل القراءة اليومية لإنهاء متونك الشرعية ونيل شرف ختمها مباركة',
                style: textTheme.bodySmall.copyWith(
                  color: palette.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsetsDirectional.all(AppSpace.xl),
      itemCount: widget.completedBooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpace.md),
      itemBuilder: (context, index) {
        final progress = widget.completedBooks[index];
        final book = widget.bookCatalog[progress.bookId];
        final title = book?.title ?? progress.bookTitle;
        final author = book?.author ?? 'علم شرعي';
        final total = progress.totalPages > 0 ? progress.totalPages : 1;

        return Material(
          color: palette.surface,
          borderRadius: AppRadius.lgRadius,
          child: InkWell(
            borderRadius: AppRadius.lgRadius,
            onTap: () {
              Navigator.of(context).pop();
              widget.onOpenBook(progress.bookId);
            },
            child: Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgRadius,
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: palette.gold,
                      size: AppIcon.md,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          author,
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          'تمت قراءة كامل المتن ($total صفحة)',
                          style: textTheme.caption.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  AppButton(
                    label: 'مراجعة',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.tonal,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOpenBook(progress.bookId);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
