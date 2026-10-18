import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import 'ilm_mutn_card.dart';
import 'ilm_partition_header.dart';
import 'shamela_book_card.dart';

/// Clean unified search results view for both Mutun and Shamela classical texts.
class IlmSearchResultsView extends StatelessWidget {
  final String searchQuery;
  final List<IlmBook> allBooks;
  final Map<String, BookProgress> progressById;
  final Set<String> favoriteBookIds;
  final VoidCallback onClearSearch;
  final ValueChanged<IlmBook> onNavigateToBook;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<ShamelaBook> onOpenShamelaReader;
  final void Function(ShamelaBook, List<ShamelaBook>) onOpenShuruhSheet;

  const IlmSearchResultsView({
    super.key,
    required this.searchQuery,
    required this.allBooks,
    required this.progressById,
    required this.favoriteBookIds,
    required this.onClearSearch,
    required this.onNavigateToBook,
    required this.onToggleFavorite,
    required this.onOpenShamelaReader,
    required this.onOpenShuruhSheet,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final query = searchQuery.toLowerCase();

    final matchedMutun = allBooks.where((b) {
      return b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query) ||
          b.description.toLowerCase().contains(query);
    }).toList();

    final matchedShamela = ShamelaService.searchCatalog(query: query);
    final totalMatches = matchedMutun.length + matchedShamela.length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نتائج البحث: $totalMatches كتب ومتون',
                  style: context.text.titleSmall.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: onClearSearch,
                  borderRadius: AppRadius.pillRadius,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    child: Text(
                      'إلغاء البحث',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (matchedMutun.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: IlmPartitionHeader(
              title: 'المتون العلمية المطابقة',
              countLabel: '${matchedMutun.length} متون',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = matchedMutun[index];
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpace.md,
                    ),
                    child: IlmMutnCard(
                      book: book,
                      progress: progressById[book.id],
                      isFavoriteOverride: favoriteBookIds.contains(book.id),
                      onOpenReader: () => onNavigateToBook(book),
                      onToggleFavorite: () => onToggleFavorite(book.id),
                    ),
                  );
                },
                childCount: matchedMutun.length,
              ),
            ),
          ),
        ],
        if (matchedShamela.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: IlmPartitionHeader(
              title: 'كتب المكتبة العلمية المطابقة',
              countLabel: '${matchedShamela.length} كتب',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = matchedShamela[index];
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpace.md,
                    ),
                    child: ShamelaBookCard(
                      book: book,
                      isDownloaded: true,
                      downloadProgress: null,
                      onOpen: () => onOpenShamelaReader(book),
                      onDownload: () {},
                      onOpenShuruh: onOpenShuruhSheet,
                    ),
                  );
                },
                childCount: matchedShamela.length,
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: SizedBox(
            height: AppSize.navClearance(context) + AppSpace.xxxl,
          ),
        ),
      ],
    );
  }
}
