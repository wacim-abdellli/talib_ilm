import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'constants/app_strings.dart';
import 'theme/app_ui.dart';
import '../shared/navigation/app_shell.dart';
import '../shared/widgets/app_scroll_behavior.dart';
import '../core/services/theme_service.dart';

/// Global theme service instance
final themeService = ThemeService();

class TalibIlmApp extends StatefulWidget {
  const TalibIlmApp({super.key});

  @override
  State<TalibIlmApp> createState() => _TalibIlmAppState();
}

class _TalibIlmAppState extends State<TalibIlmApp> {
  @override
  void initState() {
    super.initState();
    // Load saved theme preference
    themeService.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeService.themeMode,
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
            final sizeScale = (shortestSide / AppUi.textScaleBaseWidth)
                .clamp(AppUi.textScaleMin, AppUi.textScaleMax)
                .toDouble();
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
      },
    );
  }
}
