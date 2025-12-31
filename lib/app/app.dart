import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class TalibIlmApp extends StatelessWidget {
  const TalibIlmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'طالب العلم',
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Text(
              'طالب العلم',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
