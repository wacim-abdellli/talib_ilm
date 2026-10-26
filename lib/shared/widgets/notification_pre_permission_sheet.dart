import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/prayer_schedule_service.dart';
import 'app_button.dart';
import 'app_sheet.dart';
import 'app_snackbar.dart';

/// Dignified pre-permission explainer sheet prompting the user
/// before requesting system notification and exact alarm permissions.
/// Offers a clear "Not Now" path leaving the app fully usable.
class NotificationPrePermissionSheet extends StatelessWidget {
  final VoidCallback? onAllow;
  final VoidCallback? onDecline;

  const NotificationPrePermissionSheet({
    super.key,
    this.onAllow,
    this.onDecline,
  });

  static const String prefKey = 'has_shown_notification_onboarding';

  /// Checks if the notification pre-permission sheet has been shown before,
  /// and displays it if not yet completed.
  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(prefKey) ?? false;
    if (hasShown) return;

    if (!context.mounted) return;
    await show(context);
  }

  /// Displays the sheet. Returns true if user chose to enable, false if deferred.
  static Future<bool?> show(BuildContext context) {
    return AppSheet.show<bool>(
      context: context,
      builder: (ctx) => NotificationPrePermissionSheet(
        onAllow: () => Navigator.pop(ctx, true),
        onDecline: () => Navigator.pop(ctx, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppSheet(
      titleText: 'تفعيل تنبيهات الأذان والأذكار',
      icon: Icons.notifications_active_rounded,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: AppSpace.xl),
            AppButton(
              label: 'تفعيل التنبيهات الآن',
              icon: Icons.check_circle_rounded,
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(prefKey, true);
                onAllow?.call();

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
            const SizedBox(height: AppSpace.sm),
            AppButton.text(
              label: 'لاحقاً',
              onPressed: () async {
                HapticFeedback.lightImpact();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(prefKey, true);
                onDecline?.call();
              },
            ),
          ],
        ),
      ),
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
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                desc,
                style: textTheme.caption.copyWith(
                  color: palette.textSubtle,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
