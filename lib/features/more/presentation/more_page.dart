import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/primary_app_bar.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_MoreSection>[
      _MoreSection(
        title: 'الإعدادات',
        subtitle: 'إعدادات عامة للتطبيق.',
        icon: Icons.settings_outlined,
        onTap: () => _showInfo(context, 'سيتم توسيع الإعدادات قريبًا.'),
      ),
      _MoreSection(
        title: 'المظهر',
        subtitle: 'الوضع الداكن والخيارات المستقبلية.',
        icon: Icons.color_lens_outlined,
        onTap: () => _showInfo(context, 'تغيير المظهر قيد الإعداد.'),
      ),
      _MoreSection(
        title: 'اللغة',
        subtitle: 'إدارة اللغة والترجمة لاحقًا.',
        icon: Icons.language_outlined,
        onTap: () => _showInfo(context, 'إدارة اللغة ستتوفر قريبًا.'),
      ),
      _MoreSection(
        title: 'النسخ الاحتياطي والاستعادة',
        subtitle: 'حفظ التقدم واستعادته بسهولة.',
        icon: Icons.backup_outlined,
        onTap: () =>
            _showInfo(context, 'النسخ الاحتياطي قيد الإعداد حاليًا.'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PrimaryAppBar(
        title: 'المزيد',
        showBack: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final section = sections[index];
          return PressableCard(
            onTap: section.onTap,
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: AppText.heading),
                      const SizedBox(height: 4),
                      Text(section.subtitle, style: AppText.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.body),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MoreSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _MoreSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
