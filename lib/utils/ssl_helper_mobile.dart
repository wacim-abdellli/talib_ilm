import 'dart:io';
import 'package:flutter/foundation.dart';

/// SSL Helper to bypass certificate errors in Debug Mode (Emulator fix)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void enableBadCertificateCatcher() {
  if (kDebugMode) {
    debugPrint('SSL helper: Bypassing SSL validation for Emulator');
    HttpOverrides.global = MyHttpOverrides();
  }
}
