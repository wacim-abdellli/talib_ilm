import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';

/// Test bench widget for adhan audio playback and notification delivery verification.
///
/// Supports instant testing, 5-second delayed testing (to verify lock screen and
/// background delivery outside the app), and testing all notification modes.
class PrayerNotificationTester extends StatelessWidget {
  final AdhanSettings settings;
  final AdhanService adhanService;

  const PrayerNotificationTester({
    super.key,
    required this.settings,
    required this.adhanService,
  });

  Future<void> _testAudio(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (adhanService.isPlaying) {
      await adhanService.stop();
      return;
    }

    if (settings.defaultMode == PrayerNotificationMode.silent ||
        settings.defaultMode == PrayerNotificationMode.off) {
      AppSnackbar.info(
        context,
        'النمط الافتراضي المحدد حالياً صامت. اختر أذان كامل أو تكبير لسماع الصوت.',
      );
      return;
    }

    final soundToPlay = settings.defaultMode == PrayerNotificationMode.takbeer
        ? AdhanSound.takbeer
        : settings.sound;

    await adhanService.test(soundToPlay, volume: settings.volume);
  }

  Future<void> _sendInstantTest(
    BuildContext context, {
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    required String label,
  }) async {
    HapticFeedback.mediumImpact();
    final notifService = NotificationService();
    await notifService.showInstantTestNotification(
      prayerName: 'العشاء',
      mode: mode,
      sound: sound,
    );
    if (context.mounted) {
      AppSnackbar.success(
        context,
        'تم إرسال إشعار ($label) فوراً! تفقد شريط الإشعارات بالأعلى.',
      );
    }
  }

  Future<void> _sendDelayed5sTest(
    BuildContext context, {
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    required String label,
  }) async {
    HapticFeedback.heavyImpact();
    final notifService = NotificationService();
    await notifService.scheduleTestNotificationAfter(
      seconds: 5,
      prayerName: 'العشاء',
      mode: mode,
      sound: sound,
    );
    if (context.mounted) {
      AppSnackbar.success(
        context,
        '⏳ تم جدولة تنبيه ($label) بعد 5 ثوانٍ! اخرج من التطبيق أو أقفل الشاشة الآن للتجربة.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      color: palette.surfaceRaised,
      border: Border.all(
        color: palette.gold.withValues(alpha: 0.35),
        width: 1.5,
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(
                  Icons.science_rounded,
                  color: palette.gold,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة فحص واختبار التنبيهات والأذان',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: palette.text,
                        fontFamily: AppTextStyles.cairo,
                      ),
                    ),
                    Text(
                      'اختبر سماع الصوت وظهور الإشعار داخل وخارج التطبيق',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: palette.textMuted,
                        fontFamily: AppTextStyles.cairo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: AppSpace.md),

          // ── Audio Preview Row ──
          StreamBuilder<PlayerState>(
            stream: adhanService.playerStateStream,
            builder: (context, _) {
              final isPlaying = adhanService.isPlaying;
              return AppButton.tonal(
                label: isPlaying ? 'إيقاف الصوت الآن' : 'استماع للصوت المحدد',
                icon: isPlaying
                    ? Icons.stop_circle_rounded
                    : Icons.volume_up_rounded,
                onPressed: () => _testAudio(context),
              );
            },
          ),
          const SizedBox(height: AppSpace.sm),

          // ── Primary 2 Actions: Instant & Delayed 5s ──
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'إشعار فوري (الآن)',
                  icon: Icons.notifications_active_rounded,
                  onPressed: () => _sendInstantTest(
                    context,
                    mode: settings.defaultMode,
                    sound: settings.sound,
                    label: 'النمط الحالي',
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: AppButton.tonal(
                  label: 'بعد 5 ثوانٍ (للخروج)',
                  icon: Icons.timer_outlined,
                  onPressed: () => _sendDelayed5sTest(
                    context,
                    mode: settings.defaultMode,
                    sound: settings.sound,
                    label: 'النمط الحالي',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: AppSpace.sm),

          // ── Test All Cases Grid ──
          Text(
            'اختبار كافة الحالات (فوري / خارج التطبيق بعد 5ث):',
            style: AppTextStyles.labelSmall.copyWith(
              color: palette.primary,
              fontFamily: AppTextStyles.cairo,
            ),
          ),
          const SizedBox(height: AppSpace.xs),

          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.mosque_rounded,
            title: 'أذان مكة المكرمة (كامل)',
            mode: PrayerNotificationMode.adhan,
            sound: AdhanSound.makkah,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.location_city_rounded,
            title: 'أذان المدينة المنورة (كامل)',
            mode: PrayerNotificationMode.adhan,
            sound: AdhanSound.madinah,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.campaign_rounded,
            title: 'تكبير وتنبيه موجز',
            mode: PrayerNotificationMode.takbeer,
            sound: AdhanSound.takbeer,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.notifications_none_rounded,
            title: 'نغمة تنبيه هادئة',
            mode: PrayerNotificationMode.tone,
            sound: AdhanSound.makkah,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.notifications_off_outlined,
            title: 'إشعار صامت مرئي',
            mode: PrayerNotificationMode.silent,
            sound: AdhanSound.makkah,
          ),

          const SizedBox(height: AppSpace.xs),
          // Permissions Button
          Center(
            child: TextButton.icon(
              icon: Icon(
                Icons.verified_user_outlined,
                color: palette.primary,
              ),
              label: Text(
                'طلب وتأكيد أذونات الإشعارات والمنبه الدقيق للنظام',
                style: AppTextStyles.labelSmall.copyWith(
                  color: palette.primary,
                  fontFamily: AppTextStyles.cairo,
                ),
              ),
              onPressed: () async {
                HapticFeedback.lightImpact();
                await NotificationService().requestPermissions();
                if (context.mounted) {
                  AppSnackbar.info(
                    context,
                    'تم فحص وطلب أذونات الإشعارات والمنبهات الدقيقة من النظام.',
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCaseRow(
    BuildContext context, {
    required AppPalette palette,
    required IconData icon,
    required String title,
    required PrayerNotificationMode mode,
    required AdhanSound sound,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.primary),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: palette.text,
                  fontFamily: AppTextStyles.cairo,
                ),
              ),
            ),
            InkWell(
              onTap: () => _sendInstantTest(
                context,
                mode: mode,
                sound: sound,
                label: title,
              ),
              borderRadius: AppRadius.smRadius,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  'فوري',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: palette.primary,
                    fontFamily: AppTextStyles.cairo,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            InkWell(
              onTap: () => _sendDelayed5sTest(
                context,
                mode: mode,
                sound: sound,
                label: title,
              ),
              borderRadius: AppRadius.smRadius,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  'بعد 5ث',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: palette.gold,
                    fontFamily: AppTextStyles.cairo,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
