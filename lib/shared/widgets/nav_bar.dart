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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSize.navMargin,
        end: AppSize.navMargin,
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
              child: _NavBarItemWidget(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  if (!isSelected) {
                    HapticFeedback.lightImpact();
                    onTap(index);
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItemWidget extends StatefulWidget {
  final NavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItemWidget> createState() => _NavBarItemWidgetState();
}

class _NavBarItemWidgetState extends State<_NavBarItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: AppMotion.base,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(_NavBarItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isSelected = widget.isSelected;
    final item = widget.item;

    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.xlRadius,
          onTap: widget.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSize.tap,
              minWidth: AppSize.tap,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.easeOut,
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.primarySoft
                        : Colors.transparent,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Icon(
                        item.icon,
                        size: AppIcon.lg,
                        color: isSelected
                            ? palette.primary
                            : palette.textSubtle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  item.label,
                  style: (isSelected ? textTheme.captionHeavy : textTheme.caption).copyWith(
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
    );
  }
}
