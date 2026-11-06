import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/utils/arabic_digits.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../data/database/quran_pack_database.dart';
import '../data/models/quran_models.dart';
import '../data/models/quran_pack_page_layout.dart';
import '../data/services/quran_audio_service.dart';
import '../data/services/quran_pack_font_service.dart';
import '../data/services/quran_pack_install_service.dart';
import '../data/services/quran_reader_preferences.dart';
import 'widgets/mushaf_reader_overlays.dart';

/// Mushaf-style page reader for installed Warsh and Qalun editions.
///
/// It shares the Hafs reader's page navigation, overlay controls, paper/dark
/// themes, and 15-line page composition. Its text, font, line references, and
/// surah counts come from the selected edition's installed pack.
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
  Map<int, QuranPackSurah> _surahs = const {};
  String? _fontFamily;
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

      final results = await Future.wait<Object>([
        QuranPackFontService.load(widget.editionId),
        QuranReaderPreferences.load(forceRefresh: true),
      ]);
      final fontFamily = results[0] as String;
      final preferences = results[1] as QuranReaderSnapshot;
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

      final surahs = {
        for (final surah in await database.getSurahList()) surah.number: surah,
      };
      if (!mounted) {
        await database.close();
        openedDatabase = null;
        return;
      }
      setState(() {
        _database = database;
        _surahs = surahs;
        _fontFamily = fontFamily;
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
                  Text('حجم الخط', style: context.text.labelBold),
                  const Spacer(),
                  Text('${sheetFontSize.round()}'),
                ],
              ),
              Slider(
                value: sheetFontSize.clamp(18, 36),
                min: 18,
                max: 36,
                divisions: 9,
                label: '${sheetFontSize.round()}',
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
                'يُستخدم خط الرواية المثبتة، مع حفظ حجم الخط والصفحة لكل جهاز.',
                style: context.text.caption.copyWith(
                  color: context.palette.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
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
    final fontFamily = _fontFamily;
    final pageCount = database?.pageCount ?? 604;
    final surahTitle = getVocalizedSurahName(
      _surah,
      fallback: _surahs[_surah]?.nameArabic ?? widget.editionId.nameArabic,
    );
    return Scaffold(
      backgroundColor: MushafColors.bgFor(_themeMode),
      body: SafeArea(
        child: database == null || fontFamily == null
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
                          database: database,
                          surahs: _surahs,
                          pageNumber: index + 1,
                          fontFamily: fontFamily,
                          fontSize: _fontSize,
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

class _PackPage extends StatelessWidget {
  final QuranPackDatabase database;
  final Map<int, QuranPackSurah> surahs;
  final int pageNumber;
  final String fontFamily;
  final double fontSize;
  final MushafThemeMode themeMode;
  final VoidCallback onTap;

  const _PackPage({
    super.key,
    required this.database,
    required this.surahs,
    required this.pageNumber,
    required this.fontFamily,
    required this.fontSize,
    required this.themeMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuranPackAyah>>(
      future: database.getPageAyahs(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('تعذر تحميل الصفحة'));
        }
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: context.palette.gold),
          );
        }
        if (snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'لا توجد آيات في هذه الصفحة',
              style: context.text.bodySmall.copyWith(
                color: context.palette.textMuted,
              ),
            ),
          );
        }
        final lines = QuranPackPageLayout.build(
          pageNumber: pageNumber,
          ayahs: snapshot.data!,
        );
        final firstAyah = snapshot.data!.first;
        final surahTitle = getVocalizedSurahName(
          firstAyah.surahNumber,
          fallback: surahs[firstAyah.surahNumber]?.nameArabic ?? '',
        );
        return InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            color: MushafColors.bgFor(themeMode),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 38,
                  child: _PackPageHeader(
                    surahTitle: surahTitle,
                    juzNumber: firstAyah.juzNumber,
                    themeMode: themeMode,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      for (final line in lines)
                        Expanded(
                          child: _PackPageLine(
                            line: line,
                            surahs: surahs,
                            fontFamily: fontFamily,
                            fontSize: fontSize,
                            themeMode: themeMode,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: _PackPageFooter(
                    pageNumber: pageNumber,
                    themeMode: themeMode,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackPageHeader extends StatelessWidget {
  final String surahTitle;
  final int juzNumber;
  final MushafThemeMode themeMode;

  const _PackPageHeader({
    required this.surahTitle,
    required this.juzNumber,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = MushafColors.textFor(themeMode);
    final borderColor = MushafColors.bannerBorderFor(themeMode);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor.withValues(alpha: 0.35)),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PositionedDirectional(
            start: 0,
            child: Text(
              surahTitle,
              style: context.text.mushafChrome.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '۞',
            style: context.text.caption.copyWith(
              color: context.palette.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          PositionedDirectional(
            end: 0,
            child: Text(
              getArabicJuzName(juzNumber),
              style: context.text.mushafChrome.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackPageFooter extends StatelessWidget {
  final int pageNumber;
  final MushafThemeMode themeMode;

  const _PackPageFooter({required this.pageNumber, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final borderColor = MushafColors.bannerBorderFor(themeMode);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor.withValues(alpha: 0.35)),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'ـ $pageNumber ـ',
        style: context.text.mushafChrome.copyWith(
          color: MushafColors.verseNumberFor(themeMode),
        ),
      ),
    );
  }
}

class _PackPageLine extends StatelessWidget {
  final QuranPackPageLine line;
  final Map<int, QuranPackSurah> surahs;
  final String fontFamily;
  final double fontSize;
  final MushafThemeMode themeMode;

  const _PackPageLine({
    required this.line,
    required this.surahs,
    required this.fontFamily,
    required this.fontSize,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = MushafColors.textFor(themeMode);
    if (line.surahHeaderNumber case final surahNumber?) {
      final surah = surahs[surahNumber];
      if (surah != null) {
        return LayoutBuilder(
          builder: (context, constraints) => Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: constraints.maxWidth,
                height: 36,
                child: _PackSurahBanner(surah: surah, themeMode: themeMode),
              ),
            ),
          ),
        );
      }
    }
    if (line.showBasmala) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textDirection: TextDirection.rtl,
            style: context.text.sacred.copyWith(
              fontFamily: fontFamily,
              fontSize: fontSize * 1.08,
              height: 1.3,
              color: textColor,
            ),
          ),
        ),
      );
    }
    if (line.runs.isEmpty) return const SizedBox.expand();
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              for (var index = 0; index < line.runs.length; index++) ...[
                if (index > 0) const TextSpan(text: ' '),
                if (line.runs[index].text.isNotEmpty)
                  TextSpan(text: line.runs[index].text),
                if (line.runs[index].endsAyah)
                  TextSpan(
                    text: ' ۝${line.runs[index].ayahNumber} ',
                    style: context.text.titleSmall.copyWith(
                      fontFamily: fontFamily,
                      color: MushafColors.verseNumberFor(themeMode),
                    ),
                  ),
              ],
            ],
          ),
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: context.text.sacred.copyWith(
            fontFamily: fontFamily,
            fontSize: fontSize * 1.2,
            height: 1.35,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _PackSurahBanner extends StatelessWidget {
  final QuranPackSurah surah;
  final MushafThemeMode themeMode;

  const _PackSurahBanner({required this.surah, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final textColor = MushafColors.bannerTextFor(themeMode);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/surah_banner.png',
            package: 'qcf_quran_plus',
            fit: BoxFit.fill,
            width: double.infinity,
            height: 36,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${surah.ayahCount} آية',
                    textAlign: TextAlign.start,
                    style: context.text.captionHeavy.copyWith(color: textColor),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    getVocalizedSurahName(
                      surah.number,
                      fallback: surah.nameArabic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.text.surahHeaderTitle.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    quran.getPlaceOfRevelation(surah.number) == 'Makkah'
                        ? 'مَكِّيَّة'
                        : 'مَدَنِيَّة',
                    textAlign: TextAlign.end,
                    style: context.text.captionHeavy.copyWith(color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
