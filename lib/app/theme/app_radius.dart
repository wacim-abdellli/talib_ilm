import 'app_palette.dart';

export 'app_palette.dart';

/// Legacy radius & icon size shim.
/// @Deprecated: Use [AppRadius] and [AppIcon] instead.
@Deprecated('Use AppRadius and AppIcon instead')
class AppIconSize {
  AppIconSize._();

  static const double hero = AppIcon.hero;
  static const double tile = AppIcon.xl;
  static const double badge = AppIcon.md;
  static const double indicator = AppIcon.sm;

  static const double xs = AppIcon.sm;
  static const double sm = AppIcon.sm;
  static const double md = AppIcon.md;
  static const double lg = AppIcon.lg;
  static const double xl = AppIcon.xl;
}
