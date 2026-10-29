import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/shamela_models.dart';

/// Tab view presenting offline-ready Shamela heritage books and bundled syllabus mutun.
class OfflineBooksTabView extends StatelessWidget {
  final List<ShamelaBook> downloadedBooks;
  final List<IlmBook> bundledMutun;
  final Map<String, BookProgress> progressById;
  final void Function(ShamelaBook book) onOpenShamelaBook;
  final void Function(IlmBook book) onOpenMutunBook;

  const OfflineBooksTabView({
    super.key,
    required this.downloadedBooks,
    required this.bundledMutun,
    required this.progressById,
    required this.onOpenShamelaBook,
    required this.onOpenMutunBook,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (downloadedBooks.isEmpty && bundledMutun.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: EmptyState(
            icon: Icons.cloud_download_outlined,
            title: 'لا توجد كتب محمّلة بعد',
            subtitle:
                'يمكنك تحميل أي كتاب من المكتبة التراثية للقراءة بدون إنترنت بنقرة زر واحدة.',
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        children: [
          // ── 1. Downloaded Shamela Classics Section ───────────────────
          if (downloadedBooks.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              title: 'الكتب التراثية المحفوظة محلياً',
              badge: '${downloadedBooks.length} كتب',
              icon: Icons.check_circle_outline_rounded,
              color: palette.primary,
            ),
            const SizedBox(height: AppSpace.sm),
            ...downloadedBooks.map((book) => _buildShamelaCard(context, book)),
            const SizedBox(height: AppSpace.lg),
          ],

          // ── 2. Bundled Core Syllabus Mutun (100% Offline) ───────────
          if (bundledMutun.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              title: 'متون طالب العلم المضمنة',
              badge: '${bundledMutun.length} متون أساسية',
              icon: Icons.menu_book_rounded,
              color: palette.primary,
            ),
            const SizedBox(height: AppSpace.sm),
            ...bundledMutun.map((mutn) => _buildMutnCard(context, mutn)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String badge,
    required IconData icon,
    required Color color,
  }) {
    final palette = context.palette;
    final textTheme = context.text;

    return Row(
      children: [
        Icon(icon, color: color, size: AppIcon.sm),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(
            title,
            style: textTheme.caption.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xxs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.pillRadius,
          ),
          child: Text(
            badge,
            style: textTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShamelaCard(BuildContext context, ShamelaBook book) {
    final palette = context.palette;
    final textTheme = context.text;
    final progress = progressById['shamela_${book.id}'];
    final currentPage = progress?.currentPage ?? 1;
    final total = book.totalPages > 0 ? book.totalPages : 1;
    final percent = ((currentPage / total) * 100).clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: palette.border),
        ),
        padding: const EdgeInsetsDirectional.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSize.tap,
                  height: AppSize.tap,
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: palette.primary,
                    size: AppIcon.md,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: textTheme.body.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        book.author,
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.offline_pin_rounded,
                      size: AppIcon.xs,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Text(
                      'جاهز للقراءة بدون إنترنت',
                      style: textTheme.caption.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currentPage / $total صفحة ($percent%)',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: palette.primary,
                borderRadius: AppRadius.smRadius,
                child: InkWell(
                  borderRadius: AppRadius.smRadius,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onOpenShamelaBook(book);
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: palette.bg,
                          size: AppIcon.sm,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          'اقرأ الآن',
                          style: textTheme.caption.copyWith(
                            color: palette.bg,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutnCard(BuildContext context, IlmBook mutn) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
      child: Semantics(
        button: true,
        label: 'فتح المتن: ${mutn.title}',
        child: Material(
          color: palette.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdRadius,
            side: BorderSide(color: palette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenMutunBook(mutn);
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              child: Row(
                children: [
                  Container(
                    width: AppSize.tap,
                    height: AppSize.tap,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: AppRadius.smRadius,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: palette.onPrimarySoft,
                      size: AppIcon.md,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mutn.title,
                          style: textTheme.body.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          '${mutn.author} · ${mutn.level}',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        color: palette.primary,
                        size: AppIcon.sm,
                      ),
                      Text(
                        'فتح المتن',
                        style: textTheme.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
