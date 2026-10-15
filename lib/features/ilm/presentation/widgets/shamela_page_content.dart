import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/shamela_models.dart';
import 'mutn_memorization_view.dart';
import 'shamela_text_highlighter.dart';

/// Single page content viewer for Shamela scholarly reader.
/// Each page owns its dedicated ScrollController to ensure isolated scrollbars
/// and prevent PrimaryScrollController conflicts in PageView.
class ShamelaPageContent extends StatefulWidget {
  final ShamelaPage page;
  final bool memorizationMode;
  final String fontFamily;
  final double fontSizeDelta;
  final double lineHeight;

  const ShamelaPageContent({
    super.key,
    required this.page,
    required this.memorizationMode,
    required this.fontFamily,
    required this.fontSizeDelta,
    required this.lineHeight,
  });

  @override
  State<ShamelaPageContent> createState() => _ShamelaPageContentState();
}

class _ShamelaPageContentState extends State<ShamelaPageContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final page = widget.page;

    return SelectionArea(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chapter Header Pill if present
              if (page.chapterTitle != null &&
                  page.chapterTitle!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: palette.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    page.chapterTitle!,
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],

              // Memorization Mode or Scholarly Syntax Highlighter
              if (widget.memorizationMode)
                MutnMemorizationView(
                  content: page.content,
                  fontFamily: widget.fontFamily,
                  fontSizeDelta: widget.fontSizeDelta,
                  lineHeight: widget.lineHeight,
                )
              else
                Text.rich(
                  ShamelaTextHighlighter.buildSpans(
                    text: page.content,
                    palette: palette,
                    textTheme: textTheme,
                    fontFamily: widget.fontFamily,
                    fontSizeDelta: widget.fontSizeDelta,
                    lineHeight: widget.lineHeight,
                  ),
                  textAlign: TextAlign.start,
                ),

              // Footnotes (الحواشي والتحقيق) Section if present
              if (page.hamesh != null && page.hamesh!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                Divider(color: palette.gold.withValues(alpha: 0.4), height: 1),
                const SizedBox(height: AppSpace.sm),
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            color: palette.primary,
                            size: AppIcon.sm,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'الحواشي والتحقيق:',
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text.rich(
                        ShamelaTextHighlighter.buildSpans(
                          text: page.hamesh!,
                          palette: palette,
                          textTheme: textTheme,
                          fontFamily: widget.fontFamily,
                          fontSizeDelta: widget.fontSizeDelta * 0.7 - 2.0,
                          lineHeight: 1.6,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpace.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
