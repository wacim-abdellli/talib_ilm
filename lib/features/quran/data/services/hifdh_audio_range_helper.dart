import 'package:quran/quran.dart' as quran;

/// Phonetic & Tajweed-weighted verse boundary calculator for full-surah MP3
/// recitations (`isSurahBased == true` or merged `full_surah.mp3`).
///
/// Enables accurate single-ayah repetition and multi-ayah Hifdh range looping
/// directly inside full-surah recordings (such as Ahmad Talib bin Humaid,
/// Badr Al-Turki, Khalid Al-Jalil, etc.) without ever switching the user's
/// selected reciter or requiring separate per-ayah audio files.
class HifdhAudioRangeHelper {
  const HifdhAudioRangeHelper._();

  static final Map<int, List<double>> _cachedCumulativeRatios = {};

  /// Computes cumulative normalized [0.0 .. 1.0] end-boundary ratios for all
  /// verses `1 .. verseCount` of [surah] based on Arabic letter count,
  /// Madd elongations, tashdeed/ghunnah weight, and natural waqf pauses.
  static List<double> cumulativeRatiosForSurah(int surah) {
    final cached = _cachedCumulativeRatios[surah];
    if (cached != null) return cached;

    final count = quran.getVerseCount(surah);
    if (count <= 0) return const [1.0];

    final weights = List<double>.filled(count, 0.0);
    double totalWeight = 0.0;

    for (var i = 1; i <= count; i++) {
      final text = quran.getVerse(surah, i);
      final w = _computeVersePhoneticWeight(text, isLastVerse: i == count);
      weights[i - 1] = w;
      totalWeight += w;
    }

    if (totalWeight <= 0) {
      final uniform = List<double>.generate(count, (i) => (i + 1) / count);
      _cachedCumulativeRatios[surah] = uniform;
      return uniform;
    }

    final ratios = List<double>.filled(count, 0.0);
    double running = 0.0;
    for (var i = 0; i < count; i++) {
      running += weights[i];
      ratios[i] = (running / totalWeight).clamp(0.0, 1.0);
    }
    ratios[count - 1] = 1.0;

    _cachedCumulativeRatios[surah] = ratios;
    return ratios;
  }

  static double _computeVersePhoneticWeight(
    String verseText, {
    required bool isLastVerse,
  }) {
    double weight = 0.0;
    for (var i = 0; i < verseText.length; i++) {
      final code = verseText.codeUnitAt(i);
      // Madd signs & long vowels (Alif, Waw, Ya, Maddah, Dagger Alif)
      if (code == 0x0653 || // Maddah above
          code == 0x0670 || // Superscript Alef
          code == 0x06E4 || // Small high Maddah
          code == 0x0622) { // Alef with Maddah
        weight += 3.2;
      } else if (code == 0x0627 || code == 0x0648 || code == 0x064A) {
        weight += 1.8;
      } else if (code == 0x0651) {
        // Shaddah (Ghunnah / gemination hold)
        weight += 1.6;
      } else if (code >= 0x0621 && code <= 0x064A) {
        // Standard Arabic consonant
        weight += 1.0;
      }
    }
    // Natural waqf breath pause at the end of every ayah (longer on final ayah)
    weight += isLastVerse ? 22.0 : 14.0;
    return weight;
  }

  /// Opening Isti'adhah / Basmalah header offset in milliseconds before Ayah 1.
  static int _openingOffsetMs(int surah, int totalDurationMs) {
    if (totalDurationMs <= 6000) return 0;
    // Surah Al-Fatihah (1) has Isti'adhah (~3.8s) before Basmalah (Ayah 1).
    // Other surahs (except 9) have Isti'adhah + Basmalah (~5.5s).
    final targetMs = surah == 1
        ? 3800
        : (surah == 9 ? 3200 : 5200);
    final maxCap = (totalDurationMs * 0.10).round();
    return targetMs < maxCap ? targetMs : maxCap;
  }

  /// Start timestamp in milliseconds for [ayah] (1-based) within [totalDurationMs].
  /// When [ayah] == 1, returns 0 so playback starts cleanly from the beginning.
  static int ayahStartMs(
    int surah,
    int ayah,
    int totalDurationMs, {
    bool includeOpeningOnFirstAyah = true,
  }) {
    if (totalDurationMs <= 0 || ayah <= 1) {
      if (ayah <= 1 && !includeOpeningOnFirstAyah) {
        return _openingOffsetMs(surah, totalDurationMs);
      }
      return 0;
    }
    final count = quran.getVerseCount(surah);
    final clampedAyah = ayah.clamp(1, count);
    if (clampedAyah <= 1) return 0;

    final opening = _openingOffsetMs(surah, totalDurationMs);
    final bodyDuration = (totalDurationMs - opening).clamp(1, totalDurationMs);
    final ratios = cumulativeRatiosForSurah(surah);
    final prevRatio = ratios[clampedAyah - 2];
    return (opening + (bodyDuration * prevRatio).round())
        .clamp(0, totalDurationMs);
  }

  /// End timestamp in milliseconds for [ayah] (1-based) within [totalDurationMs].
  static int ayahEndMs(int surah, int ayah, int totalDurationMs) {
    if (totalDurationMs <= 0) return 0;
    final count = quran.getVerseCount(surah);
    final clampedAyah = ayah.clamp(1, count);
    if (clampedAyah >= count) return totalDurationMs;

    final opening = _openingOffsetMs(surah, totalDurationMs);
    final bodyDuration = (totalDurationMs - opening).clamp(1, totalDurationMs);
    final ratios = cumulativeRatiosForSurah(surah);
    final ratio = ratios[clampedAyah - 1];
    return (opening + (bodyDuration * ratio).round())
        .clamp(0, totalDurationMs);
  }

  /// Resolves which Ayah (1-based) corresponds to [positionMs] inside [totalDurationMs].
  static int ayahAtPosition(int surah, int positionMs, int totalDurationMs) {
    final count = quran.getVerseCount(surah);
    if (totalDurationMs <= 0 || positionMs <= 0 || count <= 1) return 1;
    if (positionMs >= totalDurationMs) return count;

    final opening = _openingOffsetMs(surah, totalDurationMs);
    if (positionMs <= opening) return 1;

    final bodyDuration = (totalDurationMs - opening).clamp(1, totalDurationMs);
    final relRatio = ((positionMs - opening) / bodyDuration).clamp(0.0, 1.0);
    final ratios = cumulativeRatiosForSurah(surah);

    for (var i = 0; i < ratios.length; i++) {
      if (relRatio <= ratios[i]) {
        return i + 1;
      }
    }
    return count;
  }
}

