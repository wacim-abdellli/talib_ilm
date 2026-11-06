import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'pins complete, integrity-checked Warsh and Qalun page artwork',
    () async {
      final json =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/quran/riwayah_page_art_manifest.json',
                ),
              )
              as Map<String, dynamic>;
      final source = json['source'] as Map<String, dynamic>;
      final editions = json['editions'] as Map<String, dynamic>;

      expect(source['repository'], 'quran-ws/quran-svg');
      expect(source['commit'], 'b4155f07e4aea087d2c458069acff9f7c7e749f6');
      expect(editions.keys, containsAll(['warsh', 'qalun']));

      for (final editionId in ['warsh', 'qalun']) {
        final edition = editions[editionId] as Map<String, dynamic>;
        final pages = edition['pages'] as List<dynamic>;
        expect(edition['pageCount'], 604, reason: editionId);
        expect(pages, hasLength(604), reason: editionId);
        expect(
          pages.map((page) => (page as Map<String, dynamic>)['page']).toList(),
          List<int>.generate(604, (index) => index + 1),
          reason: '$editionId page numbers must be complete and ordered',
        );
        for (final pageValue in pages) {
          final page = pageValue as Map<String, dynamic>;
          expect(
            page['bytes'],
            greaterThan(0),
            reason: '$editionId page ${page['page']}',
          );
          expect(
            page['gitBlobSha1'],
            matches(RegExp(r'^[a-f0-9]{40}$')),
            reason:
                '$editionId page ${page['page']} must have an integrity hash',
          );
        }
      }
    },
  );
}
