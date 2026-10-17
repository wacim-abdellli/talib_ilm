import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/catalogs/mutun_categories_catalog.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/services/mutun_audio_service.dart';
import 'book_view_page.dart';

/// Matn Overview & Study Hub Page mirroring media_1792193067648.jpg.
class MatnOverviewPage extends StatelessWidget {
  final MutunItem item;

  const MatnOverviewPage({
    super.key,
    required this.item,
  });

  void _openFullReader(BuildContext context) {
    HapticFeedback.lightImpact();
    final digitalEntry = MutunDigitalCatalog.getEntry(item.id);
    final ilmBook = IlmBook(
      id: item.id,
      title: item.title,
      author: item.author,
      level: item.categoryId,
      subject: item.categoryId,
      description: item.description,
      totalPages: digitalEntry?.totalPages ?? 25,
      pdfPath: item.pdfPath,
      shuruh: const [],
    );

    Navigator.of(context).push(
      buildFadeRoute(
        page: BookViewPage(
          book: ilmBook,
          initialTabIndex: 0,
        ),
      ),
    );
  }

  void _openPdfViewer(BuildContext context) {
    if (item.pdfPath == null) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      buildFadeRoute(
        page: PdfViewerPage(
          assetPath: item.pdfPath!,
          title: item.title,
          initialPage: 1,
        ),
      ),
    );
  }

  void _startAudioStream(BuildContext context) {
    HapticFeedback.mediumImpact();
    final audioService = MutunAudioService();
    audioService.playMatnAudio(
      bookId: item.id,
      audioUrl: item.audioUrlSini,
      paragraphIndex: 1,
      totalParagraphs: item.totalLinesOrVerses,
    );
    _openFullReader(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: tokens.headerBrown,
        foregroundColor: tokens.headerTitle,
        elevation: 0,
        centerTitle: false,
        title: Text(
          item.title,
          style: textTheme.titleSmall.copyWith(
            color: tokens.headerTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: 'استماع للتسجيل الصوتي',
            onPressed: () => _startAudioStream(context),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpace.sm),

                    // ── Scholarly Intro Card ────────────────────────
                    Container(
                      padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                      decoration: BoxDecoration(
                        color: tokens.cardBg,
                        borderRadius: AppRadius.lgRadius,
                        border: Border.all(color: tokens.cardBorder, width: 1.0),
                        boxShadow: palette.shadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: textTheme.body.copyWith(
                              color: palette.text,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          InkWell(
                            onTap: () => _openFullReader(context),
                            borderRadius: AppRadius.smRadius,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                vertical: AppSpace.xs,
                              ),
                              child: Text(
                                '« تصفح المتن كاملاً »',
                                style: textTheme.body.copyWith(
                                  color: tokens.rosetteGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpace.xl),

                    // ── Lines / Verses Count Row ────────────────────
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.isPoem ? 'عدد الأبيات:' : 'عدد الأسطر:',
                            style: textTheme.body.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                          Text(
                            '${item.totalLinesOrVerses}',
                            style: textTheme.body.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: AppSpace.xl),

                    // ── Verified PDF Scanned Copy Row ───────────────
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'النسخة المصورة (PDF)',
                            style: textTheme.body.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppButton(
                            label: 'عرض',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.sm,
                            onPressed: () => _openPdfViewer(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpace.xxl),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Actions Bar (حفظ جديد / مراجعة) ─────────
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                border: Border(
                  top: BorderSide(color: palette.border, width: 1.0),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Review button (مراجعة)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.headerBrown,
                          foregroundColor: tokens.headerTitle,
                          elevation: 0,
                          minimumSize: const Size(0, AppSize.tap),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                        onPressed: () => _openFullReader(context),
                        child: Text(
                          'مراجعة',
                          style: textTheme.body.copyWith(
                            color: tokens.headerTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpace.md),

                    // New memorization button (حفظ جديد)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.rosetteGold,
                          foregroundColor: tokens.headerTitle,
                          elevation: 0,
                          minimumSize: const Size(0, AppSize.tap),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                        onPressed: () => _openFullReader(context),
                        child: Text(
                          'حفظ جديد',
                          style: textTheme.body.copyWith(
                            color: tokens.headerTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
