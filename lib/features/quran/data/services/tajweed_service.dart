import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';

enum TajweedRule {
  ghunnah, // Noon/Meem with Shaddah (نّ, مّ)
  qalqalah, // قطبجد with Sukun
  ikhfaa, // Noon Sakinah / Tanween before Ikhfaa letters
  idgham, // Noon Sakinah / Tanween before يرملون
  iqlab, // Meem before Baa (مۘ)
  madd, // Madd letters with Madd sign (ـٓ)
  normal, // Regular text
}

class TajweedService {
  TajweedService._();

  /// Qalqalah letters: ق ط ب ج د
  static final RegExp _qalqalahRegex = RegExp(r'[قطبجد][ْۡ]');

  /// Ghunnah: Noon or Meem with Shaddah
  static final RegExp _ghunnahRegex = RegExp(r'[نم][ّ]');

  /// Madd sign: \u0653 (Maddah Above) or long alif with madd
  static final RegExp _maddRegex = RegExp(r'[\u0653\u0670\u06E1]');

  /// Iqlab marker: small meem \u06E2 or \u0658
  static final RegExp _iqlabRegex = RegExp(r'[\u06E2\u0658]');

  /// Builds a list of [TextSpan]s with colored Tajweed letters
  static List<TextSpan> buildTajweedSpans(
    String verseText, {
    required TextStyle baseStyle,
    required bool isTajweedEnabled,
  }) {
    if (!isTajweedEnabled) {
      return [
        TextSpan(
          text: verseText,
          style: baseStyle,
        ),
      ];
    }

    final spans = <TextSpan>[];
    final words = verseText.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final wordSpans = _parseWordTajweed(
        word,
        baseStyle: baseStyle,
      );

      spans.addAll(wordSpans);
      if (i < words.length - 1) {
        spans.add(
          TextSpan(
            text: ' ',
            style: baseStyle,
          ),
        );
      }
    }

    return spans;
  }

  static List<TextSpan> _parseWordTajweed(
    String word, {
    required TextStyle baseStyle,
  }) {
    // Check for Madd
    if (_maddRegex.hasMatch(word)) {
      return [
        TextSpan(
          text: word,
          style: baseStyle.copyWith(
            color: TajweedPalette.madd,
          ),
        ),
      ];
    }

    // Check for Ghunnah
    if (_ghunnahRegex.hasMatch(word)) {
      return [
        TextSpan(
          text: word,
          style: baseStyle.copyWith(
            color: TajweedPalette.ghunnah,
          ),
        ),
      ];
    }

    // Check for Qalqalah
    if (_qalqalahRegex.hasMatch(word)) {
      return [
        TextSpan(
          text: word,
          style: baseStyle.copyWith(
            color: TajweedPalette.qalqalah,
          ),
        ),
      ];
    }

    // Check for Iqlab
    if (_iqlabRegex.hasMatch(word)) {
      return [
        TextSpan(
          text: word,
          style: baseStyle.copyWith(
            color: TajweedPalette.iqlab,
          ),
        ),
      ];
    }

    // Default regular Uthmanic word
    return [
      TextSpan(
        text: word,
        style: baseStyle,
      ),
    ];
  }
}
