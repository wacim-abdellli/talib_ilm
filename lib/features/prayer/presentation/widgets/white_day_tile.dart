import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

class WhiteDayTile extends StatelessWidget {
  final int hijriDay;
  final DateTime gregorianDate;
  final String dateStr;
  final bool isToday;
  final bool isDone;
  final bool isForbidden;
  final VoidCallback onTap;

  const WhiteDayTile({
    super.key,
    required this.hijriDay,
    required this.gregorianDate,
    required this.dateStr,
    required this.isToday,
    required this.isDone,
    required this.isForbidden,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final borderColor = isForbidden
        ? palette.border
        : isDone
            ? palette.primary
            : isToday
                ? palette.gold
                : palette.border;

    final bgColor = isDone
        ? palette.primarySoft
        : isToday
            ? palette.goldSoft
            : palette.surfaceMuted;

    return Semantics(
      label: 'يوم $hijriDay من الأيام البيض $dateStr',
      button: !isForbidden,
      checked: isDone,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isForbidden ? null : onTap,
          borderRadius: AppRadius.mdRadius,
          child: AnimatedContainer(
            duration: AppMotion.base,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsetsDirectional.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: borderColor,
                width: isToday || isDone ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Day Number + Checkmark/Forbidden
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$hijriDay',
                      style: context.text.titleSmall.copyWith(
                        color: isDone
                            ? palette.primary
                            : isToday
                                ? palette.gold
                                : palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Icon(
                      isForbidden
                          ? Icons.block_rounded
                          : isDone
                              ? Icons.check_circle_rounded
                              : isToday
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked,
                      size: AppIcon.sm,
                      color: isForbidden
                          ? palette.textSubtle
                          : isDone
                              ? palette.primary
                              : isToday
                                  ? palette.gold
                                  : palette.textSubtle,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  dateStr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.text.caption.copyWith(
                    color: isDone
                        ? palette.primary
                        : isToday
                            ? palette.gold
                            : palette.textMuted,
                    fontWeight: isToday || isDone
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(height: AppSpace.xs),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xs,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.gold,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      'اليوم',
                      style: context.text.caption.copyWith(
                        color: palette.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
