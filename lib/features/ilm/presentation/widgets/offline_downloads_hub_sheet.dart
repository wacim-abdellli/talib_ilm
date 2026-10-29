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
import '../../../quran/data/services/quran_audio_downloader.dart';
import 'offline_books_tab_view.dart';
import 'offline_quran_audio_tab_view.dart';

/// Central Hub for all offline-ready content in talib_ilm:
/// - Downloaded Shamela heritage books & bundled syllabus mutun
/// - Downloaded Holy Quran audio surahs
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

class _OfflineDownloadsHubSheetState extends State<OfflineDownloadsHubSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<ShamelaBook> _downloadedBooks = [];
  List<IlmBook> _bundledMutun = [];
  Map<String, BookProgress> _progressById = {};
  int _quranStorageBytes = 0;
  bool _isLoading = true;

  int get _offlineStudyContentCount =>
      _downloadedBooks.length + _bundledMutun.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllOfflineData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllOfflineData() async {
    setState(() => _isLoading = true);

    try {
      final downloadedMap = await ShamelaService.getDownloadedBooksMap();
      final quranBytes = await QuranAudioDownloader.getTotalStorageUsed();

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
          _quranStorageBytes = quranBytes;
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
                      Icons.offline_pin_rounded,
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
                          style: textTheme.title.copyWith(color: palette.text),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xl,
              ),
              child: Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  _buildSummaryMetric(
                    context,
                    icon: Icons.auto_stories_rounded,
                    label: 'الكتب التراثية: ${_downloadedBooks.length}',
                    color: palette.primary,
                  ),
                  _buildSummaryMetric(
                    context,
                    icon: Icons.menu_book_rounded,
                    label: 'المتون المضمنة: ${_bundledMutun.length}',
                    color: palette.primary,
                  ),
                  _buildSummaryMetric(
                    context,
                    icon: Icons.headphones_rounded,
                    label:
                        'صوتيات القرآن: ${QuranAudioDownloader.formatBytes(_quranStorageBytes)}',
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.sm),

            // ── Navigation Tabs ──────────────────────────────────────
            Container(
              margin: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: palette.primary,
                  borderRadius: AppRadius.pillRadius,
                ),
                labelColor: palette.bg,
                unselectedLabelColor: palette.textMuted,
                labelStyle: textTheme.caption.copyWith(),
                unselectedLabelStyle: textTheme.caption,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.menu_book_rounded, size: AppIcon.sm),
                    text: 'الكتب والمتون ($_offlineStudyContentCount)',
                  ),
                  const Tab(
                    icon: Icon(Icons.headphones_rounded, size: AppIcon.sm),
                    text: 'سور القرآن الصوتية',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.sm),

            // ── Tab Views ────────────────────────────────────────────
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
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        OfflineBooksTabView(
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
                        ),
                        OfflineQuranAudioTabView(
                          onStorageChanged: () {
                            _loadAllOfflineData();
                            widget.onRefresh?.call();
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppIcon.xs),
          const SizedBox(width: AppSpace.xxs),
          Text(label, style: textTheme.label.copyWith(color: palette.text)),
        ],
      ),
    );
  }
}
