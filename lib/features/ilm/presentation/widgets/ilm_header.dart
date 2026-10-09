import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

class IlmHeader extends StatelessWidget {
  final String dailyMicrocopy;

  const IlmHeader({
    super.key,
    required this.dailyMicrocopy,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          bottom: BorderSide(
            color: palette.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رحلتك العلمية',
            style: context.text.title,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            dailyMicrocopy,
            style: context.text.bodySmall.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
