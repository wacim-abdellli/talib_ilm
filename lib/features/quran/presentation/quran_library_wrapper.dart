import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

/// Professional Quran Reading Screen using quran_library package.
///
/// Features:
/// - Audio playback with background support & lock screen controls
/// - Tafsir integration (multiple scholars)
/// - Bookmarks (color-coded)
/// - Search
/// - Font management
/// - Medina Mushaf identical layout
class ProfessionalQuranScreen extends StatelessWidget {
  final int? initialSurah;
  final int? initialAyah;
  final int? initialPage;

  const ProfessionalQuranScreen({
    super.key,
    this.initialSurah,
    this.initialAyah,
    this.initialPage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Navigate to specific location if provided
    if (initialSurah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        QuranLibrary().jumpToSurah(initialSurah!);
      });
    } else if (initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        QuranLibrary().jumpToPage(initialPage!);
      });
    }

    // ═══════════════════════════════════════════════════════════════
    // BLACK & GOLD MUSHAF THEME (To hide blue clash)
    // ═══════════════════════════════════════════════════════════════

    // Background Colors - PURE BLACK
    final Color backgroundColor = isDark
        ? const Color(0xFF000000) // Pure Black
        : const Color(0xFFFDF8F0); // Warm Cream Paper

    // Text Colors
    final Color textColor = isDark
        ? const Color(0xFFE8DED0) // Warm Cream text
        : const Color(0xFF3D2B1F); // Dark Brown text

    // Gold Accent
    final Color goldColor = const Color(0xFFD4A853); // Antique Gold

    // Highlight Color
    final Color highlightColor = isDark
        ? const Color(0xFF8B6914).withValues(alpha: 0.3)
        : const Color(0xFFD4A853).withValues(alpha: 0.25);

    // Force override library theme colors
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        primaryColor: goldColor,
        primaryColorDark: goldColor,
        primaryColorLight: goldColor,
        // indicatorColor: goldColor, // Deprecated, move to tabBarTheme if possible or remove if unused
        // Disable tap visual feedback (Ripples/Hover)
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,

        iconTheme: theme.iconTheme.copyWith(color: goldColor),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: goldColor,
          selectionColor: goldColor.withValues(alpha: 0.3),
          selectionHandleColor: goldColor,
        ),
        colorScheme: theme.colorScheme.copyWith(
          primary: goldColor,
          secondary: goldColor,
          tertiary: goldColor,
          surface: backgroundColor,
          onSurface: textColor,
          // background: backgroundColor, // Deprecated
          // onBackground: textColor, // Deprecated
          primaryContainer: goldColor.withValues(alpha: 0.1),
          onPrimaryContainer: goldColor,
          secondaryContainer: goldColor.withValues(alpha: 0.1),
          onSecondaryContainer: goldColor,
          surfaceContainer: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          surfaceTint: Colors.transparent, // Disable M3 tint
        ),
        scaffoldBackgroundColor: backgroundColor,
        dialogBackgroundColor: isDark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFFDF8F0),

        // Global Colors
        canvasColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFDF8F0),
        cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        dividerColor: goldColor.withValues(alpha: 0.2),

        // Specific overrides for commonly used widgets
        appBarTheme: AppBarTheme(
          backgroundColor: isDark
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFFDF8F0),
          foregroundColor: textColor,
          iconTheme: IconThemeData(color: goldColor),
          elevation: 0,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: isDark
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFFDF8F0),
          modalBackgroundColor: isDark
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFFDF8F0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: goldColor,
          textColor: textColor,
          tileColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          selectedColor: goldColor.withValues(alpha: 0.1),
          selectedTileColor: goldColor.withValues(alpha: 0.1),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(goldColor),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(goldColor),
          checkColor: WidgetStateProperty.all(
            isDark ? Colors.black : Colors.white,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(goldColor),
          trackColor: WidgetStateProperty.all(goldColor.withValues(alpha: 0.3)),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: goldColor,
          thumbColor: goldColor,
          inactiveTrackColor: goldColor.withValues(alpha: 0.2),
          valueIndicatorColor: goldColor,
          valueIndicatorTextStyle: TextStyle(
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(color: goldColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: goldColor,
            foregroundColor: isDark ? Colors.black : Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: goldColor),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: goldColor,
            side: BorderSide(color: goldColor),
          ),
        ),
      ),
      child: QuranLibraryScreen(
        parentContext: context,
        withPageView: true,
        useDefaultAppBar: true,
        isShowAudioSlider: true,
        showAyahBookmarkedIcon: true,
        isDark: isDark,

        // ═══════════════ COLORS ═══════════════
        backgroundColor: backgroundColor,
        textColor: textColor,
        ayahSelectedBackgroundColor: highlightColor,
        ayahIconColor: goldColor,

        // ═══════════════ SURAH INFO STYLE ═══════════════
        surahInfoStyle:
            SurahInfoStyle.defaults(isDark: isDark, context: context).copyWith(
              ayahCount: 'عدد الآيات',
              firstTabText: 'أسماء السور',
              secondTabText: 'عن السورة',
              bottomSheetWidth: MediaQuery.of(context).size.width * 0.9,
            ),

        // ═══════════════ BASMALA STYLE ═══════════════
        basmalaStyle: BasmalaStyle(
          verticalPadding: 16.0,
          basmalaColor: textColor.withValues(alpha: 0.9),
          basmalaFontSize: 28.0,
        ),

        // ═══════════════ AUDIO STYLE ═══════════════
        ayahStyle: AyahAudioStyle.defaults(
          isDark: isDark,
          context: context,
        ).copyWith(dialogWidth: 320, readersTabText: 'القراء'),

        // ═══════════════ TOP BAR STYLE ═══════════════
        topBarStyle: QuranTopBarStyle.defaults(isDark: isDark, context: context)
            .copyWith(
              showAudioButton: true,
              showFontsButton: true,
              tabIndexLabel: 'الفهرس',
              tabBookmarksLabel: 'العلامات',
              tabSearchLabel: 'البحث',
            ),

        // ═══════════════ INDEX TAB STYLE ═══════════════
        indexTabStyle: IndexTabStyle.defaults(
          isDark: isDark,
          context: context,
        ).copyWith(tabSurahsLabel: 'السور', tabJozzLabel: 'الأجزاء'),

        // ═══════════════ SEARCH TAB STYLE ═══════════════
        searchTabStyle: SearchTabStyle.defaults(
          isDark: isDark,
          context: context,
        ).copyWith(searchHintText: 'ابحث في القرآن...'),

        // ═══════════════ BOOKMARKS TAB STYLE ═══════════════
        bookmarksTabStyle:
            BookmarksTabStyle.defaults(
              isDark: isDark,
              context: context,
            ).copyWith(
              emptyStateText: 'لا توجد علامات مرجعية',
              greenGroupText: 'الأخضر',
              yellowGroupText: 'الأصفر',
              redGroupText: 'الأحمر',
            ),

        // ═══════════════ AYAH MENU STYLE ═══════════════
        ayahMenuStyle: AyahMenuStyle.defaults(
          isDark: isDark,
          context: context,
        ).copyWith(copySuccessMessage: 'تم نسخ الآية', showPlayAllButton: true),

        // ═══════════════ TAFSIR STYLE ═══════════════
        tafsirStyle: TafsirStyle.defaults(isDark: isDark, context: context)
            .copyWith(
              widthOfBottomSheet: MediaQuery.of(context).size.width * 0.95,
              heightOfBottomSheet: MediaQuery.of(context).size.height * 0.85,
              changeTafsirDialogHeight:
                  MediaQuery.of(context).size.height * 0.8,
              changeTafsirDialogWidth: 350,
              tafsirName: 'التفسير',
              translateName: 'الترجمة',
              tafsirIsEmptyNote: 'التفسير غير متوفر حالياً',
              footnotesName: 'الحواشي',
            ),

        // ═══════════════ JUZ/HIZB LABELS ═══════════════
        topBottomQuranStyle: TopBottomQuranStyle.defaults(
          isDark: isDark,
          context: context,
        ).copyWith(hizbName: 'حزب', juzName: 'جزء', sajdaName: 'سجدة'),
      ),
    );
  }
}
