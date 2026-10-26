import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/services/mutun_audio_service.dart';
import 'shamela_text_highlighter.dart';

/// Renders classical text split into numbered paragraphs with active audio highlight.
/// Viewport scrolling remains manual so the user retains full scroll control.
class MutnParagraphsView extends StatelessWidget {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < paragraphs.length; i++) ...[
          _buildParagraphBlock(
            context: context,
            index: startingIndex + i,
            text: paragraphs[i],
            palette: palette,
            textTheme: textTheme,
            tokens: tokens,
            service: service,
          ),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }

  Widget _buildParagraphBlock({
    required BuildContext context,
    required int index,
    required String text,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required MutunThemeTokens tokens,
    required MutunAudioService service,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppSpace.xs,
        horizontal: AppSpace.xxs,
      ),
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
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '- $index -',
                  style: textTheme.caption.copyWith(
                    color: tokens.paragraphNumber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
