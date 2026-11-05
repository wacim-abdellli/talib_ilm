import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/models/quran_models.dart';
import 'package:talib_ilm/features/quran/data/services/quran_pack_install_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp(
      'quran_pack_install_test_',
    );
    QuranPackInstallService.resetForTesting();
    QuranPackInstallService.testBaseDir = tempDirectory;
  });

  tearDown(() async {
    QuranPackInstallService.resetForTesting();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('QuranPackInstallService source pins and fail-closed install', () {
    test('all catalog URLs and source hashes are pinned to one commit', () {
      for (final edition in QuranRiwayahId.values) {
        final pin = QuranPackInstallService.sourcePin(edition);
        final data = pin['data'] as Map<String, dynamic>;
        final font = pin['font'] as Map<String, dynamic>;
        expect(data['url'], contains(QuranPackInstallService.sourceCommit));
        expect(font['url'], contains(QuranPackInstallService.sourceCommit));
        expect(data['sha256'], matches(RegExp(r'^[A-F0-9]{64}$')));
        expect(font['sha256'], matches(RegExp(r'^[A-F0-9]{64}$')));
        expect(data['bytes'], greaterThan(0));
        expect(font['bytes'], greaterThan(0));
      }
    });

    test(
      'rejects a truncated pinned source and removes staging files',
      () async {
        var requestCount = 0;
        QuranPackInstallService.setHttpClient(
          MockClient((request) async {
            requestCount++;
            return http.Response('truncated', 200);
          }),
        );

        final events = await QuranPackInstallService.install(
          QuranRiwayahId.warsh,
        ).toList();

        expect(requestCount, 1);
        expect(events.last.isError, isTrue);
        expect(
          await QuranPackInstallService.isInstalled(QuranRiwayahId.warsh),
          isFalse,
        );
        final packsDirectory = Directory('${tempDirectory.path}/quran_packs');
        expect(await packsDirectory.exists(), isTrue);
        expect(await packsDirectory.list().toList(), isEmpty);
      },
    );

    test(
      'rejects a failed GitHub response without marking an edition installed',
      () async {
        QuranPackInstallService.setHttpClient(
          MockClient((_) async => http.Response('missing', 404)),
        );

        final events = await QuranPackInstallService.install(
          QuranRiwayahId.qalun,
        ).toList();

        expect(events.last.isError, isTrue);
        expect(
          await QuranPackInstallService.isInstalled(QuranRiwayahId.qalun),
          isFalse,
        );
        final packsDirectory = Directory('${tempDirectory.path}/quran_packs');
        expect(await packsDirectory.list().toList(), isEmpty);
      },
    );
  });
}
