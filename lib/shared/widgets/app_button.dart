import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_palette.dart';

enum AppButtonVariant { primary, tonal, outline, text }

enum AppButtonSize { sm, md }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.width,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.width,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.width,
  }) : variant = AppButtonVariant.text;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _pressed = true);
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  void _onTapCancel() {
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = palette.primary;
        fg = palette.onPrimary;
        break;
      case AppButtonVariant.tonal:
        bg = palette.primarySoft;
        fg = palette.onPrimarySoft;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = palette.text;
        border = Border.all(color: palette.border, width: 1);
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = palette.primary;
        break;
    }

    final visualH = widget.size == AppButtonSize.sm ? 40.0 : AppSize.buttonH;
    final content = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.38,
        duration: AppMotion.fast,
        child: Container(
          height: visualH,
          width: widget.width,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.mdRadius,
            border: border,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.mdRadius,
              onTapDown: isEnabled ? _onTapDown : null,
              onTapUp: isEnabled ? _onTapUp : null,
              onTapCancel: isEnabled ? _onTapCancel : null,
              onTap: isEnabled
                  ? () {
                      if (widget.variant == AppButtonVariant.primary) {
                        HapticFeedback.lightImpact();
                      }
                      widget.onPressed?.call();
                    }
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size == AppButtonSize.sm
                      ? AppSpace.md
                      : AppSpace.lg,
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: AppIcon.sm,
                          height: AppIcon.sm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(fg),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, size: AppIcon.md, color: fg),
                              SizedBox(width: AppSpace.sm),
                            ],
                            Text(
                              widget.label,
                              style: textTheme.label.copyWith(color: fg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Guaranteed minimum 48x48 hit target
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSize.tap,
        minWidth: AppSize.tap,
      ),
      child: Center(child: content),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.iconSize = AppIcon.lg,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final effectiveColor = color ?? palette.text;
    final isEnabled = onPressed != null;

    return Semantics(
      label: tooltip,
      button: true,
      enabled: isEnabled,
      child: Tooltip(
        message: tooltip,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSize.tap,
            minHeight: AppSize.tap,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: onPressed,
              radius: 24,
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.38,
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: effectiveColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
