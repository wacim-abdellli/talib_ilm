import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/database/quran_pack_database.dart';
import '../data/models/quran_models.dart';
import '../data/services/quran_pack_font_service.dart';
import '../data/services/quran_pack_install_service.dart';

/// Text-mode reader for editions whose source layout is not the bundled Hafs
/// QCF page layout. It reads only from the selected edition's installed pack.
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
  String? _fontFamily;
  String? _error;
  int _page = 1;
  int _surah = 1;
  int _ayah = 1;
  int _positionGeneration = 0;
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
    try {
      final database = await QuranPackInstallService.openInstalled(
        widget.editionId,
      );
      if (database == null) throw StateError('حزمة الرواية غير مثبتة');
      final fontFamily = await QuranPackFontService.load(widget.editionId);
      var targetPage = _page.clamp(1, database.pageCount);
      if (widget.initialPage == null && widget.initialSurah == null) {
        final preferences = await SharedPreferences.getInstance();
        targetPage = (preferences.getInt(_lastPageKey) ?? targetPage).clamp(
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
        return;
      }
      setState(() {
        _database = database;
        _fontFamily = fontFamily;
        _page = targetPage;
      });
      if (targetPage != 1) _pageController.jumpToPage(targetPage - 1);
      await _updatePosition(targetPage);
    } catch (error) {
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

  @override
  void dispose() {
    _savePageTimer?.cancel();
    if (_database != null) unawaited(_savePage());
    final database = _database;
    if (database != null) unawaited(database.close());
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final database = _database;
    final fontFamily = _fontFamily;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: PrimaryAppBar(
        title: widget.editionId.nameArabic,
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpace.md),
            child: Center(
              child: Text(
                '$_page / ${database?.pageCount ?? 604}',
                style: context.text.label.copyWith(color: palette.gold),
              ),
            ),
          ),
        ],
      ),
      body: database == null || fontFamily == null
          ? _buildLoadingOrError(context)
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    key: ValueKey(
                      'riwayah-reader-${widget.editionId.wireValue}',
                    ),
                    controller: _pageController,
                    reverse: true,
                    itemCount: database.pageCount,
                    onPageChanged: (index) => _updatePosition(index + 1),
                    itemBuilder: (context, index) => _PackPage(
                      key: ValueKey(
                        '${widget.editionId.wireValue}:${index + 1}',
                      ),
                      database: database,
                      pageNumber: index + 1,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpace.md,
                      AppSpace.xs,
                      AppSpace.md,
                      AppSpace.sm,
                    ),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'الصفحة السابقة',
                          onPressed: _page > 1
                              ? () => _goToPage(_page - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'سورة $_surah • آية $_ayah',
                              style: context.text.bodySmall.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'الصفحة التالية',
                          onPressed: _page < database.pageCount
                              ? () => _goToPage(_page + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                  Icon(Icons.menu_book_rounded, size: AppIcon.xl, color: palette.gold),
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
  final int pageNumber;
  final String fontFamily;

  const _PackPage({
    super.key,
    required this.database,
    required this.pageNumber,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FutureBuilder<List<QuranPackAyah>>(
      future: database.getPageAyahs(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('تعذر تحميل الصفحة'));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: palette.gold));
        }
        final spanningAyahs = snapshot.data!;
        if (spanningAyahs.isEmpty) {
          return Center(
            child: Text(
              'لا توجد آيات في هذه الصفحة',
              textAlign: TextAlign.center,
            ),
          );
        }
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.xl,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: palette.border),
                boxShadow: palette.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (spanningAyahs.any((ayah) => ayah.firstPage < pageNumber))
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpace.sm,
                      ),
                      child: Text(
                        'تبدأ هذه الصفحة بامتداد آية من الصفحة السابقة؛ عُرضت الآية كاملة عند بدايتها.',
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (
                    var index = 0;
                    index < spanningAyahs.length;
                    index++
                  ) ...[
                    if (spanningAyahs[index].firstPage < pageNumber)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: AppSpace.xs,
                        ),
                        child: Text(
                          'تكملة آية بدأت في الصفحة السابقة',
                          textAlign: TextAlign.center,
                          style: context.text.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    if (spanningAyahs[index].ayahNumber == 1)
                      _SurahHeading(
                        database: database,
                        surahNumber: spanningAyahs[index].surahNumber,
                      ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: spanningAyahs[index].displayText),
                          const TextSpan(text: '  '),
                          TextSpan(
                            text: ' ۝${spanningAyahs[index].ayahNumber} ',
                            style: context.text.titleSmall.copyWith(
                              fontFamily: fontFamily,
                              color: palette.gold,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.justify,
                      style: context.text.sacred.copyWith(
                        fontFamily: fontFamily,
                        color: palette.text,
                        height: 2.05,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SurahHeading extends StatelessWidget {
  final QuranPackDatabase database;
  final int surahNumber;

  const _SurahHeading({required this.database, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FutureBuilder<QuranPackSurah?>(
      future: database.getSurah(surahNumber),
      builder: (context, snapshot) {
        final surah = snapshot.data;
        if (surah == null) return const SizedBox(height: AppSpace.md);
        return Padding(
          padding: const EdgeInsetsDirectional.only(
            top: AppSpace.md,
            bottom: AppSpace.sm,
          ),
          child: Column(
            children: [
              Text(
                surah.nameArabic,
                textAlign: TextAlign.center,
                style: context.text.title.copyWith(
                  color: palette.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: AppSpace.lg),
            ],
          ),
        );
      },
    );
  }
}
