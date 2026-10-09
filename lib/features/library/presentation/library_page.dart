import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final levels = <LibraryLevel>[
      LibraryLevel(
        title: 'طالب العلم',
        icon: Icons.school_outlined,
        onTap: () {},
      ),
      LibraryLevel(
        title: 'المستوى التمهيدي',
        icon: Icons.layers_outlined,
        onTap: () {},
      ),
      LibraryLevel(
        title: 'المستوى الأول',
        icon: Icons.looks_one_outlined,
        onTap: () {},
      ),
      LibraryLevel(
        title: 'المستوى الثاني',
        icon: Icons.looks_two_outlined,
        onTap: () {},
      ),
      LibraryLevel(
        title: 'المستوى الثالث',
        icon: Icons.looks_3_outlined,
        onTap: () {},
      ),
    ];

    return Scaffold(
      backgroundColor: palette.bg,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.xl,
              AppSpace.xl,
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
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppSize.tap,
                        height: AppSize.tap,
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(
                            color: palette.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.library_books_rounded,
                          color: palette.primary,
                          size: AppIcon.lg,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المكتبة',
                              style: textTheme.title.copyWith(
                                color: palette.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'تصفح كتب العلم الشرعي',
                              style: textTheme.bodySmall.copyWith(
                                color: palette.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.search_rounded,
                        tooltip: 'بحث',
                        color: palette.textMuted,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: palette.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: palette.textSubtle,
                          size: AppIcon.md,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            'ابحث في الكتب والشروحات...',
                            style: textTheme.bodySmall.copyWith(
                              color: palette.textSubtle,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.lg,
              ),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: levels.length + 1,
              separatorBuilder: (context, index) {
                if (index >= levels.length) return const SizedBox.shrink();
                return const SizedBox(height: AppSpace.md);
              },
              itemBuilder: (context, index) {
                if (index == levels.length) {
                  return SizedBox(height: AppSize.navClearance(context));
                }
                return _LibraryLevelCard(levels[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryLevelCard extends StatelessWidget {
  final LibraryLevel level;

  const _LibraryLevelCard(this.level);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      onTap: level.onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          Container(
            width: AppSize.tap,
            height: AppSize.tap,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: palette.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              level.icon,
              color: palette.primary,
              size: AppIcon.lg,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              level.title,
              style: textTheme.titleSmall.copyWith(
                color: palette.text,
              ),
            ),
          ),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: AppIcon.sm,
            color: palette.textMuted,
          ),
        ],
      ),
    );
  }
}

class LibraryLevel {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const LibraryLevel({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
