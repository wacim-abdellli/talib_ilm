enum AudioRepeatMode { none, repeatOnce, infinite }

/// Configuration for repeating a custom range of ayahs for Quran memorization (حفظ القرآن).
class HifdhRangeConfig {
  final int surah;
  final int startAyah;
  final int endAyah;
  final int repeatCount; // 1, 3, 5, 10, or 0 (infinite)
  final int currentIteration;

  const HifdhRangeConfig({
    required this.surah,
    required this.startAyah,
    required this.endAyah,
    this.repeatCount = 1,
    this.currentIteration = 0,
  });

  bool get isInfinite => repeatCount == 0;
  bool get isCompleted => !isInfinite && currentIteration >= repeatCount;

  HifdhRangeConfig nextIteration() {
    return HifdhRangeConfig(
      surah: surah,
      startAyah: startAyah,
      endAyah: endAyah,
      repeatCount: repeatCount,
      currentIteration: currentIteration + 1,
    );
  }
}
