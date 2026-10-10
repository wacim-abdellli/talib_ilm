import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';

/// Golden test runner helper
Future<void> testGoldenWidget({
  required WidgetTester tester,
  required Widget widget,
  required String fileName,
  bool isDark = false,
  double textScale = 1.0,
  Size surfaceSize = const Size(390, 844),
  Finder? finder,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);

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
          child: Scaffold(
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
    finder ?? (find.byType(Scaffold).evaluate().length > 1
        ? find.byType(Scaffold).last
        : find.byType(Scaffold)),
    matchesGoldenFile('$fileName.png'),
  );
}
