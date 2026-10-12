import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

/// Atomic, BiDi-safe Quranic Ayah Number Badge.
///
/// Guarantees:
/// - Ornate Quranic brackets ﴿ ﴾ NEVER split across line breaks
/// - RTL-correct orientation: ﴿ on right, western digits in center, ﴾ on left
/// - Uses semantic tokens without raw TextStyle or hardcoded colors
class AyahNumberBadge extends StatelessWidget {
  final int ayahNumber;
  final Color color;
  final double fontSize;

  const AyahNumberBadge({
    super.key,
    required this.ayahNumber,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '﴿',
              style: textTheme.sacredLarge.copyWith(
                color: color,
                fontSize: fontSize,
                height: 1.0,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xxs,
              ),
              child: Text(
                '$ayahNumber',
                style: textTheme.caption.copyWith(
                  color: color,
                  fontSize: fontSize * 0.76,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            Text(
              '﴾',
              style: textTheme.sacredLarge.copyWith(
                color: color,
                fontSize: fontSize,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
