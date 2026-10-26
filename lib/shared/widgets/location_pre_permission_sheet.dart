import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';
import 'app_button.dart';
import 'app_sheet.dart';

/// Pre-permission explainer sheet shown before the OS location permission dialog.
/// Explains why GPS is requested (astronomical prayer calculations and Qibla),
/// provides local-first privacy assurances, and offers a graceful "Not Now" deferral
/// leaving the app 100% usable with default or manual city coordinates.
class LocationPrePermissionSheet extends StatelessWidget {
  final VoidCallback? onAllow;
  final VoidCallback? onDecline;
  final VoidCallback? onManualSelect;

  const LocationPrePermissionSheet({
    super.key,
    this.onAllow,
    this.onDecline,
    this.onManualSelect,
  });

  /// Displays the sheet. Returns true if user chose to allow, false if deferred.
  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onManualSelect,
  }) {
    return AppSheet.show<bool>(
      context: context,
      builder: (ctx) => LocationPrePermissionSheet(
        onAllow: () => Navigator.pop(ctx, true),
        onDecline: () => Navigator.pop(ctx, false),
        onManualSelect: onManualSelect != null
            ? () {
                Navigator.pop(ctx, null);
                onManualSelect();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppSheet(
      titleText: 'تحديد الموقع لمواقيت الصلاة والقبلة',
      icon: Icons.location_on_rounded,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'لحساب مواقيت الصلاة بدقة تامة وتحديد اتجاه القبلة، نلتمس إذن الوصول إلى موقع هاتفك الجغرافي:',
              style: textTheme.body.copyWith(
                color: palette.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _buildFeatureRow(
              palette: palette,
              textTheme: textTheme,
              icon: Icons.access_time_filled_rounded,
              title: 'حساب مواقيت الصلاة بدقة',
              desc: 'حساب أوقات الصلوات الخمس بدقة فلكية تامة وفق إحداثيات موقعك الفعلي',
            ),
            const SizedBox(height: AppSpace.sm),
            _buildFeatureRow(
              palette: palette,
              textTheme: textTheme,
              icon: Icons.explore_rounded,
              title: 'توجيه بوصلة القبلة',
              desc: 'تحديد اتجاه الكعبة المشرفة وحساب المسافة بدقة نحو مكة المكرمة',
            ),
            const SizedBox(height: AppSpace.sm),
            _buildFeatureRow(
              palette: palette,
              textTheme: textTheme,
              icon: Icons.security_rounded,
              title: 'خصوصية تامة وأمان',
              desc: 'تُجرى الحسابات محلياً 100% على هاتفك، ولا يتم إرسال أو تتبع موقعك',
            ),
            const SizedBox(height: AppSpace.xl),
            AppButton(
              label: 'السماح بالوصول للموقع',
              icon: Icons.check_circle_rounded,
              onPressed: () {
                HapticFeedback.mediumImpact();
                onAllow?.call();
              },
            ),
            const SizedBox(height: AppSpace.sm),
            if (onManualSelect != null) ...[
              AppButton.text(
                label: 'اختيار المدينة يدوياً من القائمة',
                icon: Icons.location_city_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onManualSelect?.call();
                },
              ),
              const SizedBox(height: AppSpace.xs),
            ],
            AppButton.text(
              label: 'لاحقاً (الاعتماد على مكة المكرمة)',
              onPressed: () {
                HapticFeedback.lightImpact();
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
