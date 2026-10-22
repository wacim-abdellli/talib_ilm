import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/notification_service.dart';
import 'features/ilm/data/services/quiz_dump_service.dart';
import 'utils/ssl_helper_web.dart'
    if (dart.library.io) 'utils/ssl_helper_mobile.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('TalibIlm FlutterError: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('TalibIlm PlatformError: $error\n$stack');
    return true; // Prevents app crash
  };

  unawaited(SharedPreferences.getInstance());
  unawaited(HomeWidgetService.initBackground());
  unawaited(NotificationService().init());
  unawaited(QuizDumpService.instance.loadDump());
  if (kDebugMode) {
    enableBadCertificateCatcher();
  }
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.talib_ilm.channel.audio',
      androidNotificationChannelName: 'تلاوة القرآن الكريم والإذاعة',
      androidNotificationOngoing: false,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidStopForegroundOnPause: true,
      preloadArtwork: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground init warning: $e');
  }
  runApp(const TalibIlmApp());
}
