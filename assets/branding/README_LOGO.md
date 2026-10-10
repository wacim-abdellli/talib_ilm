# Talib Ilm logo pack: Obsidian & Gold

Concept: the 8-point Islamic star (Rub el Hizb, two squares) with an open book at its heart.
Flat, geometric, no gradients, so it stays sharp from 24px up.

## Brand colours
| Name | Hex | Use |
|---|---|---|
| Obsidian | #0A0A0C | icon background, dark surfaces |
| Ivory | #F4EFE6 | the star, text on dark, light-mode background |
| Gold | #E3B341 | the book (on dark) |
| Ink | #14130F | the star and text on light |
| Deep Gold | #B8841F | the book on light backgrounds |

## Files
| File | Use |
|---|---|
| ios_icon_1024.png | iOS / App Store (square, no transparency; iOS rounds it) |
| icon_dark_rounded.png/.svg | MAIN icon: Play Store, README, website |
| icon_light_rounded.png/.svg | Alternate light icon |
| android_foreground_432.png + android_background_432.png | Android adaptive icon (star inside the 66% safe zone) |
| android_monochrome_432.png | Android 13+ themed icon |
| symbol_on_dark / symbol_on_light (.svg/.png) | Transparent symbol for splash, app bar, About |
| symbol_mono_white | One-colour symbol (notifications, watermark) |
| lockup_on_dark / lockup_on_light | Symbol + "طالب العلم" (Vazirmatn Bold, outlined) |

## Flutter setup (flutter_launcher_icons)
Copy the PNGs to assets/branding/, then in pubspec.yaml:

    dev_dependencies:
      flutter_launcher_icons: ^0.14.0

    flutter_launcher_icons:
      android: true
      ios: true
      image_path: "assets/branding/ios_icon_1024.png"
      remove_alpha_ios: true
      adaptive_icon_background: "assets/branding/android_background_432.png"
      adaptive_icon_foreground: "assets/branding/android_foreground_432.png"
      adaptive_icon_monochrome: "assets/branding/android_monochrome_432.png"

Run: dart run flutter_launcher_icons   (if your version rejects adaptive_icon_monochrome, delete that line)
Replace assets/images/logo.png with icon_dark_rounded.png.
