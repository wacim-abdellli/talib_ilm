import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';

/// Clean confirmation dialog for deleting Quran audio files
class QuranAudioDeleteDialog extends StatelessWidget {
  final String title;
  final String content;

  const QuranAudioDeleteDialog({
    super.key,
    required this.title,
    required this.content,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => QuranAudioDeleteDialog(title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      title: Text(
        title,
        style: textTheme.titleSmall.copyWith(
          color: palette.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: textTheme.body.copyWith(color: palette.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'إلغاء',
            style: textTheme.label.copyWith(color: palette.textMuted),
          ),
        ),
        AppButton(
          label: 'حذف',
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

