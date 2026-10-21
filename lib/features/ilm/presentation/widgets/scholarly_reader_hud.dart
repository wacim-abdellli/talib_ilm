import 'dart:async';
import 'package:flutter/material.dart';

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
  final bool showPageNavigation;
  final VoidCallback? onShare;
  final VoidCallback? onToggleAudio;
  final bool isAudioActive;
  final ShamelaAccentColor accentColor;
  final ShamelaReaderSurface surface;

  const ScholarlyReaderHud({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isBookmarked,
    required this.memorizationMode,
    required this.showControls,
    this.showPageNavigation = true,
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
    this.onToggleAudio,
    this.isAudioActive = false,
    this.accentColor = ShamelaAccentColor.emerald,
    this.surface = ShamelaReaderSurface.normal,
  });

  static const double hudHeight = 104.0;
  static const double toolstripHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surfaceTokens = ReaderSurfaceColors.getTokens(
      surface,
      isDark: palette.isDark,
    );
    final isEffectiveDark = surface == ShamelaReaderSurface.night ||
        (surface == ShamelaReaderSurface.normal && palette.isDark);
    final accent = ReaderAccentColors.getTokens(
      accentColor,
      isDark: isEffectiveDark,
    );

    final effectiveHeight = showPageNavigation ? hudHeight : toolstripHeight;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      height: showControls ? effectiveHeight : 0.0,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: effectiveHeight,
          maxHeight: effectiveHeight,
          child: Container(
            decoration: BoxDecoration(
              color: surfaceTokens.surfaceRaised,
              border: Border(
                top: BorderSide(color: surfaceTokens.border, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Row 1: Fast Page Navigation (if enabled) ────────
                if (showPageNavigation) ...[
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
                          color: surfaceTokens.text,
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
                              color: surfaceTokens.bg,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(color: surfaceTokens.border, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: AppIcon.xs,
                                  color: accent.primary,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  'صفحة $currentPage من $totalPages',
                                  style: textTheme.label.copyWith(
                                    color: surfaceTokens.text,
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
                          color: surfaceTokens.text,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: surfaceTokens.border),
                ],

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
                        iconColor: isBookmarked ? accent.primary : surfaceTokens.text,
                        textColor: surfaceTokens.text,
                        onTap: onToggleBookmark,
                        onLongPress: onShowBookmarks,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      _buildToolItem(
                        icon: Icons.edit_note_rounded,
                        label: 'ملاحظة',
                        iconColor: surfaceTokens.text,
                        textColor: surfaceTokens.text,
                        onTap: onAddNote,
                        onLongPress: onShowBookmarks,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      _buildToolItem(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'الفهرس',
                        iconColor: surfaceTokens.text,
                        textColor: surfaceTokens.text,
                        onTap: onOpenFihris,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      if (onToggleAudio != null)
                        _buildToolItem(
                          icon: isAudioActive
                              ? Icons.headphones_rounded
                              : Icons.headphones_outlined,
                          label: 'استماع',
                          iconColor: isAudioActive ? accent.primary : surfaceTokens.text,
                          textColor: surfaceTokens.text,
                          bgColor: isAudioActive ? accent.soft : null,
                          onTap: onToggleAudio!,
                          palette: palette,
                          textTheme: textTheme,
                        ),
                      _buildToolItem(
                        icon: memorizationMode
                            ? Icons.visibility_off_rounded
                            : Icons.psychology_outlined,
                        label: 'تسميع',
                        iconColor: memorizationMode ? accent.primary : surfaceTokens.text,
                        textColor: surfaceTokens.text,
                        bgColor: memorizationMode ? accent.soft : null,
                        onTap: onToggleMemorization,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      _buildToolItem(
                        icon: Icons.text_format_rounded,
                        label: 'الخط',
                        iconColor: surfaceTokens.text,
                        textColor: surfaceTokens.text,
                        onTap: onOpenTypography,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      if (onShare != null)
                        _buildToolItem(
                          icon: Icons.share_rounded,
                          label: 'مشاركة',
                          iconColor: surfaceTokens.text,
                          textColor: surfaceTokens.text,
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
    required Color textColor,
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
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
