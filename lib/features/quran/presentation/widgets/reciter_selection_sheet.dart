import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/services/quran_audio_downloader.dart';
import '../../data/services/quran_audio_service.dart';

/// Modern, clean modal bottom sheet for choosing a Quran reciter with search,
/// audio riwayah details, and storage badges.
class ReciterSelectionSheet extends StatefulWidget {
  final QuranReciter selectedReciter;
  final ValueChanged<QuranReciter> onSelected;

  const ReciterSelectionSheet({
    super.key,
    required this.selectedReciter,
    required this.onSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required QuranReciter selectedReciter,
    required ValueChanged<QuranReciter> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReciterSelectionSheet(
        selectedReciter: selectedReciter,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<ReciterSelectionSheet> createState() => _ReciterSelectionSheetState();
}

class _ReciterSelectionSheetState extends State<ReciterSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, int> _reciterStorageBytes = {};

  @override
  void initState() {
    super.initState();
    _loadRecitersStorage();
  }

  Future<void> _loadRecitersStorage() async {
    final storage = await QuranAudioDownloader.getStorageByReciter();
    if (mounted) {
      setState(() {
        _reciterStorageBytes.clear();
        _reciterStorageBytes.addAll(storage);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final allReciters = QuranAudioService.reciters;

    final filtered = _searchQuery.trim().isEmpty
        ? allReciters
        : allReciters.where((r) {
            return r.name.toLowerCase().contains(_searchQuery.toLowerCase().trim());
          }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.sheetTopRadius,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpace.sm),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            // Header
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppUi.iconBoxSize,
                    height: AppUi.iconBoxSize,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: palette.primary,
                      size: AppIcon.md,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختيار القارئ الصوتي',
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'تحديد القارئ المعتمد للاستماع والتنزيل',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.textMuted),
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            // Search Bar
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.6),
                  ),
                ),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: palette.textMuted,
                      size: AppIcon.sm,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: textTheme.body.copyWith(color: palette.text),
                        decoration: InputDecoration(
                          hintText: 'ابحث باسم القارئ',
                          hintStyle: textTheme.body.copyWith(
                            color: palette.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsetsDirectional.symmetric(
                            vertical: AppSpace.md,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        tooltip: 'مسح البحث',
                        icon: Icon(
                          Icons.clear_rounded,
                          color: palette.textMuted,
                          size: AppIcon.sm,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Divider(
              height: 1,
              color: palette.border.withValues(alpha: 0.5),
            ),
            // Reciters List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                itemCount: filtered.length,
                separatorBuilder: (context, _) =>
                    const SizedBox(height: AppSpace.xs),
                itemBuilder: (context, index) {
                  final reciter = filtered[index];
                  final isSelected = reciter == widget.selectedReciter;
                  final storedBytes = _reciterStorageBytes[reciter.id] ?? 0;

                  return Material(
                    color: Colors.transparent,
                    borderRadius: AppRadius.mdRadius,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSelected(reciter);
                        Navigator.pop(context);
                      },
                      borderRadius: AppRadius.mdRadius,
                      child: Container(
                        padding: const EdgeInsetsDirectional.all(AppSpace.md),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.primarySoft.withValues(alpha: 0.15)
                              : palette.surface,
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(
                            color: isSelected
                                ? palette.primary
                                : palette.border.withValues(alpha: 0.6),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: AppUi.iconBoxSize,
                              height: AppUi.iconBoxSize,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? palette.primary
                                    : palette.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isSelected
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                                color: isSelected
                                    ? palette.onPrimary
                                    : palette.textMuted,
                                size: AppIcon.sm,
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reciter.name,
                                    style: textTheme.label.copyWith(
                                      color: isSelected
                                          ? palette.primary
                                          : palette.text,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.xxs),
                                  Row(
                                    children: [
                                      Text(
                                        reciter.isSurahBased
                                            ? 'المصحف المرتل الكامل'
                                            : 'تلاوة آية بآية • مرتل',
                                        style: textTheme.caption.copyWith(
                                          color: palette.textMuted,
                                        ),
                                      ),
                                      if (storedBytes > 0) ...[
                                        const SizedBox(width: AppSpace.xs),
                                        Container(
                                          padding:
                                              const EdgeInsetsDirectional.symmetric(
                                            horizontal: AppSpace.xs,
                                            vertical: AppSpace.xxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.gold
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                AppRadius.pillRadius,
                                          ),
                                          child: Text(
                                            QuranAudioDownloader.formatBytes(
                                              storedBytes,
                                            ),
                                            style: textTheme.caption.copyWith(
                                              color: palette.gold,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: palette.primary,
                                size: AppIcon.md,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: palette.border,
                                size: AppIcon.md,
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
        ),
      ),
    );
  }
}
