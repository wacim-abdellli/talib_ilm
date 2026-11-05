import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/asset_service.dart';
import '../../data/catalogs/turath_catalog.dart';
import '../../data/models/book_progress_model.dart';
import '../../data/models/mutun_models.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import 'offline_books_tab_view.dart';

/// Central Hub for all offline-ready books and syllabus mutun in talib_ilm.
class OfflineDownloadsHubSheet extends StatefulWidget {
  final void Function(ShamelaBook book) onOpenShamelaBook;
  final void Function(IlmBook book) onOpenMutunBook;
  final VoidCallback? onRefresh;

  const OfflineDownloadsHubSheet({
    super.key,
    required this.onOpenShamelaBook,
    required this.onOpenMutunBook,
    this.onRefresh,
  });

  static Future<void> show({
    required BuildContext context,
    required void Function(ShamelaBook book) onOpenShamelaBook,
    required void Function(IlmBook book) onOpenMutunBook,
    VoidCallback? onRefresh,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OfflineDownloadsHubSheet(
        onOpenShamelaBook: onOpenShamelaBook,
        onOpenMutunBook: onOpenMutunBook,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  State<OfflineDownloadsHubSheet> createState() =>
      _OfflineDownloadsHubSheetState();
}

class _OfflineDownloadsHubSheetState extends State<OfflineDownloadsHubSheet> {
  List<ShamelaBook> _downloadedBooks = [];
  List<IlmBook> _bundledMutun = [];
  Map<String, BookProgress> _progressById = {};
  bool _isLoading = true;

  int get _offlineStudyContentCount =>
      _downloadedBooks.length + _bundledMutun.length;

  @override
  void initState() {
    super.initState();
    _loadAllOfflineData();
  }

  Future<void> _loadAllOfflineData() async {
    setState(() => _isLoading = true);

    try {
      final downloadedMap = await ShamelaService.getDownloadedBooksMap();

      // Find downloaded Shamela books
      final books = <ShamelaBook>[];
      for (final book in TurathCatalog.books) {
        if (downloadedMap[book.id] == true) {
          books.add(book);
        }
      }

      // Load bundled mutun
      final program = await AssetService.loadMutunProgram();
      final mutun = <IlmBook>[];
      for (final lvl in program.levels) {
        if (!lvl.hidden) {
          mutun.addAll(lvl.books);
        }
      }

      // Load reading progress
      final progressMap = <String, BookProgress>{};

      if (mounted) {
        setState(() {
          _downloadedBooks = books;
          _bundledMutun = mutun;
          _progressById = progressMap;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteShamelaBook(ShamelaBook book) async {
    HapticFeedback.lightImpact();
    await ShamelaService.deleteBook(book.id);
    await _loadAllOfflineData();
    widget.onRefresh?.call();
    if (mounted) {
      AppSnackbar.info(
        context,
        'تمت إزالة كتاب "${book.title}" من المحمّلات',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: screenHeight * 0.88,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          border: Border.all(color: palette.border, width: 1),
        ),
        child: Column(
          children: [
            // ── Drag Handle ──────────────────────────────────────────
            const SizedBox(height: AppSpace.sm),
            Container(
              width: AppSize.tap,
              height: AppSpace.xs,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            const SizedBox(height: AppSpace.sm),

            // ── Luxury Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xl,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSize.tap,
                    height: AppSize.tap,
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.mdRadius,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.download_done_rounded,
                      color: palette.gold,
                      size: AppIcon.lg,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حقيبة المحتوى بدون إنترنت',
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            '$_offlineStudyContentCount كتاباً ومتناً متاحاً للقراءة بدون إنترنت',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.textMuted,
                      size: AppIcon.md,
                    ),
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.sm),

            // ── Offline Books & Mutun Content ────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.primary,
                        ),
                      ),
                    )
                  : OfflineBooksTabView(
                      downloadedBooks: _downloadedBooks,
                      bundledMutun: _bundledMutun,
                      progressById: _progressById,
                      onOpenShamelaBook: (book) {
                        Navigator.of(context).pop();
                        widget.onOpenShamelaBook(book);
                      },
                      onOpenMutunBook: (book) {
                        Navigator.of(context).pop();
                        widget.onOpenMutunBook(book);
                      },
                      onDeleteShamelaBook: _handleDeleteShamelaBook,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
