import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/reader_theme.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_categories_catalog.dart';
import 'package:talib_ilm/features/ilm/data/services/mutun_audio_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/mutun_rosette_icon.dart';

void main() {
  group('Mutun Catalog & Theme Tests', () {
    test('MutunCategoriesCatalog contains all expected categories and items', () {
      expect(MutunCategoriesCatalog.categories.isNotEmpty, isTrue);

      final aqidah = MutunCategoriesCatalog.categories
          .firstWhere((c) => c.id == 'aqidah');
      expect(aqidah.items.any((i) => i.id == 'bk_nawaqid_islam'), isTrue);
      expect(aqidah.items.any((i) => i.id == 'bk_usul_thalatha'), isTrue);

      final nawaqid = MutunCategoriesCatalog.getItemById('bk_nawaqid_islam');
      expect(nawaqid, isNotNull);
      expect(nawaqid!.audioUrlSini, contains('AbdulAzizAsSini'));
      expect(nawaqid.pdfPath, isNotNull);
    });

    test('MutunThemeColors provides high-contrast tokens in light and dark modes', () {
      final lightTokens = MutunThemeColors.getTokens(isDark: false);
      expect(lightTokens.headerBrown, isNotNull);
      expect(lightTokens.rosetteGold, isNotNull);
      expect(lightTokens.activeParagraphBg, isNotNull);

      final darkTokens = MutunThemeColors.getTokens(isDark: true);
      expect(darkTokens.headerBrown, isNotNull);
      expect(darkTokens.rosetteGold, isNotNull);
      expect(darkTokens.activeParagraphBg, isNotNull);
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
