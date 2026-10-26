import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import 'ilm_reading_tracker_completed_tab.dart';
import 'ilm_reading_tracker_in_progress_tab.dart';

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
                    IlmReadingTrackerInProgressTab(
                      inProgressBooks: widget.inProgressBooks,
                      bookCatalog: widget.bookCatalog,
                      onOpenBook: widget.onOpenBook,
                    ),

                    // ── 2. Completed Books List ──
                    IlmReadingTrackerCompletedTab(
                      completedBooks: widget.completedBooks,
                      bookCatalog: widget.bookCatalog,
                      onOpenBook: widget.onOpenBook,
                    ),
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
                  style: context.text.captionBold.copyWith(
                    color: palette.textMuted,
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
}
