import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_palette.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_downloader.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_frame_merger.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_audio_player_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('QuranAudioPlayerBar Moon Icon & Tap Targets (R62)', () {
    testWidgets('displays bedtime_outlined with AppIcon.md (20dp) when timer is non-chosen / inactive', (tester) async {
      final audioService = QuranAudioService();
      audioService.activeSurahNotifier.value = 69;
      audioService.isPlayingNotifier.value = true;
      audioService.isFullSurahModeNotifier.value = true;
      audioService.setSleepTimer(null);

      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioPlayerBar(
            audioService: audioService,
            onClose: () {},
          ),
        ),
      );
      await tester.pump();

      final moonFinder = find.byIcon(Icons.bedtime_outlined);
      expect(moonFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(moonFinder);
      expect(iconWidget.size, AppIcon.md);
      expect(iconWidget.size, 20.0);
    });

    testWidgets('displays bedtime_rounded with AppIcon.md (20dp) and countdown when timer is active', (tester) async {
      final audioService = QuranAudioService();
      audioService.activeSurahNotifier.value = 69;
      audioService.isPlayingNotifier.value = true;
      audioService.isFullSurahModeNotifier.value = true;
      audioService.setSleepTimer(15);

      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioPlayerBar(
            audioService: audioService,
            onClose: () {},
          ),
        ),
      );
      await tester.pump();

      final moonFinder = find.byIcon(Icons.bedtime_rounded);
      expect(moonFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(moonFinder);
      expect(iconWidget.size, AppIcon.md);
      expect(iconWidget.size, 20.0);

      expect(find.textContaining('15:00'), findsOneWidget);

      // Clean up timer
      audioService.setSleepTimer(null);
      await tester.pump();
    });

    testWidgets('displays "نهاية السورة" with bedtime_rounded when stopAtEnd is active', (tester) async {
      final audioService = QuranAudioService();
      audioService.activeSurahNotifier.value = 69;
      audioService.isPlayingNotifier.value = true;
      audioService.isFullSurahModeNotifier.value = true;
      audioService.setSleepTimer(null, atEndOfSurah: true);

      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioPlayerBar(
            audioService: audioService,
            onClose: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.bedtime_rounded), findsOneWidget);
      expect(find.text('نهاية السورة'), findsOneWidget);

      // Clean up timer
      audioService.setSleepTimer(null);
      await tester.pump();
    });
  });

  group('Full Surah Audio Frame Merger & Storage Path Resolution Tests (R62)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('quran_audio_r62_test');
      QuranAudioDownloader.testBaseDir = tempDir;
    });

    tearDown(() async {
      QuranAudioDownloader.testBaseDir = null;
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('getFullSurahFile resolves standard directory path for verse-by-verse reciter', () async {
      final nasser = QuranReciter.defaultReciters.firstWhere((r) => r.id == 'qatami');
      final surahDir = Directory('${tempDir.path}/${nasser.id}/69');
      await surahDir.create(recursive: true);
      final standardFile = File('${surahDir.path}/full_surah.mp3');
      await standardFile.writeAsBytes(List<int>.filled(20000, 0xEE));

      final resolved = await QuranAudioFrameMerger.getFullSurahFile(69, reciter: nasser);
      expect(resolved.existsSync(), isTrue);
      expect(resolved.path, standardFile.path);
    });

    test('getFullSurahFile resolves backward-compatible padded directory path', () async {
      final nasser = QuranReciter.defaultReciters.firstWhere((r) => r.id == 'qatami');
      final paddedDir = Directory('${tempDir.path}/${nasser.id}/069');
      await paddedDir.create(recursive: true);
      final paddedFile = File('${paddedDir.path}/full_surah.mp3');
      await paddedFile.writeAsBytes(List<int>.filled(20000, 0xEE));

      final resolved = await QuranAudioFrameMerger.getFullSurahFile(69, reciter: nasser);
      expect(resolved.existsSync(), isTrue);
      expect(resolved.path, paddedFile.path);
    });

    test('isFullSurahFileHealthy identifies valid files and rejects truncated files', () async {
      final nasser = QuranReciter.defaultReciters.firstWhere((r) => r.id == 'qatami');
      final surahDir = Directory('${tempDir.path}/${nasser.id}/69');
      await surahDir.create(recursive: true);

      // Truncated file (under min expected for 52 verses)
      final tinyFile = File('${surahDir.path}/full_surah.mp3');
      await tinyFile.writeAsBytes(List<int>.filled(500, 0xFF));
      expect(QuranAudioFrameMerger.isFullSurahFileHealthy(tinyFile, 69, reciter: nasser), isFalse);

      // Healthy full file (proper size without Xing/Info poisoning)
      final healthyBytes = List<int>.filled(52 * 500, 0xFF);
      await tinyFile.writeAsBytes(healthyBytes);
      expect(QuranAudioFrameMerger.isFullSurahFileHealthy(tinyFile, 69, reciter: nasser), isTrue);
    });
  });
}
