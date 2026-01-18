import 'dart:io';

void enableBadCertificateCatcher() {
  print('Enabling bad certificate catcher for mobile...');
  HttpOverrides.global = _MyHttpOverrides();
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
