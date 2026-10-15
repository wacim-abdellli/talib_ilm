import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

/// Prestigious Scholarly Top Bar for Shamela Reader
/// Smoothly transitions between minimal reading HUD and full action toolbar.
class ShamelaReaderTopBar extends StatelessWidget {
  final String title;
  final String author;
  final int currentPage;
  final int totalPages;
  final bool showControls;
  final Color bgColor;
  final VoidCallback onBack;
  final VoidCallback onCopy;

  const ShamelaReaderTopBar({
    super.key,
    required this.title,
    required this.author,
    required this.currentPage,
    required this.totalPages,
    required this.showControls,
    required this.bgColor,
    required this.onBack,
    required this.onCopy,
  });
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final topPadding = MediaQuery.paddingOf(context).top;
    final fullBarHeight = topPadding + AppSize.navH;
    final minimalBarHeight = topPadding + 42.0;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      height: showControls ? fullBarHeight : minimalBarHeight,
      decoration: BoxDecoration(
        color: showControls ? palette.surfaceRaised : bgColor,
        border: Border(
          bottom: BorderSide(
            color: showControls
                ? palette.border
                : palette.border.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            // ── Minimal Distraction-Free Header (Shown when controls hidden) ──
            Positioned(
              top: topPadding,
              left: AppSpace.md,
              right: AppSpace.md,
              height: 42.0,
              child: AnimatedOpacity(
                duration: AppMotion.fast,
                curve: AppMotion.easeOut,
                opacity: showControls ? 0.0 : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: palette.goldSoft,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: palette.gold.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'صفحة $currentPage من $totalPages',
                        style: textTheme.caption.copyWith(
                          color: palette.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Full Action Toolbar (Shown when controls visible) ────────────
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: AppSize.navH,
              child: IgnorePointer(
                ignoring: !showControls,
                child: AnimatedOpacity(
                  duration: AppMotion.fast,
                  curve: AppMotion.easeOut,
                  opacity: showControls ? 1.0 : 0.0,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: AppIcon.sm,
                        ),
                        tooltip: 'رجوع',
                        color: palette.text,
                        onPressed: onBack,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.titleSmall.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              author,
                              style: textTheme.caption.copyWith(
                                color: palette.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ListenableBuilder(
                        listenable: themeService,
                        builder: (context, _) {
                          return IconButton(
                            tooltip: themeService.themeDisplayName,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              themeService.toggleTheme();
                            },
                            icon: Icon(
                              themeService.themeIcon,
                              color: palette.text,
                              size: AppIcon.sm,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'نسخ الصفحة',
                        onPressed: onCopy,
                        icon: Icon(
                          Icons.copy_rounded,
                          color: palette.text,
                          size: AppIcon.sm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
