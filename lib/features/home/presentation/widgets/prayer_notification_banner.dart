import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/notification_pre_permission_sheet.dart';

/// Dignified, non-intrusive banner on the Home screen alerting the user
/// when prayer notifications and Adhan alarms are disabled.
/// Tapping opens the [NotificationPrePermissionSheet] for a 1-tap activation.
class PrayerNotificationBanner extends StatelessWidget {
  final VoidCallback? onEnabled;

  const PrayerNotificationBanner({
    super.key,
    this.onEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Semantics(
      button: true,
      label: 'تنبيهات الصلاة والأذان متوقفة، اضغط للتفعيل',
      child: Material(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.mdRadius,
        child: InkWell(
          onTap: () async {
            final enabled = await NotificationPrePermissionSheet.show(context);
            if (enabled == true) {
              onEnabled?.call();
            }
          },
          borderRadius: AppRadius.mdRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: palette.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_paused_rounded,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تنبيهات الصلاة والأذان متوقفة',
                        style: textTheme.label.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        'اضغط هنا لتفعيل الأذان والتنبيهات في مواقيتها',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    'تفعيل',
                    style: textTheme.captionBold.copyWith(
                      color: palette.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
