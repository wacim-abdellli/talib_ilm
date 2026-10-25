import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../adhkar/data/adhkar_models.dart';

/// Context-aware Daily Dhikr card for Home page
class HomeDailyDhikrCard extends StatefulWidget {
  final DailyDhikrPayload payload;
  final VoidCallback onOpenSession;

  const HomeDailyDhikrCard({
    super.key,
    required this.payload,
    required this.onOpenSession,
  });

  @override
  State<HomeDailyDhikrCard> createState() => _HomeDailyDhikrCardState();
}

class _HomeDailyDhikrCardState extends State<HomeDailyDhikrCard> {
  int _tapCount = 0;

  void _handleTap() {
    final target = widget.payload.item.target;
    if (target > 0 && _tapCount >= target) {
      widget.onOpenSession();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _tapCount++;
    });
    if (target > 0 && _tapCount >= target) {
      HapticFeedback.mediumImpact();
      AppSnackbar.success(context, 'تم إكمال الذكر اليومي، تقبّل الله');
    }
  }

  void _copyDhikr() {
    HapticFeedback.lightImpact();
    final item = widget.payload.item;
    final buffer = StringBuffer()..writeln(item.arabic);
    if (item.fadl.isNotEmpty) {
      buffer.writeln('\n${item.fadl}');
    }
    if (item.source.isNotEmpty) {
      buffer.writeln('\n— ${item.source}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppSnackbar.success(context, 'تم نسخ الذكر إلى الحافظة');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final item = widget.payload.item;
    final target = item.target <= 0 ? 1 : item.target;
    final isDone = _tapCount >= target;

    final progressRatio = (target > 0)
        ? (_tapCount / target).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'ذكر اليوم',
          padding: EdgeInsetsDirectional.only(bottom: AppSpace.sm),
        ),
        AppCard(
          color: palette.surfaceRaised,
          border: Border.all(
            color: isDone
                ? palette.gold.withValues(alpha: 0.5)
                : palette.border,
            width: isDone ? 1.5 : 1.0,
          ),
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          onTap: _handleTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                children: [
                  IconBadge(
                    icon: widget.payload.categoryIcon,
                    bg: isDone ? palette.goldSoft : palette.primarySoft,
                    fg: isDone ? palette.gold : palette.onPrimarySoft,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.payload.categoryLabel,
                          style: context.text.titleSmall.copyWith(
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          item.countDescription.isNotEmpty
                              ? item.countDescription
                              : (target > 1 ? '$target مرات' : 'مرة واحدة'),
                          style: context.text.label.copyWith(
                            color: isDone ? palette.gold : palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Copy icon button
                  Tooltip(
                    message: 'نسخ الذكر',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _copyDhikr,
                        borderRadius: AppRadius.smRadius,
                        child: Container(
                          width: AppSize.tap,
                          height: AppSize.tap,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.copy_rounded,
                            size: AppIcon.sm,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpace.md),

              // Dhikr Sacred Text
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Text(
                  item.arabic,
                  textAlign: TextAlign.center,
                  style: context.text.titleSmall.copyWith(
                    height: 1.8,
                    color: palette.text,
                  ),
                ),
              ),

              // Fadl (Merit / Virtue)
              if (item.fadl.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: AppIcon.sm,
                      color: palette.gold,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        item.fadl,
                        style: context.text.label.copyWith(
                          color: palette.gold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpace.md),

              // Interactive Footer: Counter dial pill + "قراءة الورد"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tap to count pill
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleTap,
                      borderRadius: AppRadius.pillRadius,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? palette.goldSoft
                              : palette.surfaceMuted,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: isDone
                                ? palette.gold.withValues(alpha: 0.5)
                                : palette.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : Icons.touch_app_rounded,
                              size: AppIcon.sm,
                              color: isDone ? palette.gold : palette.textMuted,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              isDone
                                  ? 'تمت القراءة'
                                  : '$_tapCount من $target',
                              style: context.text.label.copyWith(
                                color: isDone
                                    ? palette.gold
                                    : palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Open full session button
                  TextButton.icon(
                    onPressed: widget.onOpenSession,
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    label: Text(
                      'فتح الورد كاملًا',
                      style: context.text.label.copyWith(
                        color: palette.primary,
                      ),
                    ),
                  ),
                ],
              ),

              // Progress bar
              if (target > 1) ...[
                const SizedBox(height: AppSpace.xs),
                ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 3,
                    backgroundColor: palette.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? palette.gold : palette.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
