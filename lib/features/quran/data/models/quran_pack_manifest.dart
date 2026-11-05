import 'dart:convert';

part 'quran_riwayah.dart';
part 'quran_pack_entities.dart';
part 'quran_pack_json_helpers.dart';

/// Immutable metadata describing one signed, versioned Quran content pack.
///
/// Version 1 signs the RFC 8785 canonical JSON representation of this object
/// with the `signature` member omitted. Signature verification and key pinning
/// are deliberately separate from parsing and must happen before installation.
class QuranPackManifest {
  static const int supportedSchemaVersion = 1;
  static const int maxAssets = 32;

  final int schemaVersion;
  final QuranRiwayahId editionId;
  final String packVersion;
  final String minimumAppVersion;
  final DateTime publishedAt;
  final String scriptName;
  final QuranPackSource source;
  final QuranSourceCoordinates coordinates;
  final List<QuranSurahRange> surahRanges;
  final QuranPackStorage storage;
  final Set<QuranPackCapability> capabilities;
  final List<QuranPackAsset> assets;
  final QuranPackSignature signature;

  QuranPackManifest({
    required this.schemaVersion,
    required this.editionId,
    required this.packVersion,
    required this.minimumAppVersion,
    required this.publishedAt,
    required this.scriptName,
    required this.source,
    required this.coordinates,
    required List<QuranSurahRange> surahRanges,
    required this.storage,
    required Set<QuranPackCapability> capabilities,
    required List<QuranPackAsset> assets,
    required this.signature,
  }) : capabilities = Set.unmodifiable(capabilities),
       assets = List.unmodifiable(assets),
       surahRanges = List.unmodifiable(surahRanges) {
    _formatCanonicalUtcDateTime(publishedAt);
    _validate();
  }

  factory QuranPackManifest.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {
      'schemaVersion',
      'editionId',
      'packVersion',
      'minimumAppVersion',
      'publishedAt',
      'scriptName',
      'source',
      'coordinates',
      'surahRanges',
      'storage',
      'capabilities',
      'assets',
      'signature',
    }, 'manifest');

    final schemaVersion = _readInt(json, 'schemaVersion', 'manifest');
    if (schemaVersion != supportedSchemaVersion) {
      throw FormatException(
        'Unsupported Quran pack schema version: $schemaVersion',
      );
    }

    return QuranPackManifest(
      schemaVersion: schemaVersion,
      editionId: QuranRiwayahId.parse(json['editionId']),
      packVersion: _readString(json, 'packVersion', 'manifest', maxLength: 64),
      minimumAppVersion: _readString(
        json,
        'minimumAppVersion',
        'manifest',
        maxLength: 32,
      ),
      publishedAt: _readDateTime(json['publishedAt'], 'manifest.publishedAt'),
      scriptName: _readString(json, 'scriptName', 'manifest', maxLength: 100),
      source: QuranPackSource.fromJson(_readObject(json, 'source', 'manifest')),
      coordinates: QuranSourceCoordinates.fromJson(
        _readObject(json, 'coordinates', 'manifest'),
      ),
      surahRanges: _readObjectList(
        json,
        'surahRanges',
        'manifest',
        QuranSurahRange.fromJson,
        maxLength: 114,
      ),
      storage: QuranPackStorage.fromJson(
        _readObject(json, 'storage', 'manifest'),
      ),
      capabilities: _readEnumSet(
        json,
        'capabilities',
        'manifest',
        QuranPackCapability.parse,
        maxLength: QuranPackCapability.values.length,
      ),
      assets: _readObjectList(
        json,
        'assets',
        'manifest',
        QuranPackAsset.fromJson,
        maxLength: maxAssets,
      ),
      signature: QuranPackSignature.fromJson(
        _readObject(json, 'signature', 'manifest'),
      ),
    );
  }

  /// JSON payload that is covered by the detached signature.
  ///
  /// A signature verifier must canonicalize this map according to RFC 8785;
  /// ordinary JSON encoding order is not a cryptographic canonicalization.
  Map<String, dynamic> toUnsignedJson() => {
    'schemaVersion': schemaVersion,
    'editionId': editionId.wireValue,
    'packVersion': packVersion,
    'minimumAppVersion': minimumAppVersion,
    'publishedAt': _formatCanonicalUtcDateTime(publishedAt),
    'scriptName': scriptName,
    'source': source.toJson(),
    'coordinates': coordinates.toJson(),
    'surahRanges': surahRanges.map((range) => range.toJson()).toList(),
    'storage': storage.toJson(),
    'capabilities': capabilities.map((value) => value.wireValue).toList()
      ..sort(),
    'assets': assets.map((asset) => asset.toJson()).toList(),
  };

  Map<String, dynamic> toJson() => {
    ...toUnsignedJson(),
    'signature': signature.toJson(),
  };

  QuranPackAsset? assetForRole(QuranPackAssetRole role) {
    for (final asset in assets) {
      if (asset.roles.contains(role)) return asset;
    }
    return null;
  }

  void _validate() {
    if (schemaVersion != supportedSchemaVersion) {
      throw FormatException('Unsupported Quran pack schema version');
    }
    _requireText(packVersion, 'packVersion', maxLength: 64);
    if (!RegExp(r'^\d+\.\d+\.\d+(?:\+\d+)?$').hasMatch(minimumAppVersion)) {
      throw const FormatException(
        'minimumAppVersion must be a semantic app version such as 1.2.3+45',
      );
    }
    _requireText(scriptName, 'scriptName', maxLength: 100);
    if (source.editionId != editionId) {
      throw const FormatException(
        'Manifest editionId does not match the source transmission identity',
      );
    }
    if (!capabilities.contains(QuranPackCapability.displayText)) {
      throw const FormatException(
        'Every Quran pack must declare the display_text capability',
      );
    }
    if (assets.isEmpty || assets.length > maxAssets) {
      throw FormatException('A Quran pack must contain 1-$maxAssets assets');
    }

    final assetIds = <String>{};
    final assetPaths = <String>{};
    final assetRoles = <QuranPackAssetRole>{};
    var totalAssetBytes = 0;
    var fontBytes = 0;
    for (final asset in assets) {
      if (!assetIds.add(asset.id)) {
        throw FormatException('Duplicate Quran pack asset id: ${asset.id}');
      }
      if (!assetPaths.add(asset.path)) {
        throw FormatException('Duplicate Quran pack asset path: ${asset.path}');
      }
      for (final role in asset.roles) {
        if (!assetRoles.add(role)) {
          throw FormatException(
            'Duplicate Quran pack asset role: ${role.wireValue}',
          );
        }
      }
      totalAssetBytes += asset.byteLength;
      if (totalAssetBytes > 0x7fffffff) {
        throw const FormatException('Total Quran pack assets exceed 2 GiB');
      }
      if (asset.roles.contains(QuranPackAssetRole.font)) {
        fontBytes += asset.byteLength;
      }
    }

    if (coordinates.surahCount != 114 || surahRanges.length != 114) {
      throw const FormatException(
        'A complete Quran pack must declare exactly 114 surah ranges',
      );
    }
    var declaredAyahCount = 0;
    for (var index = 0; index < surahRanges.length; index++) {
      final range = surahRanges[index];
      if (range.surahNumber != index + 1) {
        throw FormatException(
          'Surah ranges must be unique and ordered 1..114; found ${range.surahNumber} at index $index',
        );
      }
      if (range.firstAyahNumber != 1) {
        throw FormatException(
          'Surah ${range.surahNumber} must begin at ayah number 1',
        );
      }
      declaredAyahCount += range.ayahCount;
    }
    if (declaredAyahCount != coordinates.ayahCount) {
      throw FormatException(
        'Surah range total ($declaredAyahCount) does not match coordinates.ayahCount (${coordinates.ayahCount})',
      );
    }
    if (storage.packageBytes != totalAssetBytes ||
        storage.fontBytes != fontBytes ||
        storage.dataBytes != totalAssetBytes - fontBytes) {
      throw const FormatException(
        'Storage byte totals must match the declared pack assets',
      );
    }
    if (storage.requiredTemporaryFreeSpaceBytes < storage.packageBytes) {
      throw const FormatException(
        'requiredTemporaryFreeSpaceBytes cannot be smaller than packageBytes',
      );
    }

    _requireAsset(
      QuranPackCapability.displayText,
      QuranPackAssetRole.displayText,
      assetRoles,
    );
    _requireAsset(
      QuranPackCapability.localSearch,
      QuranPackAssetRole.searchIndex,
      assetRoles,
    );
    _requireAsset(
      QuranPackCapability.pageReferences,
      QuranPackAssetRole.pageMap,
      assetRoles,
    );
    _requireAsset(
      QuranPackCapability.exactPageLayout,
      QuranPackAssetRole.pageLayout,
      assetRoles,
    );
    _requireAsset(
      QuranPackCapability.tajweed,
      QuranPackAssetRole.tajweed,
      assetRoles,
    );
    _requireAsset(
      QuranPackCapability.audioAlignment,
      QuranPackAssetRole.audioAlignment,
      assetRoles,
    );

    if (capabilities.contains(QuranPackCapability.exactPageLayout) &&
        !capabilities.contains(QuranPackCapability.pageReferences)) {
      throw const FormatException(
        'exact_page_layout requires page_references capability',
      );
    }
    if (capabilities.contains(QuranPackCapability.pageReferences) &&
        coordinates.pageCount == null) {
      throw const FormatException(
        'page_references requires page coordinates in the manifest',
      );
    }
  }

  void _requireAsset(
    QuranPackCapability capability,
    QuranPackAssetRole role,
    Set<QuranPackAssetRole> assetRoles,
  ) {
    if (capabilities.contains(capability) && !assetRoles.contains(role)) {
      throw FormatException(
        '${capability.wireValue} capability requires a ${role.wireValue} asset',
      );
    }
  }
}
