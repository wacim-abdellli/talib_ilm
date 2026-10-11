import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'utils/ssl_helper_web.dart'
    if (dart.library.io) 'utils/ssl_helper_mobile.dart';

import 'package:quran_library/quran_library.dart';

import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    enableBadCertificateCatcher();
  }
  // Initialize QuranLibrary in the background without blocking initial app frame render
  unawaited(QuranLibrary.init());
  runApp(const TalibIlmApp());
}
