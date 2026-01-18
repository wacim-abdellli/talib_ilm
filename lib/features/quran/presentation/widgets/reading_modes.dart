import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/responsive.dart';
import '../widgets/verse_widget.dart';

/// Reading mode enum
enum ReadingMode {
  mushaf, // Page-by-page like physical Quran
  verse, // One verse per view with translation
  continuous, // Infinite scroll
}

/// Reading mode preferences
class ReadingModePreferences {
  static const String _modeKey = 'quran_reading_mode';

  static Future<ReadingMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_modeKey);
    switch (value) {
      case 'mushaf':
        return ReadingMode.mushaf;
      case 'continuous':
        return ReadingMode.continuous;
      default:
        return ReadingMode.verse;
    }
  }

  static Future<void> setMode(ReadingMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }
}

/// Reading mode selector widget
class ReadingModeSelector extends StatelessWidget {
  final ReadingMode currentMode;
  final ValueChanged<ReadingMode> onModeChanged;
  final bool nightMode;

  const ReadingModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.nightMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    required ReadingMode currentMode,
    required ValueChanged<ReadingMode> onModeChanged,
    bool nightMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReadingModeSelector(
        currentMode: currentMode,
        onModeChanged: onModeChanged,
        nightMode: nightMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nightMode ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'وضع القراءة',
            style: TextStyle(
              fontSize: responsive.sp(18),
              fontWeight: FontWeight.w700,
              color: nightMode ? Colors.white : Colors.grey.shade800,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 16),

          // Mode options
          _ModeOption(
            icon: Icons.menu_book,
            title: 'وضع المصحف',
            subtitle: 'صفحة بصفحة مثل المصحف الورقي',
            isSelected: currentMode == ReadingMode.mushaf,
            nightMode: nightMode,
            onTap: () {
              onModeChanged(ReadingMode.mushaf);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),

          _ModeOption(
            icon: Icons.view_list,
            title: 'وضع الآيات',
            subtitle: 'آية بآية مع الترجمة والتفسير',
            isSelected: currentMode == ReadingMode.verse,
            nightMode: nightMode,
            onTap: () {
              onModeChanged(ReadingMode.verse);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),

          _ModeOption(
            icon: Icons.view_stream,
            title: 'وضع متصل',
            subtitle: 'تمرير متواصل للقراءة السريعة',
            isSelected: currentMode == ReadingMode.continuous,
            nightMode: nightMode,
            onTap: () {
              onModeChanged(ReadingMode.continuous);
              Navigator.pop(context);
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool nightMode;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.nightMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF14B8A6).withValues(alpha: 0.1)
              : (nightMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14B8A6)
                : (nightMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF14B8A6)
                    : (nightMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (nightMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey.shade600),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: responsive.sp(16),
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF14B8A6)
                          : (nightMode ? Colors.white : Colors.grey.shade800),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: responsive.sp(13),
                      color: nightMode
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.grey.shade500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF14B8A6),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MUSHAF MODE VIEW
// ═══════════════════════════════════════════════════════════════════════════

class MushafModeView extends StatelessWidget {
  final int pageNumber;
  final List<VerseData> verses;
  final double fontSize;
  final bool nightMode;
  final String surahName;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const MushafModeView({
    super.key,
    required this.pageNumber,
    required this.verses,
    this.fontSize = 24,
    this.nightMode = false,
    required this.surahName,
    this.onPreviousPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = nightMode
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFFFF9E6);
    final textColor = nightMode ? Colors.white : const Color(0xFF0F172A);
    final borderColor = nightMode
        ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
        : const Color(0xFFD4AF37).withValues(alpha: 0.5);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          onNextPage?.call(); // Swipe right = next (RTL)
        } else if (details.primaryVelocity! < 0) {
          onPreviousPage?.call(); // Swipe left = previous (RTL)
        }
      },
      child: Container(
        color: bgColor,
        child: Column(
          children: [
            // Page header (decorative)
            _MushafPageHeader(
              pageNumber: pageNumber,
              surahName: surahName,
              nightMode: nightMode,
            ),

            // Main content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text.rich(
                      TextSpan(
                        children: verses.map((verse) {
                          return TextSpan(
                            children: [
                              TextSpan(
                                text: verse.arabicText,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Amiri',
                                  color: textColor,
                                  height: 2.2,
                                ),
                              ),
                              WidgetSpan(
                                child: _MushafVerseMarker(
                                  number: verse.verseNumber,
                                  nightMode: nightMode,
                                ),
                              ),
                              const TextSpan(text: ' '),
                            ],
                          );
                        }).toList(),
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              ),
            ),

            // Page footer
            _MushafPageFooter(
              pageNumber: pageNumber,
              juzNumber: (pageNumber / 20).ceil(),
              nightMode: nightMode,
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafPageHeader extends StatelessWidget {
  final int pageNumber;
  final String surahName;
  final bool nightMode;

  const _MushafPageHeader({
    required this.pageNumber,
    required this.surahName,
    required this.nightMode,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final decorColor = nightMode
        ? const Color(0xFF14B8A6).withValues(alpha: 0.5)
        : const Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          // Left decoration
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: decorColor, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: decorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                'سورة $surahName',
                style: TextStyle(
                  fontSize: responsive.sp(18),
                  fontWeight: FontWeight.w600,
                  color: decorColor,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
          ),

          // Right decoration
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: decorColor, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: decorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafPageFooter extends StatelessWidget {
  final int pageNumber;
  final int juzNumber;
  final bool nightMode;

  const _MushafPageFooter({
    required this.pageNumber,
    required this.juzNumber,
    required this.nightMode,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final textColor = nightMode
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'الجزء $juzNumber',
            style: TextStyle(
              fontSize: responsive.sp(12),
              color: textColor,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            '$pageNumber',
            style: TextStyle(
              fontSize: responsive.sp(14),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafVerseMarker extends StatelessWidget {
  final int number;
  final bool nightMode;

  const _MushafVerseMarker({required this.number, required this.nightMode});

  String _toArabicNumerals(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final color = nightMode
        ? const Color(0xFF14B8A6).withValues(alpha: 0.7)
        : const Color(0xFFD4AF37);

    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          _toArabicNumerals(number),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VERSE MODE VIEW
// ═══════════════════════════════════════════════════════════════════════════

class VerseModeView extends StatelessWidget {
  final List<VerseData> verses;
  final int currentVerseIndex;
  final double fontSize;
  final bool nightMode;
  final bool showTranslation;
  final bool showTafsir;
  final ValueChanged<int>? onVerseChanged;
  final Function(VerseData)? onBookmark;
  final Function(VerseData)? onPlay;

  const VerseModeView({
    super.key,
    required this.verses,
    this.currentVerseIndex = 0,
    this.fontSize = 28,
    this.nightMode = false,
    this.showTranslation = false,
    this.showTafsir = false,
    this.onVerseChanged,
    this.onBookmark,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: verses.length,
      controller: PageController(initialPage: currentVerseIndex),
      onPageChanged: onVerseChanged,
      itemBuilder: (context, index) {
        final verse = verses[index];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              VerseWidget(
                verse: verse,
                fontSize: fontSize,
                nightMode: nightMode,
                showTranslation: showTranslation,
                showTafsir: showTafsir,
                onBookmark: () => onBookmark?.call(verse),
                onPlay: () => onPlay?.call(verse),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTINUOUS MODE VIEW
// ═══════════════════════════════════════════════════════════════════════════

class ContinuousModeView extends StatelessWidget {
  final List<VerseData> verses;
  final double fontSize;
  final bool nightMode;
  final ScrollController? scrollController;
  final int? currentSurahNumber;
  final Function(VerseData)? onVerseTap;

  const ContinuousModeView({
    super.key,
    required this.verses,
    this.fontSize = 24,
    this.nightMode = false,
    this.scrollController,
    this.currentSurahNumber,
    this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = nightMode
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFFFF9E6);

    return Container(
      color: bgColor,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: verses.length,
        itemBuilder: (context, index) {
          final verse = verses[index];
          final showSurahHeader =
              index == 0 || verses[index - 1].surahNumber != verse.surahNumber;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Surah header divider
              if (showSurahHeader)
                _ContinuousSurahDivider(
                  surahNumber: verse.surahNumber,
                  nightMode: nightMode,
                ),

              // Verse text
              GestureDetector(
                onTap: () => onVerseTap?.call(verse),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: verse.arabicText,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontFamily: 'Amiri',
                              color: nightMode
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              height: 2.0,
                            ),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: VerseNumberBadge(
                              number: verse.verseNumber,
                              nightMode: nightMode,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContinuousSurahDivider extends StatelessWidget {
  final int surahNumber;
  final bool nightMode;

  const _ContinuousSurahDivider({
    required this.surahNumber,
    required this.nightMode,
  });

  static const _surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف',
    'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
    // ... (abbreviated for space)
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final borderColor = nightMode
        ? const Color(0xFF14B8A6).withValues(alpha: 0.5)
        : const Color(0xFF14B8A6).withValues(alpha: 0.3);
    final name = surahNumber <= _surahNames.length
        ? _surahNames[surahNumber - 1]
        : 'سورة $surahNumber';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        gradient: LinearGradient(
          colors: [
            nightMode
                ? const Color(0xFF14B8A6).withValues(alpha: 0.1)
                : const Color(0xFF14B8A6).withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Text(
            'سورة $name',
            style: TextStyle(
              fontSize: responsive.sp(22),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF14B8A6),
              fontFamily: 'Cairo',
            ),
          ),
          if (surahNumber != 9 && surahNumber != 1) ...[
            const SizedBox(height: 12),
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: TextStyle(
                fontSize: responsive.sp(20),
                color: nightMode ? Colors.white : const Color(0xFF0F172A),
                fontFamily: 'Amiri',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
