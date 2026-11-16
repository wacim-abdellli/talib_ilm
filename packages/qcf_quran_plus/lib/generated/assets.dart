/// Contains static asset paths bundled by `qcf_quran_plus`.
class Assets {
  Assets._();

  static const String assetsSurahBanner = 'assets/surah_banner.png';
  static const String fontsArsura = 'assets/fonts/arsura.ttf';
  static const String fontsHafsSmart08 = 'assets/fonts/HafsSmart_08.ttf';
  static const String qCF4BSMLQCF4BSML = 'assets/fonts/QCF4_BSML/QCF4_BSML.ttf';
  static const String qcfQuranPlusAssetsSurahBanner = 'assets/surah_banner.png';

  static String qcfChunk(int chunkIndex) =>
      'assets/fonts/qcf_tajweed/qcf_chunk_${chunkIndex.toString().padLeft(2, '0')}.bin.xz';
}
