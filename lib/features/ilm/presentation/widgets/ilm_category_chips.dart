import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';

class IlmCategoryChipItem {
  final String id;
  final String label;
  final IconData icon;

  const IlmCategoryChipItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class IlmCategoryChips extends StatelessWidget {
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const IlmCategoryChips({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  static const List<IlmCategoryChipItem> categories = [
    IlmCategoryChipItem(
      id: 'all',
      label: 'الكل',
      icon: Icons.dashboard_outlined,
    ),
    IlmCategoryChipItem(
      id: 'quiz',
      label: 'المسابقات والاختبارات',
      icon: Icons.emoji_events_outlined,
    ),
    IlmCategoryChipItem(
      id: 'mutun',
      label: 'متون طالب العلم',
      icon: Icons.menu_book_rounded,
    ),
    IlmCategoryChipItem(
      id: 'aqidah',
      label: 'العقيدة والتوحيد',
      icon: Icons.shield_outlined,
    ),
    IlmCategoryChipItem(
      id: 'hadith',
      label: 'الحديث الشريف',
      icon: Icons.format_quote_rounded,
    ),
    IlmCategoryChipItem(
      id: 'fiqh',
      label: 'الفقه وأصوله',
      icon: Icons.balance_rounded,
    ),
    IlmCategoryChipItem(
      id: 'adab',
      label: 'الآداب والأذكار',
      icon: Icons.favorite_border_rounded,
    ),
    IlmCategoryChipItem(
      id: 'tafsir',
      label: 'التفسير وعلومه',
      icon: Icons.auto_stories_outlined,
    ),
    IlmCategoryChipItem(
      id: 'seerah',
      label: 'السيرة والتاريخ',
      icon: Icons.history_edu_rounded,
    ),
    IlmCategoryChipItem(
      id: 'arabic',
      label: 'اللغة العربية',
      icon: Icons.edit_note_rounded,
    ),
    IlmCategoryChipItem(
      id: 'shamela',
      label: 'المكتبة الشاملة',
      icon: Icons.collections_bookmark_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: AppSize.tap,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpace.xs),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = selectedCategoryId == cat.id;

            return Semantics(
              button: true,
              selected: isSelected,
              label: 'قسم ${cat.label}',
              child: Material(
                color: isSelected ? palette.primary : palette.surfaceRaised,
                borderRadius: AppRadius.pillRadius,
                child: InkWell(
                  borderRadius: AppRadius.pillRadius,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCategorySelected(cat.id);
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: AppSize.tap),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: isSelected ? palette.primary : palette.border,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: AppIcon.sm,
                          color: isSelected
                              ? palette.onPrimary
                              : palette.textMuted,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          cat.label,
                          style: textTheme.caption.copyWith(
                            color: isSelected
                                ? palette.onPrimary
                                : palette.text,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
