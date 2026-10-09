import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_spacing.dart';

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
    final palette = context.palette;
    final isDark = palette.isDark;

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
    // HARMONIZED MUSHAF THEME (Calm Scholar Design System)
    // ═══════════════════════════════════════════════════════════════

    final Color backgroundColor = palette.bg;
    final Color textColor = palette.text;
    final Color goldColor = palette.gold;
    final Color highlightColor = palette.gold.withValues(alpha: 0.22);

    // Force override library theme colors
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        primaryColor: goldColor,
        primaryColorDark: goldColor,
        primaryColorLight: goldColor,
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
          primaryContainer: palette.goldSoft,
          onPrimaryContainer: palette.onGold,
          secondaryContainer: palette.goldSoft,
          onSecondaryContainer: palette.onGold,
          surfaceContainer: palette.surface,
          surfaceTint: Colors.transparent, // Disable M3 tint
        ),
        scaffoldBackgroundColor: backgroundColor,
        dialogTheme: DialogThemeData(
          backgroundColor: palette.surfaceRaised,
        ),

        // Global Colors
        canvasColor: backgroundColor,
        cardColor: palette.surface,
        dividerColor: palette.border,

        // Specific overrides for commonly used widgets
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          iconTheme: IconThemeData(color: goldColor),
          elevation: 0,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: palette.surfaceRaised,
          modalBackgroundColor: palette.surfaceRaised,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: goldColor,
          textColor: textColor,
          tileColor: palette.surface,
          selectedColor: palette.goldSoft,
          selectedTileColor: palette.goldSoft,
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(goldColor),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(goldColor),
          checkColor: WidgetStateProperty.all(palette.onGold),
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
            color: palette.onGold,
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(color: goldColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: goldColor,
            foregroundColor: palette.onGold,
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
