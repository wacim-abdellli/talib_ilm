import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/services/mutun_audio_service.dart';
import 'shamela_text_highlighter.dart';

/// Renders classical text split into numbered paragraphs with active audio highlight
/// that follows the reciter during playback, without imposing persistent stuck selection boxes.
class MutnParagraphsView extends StatelessWidget {
  final String content;
  final String fontFamily;
  final double fontSizeDelta;
  final double lineHeight;
  final ShamelaAccentColor accentColor;
  final ShamelaReaderSurface surface;
  final MutunAudioService? audioService;

  const MutnParagraphsView({
    super.key,
    required this.content,
    required this.fontFamily,
    required this.fontSizeDelta,
    required this.lineHeight,
    this.accentColor = ShamelaAccentColor.emerald,
    this.surface = ShamelaReaderSurface.normal,
    this.audioService,
  });

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
    final paragraphs = _extractParagraphs(content);
    final service = audioService ?? MutunAudioService();

    return ValueListenableBuilder<bool>(
      valueListenable: service.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return ValueListenableBuilder<int?>(
          valueListenable: service.activeParagraphNotifier,
          builder: (context, activeIndex, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < paragraphs.length; i++) ...[
                  _buildParagraphBlock(
                    context: context,
                    index: i + 1,
                    text: paragraphs[i],
                    isActive: activeIndex == (i + 1),
                    isPlaying: isPlaying,
                    palette: palette,
                    textTheme: textTheme,
                    tokens: tokens,
                    service: service,
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
                fontFamily: fontFamily,
                fontSizeDelta: fontSizeDelta,
                lineHeight: lineHeight,
                accentColor: accentColor,
                surface: surface,
              ),
              textAlign: TextAlign.start,
            ),

            const SizedBox(height: AppSpace.xs),

            // ── Paragraph Number Badge (-1-, -2- ...) ────────────────
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
        ),
      ),
    );
  }
}
