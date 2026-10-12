import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_palette.dart';
import 'package:talib_ilm/features/quran/data/services/tajweed_service.dart';

void main() {
  const base = TextStyle(fontSize: 20, color: Colors.black);

  test('buildMarkupSpans colors madd and neutral ham wasl', () {
    const markup =
        'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ '
        '<tajweed class=madda_normal>ـٰ</tajweed>';

    final spans = TajweedService.buildMarkupSpans(markup, baseStyle: base);
    expect(spans.length, greaterThan(1));

    final maddSpan = spans.firstWhere(
      (s) => s.text?.contains('ـٰ') ?? false,
    );
    expect(maddSpan.style?.color, TajweedPalette.madd);

    final waslSpan = spans.firstWhere(
      (s) => s.text == 'ٱ',
    );
    expect(waslSpan.style?.color, Colors.black);
  });

  test('buildVerseSpans strips end ayah span from markup', () {
    const markup =
        'الْحَمْدُ <span class=end>١</span>';
    final spans = TajweedService.buildVerseSpans(
      plainUthmani: 'الْحَمْدُ',
      quranComMarkup: markup,
      baseStyle: base,
      isTajweedEnabled: true,
    );
    final fullText = spans.map((s) => s.text ?? '').join();
    expect(fullText.contains('١'), isFalse);
    expect(fullText.contains('الْحَمْدُ'), isTrue);
  });
}
