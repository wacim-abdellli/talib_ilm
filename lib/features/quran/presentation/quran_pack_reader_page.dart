import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/utils/arabic_digits.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../data/database/quran_pack_database.dart';
import '../data/models/quran_models.dart';
import '../data/services/quran_audio_service.dart';
import '../data/services/quran_pack_install_service.dart';
import '../data/services/quran_page_artwork_service.dart';
import '../data/services/quran_reader_preferences.dart';
import 'widgets/mushaf_reader_overlays.dart';

/// Mushaf-style page reader for installed Warsh and Qalun editions.
///
/// It shares the Hafs reader's navigation and controls, while painting each
/// page from pinned King Fahd Complex Warsh/Qalun Mushaf page artwork.
class QuranPackReaderPage extends StatefulWidget {
  final QuranRiwayahId editionId;
  final int? initialPage;
  final int? initialSurah;
  final int? initialAyah;

  const QuranPackReaderPage({
    super.key,
    required this.editionId,
    this.initialPage,
    this.initialSurah,
    this.initialAyah,
  });

  @override
  State<QuranPackReaderPage> createState() => _QuranPackReaderPageState();
}

class _QuranPackReaderPageState extends State<QuranPackReaderPage> {
  final PageController _pageController = PageController();
  QuranPackDatabase? _database;
  String? _error;
  int _page = 1;
  int _surah = 1;
  int _ayah = 1;
  int _juz = 1;
  int _positionGeneration = 0;
  double _fontSize = 24;
  MushafThemeMode _themeMode = MushafThemeMode.sepia;
  bool _keepScreenAwake = true;
  bool _showOverlays = true;
  Timer? _savePageTimer;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage?.clamp(1, 604) ?? 1;
    _surah = widget.initialSurah?.clamp(1, 114) ?? 1;
    _ayah = widget.initialAyah?.clamp(1, 10000) ?? 1;
    _openPack();
  }

  Future<void> _openPack() async {
    QuranPackDatabase? openedDatabase;
    try {
      final database = await QuranPackInstallService.openInstalled(
        widget.editionId,
      );
      if (database == null) throw StateError('حزمة الرواية غير مثبتة');
      openedDatabase = database;

      final preferences = await QuranReaderPreferences.load(forceRefresh: true);
      var targetPage = _page.clamp(1, database.pageCount);
      if (widget.initialPage == null && widget.initialSurah == null) {
        final storage = await SharedPreferences.getInstance();
        targetPage = (storage.getInt(_lastPageKey) ?? targetPage).clamp(
          1,
          database.pageCount,
        );
      }

      if (widget.initialSurah != null) {
        final ayah = await database.getAyah(
          widget.initialSurah!,
          widget.initialAyah ?? 1,
        );
        if (ayah == null) throw StateError('موضع القراءة غير موجود في الرواية');
        targetPage = ayah.firstPage;
        _surah = ayah.surahNumber;
        _ayah = ayah.ayahNumber;
      }

      if (!mounted) {
        await database.close();
        openedDatabase = null;
        return;
      }
      setState(() {
        _database = database;
        _page = targetPage;
        _fontSize = preferences.fontSize;
        _themeMode = preferences.themeMode;
        _keepScreenAwake = preferences.keepScreenAwake;
      });
      openedDatabase = null;
      await _applyWakelock(_keepScreenAwake);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients && targetPage > 1) {
          _pageController.jumpToPage(targetPage - 1);
        }
      });
      await _updatePosition(targetPage);
    } catch (error) {
      final database = openedDatabase;
      if (database != null) await database.close();
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _updatePosition(int page) async {
    final generation = ++_positionGeneration;
    final ayahs = await _database?.getPageAyahs(page);
    if (!mounted ||
        generation != _positionGeneration ||
        ayahs == null ||
        ayahs.isEmpty) {
      return;
    }
    setState(() {
      _page = page;
      _surah = ayahs.first.surahNumber;
      _ayah = ayahs.first.ayahNumber;
      _juz = ayahs.first.juzNumber;
    });
    _savePageTimer?.cancel();
    _savePageTimer = Timer(AppMotion.debounce, _savePage);
  }

  String get _lastPageKey =>
      'quran_pack_last_page_${widget.editionId.wireValue}_v1';

  Future<void> _savePage() async {
    if (_database == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_lastPageKey, _page);
  }

  void _goToPage(int page) {
    final database = _database;
    if (database == null) return;
    final target = page.clamp(1, database.pageCount);
    _pageController.animateToPage(
      target - 1,
      duration: AppMotion.base,
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleOverlays() => setState(() => _showOverlays = !_showOverlays);

  void _toggleTheme() {
    final next = _themeMode == MushafThemeMode.dark
        ? MushafThemeMode.sepia
        : MushafThemeMode.dark;
    setState(() => _themeMode = next);
    unawaited(QuranReaderPreferences.saveThemeMode(next));
  }

  Future<void> _applyWakelock(bool enabled) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Reading remains available when a device does not support wakelock.
    }
  }

  Future<void> _openSettings() async {
    var sheetTheme = _themeMode;
    var sheetFontSize = _fontSize;
    var sheetKeepAwake = _keepScreenAwake;
    var artworkStatusFuture = QuranPageArtworkService.storageStatus(
      widget.editionId,
    );
    ArtworkDownloadProgress? artworkProgress;
    StreamSubscription<ArtworkDownloadProgress>? artworkSubscription;
    var artworkDownloading = false;
    await AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.72,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => AppSheet(
          titleText: 'إعدادات المصحف',
          icon: Icons.tune_rounded,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'لون الصفحة',
                style: context.text.labelBold.copyWith(
                  color: context.palette.text,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpace.sm),
              SegmentedButton<MushafThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: MushafThemeMode.white,
                    label: Text('أبيض'),
                  ),
                  ButtonSegment(
                    value: MushafThemeMode.sepia,
                    label: Text('ورقي'),
                  ),
                  ButtonSegment(
                    value: MushafThemeMode.dark,
                    label: Text('ليلي'),
                  ),
                ],
                selected: {sheetTheme},
                onSelectionChanged: (selection) {
                  final value = selection.first;
                  setSheetState(() => sheetTheme = value);
                  setState(() => _themeMode = value);
                  unawaited(QuranReaderPreferences.saveThemeMode(value));
                },
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Text('تكبير الصفحة', style: context.text.labelBold),
                  const Spacer(),
                  Text('${(sheetFontSize / 24 * 100).round()}%'),
                ],
              ),
              Slider(
                value: sheetFontSize.clamp(18, 36),
                min: 18,
                max: 36,
                divisions: 9,
                label: '${(sheetFontSize / 24 * 100).round()}%',
                onChanged: (value) {
                  setSheetState(() => sheetFontSize = value);
                  setState(() => _fontSize = value);
                  unawaited(QuranReaderPreferences.saveFontSize(value));
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('إبقاء الشاشة مضاءة أثناء القراءة'),
                value: sheetKeepAwake,
                onChanged: (value) {
                  setSheetState(() => sheetKeepAwake = value);
                  setState(() => _keepScreenAwake = value);
                  unawaited(_applyWakelock(value));
                  unawaited(QuranReaderPreferences.saveKeepScreenAwake(value));
                },
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'تُعرض صفحات المصحف الأصلية بالرسم والتخطيط المطبوع، ويُحفظ مستوى التكبير لكل جهاز.',
                style: context.text.caption.copyWith(
                  color: context.palette.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'ألوان التجويد الموثقة متاحة لحفص فقط؛ تعرض ورش وقالون صفحة المصحف الأصلية دون تلوين إضافي.',
                style: context.text.caption.copyWith(
                  color: context.palette.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpace.md),
              FutureBuilder<ArtworkStorageStatus>(
                future: artworkStatusFuture,
                builder: (context, snapshot) {
                  final status = snapshot.data;
                  final totalMb = status == null
                      ? null
                      : (status.totalBytes / (1024 * 1024)).round();
                  return Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: context.palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'صفحات المصحف دون اتصال',
                          style: context.text.labelBold.copyWith(
                            color: context.palette.text,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          artworkDownloading && artworkProgress != null
                              ? artworkProgress!.status
                              : status?.isComplete == true
                              ? 'الصفحات الـ604 محفوظة على الجهاز.'
                              : status == null
                              ? 'جارٍ فحص الصفحات المحفوظة…'
                              : '${status.downloadedPages} من ${status.totalPages} صفحة محفوظة. تنزيل الكل يستهلك نحو $totalMb م.ب إضافية.',
                          style: context.text.caption.copyWith(
                            color: context.palette.textMuted,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        if (artworkDownloading && artworkProgress != null) ...[
                          const SizedBox(height: AppSpace.sm),
                          LinearProgressIndicator(
                            value: artworkProgress!.progress.clamp(0, 1),
                            color: context.palette.gold,
                            backgroundColor: context.palette.surface,
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            '${(artworkProgress!.completedBytes / (1024 * 1024)).toStringAsFixed(1)} / ${(artworkProgress!.totalBytes / (1024 * 1024)).toStringAsFixed(1)} م.ب',
                            style: context.text.caption,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpace.sm),
                        if (artworkDownloading)
                          OutlinedButton.icon(
                            onPressed: () =>
                                QuranPageArtworkService.cancelDownload(
                                  widget.editionId,
                                ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('إيقاف التنزيل'),
                          )
                        else if (status?.isComplete == true)
                          OutlinedButton.icon(
                            onPressed: () async {
                              await QuranPageArtworkService.deleteArtwork(
                                widget.editionId,
                              );
                              if (!context.mounted) return;
                              setSheetState(() {
                                artworkProgress = null;
                                artworkStatusFuture =
                                    QuranPageArtworkService.storageStatus(
                                      widget.editionId,
                                    );
                              });
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('حذف الصفحات المحفوظة'),
                          )
                        else
                          FilledButton.tonalIcon(
                            onPressed: status == null
                                ? null
                                : () {
                                    setSheetState(() {
                                      artworkDownloading = true;
                                      artworkProgress = null;
                                    });
                                    artworkSubscription =
                                        QuranPageArtworkService.downloadAll(
                                          widget.editionId,
                                        ).listen(
                                          (progress) {
                                            if (!context.mounted) return;
                                            setSheetState(() {
                                              artworkProgress = progress;
                                              if (progress.isComplete ||
                                                  progress.isCanceled ||
                                                  progress.isError) {
                                                artworkDownloading = false;
                                                artworkStatusFuture =
                                                    QuranPageArtworkService.storageStatus(
                                                      widget.editionId,
                                                    );
                                              }
                                            });
                                          },
                                          onError: (Object error) {
                                            if (!context.mounted) return;
                                            setSheetState(() {
                                              artworkDownloading = false;
                                            });
                                          },
                                        );
                                  },
                            icon: const Icon(Icons.download_rounded),
                            label: Text(
                              status == null || status.downloadedPages == 0
                                  ? 'تنزيل كل الصفحات'
                                  : 'استكمال تنزيل الصفحات',
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (artworkDownloading) {
      QuranPageArtworkService.cancelDownload(widget.editionId);
    }
    await artworkSubscription?.cancel();
  }

  @override
  void dispose() {
    _savePageTimer?.cancel();
    if (_database != null) unawaited(_savePage());
    final database = _database;
    if (database != null) unawaited(database.close());
    if (_keepScreenAwake) unawaited(WakelockPlus.disable());
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = _database;
    final pageCount = database?.pageCount ?? 604;
    final surahTitle = getVocalizedSurahName(
      _surah,
      fallback: quran.getSurahNameArabic(_surah),
    );
    return Scaffold(
      backgroundColor: MushafColors.bgFor(_themeMode),
      body: SafeArea(
        child: database == null
            ? _buildLoadingOrError(context)
            : Stack(
                children: [
                  Positioned.fill(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: PageView.builder(
                        key: ValueKey(
                          'riwayah-reader-${widget.editionId.wireValue}',
                        ),
                        controller: _pageController,
                        reverse: true,
                        physics: const BouncingScrollPhysics(
                          parent: PageScrollPhysics(),
                        ),
                        itemCount: database.pageCount,
                        onPageChanged: (index) => _updatePosition(index + 1),
                        itemBuilder: (context, index) => _PackPage(
                          key: ValueKey(
                            '${widget.editionId.wireValue}:${index + 1}',
                          ),
                          editionId: widget.editionId,
                          pageNumber: index + 1,
                          zoom: _fontSize,
                          themeMode: _themeMode,
                          onTap: _toggleOverlays,
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: AppMotion.slow,
                    curve: AppMotion.easeOut,
                    top: _showOverlays ? 0 : -100,
                    left: 0,
                    right: 0,
                    child: MushafReaderTopBar(
                      currentSurah: _surah,
                      currentPage: _page,
                      currentAyah: _ayah,
                      currentSurahTitle: surahTitle,
                      currentJuzNumber: _juz,
                      themeMode: _themeMode,
                      onJumpToPage: _goToPage,
                      onOpenSettings: _openSettings,
                      onToggleTheme: _toggleTheme,
                    ),
                  ),
                  AnimatedPositioned(
                    duration: AppMotion.slow,
                    curve: AppMotion.easeOut,
                    bottom: _showOverlays ? 0 : -120,
                    left: 0,
                    right: 0,
                    child: MushafReaderBottomBar(
                      currentPage: _page,
                      pageCount: pageCount,
                      themeMode: _themeMode,
                      audioService: QuranAudioService(),
                      allowAudioControls: false,
                      showTajweedLegend: false,
                      onPageChanged: _goToPage,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingOrError(BuildContext context) {
    final palette = context.palette;
    final error = _error;
    return Center(
      child: error == null
          ? CircularProgressIndicator(color: palette.gold)
          : Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: AppIcon.xl,
                    color: palette.gold,
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    'تعذر فتح الرواية المثبتة',
                    style: context.text.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    error,
                    style: context.text.bodySmall.copyWith(
                      color: palette.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _PackPage extends StatefulWidget {
  final QuranRiwayahId editionId;
  final int pageNumber;
  final double zoom;
  final MushafThemeMode themeMode;
  final VoidCallback onTap;

  const _PackPage({
    super.key,
    required this.editionId,
    required this.pageNumber,
    required this.zoom,
    required this.themeMode,
    required this.onTap,
  });

  @override
  State<_PackPage> createState() => _PackPageState();
}

class _PackPageState extends State<_PackPage> {
  late Future<String> _artworkFuture;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  void _loadArtwork() {
    _artworkFuture = QuranPageArtworkService.loadPage(
      widget.editionId,
      widget.pageNumber,
    );
  }

  void _retryArtwork() {
    setState(() {
      _artworkFuture = QuranPageArtworkService.retryPage(
        widget.editionId,
        widget.pageNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _artworkFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ArtworkLoadError(
            themeMode: widget.themeMode,
            onRetry: _retryArtwork,
          );
        }
        if (!snapshot.hasData) {
          return ColoredBox(
            color: MushafColors.bgFor(widget.themeMode),
            child: Center(
              child: CircularProgressIndicator(color: context.palette.gold),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final artwork = SvgPicture.string(
              snapshot.data!,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              allowDrawingOutsideViewBox: false,
            );
            return ColoredBox(
              color: MushafColors.bgFor(widget.themeMode),
              child: InkWell(
                onTap: widget.onTap,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: ClipRect(
                  child: Center(
                    child: Transform.scale(
                      scale: widget.zoom / 24,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: widget.themeMode == MushafThemeMode.dark
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  MushafColors.darkText,
                                  BlendMode.srcIn,
                                ),
                                child: artwork,
                              )
                            : artwork,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ArtworkLoadError extends StatelessWidget {
  final MushafThemeMode themeMode;
  final VoidCallback onRetry;

  const _ArtworkLoadError({required this.themeMode, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MushafColors.bgFor(themeMode),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: context.palette.gold),
              const SizedBox(height: AppSpace.sm),
              Text(
                'تعذر تحميل صورة الصفحة الأصلية',
                style: context.text.titleSmall.copyWith(
                  color: MushafColors.textFor(themeMode),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'تحتاج هذه الصفحة إلى اتصال بالإنترنت أول مرة. بعد تنزيلها ستبقى متاحة دون اتصال.',
                style: context.text.caption.copyWith(
                  color: context.palette.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
