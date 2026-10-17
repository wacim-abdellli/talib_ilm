/// Scholarly audio recitations catalog linking real syllabus mutun (bk_*)
/// to high-quality authentic audio streams by prominent scholars (Dr. Abdul Aziz As-Sini).
class MutunAudioEntry {
  final String bookId;
  final String title;
  final String siniAudioFileName;
  final String? archiveFileName;
  final String? directUrl;
  final String? fallbackUrl;
  final int totalParagraphs;

  const MutunAudioEntry({
    required this.bookId,
    required this.title,
    required this.siniAudioFileName,
    this.archiveFileName,
    this.directUrl,
    this.fallbackUrl,
    this.totalParagraphs = 1,
  });
}

class MutunAudioCatalog {
  const MutunAudioCatalog._();

  static const String archiveBaseUrl =
      'https://archive.org/download/Mottoon_Talib_Elm';
  static const String siniBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini';

  static const Map<String, MutunAudioEntry> _entries = {
    // ── المستوى التمهيدي ──────────────────────────────────────
    'bk_adhkar_adab': MutunAudioEntry(
      bookId: 'bk_adhkar_adab',
      title: 'الآداب والأذكار',
      archiveFileName: '03.mp3',
      siniAudioFileName: '0101AlAthkaar_AbdulAzizAsSini.mp3',
      totalParagraphs: 24,
    ),

    // ── المستوى الأول ─────────────────────────────────────────
    'bk_nawaqid_islam': MutunAudioEntry(
      bookId: 'bk_nawaqid_islam',
      title: 'نواقض الإسلام',
      archiveFileName: '04.mp3',
      siniAudioFileName: '0203NawaaqidAlIslaam_AbdulAzizAsSini.mp3',
      totalParagraphs: 10,
    ),
    'bk_qawaid_arba': MutunAudioEntry(
      bookId: 'bk_qawaid_arba',
      title: 'القواعد الأربع',
      archiveFileName: '05.mp3',
      siniAudioFileName: '0202AlQawaidAlArba_AbdulAzizAsSini.mp3',
      totalParagraphs: 8,
    ),
    'bk_usul_thalatha': MutunAudioEntry(
      bookId: 'bk_usul_thalatha',
      title: 'ثلاثة الأصول وأدلتها',
      archiveFileName: '06.mp3',
      siniAudioFileName: '0201AlUsulAtThalaath_AbdulAzizAsSini.mp3',
      totalParagraphs: 28,
    ),
    'bk_arbaeen_nawawi': MutunAudioEntry(
      bookId: 'bk_arbaeen_nawawi',
      title: 'الأربعون النووية',
      archiveFileName: '07.mp3',
      siniAudioFileName: '0204AlArbaunAnNawawiyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 42,
    ),

    // ── المستوى الثاني ─────────────────────────────────────────
    'bk_tuhfat_atfal': MutunAudioEntry(
      bookId: 'bk_tuhfat_atfal',
      title: 'تحفة الأطفال في تجويد القرآن',
      archiveFileName: '08.mp3',
      siniAudioFileName: '0301ThufatUlAtfaal_AbdulAzizAsSini.mp3',
      totalParagraphs: 61,
    ),
    'bk_shuroot_salah': MutunAudioEntry(
      bookId: 'bk_shuroot_salah',
      title: 'شروط الصلاة وأركانها وواجباتها',
      archiveFileName: '09.mp3',
      siniAudioFileName: '0302ShurutAsSalaah_AbdulAzizAsSini.mp3',
      totalParagraphs: 14,
    ),
    'bk_shurut_salah': MutunAudioEntry(
      bookId: 'bk_shurut_salah',
      title: 'شروط الصلاة وأركانها وواجباتها',
      archiveFileName: '09.mp3',
      siniAudioFileName: '0302ShurutAsSalaah_AbdulAzizAsSini.mp3',
      totalParagraphs: 14,
    ),
    'bk_kitab_tawheed': MutunAudioEntry(
      bookId: 'bk_kitab_tawheed',
      title: 'كتاب التوحيد',
      archiveFileName: '10.mp3',
      siniAudioFileName: '0303KitaabAtTawheed_AbdulAzizAsSini.mp3',
      totalParagraphs: 67,
    ),
    'bk_kashf_shubuhat': MutunAudioEntry(
      bookId: 'bk_kashf_shubuhat',
      title: 'كشف الشبهات',
      siniAudioFileName: '0804Kashf_AbdulGhaniSaadiqAlFaqeeh.mp3',
      directUrl:
          'https://files.a-alqasim.com/audio/Mutoon/AbdulGhaniSaadiqAlFaqeeh/0804Kashf_AbdulGhaniSaadiqAlFaqeeh.mp3',
      totalParagraphs: 20,
    ),

    // ── المستوى الثالث ─────────────────────────────────────────
    'bk_manzumah_baiquoni': MutunAudioEntry(
      bookId: 'bk_manzumah_baiquoni',
      title: 'المنظومة البيقونية',
      archiveFileName: '11.mp3',
      siniAudioFileName: '0401AlBayqooni_AbdulAzizAsSini.mp3',
      totalParagraphs: 34,
    ),
    'bk_manzooma_bayquniyya': MutunAudioEntry(
      bookId: 'bk_manzooma_bayquniyya',
      title: 'المنظومة البيقونية',
      archiveFileName: '11.mp3',
      siniAudioFileName: '0401AlBayqooni_AbdulAzizAsSini.mp3',
      totalParagraphs: 34,
    ),
    'bk_manzumah_albiri': MutunAudioEntry(
      bookId: 'bk_manzumah_albiri',
      title: 'منظومة أبي إسحاق الإلبيري',
      archiveFileName: '12.mp3',
      siniAudioFileName: '0402AlIlbiri_AbdulAzizAsSini.mp3',
      totalParagraphs: 25,
    ),
    'bk_ilbiri': MutunAudioEntry(
      bookId: 'bk_ilbiri',
      title: 'منظومة أبي إسحاق الإلبيري',
      archiveFileName: '12.mp3',
      siniAudioFileName: '0402AlIlbiri_AbdulAzizAsSini.mp3',
      totalParagraphs: 25,
    ),
    'bk_ajrumiyyah': MutunAudioEntry(
      bookId: 'bk_ajrumiyyah',
      title: 'الآجرومية',
      archiveFileName: '13.mp3',
      siniAudioFileName: '0403AlAajurrumiyyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 30,
    ),
    'bk_ajrumiyya': MutunAudioEntry(
      bookId: 'bk_ajrumiyya',
      title: 'الآجرومية',
      archiveFileName: '13.mp3',
      siniAudioFileName: '0403AlAajurrumiyyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 30,
    ),
    'bk_wasitiyyah': MutunAudioEntry(
      bookId: 'bk_wasitiyyah',
      title: 'العقيدة الواسطية',
      archiveFileName: '14.mp3',
      siniAudioFileName: '0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 35,
    ),
    'bk_wasitiyya': MutunAudioEntry(
      bookId: 'bk_wasitiyya',
      title: 'العقيدة الواسطية',
      archiveFileName: '14.mp3',
      siniAudioFileName: '0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 35,
    ),

    // ── المستوى الرابع ─────────────────────────────────────────
    'bk_waraqat': MutunAudioEntry(
      bookId: 'bk_waraqat',
      title: 'الورقات في أصول الفقه',
      archiveFileName: '15.mp3',
      siniAudioFileName: '0501AlWaraqat_AbdulAzizAsSini.mp3',
      totalParagraphs: 22,
    ),
    'bk_unwan_al_hukm': MutunAudioEntry(
      bookId: 'bk_unwan_al_hukm',
      title: 'عنوان الحكم',
      archiveFileName: '16.mp3',
      siniAudioFileName: '0502UnwanAlHikm_AbdulAzizAsSini.mp3',
      totalParagraphs: 20,
    ),
    'bk_unwan_alhikam': MutunAudioEntry(
      bookId: 'bk_unwan_alhikam',
      title: 'عنوان الحكم',
      archiveFileName: '16.mp3',
      siniAudioFileName: '0502UnwanAlHikm_AbdulAzizAsSini.mp3',
      totalParagraphs: 20,
    ),
    'bk_rahibiyyah': MutunAudioEntry(
      bookId: 'bk_rahibiyyah',
      title: 'الرحبية في علم الفرائض',
      archiveFileName: '17.mp3',
      siniAudioFileName: '0503ArRahbiyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 30,
    ),
    'bk_rahbiyya': MutunAudioEntry(
      bookId: 'bk_rahbiyya',
      title: 'الرحبية في علم الفرائض',
      archiveFileName: '17.mp3',
      siniAudioFileName: '0503ArRahbiyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 30,
    ),
    'bk_aqidah_tahawiyyah': MutunAudioEntry(
      bookId: 'bk_aqidah_tahawiyyah',
      title: 'العقيدة الطحاوية',
      archiveFileName: '18.mp3',
      siniAudioFileName: '0504AtTahawiyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 50,
    ),
    'bk_tahawiyya': MutunAudioEntry(
      bookId: 'bk_tahawiyya',
      title: 'العقيدة الطحاوية',
      archiveFileName: '18.mp3',
      siniAudioFileName: '0504AtTahawiyah_AbdulAzizAsSini.mp3',
      totalParagraphs: 50,
    ),

    // ── المطولات المتقدمة ──────────────────────────────────────
    'bk_bulugh_maram': MutunAudioEntry(
      bookId: 'bk_bulugh_maram',
      title: 'بلوغ المرام من أدلة الأحكام',
      siniAudioFileName: '0601Buloogh_AbdulAzizAsSini.mp3',
      totalParagraphs: 120,
    ),
    'bk_zad_mustaqni': MutunAudioEntry(
      bookId: 'bk_zad_mustaqni',
      title: 'زاد المستقنع في اختصار المقنع',
      siniAudioFileName:
          '0602Zaad/0602Zaad_01_KitaabAtTahaarah_AbdulAzizAsSini.mp3',
      totalParagraphs: 140,
    ),
    'bk_umdat_ahkam': MutunAudioEntry(
      bookId: 'bk_umdat_ahkam',
      title: 'عمدة الأحكام',
      siniAudioFileName: '0802AlUmdatuFilAhkaam_AbdulAzizAsSini.mp3',
      totalParagraphs: 85,
    ),
    'bk_qawaid_fiqhiyya': MutunAudioEntry(
      bookId: 'bk_qawaid_fiqhiyya',
      title: 'منظومة القواعد الفقهية',
      siniAudioFileName: 'Mandhoumat_al-qawid_al-fiqhiyah_As-saady.mp3',
      directUrl:
          'https://archive.org/download/shaydzmi111/Mandhoumat_al-qawid_al-fiqhiyah_As-saady.mp3',
      totalParagraphs: 18,
    ),
  };

  /// Check whether authentic audio recitation is available for this matn ID.
  static bool hasAudio(String bookId) => _entries.containsKey(bookId);

  /// Get audio recitation entry.
  static MutunAudioEntry? getEntry(String bookId) => _entries[bookId];

  /// Get primary streaming audio URL for the specified matn and reciter.
  static String? getAudioUrl(String bookId, {String reciterId = 'sini'}) {
    final entry = _entries[bookId];
    if (entry == null) return null;

    if (entry.directUrl != null) {
      return entry.directUrl;
    }

    // High-speed CDN mirror for Dr. Abdul Aziz As-Sini recordings
    if (entry.archiveFileName != null) {
      return '$archiveBaseUrl/${entry.archiveFileName}';
    }

    return '$siniBaseUrl/${entry.siniAudioFileName}';
  }

  /// Get backup fallback URL in case of network or mirror failure.
  static String? getFallbackAudioUrl(String bookId, {String reciterId = 'sini'}) {
    final entry = _entries[bookId];
    if (entry == null) return null;

    if (entry.fallbackUrl != null) {
      return entry.fallbackUrl;
    }

    if (entry.archiveFileName != null) {
      return '$siniBaseUrl/${entry.siniAudioFileName}';
    }

    return null;
  }

  /// Get total paragraphs / lines for reader synchronization.
  static int getTotalParagraphs(String bookId) {
    return _entries[bookId]?.totalParagraphs ?? 1;
  }
}
