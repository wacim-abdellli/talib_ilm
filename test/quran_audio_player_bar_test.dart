import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_audio_player_bar.dart';

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
            body: Align(
              alignment: Alignment.bottomCenter,
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

  group('QuranAudioPlayerBar Tests', () {
    testWidgets('renders all transport controls, title, reciter, timer, and close buttons', (tester) async {
      final service = QuranAudioService();
      service.activeSurahNotifier.value = 1;
      service.activeAyahNotifier.value = 1;
      service.isFullSurahModeNotifier.value = true;

      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioPlayerBar(
            audioService: service,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Surah title and reciter
      expect(find.textContaining('سورة الفاتحة'), findsOneWidget);
      expect(find.textContaining('تلاوة كاملة'), findsOneWidget);

      // Media transport icons
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.replay_10_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.forward_10_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

      // Repeat mode button
      expect(find.byTooltip('تكرار: معطل'), findsOneWidget);

      // Sleep timer and close buttons
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);

      // Speed selector pill
      expect(find.textContaining('1.0x'), findsOneWidget);
    });

    testWidgets('repeat button cycles repeat mode on tap', (tester) async {
      final service = QuranAudioService();
      service.activeSurahNotifier.value = 1;
      service.activeAyahNotifier.value = 1;
      service.setRepeatMode(AudioRepeatMode.none);

      await tester.pumpWidget(
        wrapWithTheme(
          QuranAudioPlayerBar(
            audioService: service,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(service.repeatModeNotifier.value, AudioRepeatMode.none);

      // Tap repeat button -> cycles to infinite
      await tester.tap(find.byTooltip('تكرار: معطل'));
      await tester.pumpAndSettle();
      expect(service.repeatModeNotifier.value, AudioRepeatMode.infinite);
      expect(find.byTooltip('تكرار السورة: مستمر'), findsOneWidget);

      // Tap again -> cycles to repeatOnce
      await tester.tap(find.byTooltip('تكرار السورة: مستمر'));
      await tester.pumpAndSettle();
      expect(service.repeatModeNotifier.value, AudioRepeatMode.repeatOnce);
      expect(find.byTooltip('تكرار السورة: مرة واحدة'), findsOneWidget);

      // Tap again -> cycles to none
      await tester.tap(find.byTooltip('تكرار السورة: مرة واحدة'));
      await tester.pumpAndSettle();
      expect(service.repeatModeNotifier.value, AudioRepeatMode.none);
      expect(find.byTooltip('تكرار: معطل'), findsOneWidget);
    });

    testWidgets('survives text scale 1.0, 1.5, 2.0 without overflow', (tester) async {
      final service = QuranAudioService();
      service.activeSurahNotifier.value = 2; // Al-Baqarah
      service.activeAyahNotifier.value = 255;
      service.isFullSurahModeNotifier.value = true;

      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          wrapWithTheme(
            QuranAudioPlayerBar(
              audioService: service,
              onClose: () {},
            ),
            textScaler: TextScaler.linear(scale),
            width: 360,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at text scale $scale');
      }
    });
  });
}
