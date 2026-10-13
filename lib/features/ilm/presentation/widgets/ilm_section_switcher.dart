import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

enum IlmSection {
  mutun,
  shamela,
}

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
        color: palette.surfaceRaised,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildItem(
              context: context,
              section: IlmSection.mutun,
              title: 'متون المنهج',
              icon: Icons.school_rounded,
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
              title: 'خزانة التراث',
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
            height: AppSize.tap,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? palette.primary : Colors.transparent,
              borderRadius: AppRadius.pillRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: AppIcon.sm,
                  color: isSelected ? palette.brandDark : palette.textMuted,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  title,
                  style: textTheme.caption.copyWith(
                    color: isSelected ? palette.brandDark : palette.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
