import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

/// Tajweed rule types
enum TajweedRule {
  ghunnah, // Nasal sound (غنة)
  ikhfa, // Hidden (إخفاء)
  idgham, // Merging (إدغام)
  iqlab, // Conversion (إقلاب)
  qalqalah, // Echo (قلقلة)
  madd, // Prolongation (مد)
  lamShams, // Lam Shamsiyyah (اللام الشمسية)
  lamQamar, // Lam Qamariyyah (اللام القمرية)
  silent, // Silent letters (الحروف الساكنة)
  normal, // Normal text
}

/// Tajweed color definitions
class TajweedColors {
  // Light mode colors (pastel for readability)
  static const Color ghunnah = Color(0xFFE9D5FF); // Light purple
  static const Color ikhfa = Color(0xFFF3F4F6); // Light grey
  static const Color idgham = Color(0xFFD1FAE5); // Light green
  static const Color iqlab = Color(0xFFDBEAFE); // Light blue
  static const Color qalqalah = Color(0xFFFEE2E2); // Light red
  static const Color madd = Color(0xFFFEF3C7); // Yellow
  static const Color lamShams = Color(0xFFBFDBFE); // Dark blue
  static const Color lamQamar = Color(0xFFCCFBF1); // Light teal
  static const Color silent = Color(0xFFE5E7EB); // Light grey

  // Dark mode colors (slightly darker for contrast)
  static const Color ghunnaDark = Color(0xFF7C3AED); // Purple
  static const Color ikhfaDark = Color(0xFF6B7280); // Grey
  static const Color idghamDark = Color(0xFF10B981); // Green
  static const Color iqlabDark = Color(0xFF3B82F6); // Blue
  static const Color qalqalahDark = Color(0xFFEF4444); // Red
  static const Color maddDark = Color(0xFFF59E0B); // Amber
  static const Color lamShamsDark = Color(0xFF60A5FA); // Blue
  static const Color lamQamarDark = Color(0xFF14B8A6); // Teal
  static const Color silentDark = Color(0xFF9CA3AF); // Grey

  static Color getColor(TajweedRule rule, {bool nightMode = false}) {
    if (nightMode) {
      switch (rule) {
        case TajweedRule.ghunnah:
          return ghunnaDark;
        case TajweedRule.ikhfa:
          return ikhfaDark;
        case TajweedRule.idgham:
          return idghamDark;
        case TajweedRule.iqlab:
          return iqlabDark;
        case TajweedRule.qalqalah:
          return qalqalahDark;
        case TajweedRule.madd:
          return maddDark;
        case TajweedRule.lamShams:
          return lamShamsDark;
        case TajweedRule.lamQamar:
          return lamQamarDark;
        case TajweedRule.silent:
          return silentDark;
        case TajweedRule.normal:
          return Colors.white;
      }
    } else {
      switch (rule) {
        case TajweedRule.ghunnah:
          return ghunnah;
        case TajweedRule.ikhfa:
          return ikhfa;
        case TajweedRule.idgham:
          return idgham;
        case TajweedRule.iqlab:
          return iqlab;
        case TajweedRule.qalqalah:
          return qalqalah;
        case TajweedRule.madd:
          return madd;
        case TajweedRule.lamShams:
          return lamShams;
        case TajweedRule.lamQamar:
          return lamQamar;
        case TajweedRule.silent:
          return silent;
        case TajweedRule.normal:
          return const Color(0xFF0F172A);
      }
    }
  }
}

/// Tajweed rule info for legend
class TajweedRuleInfo {
  final TajweedRule rule;
  final String arabicName;
  final String description;
  final String example;

  const TajweedRuleInfo({
    required this.rule,
    required this.arabicName,
    required this.description,
    required this.example,
  });
}

/// All Tajweed rules with descriptions
const List<TajweedRuleInfo> tajweedRulesList = [
  TajweedRuleInfo(
    rule: TajweedRule.ghunnah,
    arabicName: 'الغنة',
    description: 'صوت يخرج من الخيشوم مع النون والميم المشددتين',
    example: 'إِنَّ • ثُمَّ',
  ),
  TajweedRuleInfo(
    rule: TajweedRule.ikhfa,
    arabicName: 'الإخفاء',
    description: 'النطق بالنون الساكنة بين الإظهار والإدغام',
    example: 'مِن قَبْلُ • أَنتُم',
  ),
  TajweedRuleInfo(
    rule: TajweedRule.idgham,
    arabicName: 'الإدغام',
    description: 'إدخال حرف في حرف آخر',
    example: 'مَن يَعْمَل • مِن وَاقٍ',
  ),
  TajweedRuleInfo(
    rule: TajweedRule.iqlab,
    arabicName: 'الإقلاب',
    description: 'قلب النون الساكنة ميماً عند الباء',
    example: 'مِن بَعْدِ • أَنبِيَاء',
  ),
  TajweedRuleInfo(
    rule: TajweedRule.qalqalah,
    arabicName: 'القلقلة',
    description: 'اهتزاز صوت الحرف عند سكونه (ق ط ب ج د)',
    example: 'يَخْلُقْ • أَحَدٌ',
  ),
  TajweedRuleInfo(
    rule: TajweedRule.madd,
    arabicName: 'المد',
    description: 'إطالة الصوت بحرف من حروف المد',
    example: 'قَالَ • يَقُولُ • فِيهِ',
  ),
  TajweedRuleInfo(
    rule: TajweedRule.lamShams,
    arabicName: 'اللام الشمسية',
    description: 'لام أل التعريف التي تدغم',
    example: 'الشَّمْس • النَّاس',
  ),
  TajweedRuleInfo(
    rule: TajweedRule.lamQamar,
    arabicName: 'اللام القمرية',
    description: 'لام أل التعريف التي تظهر',
    example: 'الْقَمَر • الْكِتَاب',
  ),
  TajweedRuleInfo(
    rule: TajweedRule.silent,
    arabicName: 'السكون',
    description: 'الحرف الساكن',
    example: 'يَعْلَم • مِنْ',
  ),
];

/// Parsed tajweed segment
class TajweedSegment {
  final String text;
  final TajweedRule rule;

  const TajweedSegment(this.text, this.rule);
}

/// Tajweed parser for Quran text
class TajweedParser {
  // Letters that trigger Qalqalah when sukoon
  static const qalqalahLetters = ['ق', 'ط', 'ب', 'ج', 'د'];

  // Shamsiyyah letters (lam assimilates)
  static const shamsLetters = [
    'ت',
    'ث',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ل',
    'ن',
  ];

  // Qamariyyah letters (lam appears)
  static const qamarLetters = [
    'ا',
    'ب',
    'غ',
    'ح',
    'ج',
    'ك',
    'و',
    'خ',
    'ف',
    'ع',
    'ق',
    'ي',
    'م',
    'ه',
  ];

  // Ikhfa letters
  static const ikhfaLetters = [
    'ت',
    'ث',
    'ج',
    'د',
    'ذ',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ف',
    'ق',
    'ك',
  ];

  // Idgham letters (يرملون)
  static const idghamLetters = ['ي', 'ر', 'م', 'ل', 'و', 'ن'];

  // Madd letters
  static const maddLetters = ['ا', 'و', 'ي', 'ى'];

  // Shaddah (تشديد)
  static const String shaddah = 'ّ';

  // Sukoon
  static const String sukoon = 'ْ';

  // Noon sakinah / tanween
  static const noonSakinah = ['ن'];
  static const tanweenMarks = ['ً', 'ٍ', 'ٌ'];

  /// Parse text and return segments with Tajweed rules
  static List<TajweedSegment> parse(String text) {
    final segments = <TajweedSegment>[];
    final chars = text.characters.toList();

    int i = 0;
    while (i < chars.length) {
      final char = chars[i];
      final nextChar = i + 1 < chars.length ? chars[i + 1] : '';
      final prevChar = i > 0 ? chars[i - 1] : '';

      TajweedRule rule = TajweedRule.normal;
      String segment = char;

      // Check for Shaddah (Ghunnah if noon or meem with shaddah)
      if (nextChar == shaddah) {
        if (char == 'ن' || char == 'م') {
          rule = TajweedRule.ghunnah;
          segment = char + nextChar;
          i += 2;
          segments.add(TajweedSegment(segment, rule));
          continue;
        }
      }

      // Check for Alif-Lam (ال)
      if (char == 'ا' && nextChar == 'ل') {
        // Look ahead to next letter after lam
        if (i + 2 < chars.length) {
          String afterLam = chars[i + 2];
          // Skip any diacritics
          int j = i + 2;
          while (j < chars.length && _isDiacritic(chars[j])) {
            j++;
          }
          if (j < chars.length) {
            afterLam = chars[j];
            if (shamsLetters.contains(afterLam)) {
              rule = TajweedRule.lamShams;
              segment = 'ال';
              i += 2;
              segments.add(TajweedSegment(segment, rule));
              continue;
            } else if (qamarLetters.contains(afterLam)) {
              rule = TajweedRule.lamQamar;
              segment = 'ال';
              i += 2;
              segments.add(TajweedSegment(segment, rule));
              continue;
            }
          }
        }
      }

      // Check for Noon Sakinah / Tanween rules
      if (char == 'ن' && (nextChar == sukoon || nextChar == ' ')) {
        // Look for next letter
        int j = i + 1;
        while (j < chars.length &&
            (chars[j] == ' ' || _isDiacritic(chars[j]))) {
          j++;
        }
        if (j < chars.length) {
          final nextLetter = chars[j];
          if (nextLetter == 'ب') {
            rule = TajweedRule.iqlab;
          } else if (ikhfaLetters.contains(nextLetter)) {
            rule = TajweedRule.ikhfa;
          } else if (idghamLetters.contains(nextLetter)) {
            rule = TajweedRule.idgham;
          }
        }
      }

      // Check for Tanween followed by rules
      if (tanweenMarks.contains(char)) {
        int j = i + 1;
        while (j < chars.length &&
            (chars[j] == ' ' || _isDiacritic(chars[j]))) {
          j++;
        }
        if (j < chars.length) {
          final nextLetter = chars[j];
          if (nextLetter == 'ب') {
            rule = TajweedRule.iqlab;
          } else if (ikhfaLetters.contains(nextLetter)) {
            rule = TajweedRule.ikhfa;
          } else if (idghamLetters.contains(nextLetter)) {
            rule = TajweedRule.idgham;
          }
        }
      }

      // Check for Qalqalah
      if (qalqalahLetters.contains(char) &&
          (nextChar == sukoon || nextChar == ' ' || i == chars.length - 1)) {
        rule = TajweedRule.qalqalah;
      }

      // Check for Madd
      if (maddLetters.contains(char)) {
        // Simple madd detection (letter followed by vowel extension)
        if (_isVowelMark(prevChar)) {
          rule = TajweedRule.madd;
        }
      }

      // Check for Sukoon (silent)
      if (nextChar == sukoon) {
        rule = TajweedRule.silent;
        segment = char + nextChar;
        i += 2;
        segments.add(TajweedSegment(segment, rule));
        continue;
      }

      segments.add(TajweedSegment(segment, rule));
      i++;
    }

    return _mergeConsecutiveSegments(segments);
  }

  static bool _isDiacritic(String char) {
    final codeUnit = char.codeUnits.isNotEmpty ? char.codeUnits[0] : 0;
    return codeUnit >= 0x064B && codeUnit <= 0x0652;
  }

  static bool _isVowelMark(String char) {
    return char == 'َ' || char == 'ُ' || char == 'ِ';
  }

  /// Merge consecutive segments with same rule
  static List<TajweedSegment> _mergeConsecutiveSegments(
    List<TajweedSegment> segments,
  ) {
    if (segments.isEmpty) return segments;

    final merged = <TajweedSegment>[];
    var currentRule = segments[0].rule;
    var currentText = segments[0].text;

    for (int i = 1; i < segments.length; i++) {
      if (segments[i].rule == currentRule) {
        currentText += segments[i].text;
      } else {
        merged.add(TajweedSegment(currentText, currentRule));
        currentRule = segments[i].rule;
        currentText = segments[i].text;
      }
    }
    merged.add(TajweedSegment(currentText, currentRule));

    return merged;
  }
}

/// Widget to display Tajweed-colored text
class TajweedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool nightMode;
  final bool showTajweed;
  final TextAlign textAlign;

  const TajweedText({
    super.key,
    required this.text,
    this.fontSize = 28,
    this.nightMode = false,
    this.showTajweed = true,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    if (!showTajweed) {
      // Return plain text
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: nightMode ? Colors.white : const Color(0xFF0F172A),
          fontFamily: 'Amiri',
          height: 2.0,
        ),
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
      );
    }

    // Parse and apply Tajweed colors
    final segments = TajweedParser.parse(text);

    return RichText(
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Amiri',
          height: 2.0,
        ),
        children: segments.map((segment) {
          return TextSpan(
            text: segment.text,
            style: TextStyle(
              color: segment.rule == TajweedRule.normal
                  ? (nightMode ? Colors.white : const Color(0xFF0F172A))
                  : null,
              backgroundColor: segment.rule != TajweedRule.normal
                  ? TajweedColors.getColor(
                      segment.rule,
                      nightMode: nightMode,
                    ).withValues(alpha: nightMode ? 0.3 : 0.5)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tajweed legend bottom sheet
class TajweedLegendSheet extends StatelessWidget {
  final bool nightMode;

  const TajweedLegendSheet({super.key, this.nightMode = false});

  static Future<void> show(BuildContext context, {bool nightMode = false}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TajweedLegendSheet(nightMode: nightMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final backgroundColor = nightMode ? const Color(0xFF0A0A0A) : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: Color(0xFF14B8A6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'دليل ألوان التجويد',
                  style: TextStyle(
                    fontSize: responsive.sp(18),
                    fontWeight: FontWeight.w700,
                    color: nightMode ? Colors.white : Colors.grey.shade800,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),

          // Legend items
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: tajweedRulesList.length,
              separatorBuilder: (_, __) => Divider(
                color: nightMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final info = tajweedRulesList[index];
                final color = TajweedColors.getColor(
                  info.rule,
                  nightMode: nightMode,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Color indicator
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: nightMode ? 0.3 : 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color, width: 2),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.arabicName,
                              style: TextStyle(
                                fontSize: responsive.sp(16),
                                fontWeight: FontWeight.w600,
                                color: nightMode
                                    ? Colors.white
                                    : Colors.grey.shade800,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              info.description,
                              style: TextStyle(
                                fontSize: responsive.sp(13),
                                color: nightMode
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : Colors.grey.shade600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(
                                  alpha: nightMode ? 0.2 : 0.3,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                info.example,
                                style: TextStyle(
                                  fontSize: responsive.sp(14),
                                  fontWeight: FontWeight.w500,
                                  color: nightMode
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                  fontFamily: 'Amiri',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Close button
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إغلاق',
                  style: TextStyle(
                    fontSize: responsive.sp(16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14B8A6),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating button to show Tajweed legend
class TajweedLegendButton extends StatelessWidget {
  final bool nightMode;

  const TajweedLegendButton({super.key, this.nightMode = false});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () => TajweedLegendSheet.show(context, nightMode: nightMode),
      backgroundColor: const Color(0xFF14B8A6),
      child: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
    );
  }
}
