import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'utils/ssl_helper_web.dart'
    if (dart.library.io) 'utils/ssl_helper_mobile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    enableBadCertificateCatcher();
  }
  runApp(const TalibIlmApp());
}
