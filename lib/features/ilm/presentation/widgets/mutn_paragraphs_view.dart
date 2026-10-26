import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/services/mutun_audio_service.dart';
import 'shamela_text_highlighter.dart';

/// Renders classical text split into numbered paragraphs with active audio highlight
/// and autonomous auto-scrolling that follows the reciter during playback.
class MutnParagraphsView extends StatefulWidget {
  final String content;
  final String fontFamily;
  final double fontSizeDelta;
  final double lineHeight;
  final ShamelaAccentColor accentColor;
  final ShamelaReaderSurface surface;
  final MutunAudioService? audioService;
  final int startingIndex;

  const MutnParagraphsView({
    super.key,
    required this.content,
    required this.fontFamily,
    required this.fontSizeDelta,
    required this.lineHeight,
    this.accentColor = ShamelaAccentColor.emerald,
    this.surface = ShamelaReaderSurface.normal,
    this.audioService,
    this.startingIndex = 1,
  });

  @override
  State<MutnParagraphsView> createState() => _MutnParagraphsViewState();
}

class _MutnParagraphsViewState extends State<MutnParagraphsView> {
  late final MutunAudioService _service;
  final Map<int, GlobalKey> _paragraphKeys = {};
  int? _lastScrolledIndex;

  @override
  void initState() {
    super.initState();
    _service = widget.audioService ?? MutunAudioService();
    _service.activeParagraphNotifier.addListener(_onAudioChanged);
    _service.isPlayingNotifier.addListener(_onAudioChanged);
    if (_service.isPlayingNotifier.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAudioChanged());
    }
  }

  @override
  void didUpdateWidget(covariant MutnParagraphsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioService != oldWidget.audioService) {
      _service.activeParagraphNotifier.removeListener(_onAudioChanged);
      _service.isPlayingNotifier.removeListener(_onAudioChanged);
      _service = widget.audioService ?? MutunAudioService();
      _service.activeParagraphNotifier.addListener(_onAudioChanged);
      _service.isPlayingNotifier.addListener(_onAudioChanged);
    }
  }

  @override
  void dispose() {
    _service.activeParagraphNotifier.removeListener(_onAudioChanged);
    _service.isPlayingNotifier.removeListener(_onAudioChanged);
    super.dispose();
  }

  void _onAudioChanged() {
    if (!mounted) return;
    if (!_service.isPlayingNotifier.value) return;
    final active = _service.activeParagraphNotifier.value;
    if (active == null || active == _lastScrolledIndex) return;

    if (_paragraphKeys.containsKey(active)) {
      _lastScrolledIndex = active;
      _scrollToParagraph(active);
    }
  }

  void _scrollToParagraph(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _paragraphKeys[index];
      final currentCtx = key?.currentContext;
      if (currentCtx != null && currentCtx.mounted) {
        Scrollable.ensureVisible(
          currentCtx,
          duration: AppMotion.slow,
          curve: Curves.easeInOutCubic,
          alignment: 0.22,
        );
      }
    });
  }

  List<String> _extractParagraphs(String raw) {
    final lines = raw.split('\n');
    final paragraphs = <String>[];
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (buffer.isNotEmpty) {
          paragraphs.add(buffer.toString().trim());
          buffer.clear();
        }
      } else {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(trimmed);
      }
    }
    if (buffer.isNotEmpty) {
      paragraphs.add(buffer.toString().trim());
    }

    return paragraphs.isNotEmpty ? paragraphs : [raw.trim()];
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);
    final paragraphs = _extractParagraphs(widget.content);

    return ValueListenableBuilder<bool>(
      valueListenable: _service.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return ValueListenableBuilder<int?>(
          valueListenable: _service.activeParagraphNotifier,
          builder: (context, activeIndex, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < paragraphs.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final pIndex = widget.startingIndex + i;
                      final key = _paragraphKeys.putIfAbsent(
                        pIndex,
                        () => GlobalKey(),
                      );
                      return Container(
                        key: key,
                        child: _buildParagraphBlock(
                          context: context,
                          index: pIndex,
                          text: paragraphs[i],
                          isActive: activeIndex == pIndex,
                          isPlaying: isPlaying,
                          palette: palette,
                          textTheme: textTheme,
                          tokens: tokens,
                          service: _service,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildParagraphBlock({
    required BuildContext context,
    required int index,
    required String text,
    required bool isActive,
    required bool isPlaying,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required MutunThemeTokens tokens,
    required MutunAudioService service,
  }) {
    // Only show the highlight container when audio is actively playing and following the reader.
    final bool showHighlight = isActive && isPlaying;

    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.easeOut,
      decoration: BoxDecoration(
        color: showHighlight ? tokens.activeParagraphBg : Colors.transparent,
        borderRadius: AppRadius.mdRadius,
        border: showHighlight
            ? Border.all(color: tokens.activeParagraphBorder, width: 1.0)
            : null,
      ),
      padding: EdgeInsetsDirectional.all(
        showHighlight ? AppSpace.md : AppSpace.xs,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (isPlaying) {
            if (isActive) {
              // Tapping the active reciting paragraph dismisses/toggles the highlight
              service.clearActiveParagraph();
            } else {
              // Tapping another paragraph seeks the audio recitation there
              service.seekToParagraph(index);
            }
          } else {
            // When not playing, ensure any lingering highlight is dismissed
            if (isActive) {
              service.clearActiveParagraph();
            }
          }
        },
        borderRadius: AppRadius.mdRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Paragraph Text ──────────────────────────────────────
            Text.rich(
              ShamelaTextHighlighter.buildSpans(
                text: text,
                palette: palette,
                textTheme: textTheme,
                fontFamily: widget.fontFamily,
                fontSizeDelta: widget.fontSizeDelta,
                lineHeight: widget.lineHeight,
                accentColor: widget.accentColor,
                surface: widget.surface,
              ),
              textAlign: TextAlign.start,
            ),

            // ── Paragraph Number Badge (-1-, -2- ...) (Only when audio syllabus is present) ──
            if (service.hasAudio) ...[
              const SizedBox(height: AppSpace.xs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: showHighlight
                        ? tokens.rosetteGold.withValues(alpha: 0.2)
                        : palette.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: showHighlight
                          ? tokens.rosetteGold
                          : palette.border.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '- $index -',
                    style: textTheme.caption.copyWith(
                      color: showHighlight
                          ? tokens.rosetteGold
                          : tokens.paragraphNumber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
