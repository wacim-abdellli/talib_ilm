part of 'quran_pack_manifest.dart';

/// Provenance for the authoritative source used to build this pack.
class QuranPackSource {
  final String organization;
  final String title;
  final QuranRiwayahId editionId;
  final String transmissionIdentity;
  final Uri archiveUrl;
  final String archiveVersion;
  final String? archiveSha256;
  final DateTime? sourceUpdatedAt;
  final String attribution;
  final Uri? licenseUrl;

  QuranPackSource({
    required this.organization,
    required this.title,
    required this.editionId,
    required this.transmissionIdentity,
    required this.archiveUrl,
    required this.archiveVersion,
    required this.attribution,
    this.archiveSha256,
    this.sourceUpdatedAt,
    this.licenseUrl,
  }) {
    _requireText(organization, 'source.organization', maxLength: 200);
    _requireText(title, 'source.title', maxLength: 300);
    _requireText(
      transmissionIdentity,
      'source.transmissionIdentity',
      maxLength: 200,
    );
    _requireText(archiveVersion, 'source.archiveVersion', maxLength: 100);
    _requireText(attribution, 'source.attribution', maxLength: 1000);
    _requireHttpsUri(archiveUrl, 'source.archiveUrl');
    if (licenseUrl != null) _requireHttpsUri(licenseUrl!, 'source.licenseUrl');
    if (sourceUpdatedAt != null) {
      _formatCanonicalUtcDateTime(sourceUpdatedAt!);
    }
    if (archiveSha256 != null) {
      _requireSha256(archiveSha256!, 'source.archiveSha256');
    }
  }

  factory QuranPackSource.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {
      'organization',
      'title',
      'editionId',
      'transmissionIdentity',
      'archiveUrl',
      'archiveVersion',
      'archiveSha256',
      'sourceUpdatedAt',
      'attribution',
      'licenseUrl',
    }, 'source');

    final updatedAtValue = _readOptionalValue(
      json,
      'sourceUpdatedAt',
      'source',
    );
    final licenseUrlValue = _readOptionalValue(json, 'licenseUrl', 'source');
    return QuranPackSource(
      organization: _readString(json, 'organization', 'source', maxLength: 200),
      title: _readString(json, 'title', 'source', maxLength: 300),
      editionId: QuranRiwayahId.parse(
        json['editionId'],
        field: 'source.editionId',
      ),
      transmissionIdentity: _readString(
        json,
        'transmissionIdentity',
        'source',
        maxLength: 200,
      ),
      archiveUrl: _readHttpsUri(json, 'archiveUrl', 'source'),
      archiveVersion: _readString(
        json,
        'archiveVersion',
        'source',
        maxLength: 100,
      ),
      archiveSha256: _readOptionalString(
        json,
        'archiveSha256',
        'source',
        maxLength: 64,
      ),
      sourceUpdatedAt: updatedAtValue == null
          ? null
          : _readDateTime(updatedAtValue, 'source.sourceUpdatedAt'),
      attribution: _readString(json, 'attribution', 'source', maxLength: 1000),
      licenseUrl: licenseUrlValue == null
          ? null
          : _readHttpsUri(json, 'licenseUrl', 'source'),
    );
  }

  Map<String, dynamic> toJson() => {
    'organization': organization,
    'title': title,
    'editionId': editionId.wireValue,
    'transmissionIdentity': transmissionIdentity,
    'archiveUrl': archiveUrl.toString(),
    'archiveVersion': archiveVersion,
    if (archiveSha256 != null) 'archiveSha256': archiveSha256,
    if (sourceUpdatedAt != null)
      'sourceUpdatedAt': _formatCanonicalUtcDateTime(sourceUpdatedAt!),
    'attribution': attribution,
    if (licenseUrl != null) 'licenseUrl': licenseUrl.toString(),
  };
}

/// Source numbering systems and counts. Page values are edition-specific and
/// intentionally optional; the app must never infer them from a Hafs constant.
class QuranSourceCoordinates {
  final int surahCount;
  final int ayahCount;
  final String ayahNumberingSystem;
  final int? pageCount;
  final String? pageNumberingSystem;

  QuranSourceCoordinates({
    required this.surahCount,
    required this.ayahCount,
    required this.ayahNumberingSystem,
    this.pageCount,
    this.pageNumberingSystem,
  }) {
    if (surahCount <= 0 || surahCount > 114) {
      throw const FormatException('coordinates.surahCount must be 1-114');
    }
    if (ayahCount <= 0 || ayahCount > 10000) {
      throw const FormatException('coordinates.ayahCount must be 1-10000');
    }
    _requireText(
      ayahNumberingSystem,
      'coordinates.ayahNumberingSystem',
      maxLength: 200,
    );
    if (pageCount != null && (pageCount! <= 0 || pageCount! > 2000)) {
      throw const FormatException('coordinates.pageCount must be 1-2000');
    }
    if ((pageCount == null) != (pageNumberingSystem == null)) {
      throw const FormatException(
        'pageCount and pageNumberingSystem must both be supplied or omitted',
      );
    }
    if (pageNumberingSystem != null) {
      _requireText(
        pageNumberingSystem!,
        'coordinates.pageNumberingSystem',
        maxLength: 200,
      );
    }
  }

  factory QuranSourceCoordinates.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {
      'surahCount',
      'ayahCount',
      'ayahNumberingSystem',
      'pageCount',
      'pageNumberingSystem',
    }, 'coordinates');

    return QuranSourceCoordinates(
      surahCount: _readInt(json, 'surahCount', 'coordinates'),
      ayahCount: _readInt(json, 'ayahCount', 'coordinates'),
      ayahNumberingSystem: _readString(
        json,
        'ayahNumberingSystem',
        'coordinates',
        maxLength: 200,
      ),
      pageCount: _readOptionalInt(json, 'pageCount', 'coordinates'),
      pageNumberingSystem: _readOptionalString(
        json,
        'pageNumberingSystem',
        'coordinates',
        maxLength: 200,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'surahCount': surahCount,
    'ayahCount': ayahCount,
    'ayahNumberingSystem': ayahNumberingSystem,
    if (pageCount != null) 'pageCount': pageCount,
    if (pageNumberingSystem != null) 'pageNumberingSystem': pageNumberingSystem,
  };
}

/// Source numbering range for one complete surah.
class QuranSurahRange {
  final int surahNumber;
  final int firstAyahNumber;
  final int lastAyahNumber;

  QuranSurahRange({
    required this.surahNumber,
    required this.firstAyahNumber,
    required this.lastAyahNumber,
  }) {
    if (surahNumber < 1 || surahNumber > 114) {
      throw const FormatException('surahRange.surahNumber must be 1-114');
    }
    if (firstAyahNumber < 1 ||
        lastAyahNumber < firstAyahNumber ||
        lastAyahNumber > 10000) {
      throw const FormatException('surahRange ayah interval is invalid');
    }
  }

  int get ayahCount => lastAyahNumber - firstAyahNumber + 1;

  factory QuranSurahRange.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {
      'surahNumber',
      'firstAyahNumber',
      'lastAyahNumber',
    }, 'surahRange');
    return QuranSurahRange(
      surahNumber: _readInt(json, 'surahNumber', 'surahRange'),
      firstAyahNumber: _readInt(json, 'firstAyahNumber', 'surahRange'),
      lastAyahNumber: _readInt(json, 'lastAyahNumber', 'surahRange'),
    );
  }

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'firstAyahNumber': firstAyahNumber,
    'lastAyahNumber': lastAyahNumber,
  };
}

/// Signed storage-size declarations for one freshly installed pack.
class QuranPackStorage {
  final int packageBytes;
  final int dataBytes;
  final int fontBytes;
  final int requiredTemporaryFreeSpaceBytes;

  QuranPackStorage({
    required this.packageBytes,
    required this.dataBytes,
    required this.fontBytes,
    required this.requiredTemporaryFreeSpaceBytes,
  }) {
    if (packageBytes <= 0 ||
        dataBytes < 0 ||
        fontBytes < 0 ||
        requiredTemporaryFreeSpaceBytes <= 0 ||
        packageBytes > 0x7fffffff ||
        requiredTemporaryFreeSpaceBytes > 0x7fffffff) {
      throw const FormatException('Pack storage byte counts are out of range');
    }
    if (dataBytes + fontBytes != packageBytes) {
      throw const FormatException(
        'dataBytes + fontBytes must equal packageBytes',
      );
    }
    if (requiredTemporaryFreeSpaceBytes < packageBytes) {
      throw const FormatException(
        'requiredTemporaryFreeSpaceBytes cannot be smaller than packageBytes',
      );
    }
  }

  factory QuranPackStorage.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {
      'packageBytes',
      'dataBytes',
      'fontBytes',
      'requiredTemporaryFreeSpaceBytes',
    }, 'storage');
    return QuranPackStorage(
      packageBytes: _readInt(json, 'packageBytes', 'storage'),
      dataBytes: _readInt(json, 'dataBytes', 'storage'),
      fontBytes: _readInt(json, 'fontBytes', 'storage'),
      requiredTemporaryFreeSpaceBytes: _readInt(
        json,
        'requiredTemporaryFreeSpaceBytes',
        'storage',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'packageBytes': packageBytes,
    'dataBytes': dataBytes,
    'fontBytes': fontBytes,
    'requiredTemporaryFreeSpaceBytes': requiredTemporaryFreeSpaceBytes,
  };
}

/// One integrity-checked file within a Quran pack.
class QuranPackAsset {
  final String id;
  final Set<QuranPackAssetRole> roles;
  final String mediaType;
  final String path;
  final Uri downloadUrl;
  final String? fontFamily;
  final String? fontVersion;
  final int byteLength;
  final String sha256;

  QuranPackAsset({
    required this.id,
    required Set<QuranPackAssetRole> roles,
    required this.mediaType,
    required this.path,
    required this.downloadUrl,
    this.fontFamily,
    this.fontVersion,
    required this.byteLength,
    required this.sha256,
  }) : roles = Set.unmodifiable(roles) {
    _requireText(id, 'asset.id', maxLength: 64);
    if (this.roles.isEmpty ||
        this.roles.length > QuranPackAssetRole.values.length) {
      throw const FormatException('asset.roles must contain supported roles');
    }
    _requireText(mediaType, 'asset.mediaType', maxLength: 128);
    _requireSafeRelativePath(path);
    _requireHttpsUri(downloadUrl, 'asset.downloadUrl');
    if (this.roles.contains(QuranPackAssetRole.font)) {
      if (this.roles.length != 1) {
        throw const FormatException(
          'A font asset cannot share other asset roles',
        );
      }
      _requireText(fontFamily ?? '', 'asset.fontFamily', maxLength: 200);
      if (fontVersion != null) {
        _requireText(fontVersion!, 'asset.fontVersion', maxLength: 100);
      }
    } else if (fontFamily != null || fontVersion != null) {
      throw const FormatException(
        'fontFamily and fontVersion are only valid for font assets',
      );
    }
    if (byteLength <= 0 || byteLength > 0x7fffffff) {
      throw const FormatException('asset.byteLength must be 1-2147483647');
    }
    _requireSha256(sha256, 'asset.sha256');
  }

  factory QuranPackAsset.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {
      'id',
      'roles',
      'mediaType',
      'path',
      'downloadUrl',
      'fontFamily',
      'fontVersion',
      'byteLength',
      'sha256',
    }, 'asset');
    return QuranPackAsset(
      id: _readString(json, 'id', 'asset', maxLength: 64),
      roles: _readEnumSet(
        json,
        'roles',
        'asset',
        QuranPackAssetRole.parse,
        maxLength: QuranPackAssetRole.values.length,
      ),
      mediaType: _readString(json, 'mediaType', 'asset', maxLength: 128),
      path: _readString(json, 'path', 'asset', maxLength: 240),
      downloadUrl: _readHttpsUri(json, 'downloadUrl', 'asset'),
      fontFamily: _readOptionalString(
        json,
        'fontFamily',
        'asset',
        maxLength: 200,
      ),
      fontVersion: _readOptionalString(
        json,
        'fontVersion',
        'asset',
        maxLength: 100,
      ),
      byteLength: _readInt(json, 'byteLength', 'asset'),
      sha256: _readString(json, 'sha256', 'asset', maxLength: 64),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roles': roles.map((role) => role.wireValue).toList()..sort(),
    'mediaType': mediaType,
    'path': path,
    'downloadUrl': downloadUrl.toString(),
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (fontVersion != null) 'fontVersion': fontVersion,
    'byteLength': byteLength,
    'sha256': sha256,
  };
}

/// Detached Ed25519 signature over the canonical unsigned manifest.
class QuranPackSignature {
  final String keyId;
  final String valueBase64;

  QuranPackSignature({required this.keyId, required this.valueBase64}) {
    _requireText(keyId, 'signature.keyId', maxLength: 128);
    final List<int> decoded;
    try {
      decoded = base64.decode(valueBase64);
    } on FormatException {
      throw const FormatException('signature.value must be valid base64');
    }
    if (decoded.length != 64 || base64.encode(decoded) != valueBase64) {
      throw const FormatException(
        'Ed25519 signature must be canonical base64 for exactly 64 bytes',
      );
    }
  }

  factory QuranPackSignature.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {'algorithm', 'keyId', 'value'}, 'signature');
    if (json['algorithm'] != 'Ed25519') {
      throw FormatException(
        'Unsupported Quran pack signature algorithm: ${json['algorithm']}',
      );
    }
    return QuranPackSignature(
      keyId: _readString(json, 'keyId', 'signature', maxLength: 128),
      valueBase64: _readString(json, 'value', 'signature', maxLength: 128),
    );
  }

  Map<String, dynamic> toJson() => {
    'algorithm': 'Ed25519',
    'keyId': keyId,
    'value': valueBase64,
  };
}
