import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/services/mutun_audio_service.dart';

/// Shared Calm Scholar bottom sheet for choosing a verified reciter / audio edition
/// for any Mutn or Shamela heritage book.
class BookReciterPickerSheet extends StatelessWidget {
  final MutunAudioService audioService;
  final String? bookId;

  const BookReciterPickerSheet({
    super.key,
    required this.audioService,
    this.bookId,
  });

  static Future<void> show(
    BuildContext context, {
    required MutunAudioService audioService,
    String? bookId,
  }) {
    HapticFeedback.lightImpact();
    return AppSheet.show<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: BookReciterPickerSheet(
          audioService: audioService,
          bookId: bookId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final reciters = audioService.getAvailableRecitersForBook(bookId);
    final activeReciter = audioService.effectiveReciterForBook(bookId);
    final entry = bookId != null ? MutunAudioCatalog.getEntry(bookId!) : null;
    final hasDual = entry != null && entry.hasReading && entry.hasSharh;

    int filterMode = 0; // 0 = الكل, 1 = قراءة, 2 = شروح

    return StatefulBuilder(
      builder: (context, setSheetState) {
        final List<MutunReciter> displayedReciters;
        if (!hasDual || filterMode == 0) {
          displayedReciters = reciters;
        } else if (filterMode == 1) {
          displayedReciters =
              entry.readingSources.map((s) => s.reciter).toList();
        } else {
          displayedReciters =
              entry.sharhSources.map((s) => s.reciter).toList();
        }

        return AppSheet(
          titleText: 'اختيار القارئ والإصدار الصوتي',
          icon: Icons.record_voice_over_rounded,
          showCloseButton: true,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.lg,
            AppSpace.xs,
            AppSpace.lg,
            AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasDual) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                  child: Row(
                    children: [
                      _buildModeChip(
                        context: context,
                        label: 'الكل (${entry.sources.length})',
                        isSelected: filterMode == 0,
                        onTap: () => setSheetState(() => filterMode = 0),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _buildModeChip(
                        context: context,
                        label: 'قراءة (${entry.readingSources.length})',
                        isSelected: filterMode == 1,
                        onTap: () => setSheetState(() => filterMode = 1),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _buildModeChip(
                        context: context,
                        label: 'شرح (${entry.sharhSources.length})',
                        isSelected: filterMode == 2,
                        onTap: () => setSheetState(() => filterMode = 2),
                      ),
                    ],
                  ),
                ),
              ],
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedReciters.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.xs),
                itemBuilder: (sheetContext, index) {
            final reciter = displayedReciters[index];
            final isSelected = activeReciter.id == reciter.id;
            final source = audioService.getSourceForBook(
              bookId,
              reciterId: reciter.id,
            );
            final showEditionPill = source != null &&
                source.edition != BookAudioEdition.fullText;
            final showChaptersPill = source != null && source.isMultiChapter;

            return Semantics(
              button: true,
              selected: isSelected,
              label: reciter.name,
              child: Material(
                color: isSelected ? palette.primarySoft : Colors.transparent,
                borderRadius: AppRadius.mdRadius,
                child: InkWell(
                  borderRadius: AppRadius.mdRadius,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    audioService.setSelectedReciter(
                      reciter,
                      forBookId: bookId,
                    );
                    Navigator.of(sheetContext).pop();
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSize.tap),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: AppSpace.xxs,
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSelected
                                  ? palette.onPrimarySoft
                                  : palette.textMuted,
                              size: AppIcon.md,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reciter.name,
                                  style: (isSelected
                                          ? textTheme.bodyBold
                                          : textTheme.body)
                                      .copyWith(
                                    color: isSelected
                                        ? palette.onPrimarySoft
                                        : palette.text,
                                  ),
                                ),
                                const SizedBox(height: AppSpace.xxs),
                                Text(
                                  reciter.description,
                                  style: textTheme.caption.copyWith(
                                    color: isSelected
                                        ? palette.onPrimarySoft
                                        : palette.textMuted,
                                  ),
                                ),
                                if (showEditionPill || showChaptersPill) ...[
                                  const SizedBox(height: AppSpace.sm),
                                  Wrap(
                                    spacing: AppSpace.xs,
                                    runSpacing: AppSpace.xs,
                                    children: [
                                      if (showEditionPill)
                                        _AudioMetaBadge(
                                          icon: Icons.auto_stories_rounded,
                                          label: source.edition.label,
                                          bg: isSelected
                                              ? palette.surface
                                              : palette.goldSoft,
                                          fg: palette.onPrimarySoft,
                                        ),
                                      if (showChaptersPill)
                                        _AudioMetaBadge(
                                          icon: Icons.queue_music_rounded,
                                          label:
                                              '${source.chapterCount} مقطعاً',
                                          bg: isSelected
                                              ? palette.surface
                                              : palette.surfaceMuted,
                                          fg: isSelected
                                              ? palette.onPrimarySoft
                                              : palette.textMuted,
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildModeChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    final textTheme = context.text;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? palette.primarySoft : palette.surfaceMuted,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: isSelected ? palette.primary : palette.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: textTheme.captionBold.copyWith(
                color: isSelected ? palette.primary : palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared Calm Scholar bottom sheet for browsing and jumping directly to any
/// audio chapter/bab/majlis in multi-chapter Mutun and Shamela heritage books.
class BookAudioChaptersSheet extends StatefulWidget {
  final MutunAudioService audioService;
  final String bookId;

  const BookAudioChaptersSheet({
    super.key,
    required this.audioService,
    required this.bookId,
  });

  static Future<void> show(
    BuildContext context, {
    required MutunAudioService audioService,
    required String bookId,
  }) {
    HapticFeedback.lightImpact();
    return AppSheet.show<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: BookAudioChaptersSheet(
          audioService: audioService,
          bookId: bookId,
        ),
      ),
    );
  }

  @override
  State<BookAudioChaptersSheet> createState() => _BookAudioChaptersSheetState();
}

class _BookAudioChaptersSheetState extends State<BookAudioChaptersSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final reciter = widget.audioService.effectiveReciterForBook(widget.bookId);
    final chapters = widget.audioService.getChaptersForBook(
      widget.bookId,
      reciterId: reciter.id,
    );
    final trimmed = _query.trim();
    final filtered = trimmed.isEmpty
        ? List<int>.generate(chapters.length, (i) => i)
        : <int>[
            for (var i = 0; i < chapters.length; i++)
              if (chapters[i].title.contains(trimmed) ||
                  '${chapters[i].index}'.contains(trimmed))
                i,
          ];

    return AppSheet(
      titleText: 'فهرس المقاطع الصوتية (${chapters.length})',
      icon: Icons.queue_music_rounded,
      showCloseButton: true,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reciter.name,
              style: textTheme.captionBold.copyWith(color: palette.textMuted),
            ),
            if (chapters.length > 10) ...[
              const SizedBox(height: AppSpace.sm),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'ابحث في الأبواب والمقاطع الصوتية...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: AppIcon.md,
                    color: palette.textMuted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpace.sm),
            Flexible(
              child: ValueListenableBuilder<int>(
                valueListenable: widget.audioService.activeChapterIndexNotifier,
                builder: (context, activeIdx, _) {
                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                      child: Text(
                        'لا توجد مقاطع مطابقة للبحث',
                        textAlign: TextAlign.center,
                        style: textTheme.body.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: palette.border,
                    ),
                    itemBuilder: (sheetContext, listPos) {
                      final chapterIdx = filtered[listPos];
                      final chapter = chapters[chapterIdx];
                      final isCurrent = chapterIdx == activeIdx;

                      return Semantics(
                        button: true,
                        selected: isCurrent,
                        label: '${chapter.index} ${chapter.title}',
                        child: Material(
                          color: isCurrent
                              ? palette.primarySoft
                              : Colors.transparent,
                          borderRadius: AppRadius.smRadius,
                          child: InkWell(
                            borderRadius: AppRadius.smRadius,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.audioService.seekToChapter(
                                chapterIdx,
                                bookId: widget.bookId,
                              );
                              Navigator.of(sheetContext).pop();
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: AppSize.tap,
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: AppSpace.sm,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                        horizontal: AppSpace.sm,
                                        vertical: AppSpace.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? palette.surface
                                            : palette.surfaceMuted,
                                        borderRadius: AppRadius.smRadius,
                                      ),
                                      child: Text(
                                        '${chapter.index}',
                                        style: textTheme.captionBold.copyWith(
                                          color: isCurrent
                                              ? palette.onPrimarySoft
                                              : palette.textMuted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.md),
                                    Expanded(
                                      child: Text(
                                        chapter.title,
                                        style: (isCurrent
                                                ? textTheme.bodyBold
                                                : textTheme.body)
                                            .copyWith(
                                          color: isCurrent
                                              ? palette.onPrimarySoft
                                              : palette.text,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.sm),
                                    Icon(
                                      isCurrent
                                          ? Icons.graphic_eq_rounded
                                          : Icons.play_circle_outline_rounded,
                                      size: AppIcon.md,
                                      color: isCurrent
                                          ? palette.onPrimarySoft
                                          : palette.textSubtle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

class _AudioMetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _AudioMetaBadge({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcon.sm, color: fg),
          const SizedBox(width: AppSpace.xs),
          Text(
            label,
            style: context.text.captionBold.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
