import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget>? actions;
  final EdgeInsetsGeometry contentPadding;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.actions,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpace.xl,
      vertical: AppSpace.md,
    ),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: context.palette.brandDark.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          child: builder(dialogContext),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.xxl,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.xlRadius,
          border: Border.all(color: palette.border),
          boxShadow: palette.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.xl,
                AppSpace.xl,
                AppSpace.xl,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (iconColor ?? palette.primary).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (iconColor ?? palette.primary).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor ?? palette.primary,
                        size: AppIcon.sm,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: contentPadding,
              child: content,
            ),

            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              Divider(height: 1, thickness: 1, color: palette.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
