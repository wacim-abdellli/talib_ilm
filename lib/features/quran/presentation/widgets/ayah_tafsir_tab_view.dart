import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/quran_tafsir_service.dart';

class AyahTafsirTabView extends StatefulWidget {
  final TafsirScholar selectedScholar;
  final String tafsirText;
  final bool loadingTafsir;
  final ValueChanged<TafsirScholar> onScholarChanged;

  const AyahTafsirTabView({
    super.key,
    required this.selectedScholar,
    required this.tafsirText,
    required this.loadingTafsir,
    required this.onScholarChanged,
  });

  @override
  State<AyahTafsirTabView> createState() => _AyahTafsirTabViewState();
}

class _AyahTafsirTabViewState extends State<AyahTafsirTabView> {
  final ScrollController _scrollController = ScrollController();
  double _fontScale = 1.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _increaseFont() {
    if (_fontScale < 1.35) {
      HapticFeedback.selectionClick();
      setState(() => _fontScale = (_fontScale + 0.1).clamp(0.85, 1.35));
    }
  }

  void _decreaseFont() {
    if (_fontScale > 0.85) {
      HapticFeedback.selectionClick();
      setState(() => _fontScale = (_fontScale - 0.1).clamp(0.85, 1.35));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final scholarName = QuranTafsirService.getScholarName(widget.selectedScholar);
    final scholarAuthor = QuranTafsirService.getScholarAuthor(widget.selectedScholar);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Scholar Selector Chips & Font Zoom Stepper
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xxs),
                child: Row(
                  children: TafsirScholar.values.map((scholar) {
                    final isSelected = widget.selectedScholar == scholar;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                      child: ChoiceChip(
                        label: Text(
                          QuranTafsirService.getScholarName(scholar),
                          style: textTheme.caption.copyWith(
                            color: isSelected ? palette.onPrimary : palette.text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: palette.primary,
                        backgroundColor: palette.surfaceMuted,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.pillRadius,
                          side: BorderSide(
                            color: isSelected ? palette.primary : palette.border,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            widget.onScholarChanged(scholar);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            // Quick Font Size Stepper
            Container(
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _decreaseFont,
                    borderRadius: AppRadius.pillRadius,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xxs,
                      ),
                      child: Text(
                        'A-',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 12, color: palette.border),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xxs),
                    child: Text(
                      '${(_fontScale * 100).round()}%',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 12, color: palette.border),
                  InkWell(
                    onTap: _increaseFont,
                    borderRadius: AppRadius.pillRadius,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xxs,
                      ),
                      child: Text(
                        'A+',
                        style: textTheme.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xs),

        // 2. Focused Tafsir Commentary Area with Fully Unlocked Scrolling
        Expanded(
          child: widget.loadingTafsir
              ? Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 140, height: 18),
                      SizedBox(height: AppSpace.md),
                      AppSkeleton(width: double.infinity, height: 16),
                      SizedBox(height: AppSpace.xs),
                      AppSkeleton(width: double.infinity, height: 16),
                      SizedBox(height: AppSpace.xs),
                      AppSkeleton(width: double.infinity, height: 16),
                      SizedBox(height: AppSpace.xs),
                      AppSkeleton(width: 220, height: 16),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: palette.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.mdRadius,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsetsDirectional.all(AppSpace.md),
                        child: SelectionArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Scholar Banner
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                                    decoration: BoxDecoration(
                                      color: palette.gold.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.auto_stories_rounded,
                                      size: AppIcon.sm,
                                      color: palette.gold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.xs),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          scholarName,
                                          style: textTheme.titleSmall.copyWith(
                                            color: palette.gold,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          scholarAuthor,
                                          style: textTheme.caption.copyWith(
                                            color: palette.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppIconButton(
                                    icon: Icons.copy_rounded,
                                    tooltip: 'نسخ التفسير',
                                    color: palette.textMuted,
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      Clipboard.setData(ClipboardData(text: widget.tafsirText));
                                      AppSnackbar.success(context, 'تم نسخ التفسير');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Divider(
                                height: 1,
                                color: palette.border.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: AppSpace.sm),

                              // Sacred Commentary Content with Paragraph Breakdown
                              if (widget.tafsirText.trim().isEmpty) ...[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: AppIcon.md,
                                          color: palette.textMuted,
                                        ),
                                        const SizedBox(height: AppSpace.xs),
                                        Text(
                                          'لا يتوفر نص للتفسير لهذه الآية حالياً',
                                          style: textTheme.caption.copyWith(
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Directionality(
                                  textDirection: widget.selectedScholar == TafsirScholar.englishIbnKathir
                                      ? TextDirection.ltr
                                      : TextDirection.rtl,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: widget.tafsirText
                                        .split('\n')
                                        .where((p) => p.trim().isNotEmpty)
                                        .map((paragraph) {
                                      return Padding(
                                        padding: const EdgeInsetsDirectional.only(
                                          bottom: AppSpace.sm,
                                        ),
                                        child: Text(
                                          paragraph.trim(),
                                          style: textTheme.body.copyWith(
                                            color: palette.text,
                                            height: 1.9 * _fontScale,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpace.md),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
