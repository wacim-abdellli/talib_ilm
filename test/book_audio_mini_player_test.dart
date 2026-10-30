import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_audio_catalog.dart';
import 'package:talib_ilm/features/ilm/data/services/mutun_audio_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/book_audio_mini_player.dart';

Widget _wrapTestApp(Widget child, {double textScale = 1.0}) {
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
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = MutunAudioService();
    service.activeBookIdNotifier.value = null;
    service.isPlayingNotifier.value = false;
    service.isLoadingNotifier.value = false;
    service.positionNotifier.value = Duration.zero;
    service.durationNotifier.value = Duration.zero;
  });

  group('BookAudioMiniPlayer Tests', () {
    testWidgets('Renders SizedBox.shrink when no audio is active', (tester) async {
      await tester.pumpWidget(_wrapTestApp(const BookAudioMiniPlayer()));
      await tester.pump();

      expect(find.byType(InkWell), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('Renders book title, reciter and controls when active', (tester) async {
      final service = MutunAudioService();
      service.activeBookIdNotifier.value = 'shamela_1727';
      service.isPlayingNotifier.value = true;
      service.durationNotifier.value = const Duration(minutes: 45);
      service.positionNotifier.value = const Duration(minutes: 10);

      await tester.pumpWidget(_wrapTestApp(const BookAudioMiniPlayer()));
      await tester.pump();

      expect(find.byType(BookAudioMiniPlayer), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.textContaining('مسلم'), findsOneWidget);
    });

    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('Survives textScale ${scale}x without pixel overflow on 360x800', (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final service = MutunAudioService();
        service.activeBookIdNotifier.value = 'shamela_1727';
        service.isPlayingNotifier.value = true;
        service.durationNotifier.value = const Duration(minutes: 50);
        service.positionNotifier.value = const Duration(minutes: 15);

        await tester.pumpWidget(_wrapTestApp(const BookAudioMiniPlayer(), textScale: scale));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(BookAudioMiniPlayer), findsOneWidget);
      });
    }

    testWidgets('Tapping play/pause button registers tap event cleanly', (tester) async {
      final service = MutunAudioService();
      service.activeBookIdNotifier.value = 'shamela_1727';
      service.isPlayingNotifier.value = true;

      await tester.pumpWidget(_wrapTestApp(const BookAudioMiniPlayer()));
      await tester.pump();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping dismiss button calls stop on MutunAudioService', (tester) async {
      final service = MutunAudioService();
      service.activeBookIdNotifier.value = 'shamela_1727';
      service.isPlayingNotifier.value = true;

      await tester.pumpWidget(_wrapTestApp(const BookAudioMiniPlayer()));
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 50));

      expect(service.activeBookIdNotifier.value, isNull);
    });
  });

  group('BookAudioNavigationHelper Tests', () {
    test('Returns false when no book is actively loaded', () async {
      final service = MutunAudioService();
      service.activeBookIdNotifier.value = null;

      expect(service.activeBookIdNotifier.value, isNull);
    });

    test('Identifies shamela book audio entry and reciters', () {
      final entry = MutunAudioCatalog.getEntry('shamela_1727');
      expect(entry, isNotNull);
      expect(entry!.title, contains('مسلم'));
      expect(entry.sources.isNotEmpty, isTrue);
    });
  });
}
