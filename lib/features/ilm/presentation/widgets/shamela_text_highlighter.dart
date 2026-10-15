import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

/// Intelligent scholarly text formatting, titling, and syntax coloring for classical Arabic books
class ShamelaTextHighlighter {
  static final RegExp _tokenRegex = RegExp(
    r'(﴿[^﴾]+﴾|\{[^}]+\})|' // 1: Quranic Verses (﴿...﴾ or {...})
    r'(«[^»]+»|"[^"]+")|' // 2: Prophetic Hadith / Quotes
    r'(\[[^\]]+\])|' // 3: Bracketed Section Headers / Chapters
    r'((?:^|\n)\s*(?:بَابُ?|فَصْلٌ?|مَسْأَلَةٌ?|فَرْعٌ?|فَائِدَةٌ?|تَنْبِيهٌ?|خَاتِمَةٌ?|مُقَدِّمَةٌ?)[^\n\r]+)|' // 4: Line Headings
    r'(\(قَوْلُهُ:?[^)]+\)|قَوْلُهُ:|قوله:)|' // 5: Matn Citations in Commentaries (قوله: ...)
    r'(ﷺ)|' // 6: Sacred Sallallahu Alayhi Wa Sallam
    r'(\((?:صلى الله عليه وسلم|رضي الله عنه|رضي الله عنها|رضي الله عنهم|رحمه الله|رحمهم الله|تعالى|سبحانه|عز وجل)\)|(?:صلى الله عليه وسلم|رضي الله عنه|رضي الله عنها|رضي الله عنهم|رحمه الله|عز وجل))|' // 7: Honorifics
    r'((?:قال المصنف|قال الشارح|قال الإمام|قال رحمه الله|قلت):?)|' // 8: Scholarly Attribution
    r'(\([٠-٩0-9]+\)|\[[٠-٩0-9]+\])', // 9: Footnote Numbers
    unicode: true,
  );

  /// Parse raw Arabic text and produce styled TextSpan with authentic colors
  static TextSpan buildSpans({
    required String text,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required String fontFamily,
    required double fontSizeDelta,
    double lineHeight = 1.85,
  }) {
    final baseFontSize = (textTheme.body.fontSize ?? 18.0) + fontSizeDelta;
    final baseStyle = textTheme.body.copyWith(
      fontFamily: fontFamily,
      fontSize: baseFontSize,
      height: lineHeight,
      color: palette.text,
    );

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in _tokenRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;

      if (match.group(1) != null) {
        // ── 1. Quranic Verse (﴿...﴾ or {...}) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            fontFamily: textTheme.sacred.fontFamily,
            color: palette.gold,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(2) != null) {
        // ── 2. Hadith / Direct Quote ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.primary,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(3) != null) {
        // ── 3. Bracketed Section Title / Chapter Header ──
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpace.xs,
              horizontal: AppSpace.xxs,
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xxs,
            ),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: palette.gold.withValues(alpha: 0.3)),
            ),
            child: Text(
              matchedText.length > 2
                  ? matchedText.substring(1, matchedText.length - 1).trim()
                  : matchedText,
              style: textTheme.caption.copyWith(
                color: palette.gold,
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 0.85,
              ),
            ),
          ),
        ));
      } else if (match.group(4) != null) {
        // ── 4. Prominent Line Heading (باب / فصل / مسألة) ──
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpace.sm,
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: palette.gold.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Text(
              matchedText.trim(),
              style: textTheme.titleSmall.copyWith(
                fontFamily: fontFamily,
                color: palette.gold,
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.05,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ));
      } else if (match.group(5) != null) {
        // ── 5. Matn Citation in Commentary (قوله: ...) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.primary,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
            decorationColor: palette.gold.withValues(alpha: 0.4),
            decorationThickness: 1.5,
          ),
        ));
      } else if (match.group(6) != null) {
        // ── 6. ﷺ Emblem ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.gold,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(7) != null) {
        // ── 7. Du'a / Honorific ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.textMuted,
            fontSize: baseFontSize * 0.9,
          ),
        ));
      } else if (match.group(8) != null) {
        // ── 8. Scholarly Attribution Dialog (قال المصنف:) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(9) != null) {
        // ── 9. Footnote Citation ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.gold,
            fontSize: baseFontSize * 0.75,
            fontWeight: FontWeight.bold,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans, style: baseStyle);
  }
}
