import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/services/bookmark_service.dart';
import 'mushaf_page_viewer.dart';

class QuranBookmarksTabView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (bookmarks.isEmpty) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
        child: EmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'لا توجد آيات أو ملاحظات محفوظة',
          subtitle: 'يمكنك حفظ الآيات وتدوين خواطرك بالضغط على أيقونة الحفظ عند قراءة أي آية.',
          actionLabel: 'تصفح القرآن الكريم',
          onAction: onEmptyAction,
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarks.length,
      padding: EdgeInsetsDirectional.only(
        start: AppSpace.lg,
        end: AppSpace.lg,
        bottom: AppSize.navClearance(context),
      ),
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        final surahName = quran.getSurahNameArabic(b.surah);
        final verseText = quran.getVerse(b.surah, b.ayah, verseEndSymbol: false);

        return Container(
          margin: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
          child: AppCard(
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
              ).then((_) => onReload());
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
                        color: palette.goldSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        '${b.ayah}',
                        style: textTheme.caption.copyWith(
                          color: palette.gold,
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
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: AppIcon.sm,
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
                if (b.note != null && b.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'تدبر: ${b.note}',
                    style: textTheme.caption.copyWith(
                      color: palette.primary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
