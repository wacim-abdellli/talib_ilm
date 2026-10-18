import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/mutun_audio_service.dart';
import '../../data/services/shamela_service.dart';
import 'mutn_memorization_view.dart';
import 'mutn_paragraphs_view.dart';

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
  final ShamelaReaderSurface surface;
  final int startingParagraphIndex;
  final MutunAudioService? audioService;
  final bool initialHameshExpanded;

  const ShamelaPageContent({
    super.key,
    required this.page,
    required this.memorizationMode,
    required this.fontFamily,
    required this.fontSizeDelta,
    required this.lineHeight,
    this.accentColor = ShamelaAccentColor.emerald,
    this.surface = ShamelaReaderSurface.normal,
    this.startingParagraphIndex = 1,
    this.audioService,
    this.initialHameshExpanded = true,
  });

  @override
  State<ShamelaPageContent> createState() => _ShamelaPageContentState();
}

class _ShamelaPageContentState extends State<ShamelaPageContent> {
  late final ScrollController _scrollController;
  late bool _isHameshExpanded;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _isHameshExpanded = widget.initialHameshExpanded;
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
                    : MutnParagraphsView(
                        content: page.content,
                        fontFamily: widget.fontFamily,
                        fontSizeDelta: widget.fontSizeDelta,
                        lineHeight: widget.lineHeight,
                        accentColor: widget.accentColor,
                        surface: widget.surface,
                        startingIndex: widget.startingParagraphIndex,
                        audioService: widget.audioService,
                      ),
              ),

              // Footnotes (الهامش والحواشي) Section if present
              if (page.hamesh != null) ...[
                Builder(
                  builder: (context) {
                    final cleanHamesh =
                        ShamelaService.sanitizeBookText(page.hamesh!);
                    if (cleanHamesh.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpace.xl),
                        Divider(
                          color: palette.border,
                          height: 1,
                          thickness: 1,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isHameshExpanded = !_isHameshExpanded;
                            });
                          },
                          borderRadius: AppRadius.smRadius,
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(minHeight: AppSize.tap),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.sm,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.format_quote_rounded,
                                          size: AppIcon.sm,
                                          color: palette.textMuted,
                                        ),
                                        const SizedBox(width: AppSpace.xs),
                                        Flexible(
                                          child: Text(
                                            'الهامش والحواشي',
                                            style: textTheme.caption.copyWith(
                                              color: palette.textMuted,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.xs),
                                  Icon(
                                    _isHameshExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: AppIcon.md,
                                    color: palette.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: AppSpace.xs,
                              bottom: AppSpace.md,
                              start: AppSpace.sm,
                              end: AppSpace.sm,
                            ),
                            child: Text(
                              cleanHamesh,
                              style: textTheme.bodySmall.copyWith(
                                color: palette.textMuted,
                                height: 1.6,
                                fontFamily: widget.fontFamily,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          crossFadeState: _isHameshExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: AppMotion.fast,
                        ),
                      ],
                    );
                  },
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
