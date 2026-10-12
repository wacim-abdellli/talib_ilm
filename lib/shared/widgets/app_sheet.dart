import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';
import 'app_button.dart';

class AppSheet extends StatelessWidget {
  final Widget child;
  final Widget? title;
  final String? titleText;
  final IconData? icon;
  final bool showHandle;
  final bool showCloseButton;
  final EdgeInsetsGeometry padding;

  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.titleText,
    this.icon,
    this.showHandle = true,
    this.showCloseButton = false,
    this.padding = const EdgeInsets.all(AppSpace.xl),
  });

  /// Opens a modal bottom sheet with modern luxury styling,
  /// automatic height adaptation (no arbitrary 3/4 screen stretching),
  /// keyboard avoidance, and safe area protection.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    double maxHeightFactor = 0.90,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: context.palette.brandDark.withValues(alpha: 0.55),
      builder: (ctx) {
        final keyboardBottom = MediaQuery.of(ctx).viewInsets.bottom;
        final maxH = MediaQuery.sizeOf(ctx).height * maxHeightFactor;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardBottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SafeArea(
              top: false,
              child: builder(ctx),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border(
          top: BorderSide(color: palette.border, width: 1),
          left: BorderSide(color: palette.border, width: 1),
          right: BorderSide(color: palette.border, width: 1),
        ),
        boxShadow: palette.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          if (showHandle) ...[
            Center(
              child: Container(
                margin: const EdgeInsets.only(
                  top: AppSpace.md,
                  bottom: AppSpace.sm,
                ),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
          ],

          // Title / Header
          if (titleText != null || title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppIcon.md, color: palette.primary),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  Expanded(
                    child: title ??
                        Text(
                          titleText!,
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                  if (showCloseButton)
                    AppIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'إغلاق',
                      color: palette.textMuted,
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: palette.border),
          ],

          // Body
          Flexible(
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
