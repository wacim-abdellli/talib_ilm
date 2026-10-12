import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app/app.dart';
import 'utils/ssl_helper_web.dart'
    if (dart.library.io) 'utils/ssl_helper_mobile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    enableBadCertificateCatcher();
  }
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.talib_ilm.channel.audio',
      androidNotificationChannelName: 'تلاوة القرآن الكريم',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground init warning: $e');
  }
  runApp(const TalibIlmApp());
}
