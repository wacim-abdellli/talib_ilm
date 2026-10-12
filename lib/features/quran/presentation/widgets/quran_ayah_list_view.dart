import 'package:flutter/material.dart';

import 'quran_continuous_list_view.dart';

/// Legacy single-surah list view, now redirected to [QuranContinuousListView].
@Deprecated('Use QuranContinuousListView instead for gold-standard full-Quran continuous scroll')
class QuranAyahListView extends StatelessWidget {
  final int surahNumber;
  final bool isTajweedEnabled;
  final bool showTranslation;
  final double fontSize;
  final int? initialAyah;
  final void Function(int surah, int ayah)? onAyahTap;

  const QuranAyahListView({
    super.key,
    required this.surahNumber,
    this.isTajweedEnabled = true,
    this.showTranslation = false,
    this.fontSize = 24.0,
    this.initialAyah,
    this.onAyahTap,
  });

  @override
  Widget build(BuildContext context) {
    return QuranContinuousListView(
      initialSurah: surahNumber,
      initialAyah: initialAyah ?? 1,
      isTajweedEnabled: isTajweedEnabled,
      showTranslation: showTranslation,
      fontSize: fontSize,
      onAyahTap: onAyahTap,
    );
  }
}
