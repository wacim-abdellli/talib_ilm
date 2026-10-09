import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_palette.dart';

class NavBarItem {
  final IconData icon;
  final String label;

  const NavBarItem({required this.icon, required this.label});
}

class NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  const NavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSize.navMargin,
        right: AppSize.navMargin,
        bottom: bottomInset > 0 ? bottomInset : AppSpace.sm,
      ),
      child: Container(
        height: AppSize.navH,
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.xlRadius,
          border: Border.all(color: palette.border, width: 1),
          boxShadow: palette.shadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return Expanded(
              child: Semantics(
                label: item.label,
                selected: isSelected,
                button: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppRadius.xlRadius,
                    onTap: () {
                      if (!isSelected) {
                        HapticFeedback.lightImpact();
                        onTap(index);
                      }
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSize.tap,
                        minWidth: AppSize.tap,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.primarySoft
                                  : Colors.transparent,
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Center(
                              child: Icon(
                                item.icon,
                                size: AppIcon.lg,
                                color: isSelected
                                    ? palette.primary
                                    : palette.textSubtle,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: textTheme.caption.copyWith(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? palette.primary
                                  : palette.textSubtle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
