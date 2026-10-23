import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

enum TajweedRule {
  ghunnah,
  qalqalah,
  ikhfaa,
  idgham,
  iqlab,
  madd,
  normal,
}

class TajweedService {
  TajweedService._();

  static final RegExp _endAyahSpan = RegExp(
    r'<span class=end>.*?</span>',
    dotAll: true,
  );

  static final RegExp _tajweedClassAttr = RegExp(
    r'class=(?:"([\w_-]+)"|([\w_-]+))',
  );

  static final Map<String, List<TextSpan>> _spanCache = {};
  static const int _maxCacheSize = 600;

  /// Clears the span cache when theme or font size changes.
  static void clearCache() {
    _spanCache.clear();
  }

  /// Primary entry: Quran.com markup when available, else local heuristics.
  static List<TextSpan> buildVerseSpans({
    required String plainUthmani,
    String? quranComMarkup,
    required TextStyle baseStyle,
    required bool isTajweedEnabled,
  }) {
    if (!isTajweedEnabled) {
      return [
        TextSpan(text: plainUthmani, style: baseStyle),
      ];
    }

    final cacheKey =
        '$plainUthmani|${quranComMarkup ?? ""}|${baseStyle.color?.toARGB32()}|${baseStyle.fontSize}|${baseStyle.height}';
    final cached = _spanCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final List<TextSpan> spans;
    if (quranComMarkup != null && quranComMarkup.contains('<tajweed')) {
      final cleaned = quranComMarkup.replaceAll(_endAyahSpan, '').trim();
      spans = buildMarkupSpans(cleaned, baseStyle: baseStyle);
    } else {
      spans = buildTajweedSpans(
        plainUthmani,
        baseStyle: baseStyle,
        isTajweedEnabled: true,
      );
    }

    if (_spanCache.length >= _maxCacheSize) {
      _spanCache.clear();
    }
    _spanCache[cacheKey] = spans;
    return spans;
  }

  /// Parses `text_uthmani_tajweed` from Quran.com API v4.
  static List<TextSpan> buildMarkupSpans(
    String markup, {
    required TextStyle baseStyle,
    int startIndex = 0,
  }) {
    final spans = <TextSpan>[];
    var i = startIndex;

    while (i < markup.length) {
      final tajweedStart = markup.indexOf('<tajweed', i);
      if (tajweedStart == -1) {
        _appendPlainText(spans, markup.substring(i), baseStyle);
        break;
      }

      if (tajweedStart > i) {
        _appendPlainText(spans, markup.substring(i, tajweedStart), baseStyle);
      }

      final tagHead = markup.substring(tajweedStart);
      final classMatch = _tajweedClassAttr.firstMatch(tagHead);
      final openEnd = markup.indexOf('>', tajweedStart);
      if (openEnd == -1 || classMatch == null) {
        _appendPlainText(spans, markup.substring(tajweedStart), baseStyle);
        break;
      }

      const closeTag = '</tajweed>';
      final innerStart = openEnd + 1;
      final closeIndex = markup.indexOf(closeTag, innerStart);
      if (closeIndex == -1) {
        _appendPlainText(spans, markup.substring(tajweedStart), baseStyle);
        break;
      }

      final className = classMatch.group(1) ?? classMatch.group(2)!;
      final inner = markup.substring(innerStart, closeIndex);
      final ruleColor = _colorForMarkupClass(className);
      final segmentStyle = ruleColor != null
          ? baseStyle.copyWith(color: ruleColor)
          : baseStyle;

      if (inner.contains('<tajweed')) {
        spans.addAll(
          buildMarkupSpans(inner, baseStyle: segmentStyle),
        );
      } else {
        _appendPlainText(spans, inner, segmentStyle);
      }

      i = closeIndex + closeTag.length;
    }

    return spans;
  }

  static void _appendPlainText(
    List<TextSpan> spans,
    String text,
    TextStyle style,
  ) {
    if (text.isEmpty) return;
    spans.add(TextSpan(text: text, style: style));
  }

  static Color? _colorForMarkupClass(String rawClass) {
    final c = rawClass.toLowerCase().replaceAll('-', '_');

    if (c == 'ham_wasl' ||
        c == 'laam_shamsiyah' ||
        c == 'silent' ||
        c == 'slient') {
      return null;
    }
    if (c.contains('ghunnah') && !c.contains('no_ghunnah')) {
      return TajweedPalette.ghunnah;
    }
    if (c.contains('qalaq') || c.contains('qalq')) {
      return TajweedPalette.qalqalah;
    }
    if (c.contains('ikhfa') || c.contains('ikhfaa')) {
      return TajweedPalette.ikhfaa;
    }
    if (c.contains('iqlab')) {
      return TajweedPalette.iqlab;
    }
    if (c.contains('idgh') || c.contains('idga')) {
      return TajweedPalette.idgham;
    }
    if (c.contains('madd')) {
      return TajweedPalette.madd;
    }
    return null;
  }

  /// Offline fallback: renders clean Uthmani text. Letter-level Hafs Tajweed
  /// coloring is applied accurately whenever Quran.com markup is available.
  static List<TextSpan> buildTajweedSpans(
    String verseText, {
    required TextStyle baseStyle,
    required bool isTajweedEnabled,
  }) {
    return [
      TextSpan(text: verseText, style: baseStyle),
    ];
  }
}
