import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';

Future<void>? _fontsLoaded;

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
    final loader = FontLoader(entry['family'] as String);
    for (final font in entry['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
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
