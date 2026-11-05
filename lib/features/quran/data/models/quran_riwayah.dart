part of 'quran_pack_manifest.dart';

/// Canonical identity and manifest contract for downloadable Quran editions.
///
/// Parsing this model only validates the manifest's structure. It does not
/// authenticate the signature or prove that the referenced Quran content is
/// correct; those checks belong to the pack validator before installation.
enum QuranRiwayahId {
  hafs('hafs', 'حفص عن عاصم', 'Hafs ʿan ʿĀṣim'),
  warsh('warsh', 'ورش عن نافع', 'Warsh ʿan Nāfiʿ'),
  qalun('qalun', 'قالون عن نافع', 'Qālūn ʿan Nāfiʿ');

  const QuranRiwayahId(this.wireValue, this.nameArabic, this.nameEnglish);

  /// Stable machine identifier. It is never inferred from a display name,
  /// endpoint, font family, or content filename.
  final String wireValue;
  final String nameArabic;
  final String nameEnglish;

  static QuranRiwayahId parse(Object? value, {String field = 'editionId'}) {
    if (value is String) {
      for (final edition in values) {
        if (edition.wireValue == value) return edition;
      }
    }
    throw FormatException('Unsupported Quran riwayah in $field: $value');
  }
}

/// Features explicitly supported by a verified edition pack.
enum QuranPackCapability {
  displayText('display_text'),
  localSearch('local_search'),
  pageReferences('page_references'),
  exactPageLayout('exact_page_layout'),
  tajweed('tajweed'),
  audioAlignment('audio_alignment');

  const QuranPackCapability(this.wireValue);

  final String wireValue;

  static QuranPackCapability parse(Object? value) {
    if (value is String) {
      for (final capability in values) {
        if (capability.wireValue == value) return capability;
      }
    }
    throw FormatException('Unsupported Quran pack capability: $value');
  }
}

/// Logical purpose of a file in a Quran edition pack.
enum QuranPackAssetRole {
  displayText('display_text'),
  font('font'),
  pageMap('page_map'),
  pageLayout('page_layout'),
  searchIndex('search_index'),
  tajweed('tajweed'),
  audioAlignment('audio_alignment');

  const QuranPackAssetRole(this.wireValue);

  final String wireValue;

  static QuranPackAssetRole parse(Object? value) {
    if (value is String) {
      for (final role in values) {
        if (role.wireValue == value) return role;
      }
    }
    throw FormatException('Unsupported Quran pack asset role: $value');
  }
}
