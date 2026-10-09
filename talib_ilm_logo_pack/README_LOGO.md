# Talib Ilm logo pack

Concept: an open book whose gutter is a road of light leading to an 8-point star (the Rub el Hizb motif).
Reads as "من سلك طريقًا يلتمس فيه علمًا": the path itself is the negative space between the two pages.
Built from pure geometry (two mirrored page shapes + one tapered ribbon subtracted from the book), so it stays sharp at any size.
Colours: teal gradient #13857C -> #0A4A45, pages #F8FAFC, star #FBBF24 (matches the Calm Scholar palette).

| File | Use |
|---|---|
| ios_icon_1024.png | iOS / App Store icon (square, no transparency, no rounded corners - iOS rounds it) |
| talib_ilm_icon_rounded.png/.svg | Play Store, README, website, previews |
| android_foreground_432.png + android_background_432.png | Android adaptive icon (symbol sits inside the safe zone) |
| android_monochrome_432.png | Android 13+ themed icon |
| symbol_on_dark / symbol_on_light (.svg/.png) | Symbol only, transparent, for splash / app bar / about screen |
| symbol_mono_white | One-colour symbol (notifications, watermark) |
| lockup_on_dark / lockup_on_light | Symbol + "طالب العلم" wordmark (Amiri Bold, converted to outlines) |

## Flutter setup (flutter_launcher_icons)
Copy the PNGs into `assets/branding/`, then in pubspec.yaml:

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

Then run:  dart run flutter_launcher_icons
(If your installed version rejects adaptive_icon_monochrome, delete that line.)
Also replace assets/images/logo.png (used by the README) with talib_ilm_icon_rounded.png.
