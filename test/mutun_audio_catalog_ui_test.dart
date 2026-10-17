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
      expect(MutunAudioCatalog.hasAudio('bk_jawhar_maknoon'), isTrue);
      expect(MutunAudioCatalog.hasAudio('bk_manzumah_baiquoni'), isTrue);

      final siniUrl = MutunAudioCatalog.getAudioUrl('bk_usul_thalatha', reciterId: 'sini');
      expect(siniUrl, isNotNull);
      expect(siniUrl!, contains('AbdulAzizAsSini'));

      final fallbackUrl = MutunAudioCatalog.getFallbackAudioUrl('bk_usul_thalatha', reciterId: 'sini');
      expect(fallbackUrl, isNotNull);
      expect(fallbackUrl!, contains('06.mp3'));

      final baiquoniReciters = MutunAudioCatalog.getRecitersForBook('bk_manzumah_baiquoni');
      expect(baiquoniReciters.length, greaterThanOrEqualTo(2));
      expect(baiquoniReciters.any((r) => r.id == 'fahad'), isTrue);
      expect(baiquoniReciters.any((r) => r.id == 'sini'), isTrue);
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

    test('MutunAudioService supports Dr. Al-Sini and multiple verified reciters', () {
      final service = MutunAudioService();
      expect(MutunAudioService.availableReciters.length, greaterThanOrEqualTo(2));

      final secondReciter = MutunAudioService.availableReciters[1];
      service.setSelectedReciter(secondReciter);
      expect(service.selectedReciter.id, secondReciter.id);

      final sini = MutunAudioService.availableReciters[0];
      service.setSelectedReciter(sini);
      expect(service.selectedReciter.id, 'sini');
    });

    test('Nawaqid Al-Islam has verified Al-Qasim CDN primary and fallback audio', () {
      final primary = MutunAudioCatalog.getAudioUrl('bk_nawaqid_islam', reciterId: 'sini');
      expect(primary, isNotNull);
      expect(primary, contains('files.a-alqasim.com'));
      expect(primary, contains('0203NawaaqidAlIslaam_AbdulAzizAsSini.mp3'));

      final fallback = MutunAudioCatalog.getFallbackAudioUrl('bk_nawaqid_islam', reciterId: 'sini');
      expect(fallback, isNotNull);
      expect(fallback, contains('04.mp3'));
    });

    test('Every book in MutunAudioCatalog has verified audio source and reciter', () {
      const bookIds = [
        'bk_adhkar_adab',
        'bk_nawaqid_islam',
        'bk_qawaid_arba',
        'bk_usul_thalatha',
        'bk_arbaeen_nawawi',
        'bk_tuhfat_atfal',
        'bk_shuroot_salah',
        'bk_kitab_tawheed',
        'bk_kashf_shubuhat',
        'bk_manzumah_baiquoni',
        'bk_manzumah_albiri',
        'bk_ajrumiyyah',
        'bk_wasitiyyah',
        'bk_waraqat',
        'bk_unwan_al_hukm',
        'bk_rahibiyyah',
        'bk_aqidah_tahawiyyah',
        'bk_bulugh_maram',
        'bk_zad_mustaqni',
        'bk_jawhar_maknoon',
        'bk_nokhbat_al_fikar',
        'bk_alfiyyah_ibn_malik',
        'bk_shatibiyyah',
        'bk_umdat_ahkam',
        'bk_qawaid_fiqhiyya',
        'bk_lamiyyat_al_afal',
      ];

      for (final id in bookIds) {
        expect(MutunAudioCatalog.hasAudio(id), isTrue, reason: 'Missing audio for $id');
        final reciters = MutunAudioCatalog.getRecitersForBook(id);
        expect(reciters, isNotEmpty, reason: 'No reciters found for $id');
        final url = MutunAudioCatalog.getAudioUrl(id, reciterId: reciters.first.id);
        expect(url, isNotNull, reason: 'Null audioUrl for $id');
        expect(url!.startsWith('https://'), isTrue, reason: 'Invalid URL scheme for $id: $url');
      }
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
