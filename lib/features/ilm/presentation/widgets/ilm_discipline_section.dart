import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/catalogs/aqidah_catalog.dart';
import '../../data/catalogs/arabic_catalog.dart';
import '../../data/catalogs/fiqh_catalog.dart';
import '../../data/catalogs/hadith_catalog.dart';
import '../../data/catalogs/islamic_quiz_catalog.dart';
import '../../data/catalogs/raqaeq_adab_catalog.dart';
import '../../data/catalogs/seerah_tarikh_catalog.dart';
import '../../data/catalogs/tafsir_catalog.dart';
import '../../data/catalogs/usul_catalog.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../../data/models/shamela_models.dart';
import 'ilm_book_preview_row.dart';
import 'ilm_partition_header.dart';
import 'mutun_rosette_icon.dart';
import 'shamela_book_card.dart';

class DisciplineItem {
  final String key;
  final String title;
  final String subtitle;
  final List<ShamelaBook> books;
  final FanQuiz? fan;

  const DisciplineItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.books,
    this.fan,
  });
}

/// Clean discipline shelf section for classical Islamic arts (Aqidah, Hadith, Fiqh, etc.).
/// Features dedicated discipline quiz launcher, horizontal shelf, and focused vertical listing.
class IlmDisciplineSection {
  IlmDisciplineSection._();

  static List<DisciplineItem> get disciplines => [
        DisciplineItem(
          key: 'aqidah',
          title: 'العقيدة والتوحيد',
          subtitle: 'أصول الإيمان والتوحيد والرد على الشبهات',
          books: AqidahCatalog.books,
          fan: IslamicQuizCatalog.getFan('aqidah'),
        ),
        DisciplineItem(
          key: 'hadith',
          title: 'الحديث الشريف وعلومه',
          subtitle: 'الأحاديث النبوية وشروحها ومصطلح الحديث',
          books: HadithCatalog.allBooks,
          fan: IslamicQuizCatalog.getFan('hadith'),
        ),
        DisciplineItem(
          key: 'fiqh',
          title: 'الفقه الإسلامي وأصوله',
          subtitle: 'أحكام العبادات والمعاملات وقواعد الاستنباط',
          books: [...FiqhCatalog.allBooks, ...UsulCatalog.books],
          fan: IslamicQuizCatalog.getFan('fiqh'),
        ),
        DisciplineItem(
          key: 'adab',
          title: 'الآداب والرقائق والأذكار',
          subtitle: 'تزكية النفوس وحفظ الأوقات والأخلاق الإسلامية',
          books: RaqaeqAdabCatalog.books,
          fan: IslamicQuizCatalog.getFan('adab'),
        ),
        DisciplineItem(
          key: 'tafsir',
          title: 'التفسير وعلوم القرآن',
          subtitle: 'معاني كلام الله وقواعد التدبر والتجويد',
          books: TafsirCatalog.books,
          fan: IslamicQuizCatalog.getFan('quran'),
        ),
        DisciplineItem(
          key: 'seerah',
          title: 'السيرة النبوية والتاريخ',
          subtitle: 'سيرة النبي ﷺ وتاريخ الخلفاء الراشدين والأمة',
          books: SeerahTarikhCatalog.books,
          fan: IslamicQuizCatalog.getFan('seerah'),
        ),
        DisciplineItem(
          key: 'arabic',
          title: 'اللغة العربية وعلومها',
          subtitle: 'النحو والصرف والبلاغة مفتاح فهم الوحيين',
          books: ArabicCatalog.books,
          fan: IslamicQuizCatalog.getFan('arabic'),
        ),
      ];

  static List<Widget> buildSlivers({
    required BuildContext context,
    required AppPalette palette,
    required String title,
    required String subtitle,
    required List<ShamelaBook> books,
    required String categoryKey,
    required bool isFocused,
    required FanQuiz? fan,
    required ValueChanged<ShamelaBook> onOpenBook,
    required void Function(ShamelaBook, List<ShamelaBook>) onOpenShuruh,
    required VoidCallback onViewAll,
    required VoidCallback onBackToAll,
    required ValueChanged<FanQuiz> onOpenQuiz,
    int? selectedLevel,
    ValueChanged<int?>? onSelectLevel,
    Map<int, bool>? downloadedMap,
    Map<int, double>? downloadProgress,
    ValueChanged<ShamelaBook>? onDownloadBook,
  }) {
    final catColors = palette.category(categoryKey);

    if (!isFocused) {
      // ── Clean Partitioned Shelf Section ──────────────────────────
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: AppSpace.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Elegant Two-Tier Discipline Header ──
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tier 1: Category Icon + Full Title + Count Pill <---> View All
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                            decoration: BoxDecoration(
                              color: catColors.bg,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: MutunRosetteIcon(
                              size: AppIcon.sm,
                              color: catColors.fg,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: context.text.title.copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Container(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.xs,
                                    vertical: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: catColors.bg,
                                    borderRadius: AppRadius.pillRadius,
                                  ),
                                  child: Text(
                                    '${books.length}',
                                    style: context.text.caption.copyWith(
                                      color: catColors.fg,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),

                          // View All Button with arrow
                          Semantics(
                            button: true,
                            label: 'عرض كل كتب $title',
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: AppRadius.pillRadius,
                              child: InkWell(
                                borderRadius: AppRadius.pillRadius,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onViewAll();
                                },
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.xs,
                                    vertical: AppSpace.xs,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'عرض الكل',
                                        style: context.text.caption.copyWith(
                                          color: palette.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.xxs),
                                      Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: AppIcon.xs,
                                        color: palette.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpace.xxs),

                      // Tier 2: Subtitle Description
                      Text(
                        subtitle,
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.sm),

                // ── 2. Compact Vertical Book Preview List ──
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.lg,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.border, width: 0.8),
                      borderRadius: AppRadius.lgRadius,
                      color: palette.surface,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < books.take(4).length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: palette.border,
                              indent: AppSpace.lg,
                              endIndent: 0,
                            ),
                          IlmBookPreviewRow(
                            title: books[i].title,
                            subtitle: _buildSubtitle(books[i]),
                            accentColor: catColors.fg,
                            onTap: () => onOpenBook(books[i]),
                          ),
                        ],
                        if (books.length > 4) ...[
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: palette.border,
                          ),
                          IlmViewAllRow(
                            label: 'عرض جميع الكتب (${books.length})',
                            onTap: onViewAll,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // ── Focused View for Discipline (Full Vertical Listing with Level Filters) ──
    final filteredBooks = selectedLevel == null
        ? books
        : books.where((b) => b.level == selectedLevel).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'العودة لجميع الأقسام',
                child: Material(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.pillRadius,
                  child: InkWell(
                    borderRadius: AppRadius.pillRadius,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onBackToAll();
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: AppIcon.xs,
                            color: palette.primary,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'العودة لجميع الأقسام',
                            style: context.text.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (fan != null)
                Material(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.pillRadius,
                  child: InkWell(
                    borderRadius: AppRadius.pillRadius,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onOpenQuiz(fan);
                    },
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: palette.gold.withAlpha(160),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: AppIcon.sm,
                            color: palette.gold,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'اختبر فهمك للفن (${fan.totalQuestions} سؤالاً)',
                            style: context.text.caption.copyWith(
                              color: palette.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: AppIcon.xs,
                            color: palette.gold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IlmPartitionHeader(
              title: title,
              subtitle: subtitle,
              countLabel: '${filteredBooks.length} كتب',
            ),
            // Horizontal Level Selector Filter (تمهيدي / تأصيلي / مطولات)
            SizedBox(
              height: AppSize.tap,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildLevelChip(
                    context: context,
                    label: 'جميع المستويات (${books.length})',
                    isSelected: selectedLevel == null,
                    onTap: () => onSelectLevel?.call(null),
                    palette: palette,
                  ),
                  _buildLevelChip(
                    context: context,
                    label: 'تمهيدي (مبتدئ) (${books.where((b) => b.level == 1).length})',
                    isSelected: selectedLevel == 1,
                    onTap: () => onSelectLevel?.call(1),
                    palette: palette,
                    dotColor: palette.primary,
                  ),
                  _buildLevelChip(
                    context: context,
                    label: 'تأصيلي (متوسط) (${books.where((b) => b.level == 2).length})',
                    isSelected: selectedLevel == 2,
                    onTap: () => onSelectLevel?.call(2),
                    palette: palette,
                    dotColor: palette.gold,
                  ),
                  _buildLevelChip(
                    context: context,
                    label: 'مطولات (متقدم) (${books.where((b) => b.level == 3).length})',
                    isSelected: selectedLevel == 3,
                    onTap: () => onSelectLevel?.call(3),
                    palette: palette,
                    dotColor: palette.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      ),
      if (filteredBooks.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.xxl),
            child: Center(
              child: Text(
                'لا توجد كتب متوفرة في هذا المستوى حالياً',
                style: context.text.body.copyWith(color: palette.textMuted),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final book = filteredBooks[index];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                  child: ShamelaBookCard(
                    book: book,
                    isDownloaded: downloadedMap?[book.id] ?? false,
                    downloadProgress: downloadProgress?[book.id],
                    onOpen: () => onOpenBook(book),
                    onDownload: () => onDownloadBook?.call(book),
                    onOpenShuruh: onOpenShuruh,
                  ),
                );
              },
              childCount: filteredBooks.length,
            ),
          ),
        ),
    ];
  }

  static Widget _buildLevelChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
    Color? dotColor,
  }) {
    final Color bgColor = isSelected ? palette.primarySoft : palette.surfaceRaised;
    final Color fgColor = isSelected ? palette.primary : palette.textMuted;
    final Color borderColor = isSelected ? palette.primary : palette.border;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
      child: Material(
        color: bgColor,
        borderRadius: AppRadius.pillRadius,
        child: InkWell(
          borderRadius: AppRadius.pillRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null && !isSelected) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                  ],
                  Text(
                    label,
                    style: (isSelected ? context.text.captionHeavy : context.text.captionBold).copyWith(
                      color: fgColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _buildSubtitle(ShamelaBook book) {
    final authorSubtitle = book.authorDeath != null
        ? '${book.author} (ت: ${book.authorDeath})'
        : book.author;
    return book.totalPages > 0
        ? '$authorSubtitle • ${book.totalPages} ص'
        : authorSubtitle;
  }
}
