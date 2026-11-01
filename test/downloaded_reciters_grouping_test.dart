import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_downloader.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/downloaded_reciters_list_view.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/reciter_selection_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quran_grouping_test_');
    QuranAudioDownloader.testBaseDir = tempDir;
  });

  tearDown(() async {
    QuranAudioDownloader.testBaseDir = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  test('getDownloadedSurahsByReciter scans and groups downloaded surahs by reciter', () async {
    final reciters = QuranAudioService.reciters;
    final r1 = reciters[0]; // alafasy (verse based)
    final r2 = reciters[1]; // luhaidan (surah based)

    // Initially empty
    final initial = await QuranAudioDownloader.getDownloadedSurahsByReciter();
    expect(initial.isEmpty, isTrue);

    // Mock download for r1 (Surah 1: 7 verses)
    final r1Surah1Dir = Directory('${tempDir.path}/${r1.id}/1');
    r1Surah1Dir.createSync(recursive: true);
    for (int a = 1; a <= 7; a++) {
      final f = File('${r1Surah1Dir.path}/001${a.toString().padLeft(3, '0')}.mp3');
      f.writeAsBytesSync(List.filled(100, 0x55));
    }

    // Mock download for r2 (Surah 1: full_surah.mp3)
    final r2Surah1Dir = Directory('${tempDir.path}/${r2.id}/1');
    r2Surah1Dir.createSync(recursive: true);
    final f2 = File('${r2Surah1Dir.path}/full_surah.mp3');
    f2.writeAsBytesSync(List.filled(2000, 0x66));

    final grouped = await QuranAudioDownloader.getDownloadedSurahsByReciter();
    expect(grouped.containsKey(r1), isTrue);
    expect(grouped.containsKey(r2), isTrue);
    expect(grouped[r1]!.length, 1);
    expect(grouped[r1]!.first.surah, 1);
    expect(grouped[r1]!.first.surahName, 'الفاتحة');
    expect(grouped[r2]!.length, 1);
    expect(grouped[r2]!.first.surah, 1);

    // Delete r1 audio
    await QuranAudioDownloader.deleteReciterAudio(r1);
    final afterDelete = await QuranAudioDownloader.getDownloadedSurahsByReciter();
    expect(afterDelete.containsKey(r1), isFalse);
    expect(afterDelete.containsKey(r2), isTrue);
  });

  testWidgets('DownloadedRecitersListView renders grouped list and empty state', (tester) async {
    final reciters = QuranAudioService.reciters;
    final r1 = reciters[0];

    final items = [
      DownloadedSurahItem(
        surah: 1,
        surahName: 'الفاتحة',
        verseCount: 7,
        bytes: 10240,
        reciter: r1,
      ),
      DownloadedSurahItem(
        surah: 112,
        surahName: 'الإخلاص',
        verseCount: 4,
        bytes: 5120,
        reciter: r1,
      ),
    ];

    final downloadedMap = {r1: items};

    await tester.pumpWidget(
      buildTestApp(
        DownloadedRecitersListView(
          downloadedByReciter: downloadedMap,
          onRefresh: () {},
          onPlaySurah: (_) {},
          onDeleteSurah: (_) {},
          onDeleteReciter: (_) {},
        ),
      ),
    );

    expect(find.text(r1.name), findsOneWidget);
    expect(find.text('سورة الفاتحة'), findsOneWidget);
    expect(find.text('سورة الإخلاص'), findsOneWidget);

    // Empty state test
    await tester.pumpWidget(
      buildTestApp(
        DownloadedRecitersListView(
          downloadedByReciter: const {},
          onRefresh: () {},
          onPlaySurah: (_) {},
          onDeleteSurah: (_) {},
          onDeleteReciter: (_) {},
        ),
      ),
    );

    expect(find.text('لا توجد سور محمّلة لهذا القارئ'), findsOneWidget);
  });

  testWidgets('ReciterSelectionSheet renders reciters and filters by search', (tester) async {
    final reciter = QuranAudioService.reciters[0];
    QuranReciter? chosen;

    await tester.pumpWidget(
      buildTestApp(
        ReciterSelectionSheet(
          selectedReciter: reciter,
          onSelected: (r) => chosen = r,
        ),
      ),
    );

    expect(find.text('اختيار القارئ الصوتي'), findsOneWidget);
    expect(find.text(reciter.name), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'القطامي');
    await tester.pumpAndSettle();

    expect(find.text('ناصر القطامي'), findsOneWidget);
    await tester.tap(find.text('ناصر القطامي'));
    await tester.pumpAndSettle();

    expect(chosen?.id, 'qatami');
  });
}
