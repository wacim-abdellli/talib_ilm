import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/quran/data/models/quran_models.dart';

/// Synthetic manifest metadata only: no Quran verse text is fabricated or used.
Map<String, dynamic> _validManifest() => {
  'schemaVersion': 1,
  'editionId': 'hafs',
  'packVersion': 'source-v1-build-1',
  'minimumAppVersion': '1.0.1+2003',
  'publishedAt': '2026-11-05T00:00:00Z',
  'scriptName': 'Synthetic Uthmanic fixture',
  'source': {
    'organization': 'Fixture source authority',
    'title': 'Synthetic metadata fixture',
    'editionId': 'hafs',
    'transmissionIdentity': 'Hafs ʿan ʿĀṣim',
    'archiveUrl': 'https://source.example.org/fixture.zip',
    'archiveVersion': 'fixture-v1',
    'attribution': 'Synthetic test metadata only',
    'sourceUpdatedAt': '2026-11-01T00:00:00Z',
    'licenseUrl': 'https://source.example.org/terms',
  },
  'coordinates': {
    'surahCount': 114,
    'ayahCount': 114,
    'ayahNumberingSystem': 'synthetic-one-record-per-surah',
    'pageCount': 1,
    'pageNumberingSystem': 'synthetic-fixture-page-index',
  },
  'surahRanges': List.generate(
    114,
    (index) => {
      'surahNumber': index + 1,
      'firstAyahNumber': 1,
      'lastAyahNumber': 1,
    },
  ),
  'storage': {
    'packageBytes': 2000,
    'dataBytes': 1500,
    'fontBytes': 500,
    'requiredTemporaryFreeSpaceBytes': 2500,
  },
  'capabilities': [
    'display_text',
    'exact_page_layout',
    'local_search',
    'page_references',
  ],
  'assets': [
    {
      'id': 'content-db',
      'roles': ['display_text', 'page_map', 'search_index'],
      'mediaType': 'application/vnd.sqlite3',
      'path': 'content/quran.sqlite',
      'downloadUrl': 'https://cdn.example.org/hafs/content.sqlite',
      'byteLength': 1000,
      'sha256': List.filled(64, 'a').join(),
    },
    {
      'id': 'page-layout',
      'roles': ['page_layout'],
      'mediaType': 'application/octet-stream',
      'path': 'layout/pages.pack',
      'downloadUrl': 'https://cdn.example.org/hafs/pages.pack',
      'byteLength': 500,
      'sha256': List.filled(64, 'b').join(),
    },
    {
      'id': 'font',
      'roles': ['font'],
      'mediaType': 'font/ttf',
      'path': 'fonts/fixture.ttf',
      'downloadUrl': 'https://cdn.example.org/hafs/fixture.ttf',
      'fontFamily': 'Synthetic Fixture Font',
      'fontVersion': 'fixture-v1',
      'byteLength': 500,
      'sha256': List.filled(64, 'c').join(),
    },
  ],
  'signature': {
    'algorithm': 'Ed25519',
    'keyId': 'synthetic-fixture-key',
    'value': base64.encode(List<int>.filled(64, 0)),
  },
};

void main() {
  group('QuranPackManifest v1 contract', () {
    test(
      'parses complete synthetic metadata and preserves edition-scoped data',
      () {
        final manifest = QuranPackManifest.fromJson(_validManifest());

        expect(manifest.editionId, QuranRiwayahId.hafs);
        expect(manifest.source.editionId, QuranRiwayahId.hafs);
        expect(manifest.surahRanges, hasLength(114));
        expect(manifest.coordinates.ayahCount, 114);
        expect(manifest.toJson()['publishedAt'], '2026-11-05T00:00:00Z');
        expect(manifest.storage.packageBytes, 2000);
        expect(
          manifest.assetForRole(QuranPackAssetRole.displayText)?.path,
          'content/quran.sqlite',
        );
        expect(
          manifest.assetForRole(QuranPackAssetRole.font)?.fontFamily,
          'Synthetic Fixture Font',
        );
      },
    );

    test(
      'rejects source narration identity that conflicts with manifest ID',
      () {
        final json = _validManifest();
        json['source'] = Map<String, dynamic>.from(json['source'] as Map)
          ..['editionId'] = 'warsh';

        expect(() => QuranPackManifest.fromJson(json), throwsFormatException);
      },
    );

    test('rejects incomplete surah ranges and ayah count mismatch', () {
      final missingRange = _validManifest()..['surahRanges'] = [];
      expect(
        () => QuranPackManifest.fromJson(missingRange),
        throwsFormatException,
      );

      final mismatchedCount = _validManifest();
      mismatchedCount['coordinates'] = Map<String, dynamic>.from(
        mismatchedCount['coordinates'] as Map,
      )..['ayahCount'] = 115;
      expect(
        () => QuranPackManifest.fromJson(mismatchedCount),
        throwsFormatException,
      );

      final invalidStartingAyah = _validManifest();
      final ranges = List<Map<String, dynamic>>.from(
        invalidStartingAyah['surahRanges'] as List,
      );
      ranges[0] = Map<String, dynamic>.from(ranges[0])
        ..['firstAyahNumber'] = 2
        ..['lastAyahNumber'] = 2;
      invalidStartingAyah['surahRanges'] = ranges;
      expect(
        () => QuranPackManifest.fromJson(invalidStartingAyah),
        throwsFormatException,
      );
    });

    test('rejects unsafe paths and capability-to-asset mismatches', () {
      final unsafePath = _validManifest();
      final assets = List<Map<String, dynamic>>.from(
        unsafePath['assets'] as List,
      );
      assets[0] = Map<String, dynamic>.from(assets[0])
        ..['path'] = '../../outside.sqlite';
      unsafePath['assets'] = assets;
      expect(
        () => QuranPackManifest.fromJson(unsafePath),
        throwsFormatException,
      );

      final missingDisplayText = _validManifest();
      final onlyFont = Map<String, dynamic>.from(
        (missingDisplayText['assets'] as List).last as Map,
      );
      missingDisplayText['assets'] = [onlyFont];
      expect(
        () => QuranPackManifest.fromJson(missingDisplayText),
        throwsFormatException,
      );
    });

    test('rejects byte totals inconsistent with signed asset sizes', () {
      final json = _validManifest();
      json['storage'] = Map<String, dynamic>.from(json['storage'] as Map)
        ..['packageBytes'] = 1999;

      expect(() => QuranPackManifest.fromJson(json), throwsFormatException);
    });

    test(
      'rejects traversal variants, duplicate roles, and non-HTTPS asset URLs',
      () {
        for (final invalidPath in ['../outside.sqlite', 'a//b.sqlite', 'a/']) {
          final json = _validManifest();
          final assets = List<Map<String, dynamic>>.from(
            json['assets'] as List,
          );
          assets[0] = Map<String, dynamic>.from(assets[0])
            ..['path'] = invalidPath;
          json['assets'] = assets;
          expect(
            () => QuranPackManifest.fromJson(json),
            throwsFormatException,
            reason: 'Reject path $invalidPath',
          );
        }

        final duplicateRole = _validManifest();
        final duplicateRoleAssets = List<Map<String, dynamic>>.from(
          duplicateRole['assets'] as List,
        );
        duplicateRoleAssets.add({
          ...duplicateRoleAssets.first,
          'id': 'duplicate-display',
          'path': 'content/duplicate.sqlite',
        });
        duplicateRole['assets'] = duplicateRoleAssets;
        expect(
          () => QuranPackManifest.fromJson(duplicateRole),
          throwsFormatException,
        );

        final insecureUrl = _validManifest();
        final insecureAssets = List<Map<String, dynamic>>.from(
          insecureUrl['assets'] as List,
        );
        insecureAssets[0] = Map<String, dynamic>.from(insecureAssets[0])
          ..['downloadUrl'] = 'http://cdn.example.org/content.sqlite';
        insecureUrl['assets'] = insecureAssets;
        expect(
          () => QuranPackManifest.fromJson(insecureUrl),
          throwsFormatException,
        );
      },
    );

    test(
      'rejects page capability without page coordinates and unknown keys',
      () {
        final missingPageCoordinates = _validManifest();
        missingPageCoordinates['coordinates'] = {
          'surahCount': 114,
          'ayahCount': 114,
          'ayahNumberingSystem': 'synthetic-one-record-per-surah',
        };
        expect(
          () => QuranPackManifest.fromJson(missingPageCoordinates),
          throwsFormatException,
        );

        final unknownKey = _validManifest()..['unexpected'] = true;
        expect(
          () => QuranPackManifest.fromJson(unknownKey),
          throwsFormatException,
        );
      },
    );

    test(
      'signature parsing checks envelope shape but does not authenticate it',
      () {
        final manifest = QuranPackManifest.fromJson(_validManifest());
        expect(manifest.signature.valueBase64, isNotEmpty);
        // Cryptographic verification is a separate required install gate.
      },
    );

    test(
      'rejects noncanonical timestamp offsets that would change signature bytes',
      () {
        final json = _validManifest();
        json['publishedAt'] = '2026-11-05T01:00:00+01:00';

        expect(() => QuranPackManifest.fromJson(json), throwsFormatException);
      },
    );
  });
}
