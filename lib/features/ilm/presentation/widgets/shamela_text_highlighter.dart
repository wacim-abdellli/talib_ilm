import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';

/// Intelligent scholarly text formatting, titling, and multi-tier syntax coloring
/// for classical Islamic books, mutun, hadith collections, and commentaries.
class ShamelaTextHighlighter {
  static const String _arLetters = r'[ء-يآأإؤئىة\u064B-\u065F\u0670]';

  // ── 1. Quranic Verses & Divine Speech (﴿...﴾, {...}, Basmalah, قال تعالى:) ──
  static const String _divinePattern =
      r'(?:﴿[^﴾]+﴾|\{[^}]+\}|(?:^|\n)\s*(?:بِسْمِ\s+اللَّهِ\s+الرَّحْمَنِ\s+الرَّحِيمِ|بسم\s+الله\s+الرحمن\s+الرحيم)|(?:(?:كـ?مَا|كـ?ما)\s+)?(?:وَ|و|فَ|ف)?(?:قَالَ|قال|قَوْلُهُ|قوله|لِقَوْلِهِ|لقوله|كَقَوْلِهِ|كقوله)\s+(?:اللَّهُ\s+|الله\s+)?(?:تَعَالَى|تعالى|عَزَّ\s+وَجَلَّ|عز\s+وجل|جَلَّ\s+وَعَلَا|جل\s+وعلا):?)';

  // ── 2. Prophetic Hadiths, Takhrij & Citations («...», "...", قال رسول الله ﷺ) ──
  static const String _hadithPattern =
      r'(?:«[^»]+»|"[^"]+"|(?:(?:وَ|و|فَ|ف)?(?:قَالَ|قال)\s+(?:رَسُولُ|رسول|النَّبِيُّ|النبي)\s+(?:اللَّهِ|الله)\s*(?:ﷺ|\(ﷺ\)|صلى\s+الله\s+عليه\s+وسلم)?\s*:?)|(?:(?:وَ|و|فَ|ف)?(?:عَنِ?|عن)\s+(?:النَّبِيِّ|النبي|رَسُولِ|رسول)\s+(?:اللَّهِ|الله)\s*(?:ﷺ|\(ﷺ\)|صلى\s+الله\s+عليه\s+وسلم)?\s*(?:أَنَّهُ|أنه)?\s*(?:قَالَ|قال):?)|(?:(?:سَمِعْتُ|سمعت)\s+(?:رَسُولَ|رسول)\s+(?:اللَّهِ|الله)\s*(?:ﷺ|\(ﷺ\)|صلى\s+الله\s+عليه\s+وسلم)?\s*(?:يَقُولُ|يقول):?)|(?:(?:رَوَاهُ|رواه|رَوَى|روى|أَخْرَجَهُ|أخرجه)\s+(?:البُخَارِيُّ|البخاري|مُسْلِمٌ|مسلم|أَحْمَدُ|أحمد|التِّرْمِذِيُّ|الترمذي|أَبُو\s+دَاوُدَ|أبو\s+داود|النَّسَائِيُّ|النسائي|ابْنُ\s+مَاجَهْ|ابن\s+ماجه|مَالِكٌ|مالك|الشَّيْخَانِ|الشيخان|مُتَّفَقٌ\s+عَلَيْهِ|متفق\s+عليه))|(?:صَحِيحُ\s+البُخَارِيِّ|صحيح\s+البخاري|صَحِيحُ\s+مُسْلِمٍ|صحيح\s+مسلم|مُتَّفَقٌ\s+عَلَيْهِ|متفق\s+عليه))';

  // ── 3. Prominent Line Headings (باب / فصل / مسألة / أصل / قاعدة) ──
  static const String _headingsPattern =
      r'(?:(?:^|\n)\s*(?:بَابُ?|باب|فَصْلٌ?|فصل|مَسْأَلَةٌ?|مسألة|فَرْعٌ?|فرع|فَائِدَةٌ?|فائدة|تَنْبِيهٌ?|تنبيه|خَاتِمَةٌ?|خاتمة|مُقَدِّمَةٌ?|مقدمة|تَتِمَّةٌ?|تتمة|أَصْلٌ?|أصل|قَاعِدَةٌ?|قاعدة|ضَابِطٌ?|ضابط|مَبْحَثٌ?|مبحث|مَطْلَبٌ?|مطلب)[^\n\r]+)';

  // ── 4. Bracketed Section Titles / Chapter Headers [...] ──
  static const String _bracketedPattern = r'(\[[^\]\r\n]+\])';

  // ── 5. Matn Citations in Commentaries (قوله: ... / الشرح:) ──
  static const String _matnPattern =
      r'(?:\(قَوْلُهُ:?[^)]+\)|\(قوله:?[^)]+\)|قَوْلُهُ:|قوله:|\(الشَّرْحُ:?[^)]+\)|\(الشرح:?[^)]+\)|الشَّرْحُ:|الشرح:|\(المَتْنُ:?[^)]+\)|\(المتن:?[^)]+\)|المَتْنُ:|المتن:|\(الأَصْلُ:?[^)]+\)|\(الأصل:?[^)]+\)|الأَصْلُ:|الأصل:)';

  // ── 6. Scholarly Attribution & Fiqh Dialogues (قال المصنف / الشارح / قلنا) ──
  static const String _scholarsPattern =
      r'(?:(?:(?:قَالَ|قال)\s+(?:المُصَنِّفُ|المصنف|الشَّارِحُ|الشارح|الإِمَامُ|الإمام|الشَّيْخُ|الشيخ|الشَّافِعِيُّ|الشافعي|مَالِكٌ|مالك|أَحْمَدُ|أحمد|أَبُو\s+حَنِيفَةَ|أبو\s+حنيفة|ابْنُ\s+تَيْمِيَّةَ|ابن\s+تيمية|ابْنُ\s+القَيِّمِ|ابن\s+القيم|النَّوَوِيُّ|النووي|ابْنُ\s+حَجَرٍ|ابن\s+حجر|ابْنُ\s+كَثِيرٍ|ابن\s+كثير|القُرْطُبِيُّ|القرطبي|ابْنُ\s+رَجَبٍ|ابن\s+رجب|الذَّهَبِيُّ|الذهبي|الطَّبَرِيُّ|الطبري|السَّعْدِيُّ|السعدي|العُثَيْمِينُ|العثيمين|ابْنُ\s+بَازٍ|ابن\s+باز|الأَلْبَانِيُّ|الألباني|شَيْخُ\s+الإِسْلَامِ|شيخ\s+الإسلام|القَاضِي|القاضي)(?:\s+رَحِمَهُ\s+اللَّهُ|\s+رحمه\s+الله)?(?:\s+تَعَالَى|\s+تعالى)?:?)|(?:قُلْتُ|قلت):?|(?:(?:فَإِنْ\s+قِيلَ|فإن\s+قيل|قِيلَ|قيل|فَإِنْ\s+قَالُوا|فإن\s+قالوا):?)|(?:(?:قُلْنَا|قلنا|فَالجَوَابُ|فالجواب|وَالجَوَابُ|والجواب|أُجِيبَ|أجيب):?))';

  // ── 7. Hadith Transmission Chains (حدثنا / أخبرنا / عن أبي هريرة) ──
  static const String _chainsPattern =
      r'(?:(?:^|\s)(?:(?:حَدَّثَنَا|حدثنا|حَدَّثَنِي|حدثني|أَخْبَرَنَا|أخبرنا|أَخْبَرَنِي|أخبرني|أَنْبَأَنَا|أنبأنا)(?=\s))|(?:(?:عَنْ\s+أَبِي|عن\s+أبي|عَنِ\s+ابْنِ|عن\s+ابن|عَنْ\s+عَائِشَةَ|عن\s+عائشة|عَنْ\s+أَنَسٍ|عن\s+أنس|عَنْ\s+عُمَرَ|عن\s+عمر|عَنْ\s+عَلِيٍّ|عن\s+علي|عَنْ\s+جَابِرٍ|عن\s+جابر)(?=\s)))';

  // ── 8. Sacred Honorifics & Du'a (ﷺ / رضي الله عنه / رحمه الله / سبحانه) ──
  static const String _honorificsPattern =
      r'(?:ﷺ|(?:\()?(?:صَلَّى\s+اللَّهُ\s+عَلَيْهِ\s+وَسَلَّمَ|صلى\s+الله\s+عليه\s+وسلم|عَلَيْهِ\s+الصَّلَاةُ\s+وَالسَّلَامُ|عليه\s+الصلاة\s+والسلام|عَلَيْهِ\s+السَّلَامُ|عليه\s+السلام|عَلَيْهِمَا\s+السَّلَامُ|عليهما\s+السلام|رَضِيَ\s+اللَّهُ\s+عَنْهُ|رضي\s+الله\s+عنه|رَضِيَ\s+اللَّهُ\s+عَنْهَا|رضي\s+الله\s+عنها|رَضِيَ\s+اللَّهُ\s+عَنْهُمْ|رضي\s+الله\s+عنهم|رَضِيَ\s+اللَّهُ\s+عَنْهُمَا|رضي\s+الله\s+عنهما|رَحِمَهُ\s+اللَّهُ|رحمه\s+الله|رَحِمَهُمُ\s+اللَّهُ|رحمهم\s+الله|رَحِمَنَا\s+اللَّهُ|رحمنا\s+الله|حَفِظَهُ\s+اللَّهُ|حفظه\s+الله|سُبْحَانَهُ\s+وَتَعَالَى|سبحانه\s+وتعالى|سُبْحَانَهُ|سبحانه|عَزَّ\s+وَجَلَّ|عز\s+وجل|جَلَّ\s+وَعَلَا|جل\s+وعلا|تَبَارَكَ\s+وَتَعَالَى|تبارك\s+وتعالى|جَلَّ\s+جَلَالُهُ|جل\s+جلاله)(?:\))?)';

  // ── 9. Divisions, Principles & Numerals (CRITICAL: Full unbroken words!) ──
  static const String _ordNouns =
      r'(?:المَسْأَلَةُ?|المسألة|الشَّرْطُ?|الشرط|الرُّكْنُ?|الركن|الأَصْلُ?|الأصل|القَاعِدَةُ?|القاعدة|الوَجْهُ?|الوجه|الفَرْعُ?|الفرع|الفَائِدَةُ?|الفائدة|التَّنْبِيهُ?|التنبيه|المَبْحَثُ?|المبحث|المَطْلَبُ?|المطلب|البَابُ?|الباب|الفَصْلُ?|الفصل|الصُّورَةُ?|الصورة|الحَالَةُ?|الحالة|النَّوْعُ?|النوع)';
  static const String _ordFem =
      r'(?:الأُولَى|الأولى|الثَّانِيَةُ?|الثانية|الثَّالِثَةُ?|الثالثة|الرَّابِعَةُ?|الرابعة|الخَامِسَةُ?|الخامسة|السَّادِسَةُ?|السادسة|السَّابِعَةُ?|السابعة|الثَّامِنَةُ?|الثامنة|التَّاسِعَةُ?|التاسعة|العَاشِرَةُ?|العاشرة|الحَادِيَةَ\s+عَشْرَةَ?|الحادية\s+عشرة|الثَّانِيَةَ\s+عَشْرَةَ?|الثانية\s+عشرة)';
  static const String _ordMasc =
      r'(?:الأَوَّلُ?|الأول|الثَّانِي|الثاني|الثَّالِثُ?|الثالث|الرَّابِعُ?|الرابع|الخَامِسُ?|الخامس|السَّادِسُ?|السادس|السَّابِعُ?|السابع|الثَّامِنُ?|الثامن|التَّاسِعُ?|التاسع|العَاشِرُ?|العاشر|الحَادِي\s+عَشَرَ?|الحادي\s+عشر|الثَّانِي\s+عَشَرَ?|الثاني\s+عشر)';
  static const String _adverbs =
      r'(?:أَوَّلًا|أولاً|أولا|ثَانِيًا|ثانياً|ثانيا|ثَالِثًا|ثالثاً|ثالثا|رَابِعًا|رابعاً|رابعا|خَامِسًا|خامساً|خامسا|سَادِسًا|سادساً|سادسا|سَابِعًا|سابعاً|سابعا|ثَامِنًا|ثامناً|ثامنا|تَاسِعًا|تاسعاً|تاسعا|عَاشِرًا|عاشراً|عاشرا)';
  static const String _standaloneTitles =
      r'(?:فَائِدَةٌ?|فائدة|تَنْبِيهٌ?|تنبيه|فَرْعٌ?|فرع|مَسْأَلَةٌ?|مسألة|خَاتِمَةٌ?|خاتمة|تَتِمَّةٌ?|تتمة|قَاعِدَةٌ?|قاعدة|ضَابِطٌ?|ضابط)';

  static const String _divisionsPattern =
      '(?:'
      r'(?:\(|\[)\s*(?:'
      '$_ordNouns'
      r'\s+)?(?:'
      '$_ordFem|$_ordMasc|$_standaloneTitles'
      r')\s*(?:\)|\])(?:\s*:)?|'
      '$_ordNouns'
      r'\s+(?:'
      '$_ordFem|$_ordMasc'
      r')(?!'
      '$_arLetters'
      r')(?:\s*:)?|'
      '$_adverbs'
      r'(?!'
      '$_arLetters'
      r')(?:\s*:)?|'
      r'(?:(?:^|\n)\s*[٠-٩0-9]+[\s\-–.:]+)'
      ')';

  // ── 10. Poetic Breaks (/ or ***) ──
  static const String _poeticPattern = r'(\s*(?:/{1,3}|\*{3,})\s*)';

  // ── 11. Footnote Markers ──
  static const String _footnotesPattern =
      r'''(?:\([٠-٩0-9]+\)|\[[٠-٩0-9]+\]|(?<=[ء-يآأإؤئىة\u064B-\u065F\u0670\}»"'\)])[٠-٩0-9]+|(?:\s|^)[.·][٠-٩0-9]+|[٠-٩0-9]+[\.·](?=\s|$))''';

  static final RegExp _tokenRegex = RegExp(
    '($_divinePattern)|($_hadithPattern)|($_headingsPattern)|$_bracketedPattern|($_matnPattern)|($_scholarsPattern)|($_chainsPattern)|($_honorificsPattern)|($_divisionsPattern)|$_poeticPattern|($_footnotesPattern)',
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
    ShamelaAccentColor accentColor = ShamelaAccentColor.emerald,
    ShamelaReaderSurface surface = ShamelaReaderSurface.normal,
  }) {
    final isEffectiveDark = surface.isEffectiveDark(palette.isDark);
    final surfaceTokens = ReaderSurfaceColors.getTokens(surface, isDark: isEffectiveDark);
    final accent = ReaderAccentColors.getTokens(accentColor, isDark: isEffectiveDark);
    final baseFontSize = (textTheme.body.fontSize ?? 18.0) + fontSizeDelta;
    final baseStyle = textTheme.body.copyWith(
      fontFamily: fontFamily,
      fontSize: baseFontSize,
      height: lineHeight,
      color: surfaceTokens.text,
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
        // ── 1. Quranic Verse & Divine Speech ──
        final isVerseOnly = matchedText.startsWith('{') || matchedText.startsWith('﴿');
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            fontFamily: isVerseOnly ? textTheme.sacred.fontFamily : fontFamily,
            color: accent.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(2) != null) {
        // ── 2. Prophetic Hadith & Takhrij Citation ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: surfaceTokens.hadithGreen,
            fontWeight: FontWeight.w700,
          ),
        ));
      } else if (match.group(3) != null) {
        // ── 3. Prominent Line Heading (باب / فصل / مسألة) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            fontFamily: fontFamily,
            color: accent.primary,
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize * 1.08,
            height: lineHeight * 1.2,
          ),
        ));
      } else if (match.group(4) != null) {
        // ── 4. Bracketed Section Title / Chapter Header [...] ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: accent.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(5) != null) {
        // ── 5. Matn Citation in Commentary (قوله: ...) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: surfaceTokens.citationBlue,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
            decorationColor: surfaceTokens.citationBlue.withValues(alpha: 0.45),
            decorationThickness: 1.5,
          ),
        ));
      } else if (match.group(6) != null) {
        // ── 6. Scholarly Attribution & Fiqh Dialogues (قال المصنف / الشارح / قلنا) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: surfaceTokens.citationBlue,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(7) != null) {
        // ── 7. Hadith Transmission Chains (حدثنا / أخبرنا / عن أبي هريرة) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: surfaceTokens.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(8) != null) {
        // ── 8. Sacred Honorifics & Du'a (ﷺ / رضي الله عنه / رحمه الله / سبحانه) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: accent.primary,
            fontSize: baseFontSize * 0.9,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(9) != null) {
        // ── 9. Divisions, Principles & Numerals (أولاً / المسألة الأولى / الشرط الأول) ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: accent.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(10) != null) {
        // ── 10. Poetic Breaks (/ or ***) ──
        spans.add(TextSpan(
          text: ' ✤ ',
          style: baseStyle.copyWith(
            color: accent.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(11) != null) {
        // ── 11. Footnote Markers ──
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: accent.primary,
            fontSize: baseFontSize * 0.72,
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

