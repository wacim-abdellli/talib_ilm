import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'utils/ssl_helper_web.dart'
    if (dart.library.io) 'utils/ssl_helper_mobile.dart';

import 'package:quran_library/quran_library.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuranLibrary.init();
  if (kDebugMode) {
    enableBadCertificateCatcher();
  }
  runApp(const TalibIlmApp());
}
