import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/empty_state.dart';
import 'quran_ayah_search_card.dart';
import 'surah_card.dart';

/// Section header demarcating search result categories (Surahs vs Ayahs).
class QuranSearchSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const QuranSearchSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcon.sm, color: palette.gold),
          const SizedBox(width: AppSpace.xs),
          Text(
            title,
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xs,
              vertical: AppSpace.xxs,
            ),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: AppRadius.pillRadius,
            ),
            child: Text(
              '$count',
              style: textTheme.caption.copyWith(
                color: palette.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper building slivers for unified Quran search results (Surahs & Ayahs).
List<Widget> buildQuranSearchResultsSlivers({
  required BuildContext context,
  required String query,
  required int searchFilterIndex,
  required List<int> filteredSurahs,
  required List<QuranAyahMatch> filteredAyahs,
  required Set<int> bookmarkedSurahSet,
  required ValueChanged<int> onOpenSurah,
  required ValueChanged<int> onToggleBookmark,
  required ValueChanged<QuranAyahMatch> onOpenAyah,
  required VoidCallback onResetSearch,
  required ValueChanged<int> onFilterChanged,
}) {
  final palette = context.palette;
  final textTheme = context.text;

  // 1. Completely empty results across both Surahs and Ayahs
  if (filteredSurahs.isEmpty && filteredAyahs.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'لا توجد نتائج',
            subtitle:
                'لم نتمكن من العثور على سورة أو آية تطابق "$query". جرّب البحث بكلمة أو آية أخرى.',
            actionLabel: 'إعادة ضبط البحث',
            onAction: onResetSearch,
          ),
        ),
      ),
    ];
  }

  // 2. Filter: Surahs only
  if (searchFilterIndex == 1) {
    if (filteredSurahs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد سور مطابقة',
              subtitle: 'لم نتمكن من العثور على سورة تطابق "$query".',
              actionLabel: 'عرض كل النتائج',
              onAction: () => onFilterChanged(0),
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
          return SurahCard(
            key: ValueKey('search_surah_$surahNum'),
            surahNumber: surahNum,
            isBookmarked: bookmarkedSurahSet.contains(surahNum),
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

  // 3. Filter: Ayahs only
  if (searchFilterIndex == 2) {
    if (filteredAyahs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد آيات مطابقة',
              subtitle: query.length < 2
                  ? 'يرجى كتابة حرفين أو أكثر للبحث في آيات القرآن الكريم.'
                  : 'لم نتمكن من العثور على آيات تحتوي على "$query".',
              actionLabel: 'عرض كل النتائج',
              onAction: () => onFilterChanged(0),
            ),
          ),
        ),
      ];
    }
    return [
      SliverList.builder(
        itemCount: filteredAyahs.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final match = filteredAyahs[index];
          return QuranAyahSearchCard(
            key: ValueKey(
              'search_ayah_${match.surahNumber}_${match.ayahNumber}',
            ),
            match: match,
            onTap: () => onOpenAyah(match),
          );
        },
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: AppSize.navClearance(context)),
      ),
    ];
  }

  // 4. Filter: All (Both Surahs and Ayahs with section headers)
  final slivers = <Widget>[];

  if (filteredSurahs.isNotEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        child: QuranSearchSectionHeader(
          title: 'السور',
          count: filteredSurahs.length,
          icon: Icons.menu_book_rounded,
        ),
      ),
    );
    slivers.add(
      SliverList.builder(
        itemCount: filteredSurahs.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final surahNum = filteredSurahs[index];
          return SurahCard(
            key: ValueKey('search_all_surah_$surahNum'),
            surahNumber: surahNum,
            isBookmarked: bookmarkedSurahSet.contains(surahNum),
            onTap: () => onOpenSurah(surahNum),
            onBookmarkTap: () => onToggleBookmark(surahNum),
          );
        },
      ),
    );
  }

  if (filteredAyahs.isNotEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        child: QuranSearchSectionHeader(
          title: 'الآيات والكلمات',
          count: filteredAyahs.length,
          icon: Icons.format_quote_rounded,
        ),
      ),
    );
    slivers.add(
      SliverList.builder(
        itemCount: filteredAyahs.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final match = filteredAyahs[index];
          return QuranAyahSearchCard(
            key: ValueKey(
              'search_all_ayah_${match.surahNumber}_${match.ayahNumber}',
            ),
            match: match,
            onTap: () => onOpenAyah(match),
          );
        },
      ),
    );
  } else if (query.length < 2) {
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          child: Center(
            child: Text(
              'اكتب حرفين أو أكثر للبحث في نصوص الآيات...',
              style: textTheme.caption.copyWith(color: palette.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  slivers.add(
    SliverToBoxAdapter(
      child: SizedBox(height: AppSize.navClearance(context)),
    ),
  );

  return slivers;
}
