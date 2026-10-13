import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

/// Intelligent scholarly text formatting and syntax coloring for classical Arabic books
class ShamelaTextHighlighter {
  static final RegExp _tokenRegex = RegExp(
    r'(﴿[^﴾]+﴾)|' // 1: Quranic Verses
    r'(«[^»]+»)|' // 2: Prophetic Hadith / Quotes
    r'(\[[^\]]+\])|' // 3: Section Headers / Chapters
    r'(ﷺ)|' // 4: Sacred Sallallahu Alayhi Wa Sallam
    r'(\((?:صلى الله عليه وسلم|رضي الله عنه|رضي الله عنها|رضي الله عنهم|رحمه الله|رحمهم الله|تعالى|سبحانه|عز وجل)\))|' // 5: Honorifics
    r'(\([٠-٩0-9]+\)|\[[٠-٩0-9]+\])', // 6: Footnote Numbers
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
        // ── Quranic Verse ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            fontFamily: textTheme.sacred.fontFamily,
            color: palette.gold,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(2) != null) {
        // ── Hadith / Direct Quote ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.primary,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(3) != null) {
        // ── Section Title / Bracketed Heading ──
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xs),
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
              matchedText.substring(1, matchedText.length - 1),
              style: textTheme.caption.copyWith(
                color: palette.gold,
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 0.85,
              ),
            ),
          ),
        ));
      } else if (match.group(4) != null) {
        // ── ﷺ Emblem ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.gold,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(5) != null) {
        // ── Du'a / Honorific in parentheses ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: palette.textMuted,
            fontSize: baseFontSize * 0.9,
          ),
        ));
      } else if (match.group(6) != null) {
        // ── Footnote Citation ──
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
