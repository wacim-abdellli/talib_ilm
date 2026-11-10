import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/features/quran/presentation/quran_audio_downloads_page.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_audio_delete_dialog.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_audio_download_item.dart';
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
          child: child,
        ),
      ),
    );
  }

  group('QuranAudioDownloadsPage In-App Player & Actions Tests', () {
    testWidgets('hides player bar when no active surah and displays player bar when active', (tester) async {
      final audioService = QuranAudioService();
      audioService.activeSurahNotifier.value = null;

      await tester.pumpWidget(wrapWithTheme(const QuranAudioDownloadsPage()));
      await tester.pump();

      // Initially inactive -> player bar is absent
      expect(find.byType(QuranAudioPlayerBar), findsNothing);

      // Audio starts playing Surah 61 (الصف)
      audioService.activeSurahNotifier.value = 61;
      audioService.isPlayingNotifier.value = true;
      audioService.isFullSurahModeNotifier.value = true;

      await tester.pump();

      // Now player bar appears smoothly with all its controls
      expect(find.byType(QuranAudioPlayerBar), findsOneWidget);
      expect(find.textContaining('سورة الصف'), findsWidgets);

      // Stop audio -> player bar disappears
      audioService.activeSurahNotifier.value = null;
      await tester.pump();

      expect(find.byType(QuranAudioPlayerBar), findsNothing);
    });

    testWidgets('QuranAudioDownloadItem shows play button when downloaded and onPlay is set', (tester) async {
      bool playTapped = false;
      final reciter = QuranAudioService.reciters.first;

      await tester.pumpWidget(
        wrapWithTheme(
          Scaffold(
            body: QuranAudioDownloadItem(
              surah: 61,
              surahName: 'الصف',
              verseCount: 14,
              isDownloaded: true,
              downloadedBytes: 6000000,
              reciter: reciter,
              progress: null,
              isPlaying: false,
              onPlay: () => playTapped = true,
              onStartDownload: () {},
              onPauseDownload: () {},
              onCancelDownload: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byTooltip('تشغيل السورة'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);

      await tester.tap(find.byTooltip('تشغيل السورة'));
      expect(playTapped, isTrue);
    });

    testWidgets('QuranAudioDeleteDialog renders properly and responds to cancel and confirm', (tester) async {
      bool? result;

      await tester.pumpWidget(
        wrapWithTheme(
          Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await QuranAudioDeleteDialog.show(
                      context,
                      title: 'حذف تلاوة سورة الصف',
                      content: 'هل أنت متأكد من الحذف؟',
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('حذف تلاوة سورة الصف'), findsOneWidget);
      expect(find.text('هل أنت متأكد من الحذف؟'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('حذف'), findsOneWidget);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}

