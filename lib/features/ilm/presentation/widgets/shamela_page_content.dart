import 'package:flutter/material.dart';

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
  final ShamelaAccentColor accentColor;

  const ShamelaPageContent({
    super.key,
    required this.page,
    required this.memorizationMode,
    required this.fontFamily,
    required this.fontSizeDelta,
    required this.lineHeight,
    this.accentColor = ShamelaAccentColor.emerald,
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
    final accent = ReaderAccentColors.getTokens(
      widget.accentColor,
      isDark: palette.isDark,
    );

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
                Center(
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: accent.soft,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: accent.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: AppIcon.xs,
                          color: accent.primary,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(
                          child: Text(
                            page.chapterTitle!,
                            style: textTheme.caption.copyWith(
                              color: accent.onSoft,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],

              // Reflowable Text Body with classical manuscript margin
              Container(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(
                      color: accent.border,
                      width: 2.0,
                    ),
                  ),
                ),
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpace.md,
                  end: AppSpace.xs,
                ),
                child: widget.memorizationMode
                    ? MutnMemorizationView(
                        content: page.content,
                        fontFamily: widget.fontFamily,
                        fontSizeDelta: widget.fontSizeDelta,
                        lineHeight: widget.lineHeight,
                      )
                    : Text.rich(
                        ShamelaTextHighlighter.buildSpans(
                          text: page.content,
                          palette: palette,
                          textTheme: textTheme,
                          fontFamily: widget.fontFamily,
                          fontSizeDelta: widget.fontSizeDelta,
                          lineHeight: widget.lineHeight,
                          accentColor: widget.accentColor,
                        ),
                        textAlign: TextAlign.start,
                      ),
              ),

              // Footnotes (الحواشي والتحقيق) Section if present
              if (page.hamesh != null && page.hamesh!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.xl),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: accent.border,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_edu_rounded,
                            color: accent.primary,
                            size: AppIcon.xs,
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Text(
                            'الحواشي والتحقيق',
                            style: textTheme.caption.copyWith(
                              color: accent.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: accent.border,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: palette.border,
                      width: 1,
                    ),
                  ),
                  child: Text.rich(
                    ShamelaTextHighlighter.buildSpans(
                      text: page.hamesh!,
                      palette: palette,
                      textTheme: textTheme,
                      fontFamily: widget.fontFamily,
                      fontSizeDelta: widget.fontSizeDelta * 0.7 - 2.0,
                      lineHeight: 1.6,
                      accentColor: widget.accentColor,
                    ),
                    textAlign: TextAlign.start,
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
