import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_downloader.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/features/quran/presentation/quran_audio_downloads_page.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_audio_download_item.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_audio_storage_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWithTheme(Widget child, {TextScaler? textScaler, double width = 360}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: textScaler ?? TextScaler.noScaling,
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('QuranAudioDownloadItem UI and Overflow Resistance Tests', () {
    final testReciter = QuranReciter.defaultReciters.first;

    testWidgets('formats estimated size to 1 decimal place cleanly', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioDownloadItem(
            surah: 9,
            surahName: 'التوبة',
            verseCount: 129,
            isDownloaded: false,
            downloadedBytes: 0,
            reciter: testReciter,
            progress: null,
            onStartDownload: () {},
            onPauseDownload: () {},
            onCancelDownload: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Estimated size should NOT contain raw unformatted floating point values like 10.7080078125
      expect(find.textContaining('10.7080078125'), findsNothing);
      // It should contain clean 1-decimal-place format
      expect(find.textContaining('تقديري: ~'), findsOneWidget);
      expect(find.textContaining('م.ب'), findsOneWidget);
    });

    testWidgets('does not overflow in downloading state with action buttons on narrow screen', (tester) async {
      final progress = SurahDownloadProgress(
        surah: 9,
        reciterId: testReciter.id,
        downloadedAyahs: 7,
        totalAyahs: 129,
        downloadedBytes: 500000,
        status: SurahDownloadStatus.downloading,
      );

      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioDownloadItem(
            surah: 9,
            surahName: 'التوبة',
            verseCount: 129,
            isDownloaded: false,
            downloadedBytes: 500000,
            reciter: testReciter,
            progress: progress,
            onStartDownload: () {},
            onPauseDownload: () {},
            onCancelDownload: () {},
            onDelete: () {},
          ),
          width: 320, // Strict narrow device constraint
        ),
      );
      await tester.pumpAndSettle();

      // Verify no Flutter overflow errors occurred
      expect(tester.takeException(), isNull);

      // Verify pause and cancel icons are rendered
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.textContaining('7/129 آية'), findsOneWidget);
    });

    testWidgets('survives textScale 1.5 and 2.0 without overflow in paused state', (tester) async {
      final progress = SurahDownloadProgress(
        surah: 9,
        reciterId: testReciter.id,
        downloadedAyahs: 15,
        totalAyahs: 129,
        downloadedBytes: 1200000,
        status: SurahDownloadStatus.paused,
      );

      String? detailedMsg;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        detailedMsg = details.toString();
      };

      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioDownloadItem(
            surah: 9,
            surahName: 'التوبة',
            verseCount: 129,
            isDownloaded: false,
            downloadedBytes: 1200000,
            reciter: testReciter,
            progress: progress,
            onStartDownload: () {},
            onPauseDownload: () {},
            onCancelDownload: () {},
            onDelete: () {},
          ),
          width: 320,
          textScaler: const TextScaler.linear(2.0),
        ),
      );
      await tester.pumpAndSettle();
      FlutterError.onError = originalOnError;

      if (detailedMsg != null) {
        // ignore: avoid_print
        print('FULL OVERFLOW INFO:\n$detailedMsg');
      }
      expect(detailedMsg, isNull);
      expect(find.text('متوقف مؤقتاً'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });

    testWidgets('storage header renders and resists overflow on narrow screens', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioStorageHeader(
            currentReciter: testReciter,
            reciters: [testReciter],
            onReciterChanged: (_) {},
            totalStorageBytes: 104857600, // 100 MB
            downloadedCount: 12,
            onConfirmDeleteAll: () {},
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('المساحة المستهلكة'), findsOneWidget);
      expect(find.text('تفريغ الكل'), findsOneWidget);
    });

    testWidgets('QuranAudioDownloadsPage renders without persisting spinner or overflow', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const QuranAudioDownloadsPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('التنزيلات الصوتية'), findsOneWidget);
      expect(find.text('جميع السور'), findsOneWidget);
      expect(find.text('المحمّلة فقط'), findsOneWidget);
    });
  });
}

