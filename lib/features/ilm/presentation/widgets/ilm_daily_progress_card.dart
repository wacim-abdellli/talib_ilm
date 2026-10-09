import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';
import '../../../../core/utils/responsive.dart';

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
    final responsive = Responsive(context);

    // Fresh Start Intervention
    if (lastReadDate != null && pagesReadToday == 0) {
      final daysLapsed = DateTime.now().difference(lastReadDate!).inDays;
      if (daysLapsed >= 3) {
        return _buildWelcomeBackCard(context, responsive);
      }
    }

    final progress = dailyGoal > 0
        ? (pagesReadToday / dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = pagesReadToday >= dailyGoal;
    final hasStarted = pagesReadToday > 0;

    // Dynamic subtitle based on progress
    String dynamicSubtitle;
    if (isCompleted) {
      dynamicSubtitle = 'أنجزت اليوم ✨';
    } else if (hasStarted) {
      dynamicSubtitle = 'قاربنا الهدف 🔥';
    } else {
      dynamicSubtitle = 'بداية جميلة 🌱';
    }

    // Warm gold/amber accent colors
    const goldAccent = Color(0xFFD4A853);
    const goldLight = Color(0xFFFFF8E7);
    const goldGlow = Color(0xFFE8C252);
    const completedColor = Color(0xFF6A9A9A);
    const completedLight = Color(0xFFF5FAFA);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(responsive.wp(4)),
        decoration: BoxDecoration(
          color: isCompleted
              ? (context.isDark ? AppColors.darkSuccessLight : completedLight)
              : (context.isDark ? AppColors.darkGoldLight : goldLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? completedColor.withValues(alpha: 0.3)
                : goldAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? completedColor.withValues(alpha: 0.1)
                  : goldAccent.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Animated Circular Progress with warm glow
                SizedBox(
                  width: responsive.wp(16),
                  height: responsive.wp(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft glow behind
                      Container(
                        width: responsive.wp(14),
                        height: responsive.wp(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isCompleted
                                  ? completedColor.withValues(alpha: 0.2)
                                  : goldGlow.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Animated progress ring
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return SizedBox(
                            width: responsive.wp(14),
                            height: responsive.wp(14),
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 6,
                              strokeCap: StrokeCap.round,
                              backgroundColor: isCompleted
                                  ? completedColor.withValues(alpha: 0.2)
                                  : goldAccent.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation(
                                isCompleted ? completedColor : goldAccent,
                              ),
                            ),
                          );
                        },
                      ),
                      // Center icon/number
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$pagesReadToday',
                            style: TextStyle(
                              fontSize: responsive.sp(18),
                              fontWeight: FontWeight.w800,
                              color: isCompleted ? completedColor : goldAccent,
                            ),
                          ),
                          Text(
                            '/ $dailyGoal',
                            style: TextStyle(
                              fontSize: responsive.sp(10),
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: responsive.wp(3)),

                // Goal Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الورد اليومي',
                        style: TextStyle(
                          fontSize: responsive.sp(16),
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dynamicSubtitle,
                        style: TextStyle(
                          fontSize: responsive.sp(13),
                          fontWeight: FontWeight.w500,
                          color: isCompleted ? completedColor : goldAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings icon
                IconButton(
                  onPressed: () => _showGoalSetter(context),
                  icon: Icon(
                    Icons.tune_rounded,
                    size: responsive.sp(20),
                    color: const Color(0xFF9A9A9A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBackCard(BuildContext context, Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: Container(
        padding: EdgeInsets.all(responsive.wp(5)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.isDark
                ? [AppColors.darkSurface, AppColors.darkSurfaceSecondary]
                : [const Color(0xFFFFFBF5), const Color(0xFFFFF4E0)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.goldColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: context.goldColor.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.spa_outlined,
              size: responsive.wp(10),
              color: context.goldColor,
            ),
            SizedBox(height: responsive.mediumGap),
            Text(
              AppStrings.welcomeBackTitle,
              style: TextStyle(
                fontSize: responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: responsive.smallGap),
            Text(
              AppStrings.welcomeBackMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.sp(14),
                color: context.textSecondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
            SizedBox(height: responsive.mediumGap),
            ElevatedButton(
              onPressed: onStartFresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.goldColor,
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.startFreshButton),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalSetter(BuildContext context) {
    int localGoal = dailyGoal;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFFBFAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعديل الهدف اليومي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'كم صفحة تخطط لقراءتها يومياً؟',
                style: TextStyle(color: Color(0xFF6E6E6E)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (localGoal > 1) {
                        setModalState(() => localGoal--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$localGoal',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A3A3A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setModalState(() => localGoal++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await onGoalChanged(localGoal);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'حفظ التغييرات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
