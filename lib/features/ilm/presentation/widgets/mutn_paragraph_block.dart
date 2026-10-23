import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/catalogs/mutun_curriculum_catalog.dart';
import 'mutn_memorization_view.dart';
import 'shamela_text_highlighter.dart';

class MutnParagraphBlock extends StatelessWidget {
  final MutunParagraph para;
  final ReaderSurfaceTokens surfaceTokens;
  final MutunThemeTokens tokens;
  final AppPalette palette;
  final AppTextTheme textTheme;
  final bool memorizationMode;
  final String fontFamily;
  final double fontSizeDelta;
  final double lineHeight;
  final ShamelaAccentColor accentColor;
  final ShamelaReaderSurface surface;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MutnParagraphBlock({
    super.key,
    required this.para,
    required this.surfaceTokens,
    required this.tokens,
    required this.palette,
    required this.textTheme,
    required this.memorizationMode,
    required this.fontFamily,
    required this.fontSizeDelta,
    required this.lineHeight,
    required this.accentColor,
    required this.surface,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppSpace.xs,
        horizontal: AppSpace.xxs,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.mdRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Clean Dignified Scholarly Text or Memorization Mode ──
            memorizationMode
                ? MutnMemorizationView(
                    content: para.text,
                    fontFamily: fontFamily,
                    fontSizeDelta: fontSizeDelta,
                    lineHeight: lineHeight,
                  )
                : Text.rich(
                    ShamelaTextHighlighter.buildSpans(
                      text: para.text,
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

            // ── Paragraph Number Badge (- 1 -, - 2 - ...) ─────────
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: surfaceTokens.surfaceRaised,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: surfaceTokens.border.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '- ${para.index} -',
                  style: textTheme.caption.copyWith(
                    color: tokens.paragraphNumber,
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
