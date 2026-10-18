import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/hizb_catalog.dart';
import 'hizb_card.dart';
import 'juz_card.dart';
import 'surah_card.dart';

/// Helpers for building category index slivers (Surahs, Juzs, Hizbs) in QuranPage.
class QuranIndexSlivers {
  QuranIndexSlivers._();

  static List<Widget> buildSurahsSlivers({
    required BuildContext context,
    required List<int> filteredSurahs,
    required Set<int> bookmarkedSurahSet,
    required ValueChanged<int> onOpenSurah,
    required ValueChanged<int> onToggleBookmark,
    required VoidCallback onResetSearch,
  }) {
    if (filteredSurahs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد نتائج',
              subtitle:
                  'لم نتمكن من العثور على سورة تطابق بحثك. جرّب كتابة اسم السورة أو رقمها.',
              actionLabel: 'إعادة ضبط البحث',
              onAction: onResetSearch,
            ),
          ),
        ),
      ];
    }

    return [
      SliverList.builder(
        itemCount: filteredSurahs.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final surahNum = filteredSurahs[index];
          final isBookmarked = bookmarkedSurahSet.contains(surahNum);

          return SurahCard(
            key: ValueKey('surah_$surahNum'),
            surahNumber: surahNum,
            isBookmarked: isBookmarked,
            onTap: () => onOpenSurah(surahNum),
            onBookmarkTap: () => onToggleBookmark(surahNum),
          );
        },
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: AppSize.navClearance(context)),
      ),
    ];
  }

  static List<Widget> buildJuzsSlivers({
    required BuildContext context,
    required List<int> filteredJuzs,
    required ValueChanged<int> onOpenPage,
    required VoidCallback onResetSearch,
  }) {
    if (filteredJuzs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد نتائج',
              subtitle:
                  'لم نتمكن من العثور على جزء يطابق بحثك. جرّب كتابة رقم الجزء أو اسم السورة.',
              actionLabel: 'إعادة ضبط البحث',
              onAction: onResetSearch,
            ),
          ),
        ),
      ];
    }

    return [
      SliverList.builder(
        itemCount: filteredJuzs.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final juzNum = filteredJuzs[index];
          return JuzCard(
            key: ValueKey('juz_$juzNum'),
            juzNumber: juzNum,
            onTap: () {
              final map = quran.getSurahAndVersesFromJuz(juzNum);
              final firstSurah = map.keys.first;
              final firstVerse = map[firstSurah]!.first;
              final page = quran.getPageNumber(firstSurah, firstVerse);
              onOpenPage(page);
            },
          );
        },
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: AppSize.navClearance(context)),
      ),
    ];
  }

  static List<Widget> buildHizbsSlivers({
    required BuildContext context,
    required List<int> filteredHizbs,
    required ValueChanged<int> onOpenPage,
    required VoidCallback onResetSearch,
  }) {
    if (filteredHizbs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد نتائج',
              subtitle:
                  'لم نتمكن من العثور على حزب يطابق بحثك. جرّب كتابة اسم الحزب أو السورة.',
              actionLabel: 'إعادة ضبط البحث',
              onAction: onResetSearch,
            ),
          ),
        ),
      ];
    }

    return [
      SliverList.builder(
        itemCount: filteredHizbs.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final hizbNum = filteredHizbs[index];
          final hizb = HizbCatalog.getHizb(hizbNum);
          return HizbCard(
            key: ValueKey('hizb_$hizbNum'),
            hizb: hizb,
            onOpenPage: onOpenPage,
          );
        },
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: AppSize.navClearance(context)),
      ),
    ];
  }
}
