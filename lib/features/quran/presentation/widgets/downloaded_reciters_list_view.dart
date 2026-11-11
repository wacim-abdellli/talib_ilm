import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/quran_audio_downloader.dart';
import '../../data/services/quran_audio_service.dart';
import 'empty_downloaded_audio_state.dart';
import 'surah_card.dart';

/// Renders all downloaded Quran surahs grouped by reciter with accordion collapse/expand,
/// quick reciter filter chips, search filtering, one-tap "play all" queueing, and offline indicators.
class DownloadedRecitersListView extends StatefulWidget {
  final Map<QuranReciter, List<DownloadedSurahItem>> downloadedByReciter;
  final VoidCallback onRefresh;
  final VoidCallback? onBrowseAll;
  final void Function(DownloadedSurahItem) onPlaySurah;
  final Function(DownloadedSurahItem) onDeleteSurah;
  final Function(QuranReciter) onDeleteReciter;

  const DownloadedRecitersListView({
    super.key,
    required this.downloadedByReciter,
    required this.onRefresh,
    this.onBrowseAll,
    required this.onPlaySurah,
    required this.onDeleteSurah,
    required this.onDeleteReciter,
  });

  @override
  State<DownloadedRecitersListView> createState() =>
      _DownloadedRecitersListViewState();
}

class _DownloadedRecitersListViewState
    extends State<DownloadedRecitersListView> {
  final QuranAudioService _audioService = QuranAudioService();
  final TextEditingController _searchController = TextEditingController();

  QuranReciter? _selectedFilterReciter;
  String _searchQuery = '';
  final Set<String> _expandedReciterIds = {};

  @override
  void initState() {
    super.initState();
    _initExpansionState();
  }

  void _initExpansionState() {
    final activeReciter = _audioService.selectedReciter;
    if (widget.downloadedByReciter.containsKey(activeReciter)) {
      _expandedReciterIds.add(activeReciter.id);
    } else if (widget.downloadedByReciter.isNotEmpty) {
      _expandedReciterIds.add(widget.downloadedByReciter.keys.first.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _formatSurahCount(int n) {
    if (n == 1) return 'سورة واحدة';
    if (n == 2) return 'سورتان';
    if (n >= 3 && n <= 10) return '$n سُوَر';
    return '$n سورة';
  }

  void _toggleReciterExpansion(String reciterId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedReciterIds.contains(reciterId)) {
        _expandedReciterIds.remove(reciterId);
      } else {
        _expandedReciterIds.add(reciterId);
      }
    });
  }

  void _playSurahWithQueue(
    DownloadedSurahItem item,
    List<DownloadedSurahItem> surahs,
  ) {
    _audioService.setSurahPlaybackQueue(
      surahs.map((s) => s.surah).toList(),
      downloadedOnly: true,
    );
    widget.onPlaySurah(item);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (widget.downloadedByReciter.isEmpty) {
      return EmptyDownloadedAudioState(
        onBrowseAll: widget.onBrowseAll ?? () {},
      );
    }

    final allReciters = widget.downloadedByReciter.keys.toList();
    final totalAllSurahs = widget.downloadedByReciter.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    // Filter reciters
    final targetReciters = _selectedFilterReciter != null
        ? [if (widget.downloadedByReciter.containsKey(_selectedFilterReciter)) _selectedFilterReciter!]
        : allReciters;

    // Filter surahs by search
    final Map<QuranReciter, List<DownloadedSurahItem>> filteredMap = {};
    for (final r in targetReciters) {
      final list = widget.downloadedByReciter[r] ?? const [];
      if (_searchQuery.isEmpty) {
        filteredMap[r] = list;
      } else {
        final q = _searchQuery.trim().toLowerCase();
        final matched = list.where((item) {
          final sName = item.surahName.toLowerCase();
          final sNum = item.surah.toString();
          final rName = item.reciter.name.toLowerCase();
          return sName.contains(q) || sNum.contains(q) || rName.contains(q);
        }).toList();
        if (matched.isNotEmpty) {
          filteredMap[r] = matched;
        }
      }
    }

    return Column(
      children: [
        // ── Controls Header: Search & Reciter Filter Chips ─────────────────
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.lg,
            AppSpace.xs,
            AppSpace.lg,
            AppSpace.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field
              Container(
                height: AppUi.tapTargetMin,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.7),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  style: textTheme.body.copyWith(color: palette.text),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث في السور المحمّلة باسم السورة أو القارئ...',
                    hintStyle: textTheme.caption.copyWith(color: palette.textMuted),
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: palette.textMuted,
                      size: AppIcon.sm,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: palette.textMuted,
                              size: AppIcon.xs,
                            ),
                            tooltip: 'مسح البحث',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                  ),
                ),
              ),

              // Filter Chips (when more than 1 reciter is downloaded)
              if (allReciters.length > 1) ...[
                const SizedBox(height: AppSpace.sm),
                SizedBox(
                  height: AppUi.tapTargetMin - AppSpace.xs,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: allReciters.length + 1,
                    separatorBuilder: (context, _) =>
                        const SizedBox(width: AppSpace.xs),
                    itemBuilder: (context, idx) {
                      if (idx == 0) {
                        final isAllSelected = _selectedFilterReciter == null;
                        return Material(
                          color: isAllSelected
                              ? palette.primarySoft
                              : palette.surface,
                          borderRadius: AppRadius.pillRadius,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedFilterReciter = null);
                            },
                            borderRadius: AppRadius.pillRadius,
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.md,
                                vertical: AppSpace.xs,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color: isAllSelected
                                      ? palette.primary
                                      : palette.border.withValues(alpha: 0.6),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'الكل ($totalAllSurahs)',
                                style: textTheme.caption.copyWith(
                                  color: isAllSelected
                                      ? palette.primary
                                      : palette.textMuted,
                                  fontWeight: isAllSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final reciter = allReciters[idx - 1];
                      final count =
                          widget.downloadedByReciter[reciter]?.length ?? 0;
                      final isSelected = _selectedFilterReciter == reciter;

                      return Material(
                        color: isSelected
                            ? palette.primarySoft
                            : palette.surface,
                        borderRadius: AppRadius.pillRadius,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilterReciter =
                                  isSelected ? null : reciter;
                              if (!isSelected) {
                                _expandedReciterIds.add(reciter.id);
                              }
                            });
                          },
                          borderRadius: AppRadius.pillRadius,
                          child: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: isSelected
                                    ? palette.primary
                                    : palette.border.withValues(alpha: 0.6),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.record_voice_over_rounded,
                                  size: AppIcon.xs,
                                  color: isSelected
                                      ? palette.primary
                                      : palette.textMuted,
                                ),
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  '${reciter.name} ($count)',
                                  style: textTheme.caption.copyWith(
                                    color: isSelected
                                        ? palette.primary
                                        : palette.textMuted,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Reciter Cards List ─────────────────────────────────────────────
        Expanded(
          child: filteredMap.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: AppIcon.xl,
                          color: palette.textMuted,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          'لا توجد نتائج مطابقة لبحثك',
                          style: textTheme.body.copyWith(
                            color: palette.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          'جرّب البحث باسم سورة أخرى أو إعادة تعيين عامل التصفية.',
                          textAlign: TextAlign.center,
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpace.lg,
                    AppSpace.xs,
                    AppSpace.lg,
                    AppSpace.xxl * 2,
                  ),
                  itemCount: filteredMap.length,
                  itemBuilder: (context, rIdx) {
                    final reciter = filteredMap.keys.elementAt(rIdx);
                    final surahs = filteredMap[reciter]!;
                    final fullReciterSurahs =
                        widget.downloadedByReciter[reciter] ?? surahs;
                    final totalBytes =
                        surahs.fold<int>(0, (sum, s) => sum + s.bytes);
                    final isExpanded = _searchQuery.isNotEmpty ||
                        _expandedReciterIds.contains(reciter.id);

                    return AnimatedBuilder(
                      animation: Listenable.merge([
                        _audioService.activeSurahNotifier,
                        _audioService.isPlayingNotifier,
                      ]),
                      builder: (context, _) {
                        final isReciterActive =
                            _audioService.selectedReciter.id == reciter.id;

                        return Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: AppSpace.md,
                          ),
                          child: AppCard(
                            padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                            color: palette.surface,
                            borderRadius: AppRadius.xlRadius,
                            border: Border.all(
                              color: isReciterActive && _audioService.isPlayingNotifier.value
                                  ? palette.primary.withValues(alpha: 0.8)
                                  : palette.border.withValues(alpha: 0.7),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Reciter Section Header (Collapsible) ────
                                InkWell(
                                  onTap: () =>
                                      _toggleReciterExpansion(reciter.id),
                                  borderRadius: AppRadius.lgRadius,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.all(
                                      AppSpace.xs,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: AppUi.iconBoxSize,
                                          height: AppUi.iconBoxSize,
                                          decoration: BoxDecoration(
                                            color: isReciterActive
                                                ? palette.primarySoft
                                                : palette.surfaceMuted,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.record_voice_over_rounded,
                                            color: isReciterActive
                                                ? palette.primary
                                                : palette.textMuted,
                                            size: AppIcon.sm,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpace.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      reciter.name,
                                                      style: textTheme.label
                                                          .copyWith(
                                                        color: palette.text,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isReciterActive &&
                                                      _audioService
                                                          .isPlayingNotifier
                                                          .value) ...[
                                                    const SizedBox(
                                                      width: AppSpace.xs,
                                                    ),
                                                    Icon(
                                                      Icons.graphic_eq_rounded,
                                                      size: AppIcon.xs,
                                                      color: palette.primary,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: AppSpace.xxs),
                                              Text(
                                                '${_formatSurahCount(surahs.length)} • ${QuranAudioDownloader.formatBytes(totalBytes)}',
                                                style: textTheme.caption.copyWith(
                                                  color: palette.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Play All Button
                                        IconButton(
                                          icon: Icon(
                                            Icons.play_circle_fill_rounded,
                                            color: palette.primary,
                                            size: AppIcon.md,
                                          ),
                                          tooltip:
                                              'تشغيل متتالي لسور ${reciter.name}',
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            _playSurahWithQueue(
                                              surahs.first,
                                              fullReciterSurahs,
                                            );
                                          },
                                        ),
                                        // Delete Reciter
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: palette.error,
                                            size: AppIcon.sm,
                                          ),
                                          tooltip:
                                              'حذف تلاوات ${reciter.name}',
                                          onPressed: () =>
                                              widget.onDeleteReciter(reciter),
                                        ),
                                        // Expand/Collapse Chevron
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          color: palette.textMuted,
                                          size: AppIcon.md,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Downloaded Surah Tiles (Accordion Content)
                                if (isExpanded) ...[
                                  Divider(
                                    height: AppSpace.md,
                                    color: palette.border.withValues(alpha: 0.5),
                                  ),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: surahs.length,
                                    separatorBuilder: (context, _) =>
                                        const SizedBox(height: AppSpace.xxs),
                                    itemBuilder: (context, sIdx) {
                                      final item = surahs[sIdx];
                                      final isCurrentSurah = _audioService
                                                  .activeSurahNotifier.value ==
                                              item.surah &&
                                          _audioService.selectedReciter.id ==
                                              reciter.id;
                                      final isAudioPlaying = isCurrentSurah &&
                                          _audioService.isPlayingNotifier.value;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isAudioPlaying
                                              ? palette.primarySoft
                                                  .withValues(alpha: 0.15)
                                              : palette.surfaceMuted
                                                  .withValues(alpha: 0.4),
                                          borderRadius: AppRadius.mdRadius,
                                          border: Border.all(
                                            color: isAudioPlaying
                                                ? palette.primary
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: AppRadius.mdRadius,
                                          child: InkWell(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              _playSurahWithQueue(
                                                item,
                                                fullReciterSurahs,
                                              );
                                            },
                                            borderRadius: AppRadius.mdRadius,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .symmetric(
                                                horizontal: AppSpace.sm,
                                                vertical: AppSpace.xs,
                                              ),
                                              child: Row(
                                                children: [
                                                  SurahNumberMedallion(
                                                    number: item.surah,
                                                    size: AppIcon.md,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpace.sm,
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              'سورة ${item.surahName}',
                                                              style: textTheme
                                                                  .label
                                                                  .copyWith(
                                                                color: isAudioPlaying
                                                                    ? palette
                                                                        .primary
                                                                    : palette
                                                                        .text,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            if (isAudioPlaying) ...[
                                                              const SizedBox(
                                                                width:
                                                                    AppSpace.xs,
                                                              ),
                                                              Container(
                                                                padding: const EdgeInsetsDirectional
                                                                    .symmetric(
                                                                  horizontal:
                                                                      AppSpace
                                                                          .xs,
                                                                  vertical:
                                                                      AppSpace
                                                                          .xxs,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: palette
                                                                      .primarySoft,
                                                                  borderRadius:
                                                                      AppRadius
                                                                          .pillRadius,
                                                                ),
                                                                child: Text(
                                                                  'أوفلاين',
                                                                  style:
                                                                      textTheme
                                                                          .caption
                                                                          .copyWith(
                                                                    color:
                                                                        palette
                                                                            .primary,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        Text(
                                                          '${item.verseCount} آية • ${QuranAudioDownloader.formatBytes(item.bytes)}',
                                                          style: textTheme
                                                              .caption
                                                              .copyWith(
                                                            color: palette
                                                                .textMuted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Play/Pause Action
                                                  IconButton(
                                                    icon: Icon(
                                                      isAudioPlaying
                                                          ? Icons
                                                              .pause_circle_filled_rounded
                                                          : Icons
                                                              .play_circle_fill_rounded,
                                                      color: palette.primary,
                                                      size: AppIcon.md,
                                                    ),
                                                    tooltip: isAudioPlaying
                                                        ? 'إيقاف مؤقت'
                                                        : 'تشغيل السورة',
                                                    onPressed: () {
                                                      HapticFeedback
                                                          .lightImpact();
                                                      _playSurahWithQueue(
                                                        item,
                                                        fullReciterSurahs,
                                                      );
                                                    },
                                                  ),
                                                  // Delete Action
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color: palette.textMuted,
                                                      size: AppIcon.sm,
                                                    ),
                                                    tooltip: 'حذف من الجهاز',
                                                    onPressed: () {
                                                      HapticFeedback
                                                          .lightImpact();
                                                      widget
                                                          .onDeleteSurah(item);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
