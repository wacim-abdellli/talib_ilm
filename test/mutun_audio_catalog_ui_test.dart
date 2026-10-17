import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/reader_theme.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_audio_catalog.dart';
import 'package:talib_ilm/features/ilm/data/services/mutun_audio_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/mutun_rosette_icon.dart';

void main() {
  group('Mutun Catalog & Theme Tests', () {
    test('MutunAudioCatalog contains authentic audio for syllabus mutun', () {
      expect(MutunAudioCatalog.hasAudio('bk_usul_thalatha'), isTrue);
      expect(MutunAudioCatalog.hasAudio('bk_qawaid_arba'), isTrue);
      expect(MutunAudioCatalog.hasAudio('bk_kitab_tawheed'), isTrue);

      final siniUrl = MutunAudioCatalog.getAudioUrl('bk_usul_thalatha', reciterId: 'sini');
      expect(siniUrl, isNotNull);
      expect(siniUrl!, contains('AbdulAzizAsSini'));

      final tayyibUrl = MutunAudioCatalog.getAudioUrl('bk_usul_thalatha', reciterId: 'tayyib');
      expect(tayyibUrl, isNotNull);
      expect(tayyibUrl!, contains('MuadhAlTayyib'));
    });

    test('MutunThemeColors provides high-contrast tokens in light and dark modes', () {
      final lightTokens = MutunThemeColors.getTokens(isDark: false);
      expect(lightTokens.rosetteGold, isNotNull);
      expect(lightTokens.activeParagraphBg, isNotNull);
      expect(lightTokens.cardBg, isNotNull);

      final darkTokens = MutunThemeColors.getTokens(isDark: true);
      expect(darkTokens.rosetteGold, isNotNull);
      expect(darkTokens.activeParagraphBg, isNotNull);
      expect(darkTokens.cardBg, isNotNull);
    });
  });

  group('Mutun Audio Service Tests', () {
    test('MutunAudioService cycles speed and toggles repeat mode correctly', () {
      final service = MutunAudioService();

      expect(service.speedNotifier.value, 1.0);
      service.cycleSpeed();
      expect(service.speedNotifier.value, 1.25);

      expect(service.repeatModeNotifier.value, MutunRepeatMode.none);
      service.toggleRepeatMode();
      expect(service.repeatModeNotifier.value, MutunRepeatMode.singleParagraph);
      service.toggleRepeatMode();
      expect(service.repeatModeNotifier.value, MutunRepeatMode.entireMatn);
      service.toggleRepeatMode();
      expect(service.repeatModeNotifier.value, MutunRepeatMode.none);
    });

    test('MutunAudioService supports Dr. Al-Sini and Sheikh Al-Tayyib', () {
      final service = MutunAudioService();
      expect(MutunAudioService.availableReciters.length, 2);

      final tayyib = MutunAudioService.availableReciters[1];
      service.setSelectedReciter(tayyib);
      expect(service.selectedReciter.id, 'tayyib');

      final sini = MutunAudioService.availableReciters[0];
      service.setSelectedReciter(sini);
      expect(service.selectedReciter.id, 'sini');
    });
  });

  group('MutunRosetteIcon Widget Tests', () {
    testWidgets('MutunRosetteIcon paints properly without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MutunRosetteIcon(size: 32),
            ),
          ),
        ),
      );

      expect(find.byType(MutunRosetteIcon), findsOneWidget);
    });
  });
}
