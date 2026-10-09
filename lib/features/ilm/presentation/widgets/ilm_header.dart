import 'package:flutter/material.dart';

import '../../../../app/theme/theme_colors.dart';
import '../../../../core/utils/responsive.dart';

class IlmHeader extends StatelessWidget {
  final String dailyMicrocopy;

  const IlmHeader({
    super.key,
    required this.dailyMicrocopy,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
        vertical: responsive.hp(2),
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.outlineVariantColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رحلتك العلمية',
            style: TextStyle(
              fontSize: responsive.sp(26),
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dailyMicrocopy,
            style: TextStyle(
              fontSize: responsive.sp(14),
              color: context.textSecondaryColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
