import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

class IlmDailyProgressCard extends StatelessWidget {
  final int dailyGoal;
  final int pagesReadToday;
  final DateTime? lastReadDate;
  final Future<void> Function(int) onGoalChanged;
  final VoidCallback onStartFresh;

  const IlmDailyProgressCard({
    super.key,
    required this.dailyGoal,
    required this.pagesReadToday,
    required this.lastReadDate,
    required this.onGoalChanged,
    required this.onStartFresh,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // Fresh Start Intervention
    if (lastReadDate != null && pagesReadToday == 0) {
      final daysLapsed = DateTime.now().difference(lastReadDate!).inDays;
      if (daysLapsed >= 3) {
        return _buildWelcomeBackCard(context);
      }
    }

    final progress = dailyGoal > 0
        ? (pagesReadToday / dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = pagesReadToday >= dailyGoal;
    final hasStarted = pagesReadToday > 0;

    String dynamicSubtitle;
    if (isCompleted) {
      dynamicSubtitle = 'أنجزت ورد اليوم بفضل الله ✨';
    } else if (hasStarted) {
      dynamicSubtitle = 'قاربت على إتمام الورد اليومي 🔥';
    } else {
      dynamicSubtitle = 'بداية طيبة لطلب العلم 🌱';
    }

    return Padding(
      padding: AppSpace.screenPadding,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            // Circular progress indicator
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: palette.border,
                      valueColor: AlwaysStoppedAnimation(
                        isCompleted ? palette.success : palette.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$pagesReadToday',
                        style: context.text.label.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? palette.success : palette.text,
                        ),
                      ),
                      Text(
                        '/$dailyGoal',
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpace.lg),

            // Goal Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الورد اليومي',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    dynamicSubtitle,
                    style: context.text.bodySmall.copyWith(
                      color: isCompleted ? palette.success : palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Settings button
            AppIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'تعديل الهدف اليومي',
              iconSize: AppIcon.md,
              color: palette.textSubtle,
              onPressed: () => _showGoalSetter(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBackCard(BuildContext context) {
    return Padding(
      padding: AppSpace.screenPadding,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            const IconBadge(icon: Icons.spa_outlined),
            const SizedBox(height: AppSpace.md),
            Text(
              AppStrings.welcomeBackTitle,
              style: context.text.titleSmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              AppStrings.welcomeBackMessage,
              textAlign: TextAlign.center,
              style: context.text.bodySmall.copyWith(
                color: context.palette.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              label: AppStrings.startFreshButton,
              onPressed: onStartFresh,
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalSetter(BuildContext context) {
    final palette = context.palette;
    int localGoal = dailyGoal;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.lg,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'تعديل الهدف اليومي',
                style: context.text.titleSmall,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'كم صفحة تخطط لقراءتها يومياً؟',
                style: context.text.bodySmall.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIconButton(
                    icon: Icons.remove_circle_outline,
                    tooltip: 'إنقاص',
                    iconSize: AppIcon.xl,
                    color: palette.primary,
                    onPressed: () {
                      if (localGoal > 1) {
                        setModalState(() => localGoal--);
                      }
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xl,
                    ),
                    child: Text(
                      '$localGoal',
                      style: context.text.display,
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.add_circle_outline,
                    tooltip: 'زيادة',
                    iconSize: AppIcon.xl,
                    color: palette.primary,
                    onPressed: () => setModalState(() => localGoal++),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xxl),
              AppButton(
                label: 'حفظ التغييرات',
                width: double.infinity,
                onPressed: () async {
                  await onGoalChanged(localGoal);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
              ),
              SizedBox(
                height: MediaQuery.paddingOf(context).bottom + AppSpace.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
