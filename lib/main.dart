import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/local_diagnostics_service.dart';
import 'core/services/notification_service.dart';
import 'app/theme/app_colors.dart';
import 'features/ilm/data/services/quiz_dump_service.dart';
import 'features/quran/data/services/removed_riwayah_cleanup.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('TalibIlm FlutterError: ${details.exception}');
    LocalDiagnosticsService().record(
      category: 'flutter_error',
      severity: 'error',
      message: details.exceptionAsString(),
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('TalibIlm PlatformError: $error\n$stack');
    LocalDiagnosticsService().record(
      category: 'platform_error',
      severity: 'error',
      message: 'Uncaught platform error',
      error: error,
      stackTrace: stack,
    );
    return true; // Prevents app crash
  };

  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    LocalDiagnosticsService().record(
      category: 'widget_error',
      severity: 'error',
      message: details.exceptionAsString(),
      stackTrace: details.stack,
    );
    return const SizedBox.shrink();
  };

  unawaited(SharedPreferences.getInstance());
  unawaited(LocalDiagnosticsService().loadEvents());
  unawaited(RemovedRiwayahCleanup.run());
  await HomeWidgetService.initBackground();
  unawaited(NotificationService().init());
  unawaited(QuizDumpService.instance.loadDump());

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.talibilm.app.channel.audio',
      androidNotificationChannelName: 'تلاوة القرآن الكريم والإذاعة',
      androidNotificationChannelDescription:
          'مشغل تلاوات القرآن الكريم وإذاعة طالب العلم',
      notificationColor: AppColors.notificationAccent,
      androidNotificationOngoing: false,
      androidNotificationIcon: 'drawable/ic_notification',
      androidStopForegroundOnPause: true,
      preloadArtwork: true,
      fastForwardInterval: AppMotion.networkRetry,
      rewindInterval: AppMotion.networkRetry,
    );
  } catch (e, stack) {
    debugPrint('JustAudioBackground init warning: $e');
    LocalDiagnosticsService().record(
      category: 'audio_init',
      severity: 'warn',
      message: 'JustAudioBackground init fallback',
      error: e,
      stackTrace: stack,
    );
  }
  runApp(const TalibIlmApp());
}
