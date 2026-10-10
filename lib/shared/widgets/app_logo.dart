import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

/// Available sizes for the canonical [AppLogo]
enum AppLogoSize {
  sm(24.0),
  md(32.0),
  lg(64.0);

  final double dimension;
  const AppLogoSize(this.dimension);
}

/// App logo widget displaying the Obsidian & Gold emblem or lockup.
/// Uses [AppPalette.logoSymbol] or [AppPalette.logoLockup] so it automatically
/// resolves the proper contrast asset according to current theme brightness.
class AppLogo extends StatelessWidget {
  final AppLogoSize size;
  final bool isLockup;

  const AppLogo({
    super.key,
    this.size = AppLogoSize.md,
  }) : isLockup = false;

  const AppLogo.lockup({
    super.key,
    this.size = AppLogoSize.lg,
  }) : isLockup = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final assetPath = isLockup ? palette.logoLockup : palette.logoSymbol;

    return Semantics(
      label: 'طالب العلم',
      image: true,
      child: Image.asset(
        assetPath,
        width: isLockup ? null : size.dimension,
        height: size.dimension,
        fit: BoxFit.contain,
      ),
    );
  }
}
