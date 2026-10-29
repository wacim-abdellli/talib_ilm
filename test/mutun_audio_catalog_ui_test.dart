import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/app/theme/reader_theme.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/audio/mutun_syllabus_audio_entries.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/audio/turath_books_audio_entries.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_audio_catalog.dart';
import 'package:talib_ilm/features/ilm/data/services/mutun_audio_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/book_audio_sheets.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/mutun_audio_player_hud.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/mutun_rosette_icon.dart';

Widget _wrapRtlTestApp(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    builder: (context, inner) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: inner ?? const SizedBox.shrink(),
        ),
      );
    },
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Mutun Catalog & Theme Tests', () {
    test('MutunAudioCatalog contains authentic audio for syllabus mutun', () {
      expect(MutunAudioCatalog.hasAudio('bk_usul_thalatha'), isTrue);
      expect(MutunAudioCatalog.hasAudio('bk_qawaid_arba'), isTrue);
      expect(MutunAudioCatalog.hasAudio('bk_kitab_tawheed'), isTrue);
      expect(MutunAudioCatalog.hasAudio('bk_jawhar_maknoon'), isTrue);
      expect(MutunAudioCatalog.hasAudio('bk_manzumah_baiquoni'), isTrue);
      expect(MutunAudioCatalog.hasAudio('bk_jazariyyah'), isTrue);

      final siniUrl =
          MutunAudioCatalog.getAudioUrl('bk_usul_thalatha', reciterId: 'sini');
      expect(siniUrl, isNotNull);
      expect(siniUrl!, contains('AbdulAzizAsSini'));

      final fallbackUrl = MutunAudioCatalog.getFallbackAudioUrl(
        'bk_usul_thalatha',
        reciterId: 'sini',
      );
      expect(fallbackUrl, isNotNull);
      expect(fallbackUrl!, contains('06.mp3'));

      final baiquoniReciters =
          MutunAudioCatalog.getRecitersForBook('bk_manzumah_baiquoni');
      expect(baiquoniReciters.length, greaterThanOrEqualTo(3));
      expect(baiquoniReciters.any((r) => r.id == 'fahad'), isTrue);
      expect(baiquoniReciters.any((r) => r.id == 'shaydzmi'), isTrue);
      expect(baiquoniReciters.any((r) => r.id == 'sini'), isTrue);
    });

    test('HalibaAudiobooksCatalog registers all 36 studio CloudFront audiobooks', () {
      expect(HalibaAudiobooksCatalog.items.length, 36);
      for (final item in HalibaAudiobooksCatalog.items.values) {
        expect(
          item.cloudFrontUrl.startsWith('https://d3ctxlq1ktw2nl.cloudfront.net/'),
          isTrue,
          reason: 'Invalid CloudFront URL for ${item.id}',
        );
        expect(
          item.anchorFallbackUrl.startsWith('https://anchor.fm/'),
          isTrue,
          reason: 'Invalid Anchor fallback URL for ${item.id}',
        );
      }
    });

    test('Multi-reciter & multi-chapter coverage across Mutun and Shamela Heritage', () {
      final multiReciterMutunCount = MutunSyllabusAudioEntries
          .canonicalEntries.values
          .where((e) => e.sources.length >= 2)
          .length;
      expect(multiReciterMutunCount, greaterThanOrEqualTo(20));

      expect(
        MutunAudioCatalog.getRecitersForBook('bk_tuhfat_atfal').length,
        greaterThanOrEqualTo(6),
      );
      expect(
        MutunAudioCatalog.getRecitersForBook('bk_arbaeen_nawawi')
            .map((r) => r.id),
        containsAll(<String>['haliba', 'wazzan', 'shaydzmi', 'sini']),
      );
      expect(
        MutunAudioCatalog.getChapters('bk_zad_mustaqni', reciterId: 'shaydzmi')
            ?.length,
        30,
      );
      expect(
        MutunAudioCatalog.getChapters('bk_bulugh_maram', reciterId: 'shaydzmi')
            ?.length,
        20,
      );
      expect(
        MutunAudioCatalog.getChapters('bk_shatibiyyah', reciterId: 'afasy')
            ?.length,
        78,
      );
      expect(
        MutunAudioCatalog.getChapters(
          'bk_alfiyyah_ibn_malik',
          reciterId: 'ayouni',
        )?.length,
        85,
      );

      // Shamela Heritage books coverage (expanded to 50+ books)
      final allShamelaIds = <int>{
        ...TurathBooksAudioEntries.shamelaToSyllabusAliases.keys,
        ...MutunAudioCatalog.entries.keys
            .where((k) => k.startsWith('shamela_'))
            .map((k) => int.parse(k.substring('shamela_'.length))),
      };
      expect(allShamelaIds.length, greaterThanOrEqualTo(50));
      for (final id in allShamelaIds) {
        expect(
          MutunAudioCatalog.hasShamelaAudio(id),
          isTrue,
          reason: 'Missing Shamela audio resolution for $id',
        );
      }

      // Specific multi-chapter heritage masterpieces
      expect(
        MutunAudioCatalog.getChapters('shamela_42', reciterId: 'khazaen')
            ?.length,
        114,
      );
      expect(
        MutunAudioCatalog.getChapters('shamela_12014', reciterId: 'duraihim')
            ?.length,
        372,
      );
      expect(
        MutunAudioCatalog.getChapters('shamela_735', reciterId: 'sunnahMasmuah')
            ?.length,
        94,
      );
      expect(
        MutunAudioCatalog.getChapters('shamela_20854', reciterId: 'shulaimi')
            ?.length,
        16,
      );
      // Khalid Al-Shulaimi promoted to primary reciter on shamela_20854
      expect(
        MutunAudioCatalog.getShamelaEntry(20854)?.sources.first.reciter.id,
        'shulaimi',
      );
    });

    test('Dual reading and scholarly sharh commentary editions are supported', () {
      final usulEntry = MutunAudioCatalog.getEntry('bk_usul_thalatha')!;
      expect(usulEntry.hasReading, isTrue);
      expect(usulEntry.hasSharh, isTrue);
      expect(usulEntry.readingSources.length, greaterThanOrEqualTo(2));
      expect(usulEntry.sharhSources.length, greaterThanOrEqualTo(2));
      expect(usulEntry.sharhSources.any((s) => s.reciter.id == 'fawzan'), isTrue);
      expect(usulEntry.sharhSources.any((s) => s.reciter.id == 'uthaymin'), isTrue);

      final tawheedEntry = MutunAudioCatalog.getEntry('bk_kitab_tawheed')!;
      expect(tawheedEntry.hasReading, isTrue);
      expect(tawheedEntry.hasSharh, isTrue);
      expect(tawheedEntry.sharhSources.any((s) => s.reciter.id == 'uthaymin'), isTrue);

      final arbaeenEntry = MutunAudioCatalog.getEntry('bk_arbaeen_nawawi')!;
      expect(arbaeenEntry.hasReading, isTrue);
      expect(arbaeenEntry.hasSharh, isTrue);
      expect(arbaeenEntry.sharhSources.any((s) => s.reciter.id == 'badr'), isTrue);

      // Sahih Muslim & Muwatta heritage editions
      final muslimEntry = MutunAudioCatalog.getShamelaEntry(1727)!;
      expect(muslimEntry.sources.length, greaterThanOrEqualTo(2));
      expect(muslimEntry.sources.any((s) => s.reciter.id == 'sunnah_masmuah'), isTrue);
      expect(muslimEntry.sources.any((s) => s.reciter.id == 'basati'), isTrue);

      // Shamail with 4 reciters incl Haliba
      final shamailEntry = MutunAudioCatalog.getShamelaEntry(13037)!;
      expect(shamailEntry.sources.length, 4);
      expect(shamailEntry.sources.any((s) => s.reciter.id == 'haliba'), isTrue);
    });

    test('Every entry in MutunAudioCatalog has unique reciter IDs and HTTPS URLs', () {
      for (final entry in MutunAudioCatalog.entries.values) {
        expect(entry.sources, isNotEmpty, reason: 'Empty sources for ${entry.bookId}');
        final seenReciters = <String>{};
        for (final src in entry.sources) {
          expect(
            seenReciters.add(src.reciter.id),
            isTrue,
            reason: 'Duplicate reciter ${src.reciter.id} in ${entry.bookId}',
          );
          expect(
            src.audioUrl.startsWith('https://'),
            isTrue,
            reason: 'Non-HTTPS audioUrl in ${entry.bookId}/${src.reciter.id}',
          );
          if (src.audioUrl.contains('files.a-alqasim.com')) {
            expect(
              src.fallbackUrl != null && src.fallbackUrl!.startsWith('https://'),
              isTrue,
              reason: 'Missing HTTPS fallback for files.a-alqasim.com in ${entry.bookId}',
            );
          }
          if (src.chapters != null) {
            for (final ch in src.chapters!) {
              expect(
                ch.audioUrl.startsWith('https://'),
                isTrue,
                reason: 'Non-HTTPS chapter URL in ${entry.bookId} ch ${ch.index}',
              );
            }
          }
        }
      }
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

      service.setSpeed(1.0);
      expect(service.speedNotifier.value, 1.0);
      service.cycleSpeed();
      expect(service.speedNotifier.value, 1.25);

      service.setRepeatMode(MutunRepeatMode.none);
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
      expect(MutunAudioService.availableReciters.length, greaterThanOrEqualTo(6));

      final secondReciter = MutunAudioService.availableReciters[1];
      service.setSelectedReciter(secondReciter);
      expect(service.selectedReciter.id, secondReciter.id);

      final sini = MutunAudioService.availableReciters[0];
      service.setSelectedReciter(sini);
      expect(service.selectedReciter.id, 'sini');
    });

    test('Nawaqid Al-Islam has verified Al-Qasim CDN primary and fallback audio', () {
      final primary =
          MutunAudioCatalog.getAudioUrl('bk_nawaqid_islam', reciterId: 'sini');
      expect(primary, isNotNull);
      expect(primary, contains('files.a-alqasim.com'));
      expect(primary, contains('0203NawaaqidAlIslaam_AbdulAzizAsSini.mp3'));

      final fallback = MutunAudioCatalog.getFallbackAudioUrl(
        'bk_nawaqid_islam',
        reciterId: 'sini',
      );
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

  group('Audio HUD, Sheets & Accessibility Scaling Tests', () {
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

    for (final scale in <double>[1.0, 1.5, 2.0]) {
      testWidgets(
        'MutunAudioPlayerHud renders multi-reciter & multi-chapter strip without overflow at ${scale}x',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final service = MutunAudioService();
          service.setSelectedReciter(
            MutunReciterDefaults.shaydzmi,
            forBookId: 'bk_zad_mustaqni',
          );

          await tester.pumpWidget(
            _wrapRtlTestApp(
              Align(
                alignment: Alignment.bottomCenter,
                child: MutunAudioPlayerHud(
                  audioService: service,
                  bookId: 'bk_zad_mustaqni',
                  onOpenQuickJump: () {},
                  onClose: () {},
                ),
              ),
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.textContaining('1/30'), findsOneWidget);
          expect(find.byTooltip('المقطع السابق'), findsOneWidget);
          expect(find.byTooltip('المقطع التالي'), findsOneWidget);
        },
      );

      testWidgets(
        'BookReciterPickerSheet & BookAudioChaptersSheet survive ${scale}x scaling without overflow',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final service = MutunAudioService();
          service.setSelectedReciter(
            MutunReciterDefaults.khazaen,
            forBookId: 'shamela_42',
          );

          await tester.pumpWidget(
            _wrapRtlTestApp(
              BookReciterPickerSheet(
                audioService: service,
                bookId: 'bk_zad_mustaqni',
              ),
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('30 مقطعاً'), findsOneWidget);

          await tester.pumpWidget(
            _wrapRtlTestApp(
              BookAudioChaptersSheet(
                audioService: service,
                bookId: 'shamela_42',
              ),
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('سورة الفاتحة'), findsOneWidget);

          // Verify chapter search filtering
          await tester.enterText(find.byType(TextField), 'الكهف');
          await tester.pumpAndSettle();
          expect(find.text('سورة الكهف'), findsOneWidget);
        },
      );
    }
  });
}
