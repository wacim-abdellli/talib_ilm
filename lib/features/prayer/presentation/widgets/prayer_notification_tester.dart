import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';

/// Test bench widget for adhan audio playback and notification delivery verification.
///
/// Supports instant testing, 5-second delayed testing (to verify lock screen and
/// background delivery outside the app), prayer-specific announcements, and all muezzins.
class PrayerNotificationTester extends StatefulWidget {
  final AdhanSettings settings;
  final AdhanService adhanService;

  const PrayerNotificationTester({
    super.key,
    required this.settings,
    required this.adhanService,
  });

  @override
  State<PrayerNotificationTester> createState() =>
      _PrayerNotificationTesterState();
}

class _PrayerNotificationTesterState extends State<PrayerNotificationTester> {
  String _selectedPrayer = 'العشاء';

  Future<void> _testAudio({
    required AdhanSound sound,
    String? prayerName,
  }) async {
    HapticFeedback.lightImpact();
    if (widget.adhanService.isPlaying) {
      await widget.adhanService.stop();
      return;
    }

    if (widget.settings.defaultMode == PrayerNotificationMode.silent ||
        widget.settings.defaultMode == PrayerNotificationMode.off) {
      AppSnackbar.info(
        context,
        'النمط الافتراضي المحدد حالياً صامت. اختر أذان كامل أو تكبير لسماع الصوت.',
      );
      return;
    }

    await widget.adhanService.test(
      sound,
      volume: widget.settings.volume,
      prayerName: prayerName,
    );
  }

  Future<void> _sendInstantTest({
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    required String label,
    required String prayerName,
  }) async {
    HapticFeedback.mediumImpact();
    final notifService = NotificationService();
    await notifService.showInstantTestNotification(
      prayerName: prayerName,
      mode: mode,
      sound: sound,
    );
    if (mounted) {
      AppSnackbar.success(
        context,
        'تم إرسال إشعار ($label) لصلاة $prayerName فوراً! تفقد شريط الإشعارات بالأعلى.',
      );
    }
  }

  Future<void> _sendDelayed5sTest({
    required PrayerNotificationMode mode,
    required AdhanSound sound,
    required String label,
    required String prayerName,
  }) async {
    HapticFeedback.heavyImpact();
    final notifService = NotificationService();
    await notifService.scheduleTestNotificationAfter(
      seconds: 5,
      prayerName: prayerName,
      mode: mode,
      sound: sound,
    );
    if (mounted) {
      AppSnackbar.success(
        context,
        '⏳ تم جدولة تنبيه ($label) لصلاة $prayerName بعد 5 ثوانٍ! اخرج من التطبيق أو أقفل الشاشة الآن للتجربة.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final isTakbeer =
        widget.settings.defaultMode == PrayerNotificationMode.takbeer;
    final soundToPlay = isTakbeer ? AdhanSound.takbeer : widget.settings.sound;

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
          const SizedBox(height: AppSpace.sm),

          // ── Prayer Selector for Test ──
          Text(
            'اختر الصلاة لاختبار نداء دخول وقتها:',
            style: textTheme.caption.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: AppStrings.prayerOrder.map((prayer) {
              final isSelected = _selectedPrayer == prayer;
              return ChoiceChip(
                label: Text(prayer),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedPrayer = prayer);
                  }
                },
                selectedColor: palette.primarySoft,
                backgroundColor: palette.surface,
                labelStyle: textTheme.caption.copyWith(
                  color: isSelected ? palette.primary : palette.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.smRadius,
                  side: BorderSide(
                    color: isSelected ? palette.primary : palette.border,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpace.md),

          // ── Audio Preview Row ──
          StreamBuilder<PlayerState>(
            stream: widget.adhanService.playerStateStream,
            builder: (context, _) {
              final isPlaying = widget.adhanService.isPlaying;
              final previewLabel = isPlaying
                  ? 'إيقاف الصوت الآن'
                  : (isTakbeer
                      ? 'استماع لتنبيه صلاة $_selectedPrayer'
                      : 'استماع لصوت المؤذن المحدد');
              return AppButton.tonal(
                label: previewLabel,
                icon: isPlaying
                    ? Icons.stop_circle_rounded
                    : Icons.volume_up_rounded,
                onPressed: () => _testAudio(
                  sound: soundToPlay,
                  prayerName: _selectedPrayer,
                ),
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
                    mode: widget.settings.defaultMode,
                    sound: widget.settings.sound,
                    label: 'النمط الحالي',
                    prayerName: _selectedPrayer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: AppButton.tonal(
                  label: 'بعد 5 ثوانٍ (للخروج)',
                  icon: Icons.timer_outlined,
                  onPressed: () => _sendDelayed5sTest(
                    mode: widget.settings.defaultMode,
                    sound: widget.settings.sound,
                    label: 'النمط الحالي',
                    prayerName: _selectedPrayer,
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
            'اختبار الأصوات المتاحة (استماع / فوري / بعد 5ث):',
            style: AppTextStyles.labelSmall.copyWith(
              color: palette.primary,
              fontFamily: AppTextStyles.cairo,
            ),
          ),
          const SizedBox(height: AppSpace.xs),

          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.campaign_rounded,
            title: 'تكبير وتنبيه: حانت صلاة العشاء',
            mode: PrayerNotificationMode.takbeer,
            sound: AdhanSound.takbeer,
            prayerName: 'العشاء',
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.campaign_rounded,
            title: 'تكبير وتنبيه: حانت صلاة الفجر',
            mode: PrayerNotificationMode.takbeer,
            sound: AdhanSound.takbeer,
            prayerName: 'الفجر',
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.mosque_rounded,
            title: 'أذان مكة (الشيخ علي ملا)',
            mode: PrayerNotificationMode.adhan,
            sound: AdhanSound.makkah,
            prayerName: _selectedPrayer,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.location_city_rounded,
            title: 'أذان المسجد النبوي الشريف',
            mode: PrayerNotificationMode.adhan,
            sound: AdhanSound.madinah,
            prayerName: _selectedPrayer,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.record_voice_over_rounded,
            title: 'أذان الشيخ مشاري العفاسي',
            mode: PrayerNotificationMode.adhan,
            sound: AdhanSound.alafasy,
            prayerName: _selectedPrayer,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.record_voice_over_rounded,
            title: 'أذان الشيخ عبد الباسط',
            mode: PrayerNotificationMode.adhan,
            sound: AdhanSound.abdulbasit,
            prayerName: _selectedPrayer,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.record_voice_over_rounded,
            title: 'أذان الشيخ ناصر القطامي',
            mode: PrayerNotificationMode.adhan,
            sound: AdhanSound.qatami,
            prayerName: _selectedPrayer,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.notifications_none_rounded,
            title: 'نغمة تنبيه هادئة',
            mode: PrayerNotificationMode.tone,
            sound: AdhanSound.makkah,
            prayerName: _selectedPrayer,
          ),
          _buildTestCaseRow(
            context,
            palette: palette,
            icon: Icons.notifications_off_outlined,
            title: 'إشعار صامت مرئي',
            mode: PrayerNotificationMode.silent,
            sound: AdhanSound.makkah,
            prayerName: _selectedPrayer,
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
    required String prayerName,
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
            // Preview Audio Button
            if (mode != PrayerNotificationMode.silent &&
                mode != PrayerNotificationMode.tone) ...[
              InkWell(
                onTap: () => _testAudio(sound: sound, prayerName: prayerName),
                borderRadius: AppRadius.smRadius,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: palette.primary),
                      const SizedBox(width: AppSpace.xxs),
                      Text(
                        'سماع',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: palette.text,
                          fontFamily: AppTextStyles.cairo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
            ],
            InkWell(
              onTap: () => _sendInstantTest(
                mode: mode,
                sound: sound,
                label: title,
                prayerName: prayerName,
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
                mode: mode,
                sound: sound,
                label: title,
                prayerName: prayerName,
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
