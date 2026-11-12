import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';

/// Calm inline notice shown on iOS when the signing profile strips
/// App Groups & shared Keychain capabilities (e.g. free personal sideloading).
class IosWidgetSyncNotice extends StatelessWidget {
  const IosWidgetSyncNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      color: palette.surfaceMuted,
      border: Border.all(color: palette.border),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.widgets_rounded,
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
                  'أداة الشاشة الرئيسية (iOS)',
                  style: textTheme.labelBold.copyWith(color: palette.text),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  'في هذه النسخة، تتبع الأداة موقع الآيفون ومظهر النظام تلقائياً حسب قيود شهادة التثبيت (App Groups).',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'لتثبيت المظهر الفاتح أو الداكن: اضغط مطولاً على الأداة في الشاشة الرئيسية ← «تعديل الأداة» ← «المظهر».',
                  style: textTheme.caption.copyWith(color: palette.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

