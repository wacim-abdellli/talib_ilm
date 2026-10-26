import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_ui.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/prayer_schedule_service.dart';
import 'app_button.dart';
import 'app_dialog.dart';
import 'app_snackbar.dart';
import 'notification_pre_permission_sheet.dart';

/// Dignified Calm Scholar onboarding dialog prompting the user
/// on first app launch to authorize prayer notifications, adhan alarms, and athkar reminders.
class NotificationOnboardingDialog extends StatelessWidget {
  const NotificationOnboardingDialog({super.key});

  static const String prefKey = 'has_shown_notification_onboarding';

  /// Checks if the onboarding has been shown before, and displays it if not.
  static Future<void> checkAndShow(BuildContext context) async {
    await NotificationPrePermissionSheet.checkAndShow(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppDialog(
      title: 'تفعيل تنبيهات الأذان والأذكار',
      icon: Icons.notifications_active_rounded,
      iconColor: palette.primary,
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لضمان سماع الأذان الشريف في وقته وعدم تفويت أي صلاة أو ذكر مسنون، يرجى تفعيل التنبيهات لتطبيق طالب العلم:',
              style: textTheme.body.copyWith(
                color: palette.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _buildFeatureRow(
              palette: palette,
              textTheme: textTheme,
              icon: Icons.volume_up_rounded,
              title: 'صوت الأذان عند دخول الوقت',
              desc: 'الأذان كاملاً والتكبيرات بصوت شيوخ الحرمين الشريفين',
            ),
            const SizedBox(height: AppSpace.sm),
            _buildFeatureRow(
              palette: palette,
              textTheme: textTheme,
              icon: Icons.access_time_filled_rounded,
              title: 'التذكير المسبق والإقامة',
              desc: 'تنبيه قبل الصلاة بـ 15 دقيقة للتطهر والوضوء، وتنبيه الإقامة',
            ),
            const SizedBox(height: AppSpace.sm),
            _buildFeatureRow(
              palette: palette,
              textTheme: textTheme,
              icon: Icons.menu_book_rounded,
              title: 'سورة الكهف والأذكار اليومية',
              desc: 'تذكير الجمعة المباركة وأذكار الصباح والمساء في مواعيدها',
            ),
          ],
        ),
      ),
      actions: [
        AppButton.text(
          label: 'لاحقاً',
          onPressed: () async {
            HapticFeedback.lightImpact();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(prefKey, true);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
        const SizedBox(width: AppSpace.sm),
        AppButton(
          label: 'تفعيل الآن',
          icon: Icons.check_circle_rounded,
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(prefKey, true);
            if (context.mounted) {
              Navigator.pop(context);
            }

            final notif = NotificationService();
            await notif.init();
            await notif.requestPermissions();
            await PrayerScheduleService().refreshSchedulesIfNeeded(force: true);

            if (context.mounted) {
              AppSnackbar.success(
                context,
                'تم تفعيل تنبيهات الأذان والصلوات بنجاح',
                duration: AppMotion.toastShort,
                hasNavBar: true,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildFeatureRow({
    required AppPalette palette,
    required AppTextTheme textTheme,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.xs),
          decoration: BoxDecoration(
            color: palette.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: AppIcon.sm,
            color: palette.primary,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.label.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                desc,
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
