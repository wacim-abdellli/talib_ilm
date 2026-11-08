import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../core/utils/app_share.dart';
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
import 'hifdh_repeat_options_sheet.dart';

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
  final void Function(int surah, int ayah)? onNavigateToVerse;

  const AyahActionMenuSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.audioService,
    this.defaultTafsir,
    this.onBookmarkChanged,
    this.onNavigateToVerse,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required QuranAudioService audioService,
    TafsirScholar? defaultTafsir,
    VoidCallback? onBookmarkChanged,
    void Function(int surah, int ayah)? onNavigateToVerse,
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
        onNavigateToVerse: onNavigateToVerse,
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
    final isLastRead =
        hasSavedLastRead &&
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

  Future<void> _toggleLastRead() async {
    HapticFeedback.selectionClick();
    if (_isLastRead) {
      final removed = await BookmarkService.clearLastReadIfMatches(
        surah: widget.surahNumber,
        ayah: widget.ayahNumber,
      );
      if (!mounted) return;
      if (!removed) {
        await _checkBookmark();
        return;
      }
      widget.onBookmarkChanged?.call();
      Navigator.of(context).pop();
      AppSnackbar.info(context, 'تمت إزالة موضع القراءة');
      return;
    }

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
      'تم حفظ موضع القراءة: $surahName • ${widget.ayahNumber}',
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
    await AppShare.share(
      context,
      '﴿$verse﴾ [$surahName: ${widget.ayahNumber}]',
    );
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
      onNavigateToVerse: widget.onNavigateToVerse,
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
    final switchedToAyahReciter =
        widget.audioService.selectedReciter.isSurahBased;
    widget.audioService.playVerse(
      widget.surahNumber,
      widget.ayahNumber,
      singleVerse: true,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    AppSnackbar.info(
      context,
      switchedToAyahReciter
          ? 'تعذر بدء التلاوة من منتصف السورة بهذا القارئ؛ تم اختيار مشاري العفاسي لتلاوة الآية ${widget.ayahNumber} فقط من سورة $surahName'
          : 'تلاوة الآية ${widget.ayahNumber} فقط من سورة $surahName',
    );
  }

  void _openHifdhRepeatOptions() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    HifdhRepeatOptionsSheet.show(
      context,
      audioService: widget.audioService,
      surahNumber: widget.surahNumber,
      currentAyah: widget.ayahNumber,
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

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsetsDirectional.only(
        top: AppSpace.md,
        bottom: AppSpace.lg + bottomInset,
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
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
            ),
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
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
            ),
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
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
              ),
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
                          subtitle: 'شرح الكلمات والتحليل اللغوي',
                          color: palette.gold,
                          onTap: () => _openDetailsAtTab(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 2: Mutashabihat & Waqf Scholars
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.compare_arrows_rounded,
                          title: 'المتشابهات والضوابط',
                          subtitle: 'ربط الآيات المتشابهة وقواعد الحفظ',
                          color: palette.gold,
                          onTap: () => _openDetailsAtTab(2),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.pause_circle_outline_rounded,
                          title: 'أحكام الوقف',
                          subtitle: 'أئمة الوقف الخمسة وعلله',
                          color: palette.gold,
                          onTap: () => _openDetailsAtTab(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 3: Tadabbur & Recitation Options
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.edit_note_rounded,
                          title: 'تدبر وملاحظات',
                          subtitle: 'تدوين خواطر وتأملات إيمانية',
                          color: palette.primary,
                          onTap: () => _openDetailsAtTab(5),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.record_voice_over_rounded,
                          title: 'خيارات التلاوة',
                          subtitle: 'تغيير القارئ وسرعة الصوت',
                          color: palette.primary,
                          onTap: () => _openDetailsAtTab(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 4: Continuous Recitation & Single Ayah
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.playlist_play_rounded,
                          title: 'تلاوة مستمرة',
                          subtitle: 'تابع الآيات التالية',
                          color: palette.primary,
                          onTap: _playContinuous,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.play_circle_fill_rounded,
                          title: 'استماع للآية',
                          subtitle: 'هذه الآية فقط',
                          color: palette.primary,
                          onTap: _playVerse,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 5: Repeat & Audio Options
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.repeat_one_rounded,
                          title: 'تكرار الآية',
                          subtitle: 'تكرار الآية أو مقطع كامل للحفظ',
                          color: palette.gold,
                          onTap: _openHifdhRepeatOptions,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: _isBookmarked
                              ? Icons.bookmark_added_rounded
                              : Icons.bookmark_add_outlined,
                          title: _isBookmarked
                              ? 'محفوظة في الفواصل'
                              : 'حفظ في الفواصل',
                          subtitle: _isBookmarked
                              ? 'انقر لإلغاء الحفظ'
                              : 'إضافة إلى المحفوظات',
                          color: _isBookmarked ? palette.gold : palette.text,
                          onTap: _toggleBookmark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 6: Bookmark & Last Read
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: _isLastRead
                              ? Icons.bookmark_remove_rounded
                              : Icons.bookmark_border_rounded,
                          title: _isLastRead
                              ? 'موضع القراءة الحالي'
                              : 'تعيين كموضع قراءة',
                          subtitle: _isLastRead
                              ? 'إزالة الموضع'
                              : 'حفظ كآخر موضع توقفت عنده',
                          color: _isLastRead ? palette.success : palette.text,
                          onTap: _toggleLastRead,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.copy_rounded,
                          title: 'نسخ الآية',
                          subtitle: 'نسخ النص والمرجع',
                          color: palette.text,
                          onTap: _copyVerse,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Row 7: Share Verse
                  _ActionTile(
                    icon: Icons.share_rounded,
                    title: 'مشاركة الآية الكريمة',
                    subtitle: 'النص مع المرجع',
                    color: palette.primary,
                    onTap: _shareVerse,
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 160 || textScale > 1.25;
        final iconBadge = Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: AppIcon.sm, color: color),
        );
        final textContent = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: stacked
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              textAlign: stacked ? TextAlign.center : TextAlign.start,
              style: textTheme.bodySmall.copyWith(
                color: palette.text,
                fontWeight: FontWeight.bold,
              ),
              maxLines: stacked ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              textAlign: stacked ? TextAlign.center : TextAlign.start,
              style: textTheme.caption.copyWith(color: palette.textMuted),
              maxLines: stacked ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        return Semantics(
          button: true,
          label: '$title: $subtitle',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.mdRadius,
              child: Container(
                constraints: BoxConstraints(minHeight: stacked ? 84 : 64),
                padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.7),
                  ),
                ),
                child: stacked
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          iconBadge,
                          const SizedBox(height: AppSpace.xs),
                          textContent,
                        ],
                      )
                    : Row(
                        children: [
                          iconBadge,
                          const SizedBox(width: AppSpace.xs),
                          Expanded(child: textContent),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
