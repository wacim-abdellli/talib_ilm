import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import 'package:talib_ilm/shared/widgets/app_button.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/services/bookmark_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_tafsir_service.dart';
import 'ayah_details_sheet.dart';

/// Interactive Quick Action Menu displayed on Ayah Hold / Long-Press.
///
/// Gives instant access to:
/// - Tafsir (Scholarly Commentary)
/// - Word Meanings (Mufradat & Gharib al-Quran)
/// - Ayah Audio Playback
/// - Infinite Ayah Repeat (for memorization)
/// - Bookmark toggling
/// - Setting as Last Read Position
/// - Reflection / Personal Notes
/// - Copy & Share
class AyahActionMenuSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final QuranAudioService audioService;
  final TafsirScholar? defaultTafsir;
  final VoidCallback? onBookmarkChanged;

  const AyahActionMenuSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.audioService,
    this.defaultTafsir,
    this.onBookmarkChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required QuranAudioService audioService,
    TafsirScholar? defaultTafsir,
    VoidCallback? onBookmarkChanged,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.88,
      enableDrag: true,
      builder: (_) => AyahActionMenuSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        audioService: audioService,
        defaultTafsir: defaultTafsir,
        onBookmarkChanged: onBookmarkChanged,
      ),
    );
  }

  @override
  State<AyahActionMenuSheet> createState() => _AyahActionMenuSheetState();
}

class _AyahActionMenuSheetState extends State<AyahActionMenuSheet> {
  bool _isBookmarked = false;
  bool _isLastRead = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final bookmarks = await BookmarkService.getBookmarks();
    final hasSavedLastRead = await BookmarkService.hasSavedLastRead();
    final lastRead = await BookmarkService.getLastRead();
    if (!mounted) return;
    final exists = bookmarks.any(
      (b) => b.surah == widget.surahNumber && b.ayah == widget.ayahNumber,
    );
    final isLastRead = hasSavedLastRead &&
        lastRead.surah == widget.surahNumber &&
        lastRead.ayah == widget.ayahNumber;
    setState(() {
      _isBookmarked = exists;
      _isLastRead = isLastRead;
    });
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.selectionClick();
    final isNowBookmarked = await BookmarkService.toggleBookmark(
      widget.surahNumber,
      widget.ayahNumber,
    );
    if (!mounted) return;
    setState(() => _isBookmarked = isNowBookmarked);
    widget.onBookmarkChanged?.call();
    if (isNowBookmarked) {
      AppSnackbar.success(context, 'تمت إضافة الآية إلى المحفوظات');
    } else {
      AppSnackbar.info(context, 'تمت إزالة الآية من المحفوظات');
    }
  }

  Future<void> _saveAsLastRead() async {
    HapticFeedback.selectionClick();
    final page = quran.getPageNumber(widget.surahNumber, widget.ayahNumber);
    await BookmarkService.saveLastRead(
      surah: widget.surahNumber,
      ayah: widget.ayahNumber,
      page: page,
    );
    if (!mounted) return;
    setState(() => _isLastRead = true);
    widget.onBookmarkChanged?.call();
    Navigator.of(context).pop();
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    AppSnackbar.success(
      context,
      'تم تثبيت موضع القراءة: سورة $surahName الآية ${widget.ayahNumber}',
    );
  }

  Future<void> _copyVerse() async {
    HapticFeedback.selectionClick();
    final verse = quran.getVerse(
      widget.surahNumber,
      widget.ayahNumber,
      verseEndSymbol: true,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    await Clipboard.setData(
      ClipboardData(text: '﴿$verse﴾ [$surahName: ${widget.ayahNumber}]'),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'تم نسخ نص الآية الكريمة');
  }

  Future<void> _shareVerse() async {
    HapticFeedback.selectionClick();
    final verse = quran.getVerse(
      widget.surahNumber,
      widget.ayahNumber,
      verseEndSymbol: true,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    Navigator.of(context).pop();
    await Share.share('﴿$verse﴾ [$surahName: ${widget.ayahNumber}]');
  }

  void _openDetailsAtTab(int tabIndex) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    AyahDetailsSheet.show(
      context,
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayahNumber,
      initialTafsirScholar: widget.defaultTafsir,
      onBookmarkChanged: widget.onBookmarkChanged,
      initialTabIndex: tabIndex,
    );
  }

  void _playContinuous() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.audioService.setRepeatMode(AudioRepeatMode.none);
    widget.audioService.playContinuous(
      surah: widget.surahNumber,
      startAyah: widget.ayahNumber,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    AppSnackbar.info(
      context,
      'بدء التلاوة المستمرة من الآية ${widget.ayahNumber} من سورة $surahName',
    );
  }

  void _playVerse() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.audioService.setRepeatMode(AudioRepeatMode.none);
    widget.audioService.playVerse(
      widget.surahNumber,
      widget.ayahNumber,
      singleVerse: true,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    AppSnackbar.info(
      context,
      'تلاوة الآية ${widget.ayahNumber} من سورة $surahName',
    );
  }

  void _repeatVerseInfinite() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.audioService.setRepeatMode(AudioRepeatMode.infinite);
    widget.audioService.playVerse(widget.surahNumber, widget.ayahNumber);
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    AppSnackbar.info(
      context,
      'تكرار مستمر للآية ${widget.ayahNumber} من سورة $surahName',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final juzNum = quran.getJuzNumber(widget.surahNumber, widget.ayahNumber);
    final pageNum = quran.getPageNumber(widget.surahNumber, widget.ayahNumber);
    final verseText = quran.getVerse(
      widget.surahNumber,
      widget.ayahNumber,
      verseEndSymbol: true,
    );

    return Container(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpace.md,
        bottom: AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // 2. Header: Surah & Ayah Reference
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
            child: Row(
              children: [
                const IconBadge(icon: Icons.menu_book_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سورة $surahName • الآية ${widget.ayahNumber}',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الجزء $juzNum • الصفحة $pageNum',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  color: palette.textMuted,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.xs),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.sm),

          // 3. Compact Verse Card Preview
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 96),
              child: AppCard(
                padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      '﴿$verseText﴾',
                      textAlign: TextAlign.center,
                      style: textTheme.sacred.copyWith(
                        color: palette.text,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // 4. Primary Actions Grid
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
              child: Column(
                children: [
                  // Row 1: Tafsir & Meanings
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.auto_stories_rounded,
                          title: 'تفسير الآية',
                          subtitle: 'تفاسير أهل السنة المعتمدة',
                          color: palette.primary,
                          onTap: () => _openDetailsAtTab(0),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.spellcheck_rounded,
                          title: 'معاني الكلمات',
                          subtitle: 'مفردات الآية وغريب القرآن',
                          color: palette.gold,
                          onTap: () => _openDetailsAtTab(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 2: Continuous Recitation & Single Ayah
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.playlist_play_rounded,
                          title: 'تلاوة مستمرة',
                          subtitle: 'متابعة القراءة للآيات التالية تلقائياً',
                          color: palette.primary,
                          onTap: _playContinuous,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.play_circle_fill_rounded,
                          title: 'استماع للآية',
                          subtitle: 'تلاوة هذه الآية فقط',
                          color: palette.primary,
                          onTap: _playVerse,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 3: Repeat & Audio Options
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.repeat_one_rounded,
                          title: 'تكرار الآية',
                          subtitle: 'تكرار مستمر للحفظ والمراجعة',
                          color: palette.gold,
                          onTap: _repeatVerseInfinite,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.record_voice_over_rounded,
                          title: 'خيارات التلاوة',
                          subtitle: 'تغيير القارئ وسرعة الصوت',
                          color: palette.primary,
                          onTap: () => _openDetailsAtTab(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 3: Bookmark & Last Read
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: _isBookmarked
                              ? Icons.bookmark_added_rounded
                              : Icons.bookmark_add_outlined,
                          title: _isBookmarked ? 'محفوظة في الفواصل' : 'حفظ في الفواصل',
                          subtitle: _isBookmarked ? 'انقر لإلغاء الحفظ' : 'إضافة إلى المحفوظات',
                          color: _isBookmarked ? palette.gold : palette.text,
                          onTap: _toggleBookmark,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: _isLastRead
                              ? Icons.bookmark_added_rounded
                              : Icons.bookmark_border_rounded,
                          title: _isLastRead ? 'موضع القراءة الحالي' : 'تعيين كموضع قراءة',
                          subtitle: _isLastRead
                              ? 'مثبت كآخر موضع توقفت عنده'
                              : 'حفظ كآخر موضع توقفت عنده',
                          color: _isLastRead ? palette.success : palette.text,
                          onTap: _saveAsLastRead,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 4: Reflection & Copy/Share
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.edit_note_rounded,
                          title: 'تدبر وملاحظات',
                          subtitle: 'تدوين خواطر وتأملات إيمانية',
                          color: palette.primary,
                          onTap: () => _openDetailsAtTab(3),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.copy_rounded,
                          title: 'نسخ الآية',
                          subtitle: 'نسخ النص القرآني مع السورة',
                          color: palette.text,
                          onTap: _copyVerse,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Full Width Share Button
                  InkWell(
                    onTap: _shareVerse,
                    borderRadius: AppRadius.mdRadius,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share_rounded,
                            size: AppIcon.sm,
                            color: palette.primary,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'مشاركة الآية الكريمة',
                            style: textTheme.bodySmall.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Semantics(
      button: true,
      label: '$title: $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsetsDirectional.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: AppIcon.sm,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: textTheme.bodySmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
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
          ),
        ),
      ),
    );
  }
}
