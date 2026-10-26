import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';

/// Prestigious Scholarly Top Bar for Shamela Reader
/// Smoothly transitions between minimal reading HUD and full action toolbar.
class ShamelaReaderTopBar extends StatefulWidget {
  final String title;
  final String author;
  final int currentPage;
  final int totalPages;
  final bool showControls;
  final Color bgColor;
  final ShamelaAccentColor accentColor;
  final ShamelaReaderSurface surface;
  final VoidCallback onBack;
  final VoidCallback onCopy;
  final VoidCallback? onSwitchToCurriculum;
  final VoidCallback? onOpenFihris;
  final VoidCallback? onOpenBookmarks;
  final ShamelaBook? book;

  const ShamelaReaderTopBar({
    super.key,
    required this.title,
    required this.author,
    required this.currentPage,
    required this.totalPages,
    required this.showControls,
    required this.bgColor,
    this.accentColor = ShamelaAccentColor.emerald,
    this.surface = ShamelaReaderSurface.normal,
    required this.onBack,
    required this.onCopy,
    this.onSwitchToCurriculum,
    this.onOpenFihris,
    this.onOpenBookmarks,
    this.book,
  });

  @override
  State<ShamelaReaderTopBar> createState() => _ShamelaReaderTopBarState();
}

class _ShamelaReaderTopBarState extends State<ShamelaReaderTopBar> {
  late final ValueNotifier<double> _downloadProgress;
  bool _isDownloading = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _downloadProgress = ValueNotifier<double>(0.0);
    _checkDownloaded();
  }

  Future<void> _checkDownloaded() async {
    if (widget.book == null) return;
    final downloaded = await ShamelaService.isBookDownloaded(widget.book!.id);
    if (mounted) {
      setState(() => _isDownloaded = downloaded);
    }
  }

  @override
  void dispose() {
    _downloadProgress.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    if (widget.book == null || _isDownloading || _isDownloaded) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress.value = 0.0;
    });

    try {
      await ShamelaService.downloadBook(
        widget.book!,
        onProgress: (current, total) {
          if (!mounted) return;
          if (total > 0) {
            _downloadProgress.value = (current / total).clamp(0.0, 1.0);
          }
        },
      );
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surfaceTokens = ReaderSurfaceColors.getTokens(
      widget.surface,
      isDark: palette.isDark,
    );
    final isEffectiveDark = widget.surface == ShamelaReaderSurface.night ||
        (widget.surface == ShamelaReaderSurface.normal && palette.isDark);
    final accent = ReaderAccentColors.getTokens(
      widget.accentColor,
      isDark: isEffectiveDark,
    );
    final topPadding = MediaQuery.paddingOf(context).top;
    final fullBarHeight = topPadding + AppSize.navH + AppSpace.lg;
    final minimalBarHeight = topPadding + 42.0;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      height: widget.showControls ? fullBarHeight : minimalBarHeight,
      decoration: BoxDecoration(
        color: widget.showControls
            ? surfaceTokens.surfaceRaised
            : surfaceTokens.bg,
        border: Border(
          bottom: BorderSide(
            color: widget.showControls
                ? surfaceTokens.border
                : surfaceTokens.border.withValues(alpha: 0.35),
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
                opacity: widget.showControls ? 0.0 : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: textTheme.titleSmall.copyWith(
                          color: surfaceTokens.text,
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
                        color: accent.soft,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: accent.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'صفحة ${widget.currentPage} من ${widget.totalPages}',
                        style: textTheme.caption.copyWith(
                          color: accent.onSoft,
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
              height: AppSize.navH + AppSpace.lg,
              child: IgnorePointer(
                ignoring: !widget.showControls,
                child: AnimatedOpacity(
                  duration: AppMotion.fast,
                  curve: AppMotion.easeOut,
                  opacity: widget.showControls ? 1.0 : 0.0,
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        iconSize: AppIcon.sm,
                        tooltip: 'رجوع',
                        color: surfaceTokens.text,
                        onPressed: widget.onBack,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: textTheme.titleSmall.copyWith(
                                color: surfaceTokens.text,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.author,
                              style: textTheme.captionBold.copyWith(
                                color: accent.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      if (widget.onSwitchToCurriculum != null)
                        AppIconButton(
                          tooltip: 'العودة لمتن التحفيظ المعتمد',
                          onPressed: widget.onSwitchToCurriculum,
                          icon: Icons.auto_stories_rounded,
                          color: accent.primary,
                          iconSize: AppIcon.sm,
                        ),

                      if (widget.onOpenFihris != null)
                        AppIconButton(
                          tooltip: 'فهرس الكتاب',
                          onPressed: widget.onOpenFihris,
                          icon: Icons.format_list_bulleted_rounded,
                          color: surfaceTokens.text,
                          iconSize: AppIcon.sm,
                        ),

                      if (widget.onOpenBookmarks != null)
                        AppIconButton(
                          tooltip: 'الصفحات المحفوظة',
                          onPressed: widget.onOpenBookmarks,
                          icon: Icons.bookmark_outlined,
                          color: surfaceTokens.text,
                          iconSize: AppIcon.sm,
                        ),

                      if (widget.book != null) ...[
                        if (_isDownloaded)
                          Semantics(
                            label: 'تم حفظ الكتاب للقراءة دون اتصال',
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: AppSize.tap,
                                minHeight: AppSize.tap,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.download_done_outlined,
                                  color: palette.primary,
                                  size: AppIcon.sm,
                                ),
                              ),
                            ),
                          )
                        else
                          AppIconButton(
                            tooltip: 'حفظ الكتاب للقراءة دون اتصال',
                            onPressed: _isDownloading ? null : _startDownload,
                            icon: Icons.download_outlined,
                            color: surfaceTokens.text,
                            iconSize: AppIcon.sm,
                          ),
                      ],

                      AppIconButton(
                        tooltip: 'نسخ الصفحة',
                        onPressed: widget.onCopy,
                        icon: Icons.copy_rounded,
                        color: surfaceTokens.text,
                        iconSize: AppIcon.sm,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Download Progress Indicator along bottom edge ────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _downloadProgress,
                builder: (context, progress, _) {
                  if (!_isDownloading) return const SizedBox.shrink();
                  return AppProgress(progress: progress);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
