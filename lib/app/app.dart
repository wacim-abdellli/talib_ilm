import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import '../shared/navigation/app_shell.dart';
import '../shared/widgets/app_scroll_behavior.dart';

class TalibIlmApp extends StatelessWidget {
  const TalibIlmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'طالب العلم',
      theme: AppTheme.dark(),
      scrollBehavior: const AppScrollBehavior(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final shortestSide = mediaQuery.size.shortestSide;
        final sizeScale =
            (shortestSide / 360).clamp(0.95, 1.2).toDouble();
        final baseScale = mediaQuery.textScaler.scale(1.0);
        final scaled = TextScaler.linear(baseScale * sizeScale);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: scaled),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
      home: const AppShell(),
    );
  }
}
