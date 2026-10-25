import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/asset_service.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../adhkar/data/adhkar_models.dart';
import '../../../adhkar/data/adhkar_service.dart';
import '../../../adhkar/presentation/adhkar_page.dart';
import '../../../adhkar/presentation/adhkar_session_page.dart';
import '../../../adhkar/presentation/after_prayer_athkar_page.dart';
import '../../../adhkar/presentation/duas_misc_page.dart';
import '../../../adhkar/presentation/evening_athkar_page.dart';
import '../../../adhkar/presentation/morning_athkar_page.dart';
import '../../../adhkar/presentation/sleeping_athkar_page.dart';
import '../../../adhkar/presentation/tasbeeh_istighfar_page.dart';
import '../../../hadith/presentation/pages/hadith_explorer_page.dart';
import '../../../ilm/data/catalogs/turath_catalog.dart';
import '../../../ilm/data/models/mutun_models.dart';
import '../../../ilm/data/models/shamela_models.dart';
import '../../../ilm/presentation/pages/book_view_page.dart';
import '../../../ilm/presentation/pages/shamela_reader_page.dart';
import '../../../quran/presentation/widgets/mushaf_page_viewer.dart';

/// Routes a favorite item to its canonical destination or shows a rich details dialog.
class FavoriteItemLauncher {
  const FavoriteItemLauncher._();

  static Future<void> launch(BuildContext context, FavoriteItem item) async {
    HapticFeedback.lightImpact();
    switch (item.type) {
      case FavoriteType.book:
        await _launchBook(context, item);
        break;
      case FavoriteType.hadith:
        await _launchHadith(context, item);
        break;
      case FavoriteType.dua:
        await _launchDua(context, item);
        break;
      case FavoriteType.dhikr:
        await _launchDhikr(context, item);
        break;
      case FavoriteType.quran:
        await _launchQuran(context, item);
        break;
      case FavoriteType.quote:
      case FavoriteType.lesson:
        showDetailDialog(context, item);
        break;
    }
  }

  static Future<void> _launchBook(BuildContext context, FavoriteItem item) async {
    // 1. Shamela prefixed book id
    if (item.id.startsWith('shamela_')) {
      final shamelaId = int.tryParse(item.id.replaceFirst('shamela_', ''));
      if (shamelaId != null) {
        final match = TurathCatalog.books.cast<ShamelaBook?>().firstWhere(
              (b) => b?.id == shamelaId,
              orElse: () => null,
            );
        if (match != null && context.mounted) {
          await Navigator.push(
            context,
            buildFadeRoute(page: ShamelaReaderPage(book: match)),
          );
          return;
        }
      }
    }

    // 2. Mutun program catalog
    final program = await AssetService.loadMutunProgram();
    IlmBook? targetBook;
    for (final lvl in program.levels) {
      for (final b in lvl.books) {
        if (b.id == item.id || b.title == item.title) {
          targetBook = b;
          break;
        }
      }
      if (targetBook != null) break;
    }

    if (targetBook != null && context.mounted) {
      await Navigator.push(
        context,
        buildFadeRoute(page: BookViewPage(book: targetBook)),
      );
      return;
    }

    // 3. Fallback: Shamela catalog by ID or title match
    final shamelaMatch = TurathCatalog.books.cast<ShamelaBook?>().firstWhere(
          (b) => b?.id.toString() == item.id || b?.title == item.title,
          orElse: () => null,
        );
    if (shamelaMatch != null && context.mounted) {
      await Navigator.push(
        context,
        buildFadeRoute(page: ShamelaReaderPage(book: shamelaMatch)),
      );
      return;
    }

    // 4. Fallback dialog
    if (context.mounted) {
      showDetailDialog(context, item);
    }
  }

  static Future<void> _launchHadith(BuildContext context, FavoriteItem item) async {
    final query = _extractSearchKeywords(item.title);
    await Navigator.push(
      context,
      buildFadeRoute(
        page: HadithExplorerPage(initialSearchQuery: query),
      ),
    );
  }

  static Future<void> _launchDua(BuildContext context, FavoriteItem item) async {
    final query = _extractSearchKeywords(item.title);
    await Navigator.push(
      context,
      buildFadeRoute(
        page: DuasMiscPage(initialSearchQuery: query),
      ),
    );
  }

  static Future<void> _launchDhikr(BuildContext context, FavoriteItem item) async {
    final lowerId = item.id.trim().toLowerCase();
    final lowerTitle = item.title.trim().toLowerCase();

    if (lowerId == 'morning' || lowerTitle.contains('الصباح')) {
      await Navigator.push(context, buildFadeRoute(page: const MorningAthkarPage()));
      return;
    }
    if (lowerId == 'evening' || lowerTitle.contains('المساء')) {
      await Navigator.push(context, buildFadeRoute(page: const EveningAthkarPage()));
      return;
    }
    if (lowerId == 'after_prayer' ||
        lowerId == 'afterprayer' ||
        lowerTitle.contains('الصلاة')) {
      await Navigator.push(context, buildFadeRoute(page: const AfterPrayerAthkarPage()));
      return;
    }
    if (lowerId == 'sleeping' || lowerTitle.contains('النوم')) {
      await Navigator.push(context, buildFadeRoute(page: const SleepingAthkarPage()));
      return;
    }
    if (lowerId == 'tasbeeh' || lowerTitle.contains('تسبيح')) {
      await Navigator.push(
        context,
        buildFadeRoute(page: const TasbeehIstighfarPage(initialTabIndex: 0)),
      );
      return;
    }
    if (lowerId == 'istighfar' || lowerTitle.contains('استغفار')) {
      await Navigator.push(
        context,
        buildFadeRoute(page: const TasbeehIstighfarPage(initialTabIndex: 1)),
      );
      return;
    }

    // Attempt matching specific catalog category
    final catalog = await AthkarService().loadCatalog();
    final match = catalog.categories.cast<AthkarCategoryData?>().firstWhere(
          (c) => c?.id == item.id || c?.title == item.title,
          orElse: () => null,
        );
    if (match != null && context.mounted) {
      final parsed = adhkarCategoryFromId(match.id) ?? AdhkarCategory.general;
      await Navigator.push(
        context,
        buildFadeRoute(
          page: AdhkarSessionPage(
            category: parsed,
            categoryId: match.id,
            titleOverride: match.title,
            categoryData: match,
          ),
        ),
      );
      return;
    }

    // Default to main Adhkar hub
    if (context.mounted) {
      await Navigator.push(context, buildFadeRoute(page: const AdhkarPage()));
    }
  }

  static Future<void> _launchQuran(BuildContext context, FavoriteItem item) async {
    int? targetPage;
    int? targetSurah;
    int? targetAyah;

    // Direct numeric page ID check (1 - 604)
    final numericId = int.tryParse(item.id.trim());
    if (numericId != null && numericId >= 1 && numericId <= 604) {
      targetPage = numericId;
    } else {
      // Regex parse surah name and verse number from subtitle or title
      final combined = '${item.subtitle} ${item.title}';
      final match = RegExp(
        r'(?:سورة\s+)?([^\d:\[\]\(\)\s]+)\s*[:：]\s*(\d+)',
      ).firstMatch(combined);

      if (match != null) {
        final parsedSurahName = match.group(1)?.trim() ?? '';
        final parsedAyah = int.tryParse(match.group(2) ?? '');
        if (parsedSurahName.isNotEmpty) {
          for (int s = 1; s <= 114; s++) {
            final officialName = quran.getSurahNameArabic(s);
            if (officialName == parsedSurahName ||
                parsedSurahName.contains(officialName) ||
                officialName.contains(parsedSurahName)) {
              targetSurah = s;
              targetAyah = parsedAyah ?? 1;
              targetPage = quran.getPageNumber(s, targetAyah);
              break;
            }
          }
        }
      }
    }

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MushafPageViewer(
            initialPage: targetPage,
            initialSurah: targetSurah,
            initialAyah: targetAyah,
          ),
        ),
      );
    }
  }

  static String _extractSearchKeywords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 5) return trimmed;
    return words.take(5).join(' ');
  }

  static void showDetailDialog(BuildContext context, FavoriteItem item) {
    HapticFeedback.selectionClick();
    AppDialog.show<void>(
      context: context,
      builder: (dialogCtx) {
        final palette = dialogCtx.palette;
        final textTheme = dialogCtx.text;

        final fullShareText = item.subtitle.isNotEmpty
            ? '${item.title}\n\n${item.subtitle}'
            : item.title;

        return AppDialog(
          title: _labelForType(item.type),
          icon: Icons.bookmark_rounded,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  item.title,
                  style: textTheme.body.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  SelectableText(
                    item.subtitle,
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            AppButton.text(
              label: 'نسخ',
              icon: Icons.copy_rounded,
              size: AppButtonSize.sm,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullShareText));
                Navigator.pop(dialogCtx);
                AppSnackbar.success(context, 'تم النسخ إلى الحافظة');
              },
            ),
            AppButton.text(
              label: 'مشاركة',
              icon: Icons.share_rounded,
              size: AppButtonSize.sm,
              onPressed: () {
                Navigator.pop(dialogCtx);
                Share.share(fullShareText);
              },
            ),
            AppButton(
              label: 'إغلاق',
              size: AppButtonSize.sm,
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        );
      },
    );
  }

  static String _labelForType(FavoriteType type) {
    switch (type) {
      case FavoriteType.hadith:
        return AppStrings.favoriteTypeHadith;
      case FavoriteType.dhikr:
        return AppStrings.favoriteTypeDhikr;
      case FavoriteType.dua:
        return AppStrings.favoriteTypeDua;
      case FavoriteType.lesson:
        return AppStrings.favoriteTypeLesson;
      case FavoriteType.book:
        return AppStrings.favoriteTypeBook;
      case FavoriteType.quran:
        return AppStrings.favoriteTypeQuran;
      case FavoriteType.quote:
        return AppStrings.favoriteTypeQuote;
    }
  }
}
