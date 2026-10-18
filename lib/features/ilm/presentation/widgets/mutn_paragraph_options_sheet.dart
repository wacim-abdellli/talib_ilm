import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/catalogs/mutun_curriculum_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/services/mutun_audio_service.dart';

/// Bottom modal sheet for scholarly options on an individual paragraph:
/// recitation playback from paragraph, clipboard copying, typography customization, and note-taking.
class MutnParagraphOptionsSheet extends StatelessWidget {
  final MutunParagraph paragraph;
  final IlmBook book;
  final MutunAudioService audioService;
  final VoidCallback onAddNote;
  final VoidCallback onOpenTypography;
  final void Function(int paragraphIndex) onPlayFromParagraph;

  const MutnParagraphOptionsSheet({
    super.key,
    required this.paragraph,
    required this.book,
    required this.audioService,
    required this.onAddNote,
    required this.onOpenTypography,
    required this.onPlayFromParagraph,
  });

  static Future<void> show({
    required BuildContext context,
    required MutunParagraph paragraph,
    required IlmBook book,
    required MutunAudioService audioService,
    required VoidCallback onAddNote,
    required VoidCallback onOpenTypography,
    required void Function(int paragraphIndex) onPlayFromParagraph,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MutnParagraphOptionsSheet(
        paragraph: paragraph,
        book: book,
        audioService: audioService,
        onAddNote: onAddNote,
        onOpenTypography: onOpenTypography,
        onPlayFromParagraph: onPlayFromParagraph,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.sheetTopRadius,
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.textMuted.withValues(alpha: 0.3),
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'خيارات الفقرة - ${paragraph.index} -',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              ListTile(
                leading: Icon(
                  Icons.play_circle_fill_rounded,
                  color: tokens.rosetteGold,
                ),
                title: const Text('تشغيل التلاوة من هذه الفقرة'),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onPlayFromParagraph(paragraph.index);
                },
              ),
              ListTile(
                leading: Icon(Icons.copy_rounded, color: palette.text),
                title: const Text('نسخ نص الفقرة'),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: paragraph.text));
                  Navigator.of(context).pop();
                  AppSnackbar.success(context, 'تم نسخ الفقرة بنجاح');
                },
              ),
              ListTile(
                leading: Icon(Icons.format_size_rounded, color: palette.text),
                title: const Text('تنسيق الخط والمظهر'),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenTypography();
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_note_rounded, color: palette.text),
                title: const Text('إضافة ملاحظة حول الفقرة'),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onAddNote();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
