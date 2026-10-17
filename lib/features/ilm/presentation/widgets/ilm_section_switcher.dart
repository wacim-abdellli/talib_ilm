import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

enum IlmSection { mutun, shamela }

class IlmSectionSwitcher extends StatelessWidget {
  final IlmSection selectedSection;
  final ValueChanged<IlmSection> onSectionChanged;

  const IlmSectionSwitcher({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xs,
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildItem(
              context: context,
              section: IlmSection.mutun,
              title: 'المتون العلمية',
              icon: Icons.menu_book_rounded,
              isSelected: selectedSection == IlmSection.mutun,
              palette: palette,
              textTheme: textTheme,
            ),
          ),
          const SizedBox(width: AppSpace.xxs),
          Expanded(
            child: _buildItem(
              context: context,
              section: IlmSection.shamela,
              title: 'المكتبة الشاملة',
              icon: Icons.auto_stories_rounded,
              isSelected: selectedSection == IlmSection.shamela,
              palette: palette,
              textTheme: textTheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IlmSection section,
    required String title,
    required IconData icon,
    required bool isSelected,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            onSectionChanged(section);
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.easeOut,
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xs,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? palette.surfaceRaised : Colors.transparent,
              borderRadius: AppRadius.pillRadius,
              boxShadow: isSelected ? palette.shadow : const [],
              border: isSelected
                  ? Border.all(color: palette.border.withValues(alpha: 0.8))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppIcon.sm,
                  color: isSelected ? palette.primary : palette.textSubtle,
                ),
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  child: Text(
                    title,
                    style: textTheme.caption.copyWith(
                      color: isSelected ? palette.text : palette.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
