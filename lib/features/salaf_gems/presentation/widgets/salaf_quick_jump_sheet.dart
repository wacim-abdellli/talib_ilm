import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/salaf_gem.dart';

class SalafQuickJumpSheet extends StatefulWidget {
  final int totalCount;
  final List<SalafGem> gems;
  final ValueChanged<int> onJumpToIndex;

  const SalafQuickJumpSheet({
    super.key,
    required this.totalCount,
    required this.gems,
    required this.onJumpToIndex,
  });

  static Future<void> show({
    required BuildContext context,
    required int totalCount,
    required List<SalafGem> gems,
    required ValueChanged<int> onJumpToIndex,
  }) {
    final palette = context.palette;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTopRadius,
      ),
      builder: (_) => SalafQuickJumpSheet(
        totalCount: totalCount,
        gems: gems,
        onJumpToIndex: onJumpToIndex,
      ),
    );
  }

  @override
  State<SalafQuickJumpSheet> createState() => _SalafQuickJumpSheetState();
}

class _SalafQuickJumpSheetState extends State<SalafQuickJumpSheet> {
  late double _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = 1.0;
  }

  void _applyJump(int index) {
    HapticFeedback.selectionClick();
    widget.onJumpToIndex(index - 1);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final total = widget.totalCount;
    final selectedInt = _currentIndex.round().clamp(1, total);
    final previewGem = widget.gems.isNotEmpty
        ? widget.gems[(selectedInt - 1).clamp(0, widget.gems.length - 1)]
        : null;

    final q1 = (total * 0.25).round().clamp(1, total);
    final q2 = (total * 0.50).round().clamp(1, total);
    final q3 = (total * 0.75).round().clamp(1, total);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
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
            const SizedBox(height: AppSpace.sm),

            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.directions_run_rounded,
                    color: palette.gold,
                    size: AppIcon.sm,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'انتقال سريع بين الآثار',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'تصفح مباشر عبر $total دُرّة وأثراً دون عناء التمرير',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: palette.textMuted,
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),

            // Quick Milestone Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMilestoneChip('الأول (1)', 1, palette, textTheme),
                  if (total >= 4) ...[
                    const SizedBox(width: AppSpace.xs),
                    _buildMilestoneChip('الربع ($q1)', q1, palette, textTheme),
                  ],
                  if (total >= 2) ...[
                    const SizedBox(width: AppSpace.xs),
                    _buildMilestoneChip('المنتصف ($q2)', q2, palette, textTheme),
                  ],
                  if (total >= 4) ...[
                    const SizedBox(width: AppSpace.xs),
                    _buildMilestoneChip('ثلاثة أرباع ($q3)', q3, palette, textTheme),
                  ],
                  const SizedBox(width: AppSpace.xs),
                  _buildMilestoneChip('الأخير ($total)', total, palette, textTheme),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),

            // Slider & Selected Index Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الأثر رقم: $selectedInt',
                  style: textTheme.label.copyWith(
                    color: palette.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'من أصل $total',
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
            if (total > 1)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: palette.gold,
                  inactiveTrackColor: palette.surfaceRaised,
                  thumbColor: palette.gold,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _currentIndex.clamp(1.0, total.toDouble()),
                  min: 1.0,
                  max: total.toDouble(),
                  divisions: total > 1 ? total - 1 : 1,
                  onChanged: (val) {
                    setState(() => _currentIndex = val);
                  },
                ),
              ),

            // Live Preview Card
            if (previewGem != null)
              Container(
                margin: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: palette.gold,
                          size: AppIcon.xs,
                        ),
                        const SizedBox(width: AppSpace.xxs),
                        Expanded(
                          child: Text(
                            previewGem.author,
                            style: textTheme.caption.copyWith(
                              color: palette.gold,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '#$selectedInt',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      previewGem.cleanText,
                      style: textTheme.bodySmall.copyWith(
                        color: palette.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // Confirm Jump Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppRadius.mdRadius,
                onTap: () => _applyJump(selectedInt),
                child: Container(
                  height: AppSize.buttonH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: palette.onPrimary,
                        size: AppIcon.sm,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'انتقال إلى الأثر رقم $selectedInt',
                        style: textTheme.label.copyWith(
                          color: palette.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneChip(
    String label,
    int index,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pillRadius,
        onTap: () {
          setState(() => _currentIndex = index.toDouble());
        },
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: _currentIndex.round() == index
                ? palette.goldSoft
                : palette.surfaceRaised,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: _currentIndex.round() == index
                  ? palette.gold
                  : palette.border,
            ),
          ),
          child: Text(
            label,
            style: textTheme.caption.copyWith(
              color: _currentIndex.round() == index
                  ? palette.gold
                  : palette.textMuted,
              fontWeight: _currentIndex.round() == index
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
