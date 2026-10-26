import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';

Future<void>? _fontsLoaded;

Future<ByteData> _loadMaterialIconsFont() async {
  final candidates = <String>[];
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    candidates.add(
      '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}'
      'cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
      'material_fonts${Platform.pathSeparator}materialicons-regular.otf',
    );
  }

  var directory = File(Platform.resolvedExecutable).absolute.parent;
  for (var depth = 0; depth < 12; depth++) {
    candidates.add(
      '${directory.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
      'material_fonts${Platform.pathSeparator}materialicons-regular.otf',
    );
    if (directory.parent.path == directory.path) break;
    directory = directory.parent;
  }

  for (final path in candidates) {
    final fontFile = File(path);
    if (await fontFile.exists()) {
      return ByteData.sublistView(await fontFile.readAsBytes());
    }
  }
  throw StateError(
    'MaterialIcons font is unavailable in the Flutter SDK cache; '
    'the golden tests cannot render deterministic icons.',
  );
}

Future<ByteData> _loadFontAsset(String family, String asset) async {
  try {
    return await rootBundle.load(asset);
  } catch (_) {
    if (family != 'MaterialIcons') rethrow;
    // flutter test disables SDK asset fonts, so read the same MaterialIcons
    // font from the Flutter SDK that is running this test process.
    return _loadMaterialIconsFont();
  }
}

Future<void> _loadBundledFonts() async {
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  final families = manifest.cast<Map<String, dynamic>>();
  for (final requiredFamily in ['Cairo', 'Amiri', 'MaterialIcons']) {
    if (!families.any((entry) => entry['family'] == requiredFamily)) {
      throw StateError('Golden font manifest is missing $requiredFamily');
    }
  }
  for (final entry in families) {
    final family = entry['family'] as String;
    final fontData = <ByteData>[];
    for (final font in entry['fonts'] as List<dynamic>) {
      try {
        fontData.add(await _loadFontAsset(family, font['asset'] as String));
      } catch (_) {
        if (!family.startsWith('packages/')) rethrow;
        // Some dependency font manifest entries are not copied into the test
        // asset bundle. Golden fixtures do not rely on those viewers' fonts.
      }
    }
    if (fontData.isNotEmpty) {
      final loader = FontLoader(family);
      for (final data in fontData) {
        loader.addFont(Future.value(data));
      }
      await loader.load();
    }
  }
}

Future<void> ensureBundledFontsLoaded() async {
  return _fontsLoaded ??= _loadBundledFonts();
}

/// Golden test runner helper
Future<void> testGoldenWidget({
  required WidgetTester tester,
  required Widget widget,
  required String fileName,
  bool isDark = false,
  double textScale = 1.0,
  Size surfaceSize = const Size(390, 844),
  Finder? finder,
  bool fullScreen = false,
}) async {
  // Font/asset I/O must finish outside the widget test's fake clock.
  await tester.runAsync(() => _fontsLoaded ??= _loadBundledFonts());
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final theme = isDark ? AppTheme.dark() : AppTheme.light();

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: fullScreen
              ? widget
              : Scaffold(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  body: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: widget,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    ),
  );

  for (final element in find.byType(Image).evaluate()) {
    final img = element.widget as Image;
    await tester.runAsync(() => precacheImage(img.image, element));
  }
  await tester.pumpAndSettle();

  await expectLater(
    finder ??
        (fullScreen
            ? find.byType(widget.runtimeType)
            : (find.byType(Scaffold).evaluate().length > 1
                  ? find.byType(Scaffold).last
                  : find.byType(Scaffold))),
    matchesGoldenFile('$fileName.png'),
  );
}
