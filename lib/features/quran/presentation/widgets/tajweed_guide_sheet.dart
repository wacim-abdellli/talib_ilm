import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';

/// Authentic Medina Mushaf Tajweed Color Legend Guide Sheet.
/// Matches the official King Fahd Complex printing standards.
class TajweedGuideSheet extends StatelessWidget {
  const TajweedGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppSheet.show<void>(
      context: context,
      builder: (_) => const TajweedGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppSheet(
        titleText: 'دليل ألوان التجويد',
        icon: Icons.menu_book_rounded,
        showCloseButton: true,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpace.sm,
            end: AppSpace.sm,
            bottom: AppSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'رموز الألوان المعتمدة في مصحف المدينة النبوية لضبط أحكام التلاوة والتجويد:',
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpace.md),

              _buildGuideCard(
                palette: palette,
                textTheme: textTheme,
                color: TajweedPalette.madd,
                title: 'المدود الطويلة (4 إلى 6 حركات)',
                description:
                    'المد اللازم (6 حركات)، والمد المتصل والمنفصل والصلة الكبرى (4 أو 5 حركات).',
                example: '﴿الضَّآلِّينَ﴾ • ﴿جَآءَ﴾ • ﴿بِمَآ أُنزِلَ﴾',
              ),
              const SizedBox(height: AppSpace.sm),

              _buildGuideCard(
                palette: palette,
                textTheme: textTheme,
                color: TajweedPalette.maddShort,
                title: 'مد حركتان (طبيعي / صلة صغرى)',
                description:
                    'المد الطبيعي الأصلي، ومد البدل، ومد العِوَض، وصلة هاء الضمير الصغرى.',
                example: '﴿قَالُواْ﴾ • ﴿ءَامَنُواْ﴾ • ﴿عَلِيمًا حَكِيمًا﴾',
              ),
              const SizedBox(height: AppSpace.sm),

              _buildGuideCard(
                palette: palette,
                textTheme: textTheme,
                color: TajweedPalette.ikhfaa,
                title: 'الغنة والإخفاء والإدغام بغنة',
                description:
                    'النون والميم المشددتان، الإخفاء الحقيقي والشفوي، والإدغام بغنة (ينمو).',
                example: '﴿مِن قَبْلِ﴾ • ﴿كُنتُمْ﴾ • ﴿مَن يَقُولُ﴾',
              ),
              const SizedBox(height: AppSpace.sm),

              _buildGuideCard(
                palette: palette,
                textTheme: textTheme,
                color: TajweedPalette.qalqalah,
                title: 'القلقلة وتفخيم الحروف',
                description:
                    'اضطراب المخرج عند النطق بحروف القلقلة ساكنة (ق، ط، ب، ج، د)، وتفخيم الراء واللام.',
                example: '﴿الفَلَقِ﴾ • ﴿مُحِيطٌ﴾ • ﴿أَبْوَٰبٌ﴾ • ﴿يَجْعَلْ﴾',
              ),
              const SizedBox(height: AppSpace.sm),

              _buildGuideCard(
                palette: palette,
                textTheme: textTheme,
                color: TajweedPalette.silent,
                title: 'أحرف لا تُلفظ (تُكتب ولا تُنطق)',
                description:
                    'همزة الوصل في درج الكلام، اللام الشمسية المدغمة، والألف الفارقة بعد واو الجماعة.',
                example: '﴿وَٱسْتَغْفِرْ﴾ • ﴿وَٱلشَّمْسِ﴾ • ﴿عَمِلُواْ﴾',
              ),
              const SizedBox(height: AppSpace.lg),

              AppButton(
                label: 'إغلاق الدليل',
                variant: AppButtonVariant.tonal,
                size: AppButtonSize.md,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required AppPalette palette,
    required AppTextTheme textTheme,
    required Color color,
    required String title,
    required String description,
    required String example,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: palette.border,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            description,
            style: textTheme.caption.copyWith(
              color: palette.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xxs,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.smRadius,
            ),
            child: Text(
              example,
              style: textTheme.mushafChrome.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
