import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/services/bookmark_service.dart';
import 'mushaf_page_viewer.dart';

class QuranBookmarksTabView extends StatefulWidget {
  final List<Bookmark> bookmarks;
  final VoidCallback onEmptyAction;
  final VoidCallback onReload;

  const QuranBookmarksTabView({
    super.key,
    required this.bookmarks,
    required this.onEmptyAction,
    required this.onReload,
  });

  @override
  State<QuranBookmarksTabView> createState() => _QuranBookmarksTabViewState();
}

class _QuranBookmarksTabViewState extends State<QuranBookmarksTabView> {
  int _selectedFilter = 0; // 0: الكل, 1: السور, 2: الآيات, 3: التدبر

  List<Bookmark> get _filteredBookmarks {
    switch (_selectedFilter) {
      case 1:
        return widget.bookmarks.where((b) => b.isSurah).toList();
      case 2:
        return widget.bookmarks
            .where((b) => !b.isSurah && (b.note == null || b.note!.trim().isEmpty))
            .toList();
      case 3:
        return widget.bookmarks
            .where((b) => !b.isSurah && b.note != null && b.note!.trim().isNotEmpty)
            .toList();
      default:
        return widget.bookmarks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (widget.bookmarks.isEmpty) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
        child: EmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'لا توجد محفوظات بعد',
          subtitle:
              'يمكنك حفظ السور من قائمة السور، أو حفظ الآيات وتدوين خواطرك الإيمانية أثناء تلاوة القرآن الكريم.',
          actionLabel: 'تصفح القرآن الكريم',
          onAction: widget.onEmptyAction,
        ),
      );
    }

    final surahCount = widget.bookmarks.where((b) => b.isSurah).length;
    final ayahCount = widget.bookmarks
        .where((b) => !b.isSurah && (b.note == null || b.note!.trim().isEmpty))
        .length;
    final notesCount = widget.bookmarks
        .where((b) => !b.isSurah && b.note != null && b.note!.trim().isNotEmpty)
        .length;

    final displayed = _filteredBookmarks;

    return Column(
      children: [
        // Filter chips bar
        Container(
          height: 40,
          margin: const EdgeInsetsDirectional.only(
            start: AppSpace.lg,
            end: AppSpace.lg,
            bottom: AppSpace.sm,
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildFilterChip(
                label: 'الكل (${widget.bookmarks.length})',
                index: 0,
                palette: palette,
                textTheme: textTheme,
              ),
              const SizedBox(width: AppSpace.xs),
              if (surahCount > 0) ...[
                _buildFilterChip(
                  label: 'السور ($surahCount)',
                  index: 1,
                  palette: palette,
                  textTheme: textTheme,
                ),
                const SizedBox(width: AppSpace.xs),
              ],
              if (ayahCount > 0) ...[
                _buildFilterChip(
                  label: 'الآيات ($ayahCount)',
                  index: 2,
                  palette: palette,
                  textTheme: textTheme,
                ),
                const SizedBox(width: AppSpace.xs),
              ],
              if (notesCount > 0) ...[
                _buildFilterChip(
                  label: 'خواطر وتدبر ($notesCount)',
                  index: 3,
                  palette: palette,
                  textTheme: textTheme,
                ),
              ],
            ],
          ),
        ),

        // List
        Expanded(
          child: displayed.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد عناصر في هذا التصنيف',
                    style: textTheme.caption.copyWith(color: palette.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: displayed.length,
                  padding: EdgeInsetsDirectional.only(
                    start: AppSpace.lg,
                    end: AppSpace.lg,
                    bottom: AppSize.navClearance(context),
                  ),
                  itemBuilder: (context, index) {
                    final b = displayed[index];
                    return Container(
                      margin: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                      child: b.isSurah
                          ? _buildSurahBookmarkCard(context, b, palette, textTheme)
                          : _buildAyahBookmarkCard(context, b, palette, textTheme),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int index,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    final isSelected = _selectedFilter == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pillRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = index);
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.gold : palette.surfaceRaised,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: isSelected ? palette.gold : palette.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: textTheme.caption.copyWith(
              color: isSelected ? palette.brandDark : palette.text,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahBookmarkCard(
    BuildContext context,
    Bookmark b,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    final surahName = quran.getSurahNameArabic(b.surah);
    final place = quran.getPlaceOfRevelation(b.surah) == 'Makkah' ? 'مكية' : 'مدنية';
    final verseCount = quran.getVerseCount(b.surah);

    return AppCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MushafPageViewer(
              initialPage: b.page,
              initialSurah: b.surah,
              initialAyah: 1,
            ),
          ),
        ).then((_) => widget.onReload());
      },
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: palette.gold.withValues(alpha: 0.3)),
            ),
            alignment: AlignmentDirectional.center,
            child: Icon(
              Icons.bookmark_rounded,
              color: palette.gold,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'سورة $surahName',
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
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Text(
                        'سورة محفوظة',
                        style: textTheme.caption.copyWith(
                          color: palette.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  '$place • $verseCount آية • الصفحة ${b.page}',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: AppIcon.xs,
            color: palette.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildAyahBookmarkCard(
    BuildContext context,
    Bookmark b,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    final surahName = quran.getSurahNameArabic(b.surah);
    final verseText = quran.getVerse(b.surah, b.ayah, verseEndSymbol: false);
    final hasNote = b.note != null && b.note!.trim().isNotEmpty;

    return AppCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MushafPageViewer(
              initialPage: b.page,
              initialSurah: b.surah,
              initialAyah: b.ayah,
            ),
          ),
        ).then((_) => widget.onReload());
      },
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: hasNote ? palette.goldSoft : palette.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasNote ? palette.gold : palette.border,
                  ),
                ),
                alignment: AlignmentDirectional.center,
                child: Text(
                  '${b.ayah}',
                  style: textTheme.caption.copyWith(
                    color: hasNote ? palette.gold : palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'سورة $surahName • صفحة ${b.page}',
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: hasNote ? palette.goldSoft : palette.surfaceMuted,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  hasNote ? 'تدبر وملاحظة' : 'آية محفوظة',
                  style: textTheme.caption.copyWith(
                    color: hasNote ? palette.gold : palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: AppIcon.xs,
                color: palette.textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            verseText,
            style: textTheme.sacred.copyWith(
              color: palette.text,
              height: 1.6,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasNote) ...[
            const SizedBox(height: AppSpace.xs),
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.goldSoft,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: AppIcon.sm,
                    color: palette.gold,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      b.note!,
                      style: textTheme.bodySmall.copyWith(
                        color: palette.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
