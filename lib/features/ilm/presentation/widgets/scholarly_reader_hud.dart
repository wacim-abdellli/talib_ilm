import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

/// Transparent pointer-based tap detector for book reading pages.
/// Accurately detects quick tap gestures anywhere on the page (even on text or whitespace)
/// to toggle distraction-free immersion, without blocking vertical scrolling or text selection.
class BookPageTapDetector extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const BookPageTapDetector({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  State<BookPageTapDetector> createState() => _BookPageTapDetectorState();
}

class _BookPageTapDetectorState extends State<BookPageTapDetector> {
  Offset? _downPos;
  Timer? _longPressTimer;
  bool _isCancelled = false;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _downPos = event.position;
        _isCancelled = false;
        _longPressTimer?.cancel();
        _longPressTimer = Timer(AppMotion.searchDebounce, () {
          _isCancelled = true;
        });
      },
      onPointerMove: (event) {
        if (_downPos != null) {
          final distance = (event.position - _downPos!).distance;
          if (distance >= 10.0) {
            _isCancelled = true;
            _longPressTimer?.cancel();
          }
        }
      },
      onPointerUp: (event) {
        _longPressTimer?.cancel();
        if (_downPos != null && !_isCancelled) {
          final distance = (event.position - _downPos!).distance;
          if (distance < 10.0) {
            widget.onTap();
          }
        }
      },
      onPointerCancel: (_) {
        _longPressTimer?.cancel();
        _isCancelled = true;
      },
      child: widget.child,
    );
  }
}

/// Unified scholarly bottom navigation bar and toolstrip for Islamic book and mutun readers.
/// Animates smoothly into and out of view for distraction-free full-screen reading immersion.
class ScholarlyReaderHud extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isBookmarked;
  final bool memorizationMode;
  final bool showControls;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback onPageIndicatorTap;
  final VoidCallback onToggleBookmark;
  final VoidCallback? onShowBookmarks;
  final VoidCallback onAddNote;
  final VoidCallback onOpenFihris;
  final VoidCallback onToggleMemorization;
  final VoidCallback onOpenTypography;
  final VoidCallback? onShare;

  const ScholarlyReaderHud({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isBookmarked,
    required this.memorizationMode,
    required this.showControls,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onPageIndicatorTap,
    required this.onToggleBookmark,
    this.onShowBookmarks,
    required this.onAddNote,
    required this.onOpenFihris,
    required this.onToggleMemorization,
    required this.onOpenTypography,
    this.onShare,
  });

  static const double hudHeight = 104.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      height: showControls ? hudHeight : 0.0,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: hudHeight,
          maxHeight: hudHeight,
          child: Container(
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              border: Border(
                top: BorderSide(color: palette.border, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Row 1: Fast Page Navigation ────────────────────────
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xxs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: AppIcon.sm,
                        ),
                        tooltip: 'الصفحة السابقة',
                        onPressed: onPreviousPage,
                        color: palette.text,
                      ),
                      InkWell(
                        onTap: onPageIndicatorTap,
                        borderRadius: AppRadius.pillRadius,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(color: palette.border, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: AppIcon.xs,
                                color: palette.gold,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                'صفحة $currentPage من $totalPages',
                                style: textTheme.label.copyWith(
                                  color: palette.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: AppIcon.sm,
                        ),
                        tooltip: 'الصفحة التالية',
                        onPressed: onNextPage,
                        color: palette.text,
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: palette.border),

                // ── Row 2: Consolidated Scholarly Toolstrip ───────────
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildToolItem(
                        icon: isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: isBookmarked ? 'محفوظة' : 'إشارة',
                        iconColor: isBookmarked ? palette.gold : palette.text,
                        onTap: onToggleBookmark,
                        onLongPress: onShowBookmarks,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      _buildToolItem(
                        icon: Icons.edit_note_rounded,
                        label: 'ملاحظة',
                        iconColor: palette.text,
                        onTap: onAddNote,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      _buildToolItem(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'الفهرس',
                        iconColor: palette.text,
                        onTap: onOpenFihris,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      _buildToolItem(
                        icon: memorizationMode
                            ? Icons.visibility_off_rounded
                            : Icons.psychology_outlined,
                        label: 'تسميع',
                        iconColor: memorizationMode ? palette.primary : palette.text,
                        bgColor: memorizationMode ? palette.primarySoft : null,
                        onTap: onToggleMemorization,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      _buildToolItem(
                        icon: Icons.text_format_rounded,
                        label: 'الخط',
                        iconColor: palette.text,
                        onTap: onOpenTypography,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      if (onShare != null)
                        _buildToolItem(
                          icon: Icons.share_rounded,
                          label: 'مشاركة',
                          iconColor: palette.text,
                          onTap: onShare!,
                          palette: palette,
                          textTheme: textTheme,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? bgColor,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.smRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xxs,
          ),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.transparent,
            borderRadius: AppRadius.smRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIcon.sm, color: iconColor),
              const SizedBox(height: AppSpace.xxs),
              Text(
                label,
                style: textTheme.caption.copyWith(
                  color: palette.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
