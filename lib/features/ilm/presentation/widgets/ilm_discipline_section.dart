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
import 'discipline_quiz_shelf_card.dart';
import 'ilm_partition_header.dart';
import 'mutun_rosette_icon.dart';
import 'shamela_book_card.dart';
import 'shamela_shelf_card.dart';

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

                      // Tier 2: Subtitle Description + Discipline Quiz Pill
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              style: context.text.caption.copyWith(
                                color: palette.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (fan != null) ...[
                            const SizedBox(width: AppSpace.xs),
                            Semantics(
                              button: true,
                              label: 'اختبار $title (${fan.totalQuestions} سؤالاً)',
                              child: Material(
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
                                      horizontal: AppSpace.sm,
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
                                          'اختبار الفن • ${fan.totalQuestions} س',
                                          style: context.text.caption.copyWith(
                                            color: palette.gold,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpace.xxs),
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
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.sm),

                // ── 2. Horizontal Bookshelf (featuring DisciplineQuizShelfCard) ──
                SizedBox(
                  height: 195,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.lg,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: (fan != null ? 1 : 0) + books.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpace.sm),
                    itemBuilder: (context, index) {
                      if (fan != null && index == 0) {
                        return DisciplineQuizShelfCard(
                          fan: fan,
                          onOpenQuiz: () => onOpenQuiz(fan),
                        );
                      }
                      final bookIndex = fan != null ? index - 1 : index;
                      final book = books[bookIndex];
                      return ShamelaShelfCard(
                        book: book,
                        onOpen: () => onOpenBook(book),
                        onOpenShuruh: onOpenShuruh,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // ── Focused View for Discipline (Full Vertical Listing) ───────
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
        child: IlmPartitionHeader(
          title: title,
          subtitle: subtitle,
          countLabel: '${books.length} كتب',
        ),
      ),
      SliverPadding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final book = books[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                child: ShamelaBookCard(
                  book: book,
                  isDownloaded: true,
                  downloadProgress: null,
                  onOpen: () => onOpenBook(book),
                  onDownload: () {},
                  onOpenShuruh: onOpenShuruh,
                ),
              );
            },
            childCount: books.length,
          ),
        ),
      ),
    ];
  }
}
