import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'constants/app_strings.dart';
import 'theme/app_palette.dart';
import '../features/splash/presentation/splash_page.dart';
import '../shared/widgets/app_scroll_behavior.dart';
import '../core/services/theme_service.dart';

/// Global theme service instance
final themeService = ThemeService();

/// Global root navigator key for deep links, notification taps, and top-level navigation
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
          navigatorKey: rootNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          themeAnimationDuration: AppMotion.zero,
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
            final sizeScale = (shortestSide / AppSize.textScaleBaseWidth)
                .clamp(AppSize.textScaleMin, AppSize.textScaleMax)
                .toDouble();
            final baseScale = mediaQuery.textScaler.scale(1.0);
            final scaled = TextScaler.linear(
              (baseScale * sizeScale).clamp(
                AppSize.textScaleMin,
                AppSize.textScaleMax,
              ),
            );

            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: scaled),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) {
                    final currentFocus = FocusManager.instance.primaryFocus;
                    if (currentFocus != null && currentFocus.hasFocus) {
                      currentFocus.unfocus();
                    }
                  },
                  child: child!,
                ),
              ),
            );
          },
          home: const SplashPage(),
        );
      },
    );
  }
}
