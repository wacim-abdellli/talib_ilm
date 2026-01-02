import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../shared/widgets/app_overflow_menu.dart';
import '../../../shared/widgets/pressable_card.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_LibrarySection>[
      _LibrarySection(
        title: 'كل ملفات المتون',
        subtitle: 'تصفح جميع ملفات PDF للمتون.',
        icon: Icons.picture_as_pdf_outlined,
        onTap: () {},
      ),
      _LibrarySection(
        title: 'كل الشروح',
        subtitle: 'الشروح المرتبطة بالكتب.',
        icon: Icons.menu_book_outlined,
        onTap: () {},
      ),
      _LibrarySection(
        title: 'الصفحات المحفوظة',
        subtitle: 'العودة لأهم الصفحات بسرعة.',
        icon: Icons.bookmark_outline,
        onTap: () {},
      ),
      _LibrarySection(
        title: 'الفيديوهات المحملة',
        subtitle: 'عرض المقاطع المتاحة دون اتصال.',
        icon: Icons.download_outlined,
        onTap: () {},
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المكتبة', style: AppText.headingXL),
        actions: const [AppOverflowMenu()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final section = sections[index];
          return PressableCard(
            onTap: section.onTap,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(section.icon,
                    color: AppColors.textPrimary.withValues(alpha: 0.8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: AppText.heading),
                      const SizedBox(height: 4),
                      Text(
                        section.subtitle,
                        style: AppText.bodyMuted,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, color: AppColors.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LibrarySection {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _LibrarySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
