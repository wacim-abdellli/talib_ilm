/// Scholarly audio recitations catalog linking real syllabus mutun (bk_*)
/// to high-quality audio streams by prominent scholars (Dr. Abdul Aziz As-Sini & Sheikh Muadh Al-Tayyib).
class MutunAudioEntry {
  final String bookId;
  final String title;
  final String siniAudioFileName;
  final String tayyibAudioFileName;
  final int totalParagraphs;

  const MutunAudioEntry({
    required this.bookId,
    required this.title,
    required this.siniAudioFileName,
    required this.tayyibAudioFileName,
    this.totalParagraphs = 1,
  });
}

class MutunAudioCatalog {
  const MutunAudioCatalog._();

  static const String siniBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini';
  static const String tayyibBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/MuadhAlTayyib';

  static const Map<String, MutunAudioEntry> _entries = {
    'bk_adhkar_adab': MutunAudioEntry(
      bookId: 'bk_adhkar_adab',
      title: 'الآداب والأذكار',
      siniAudioFileName: '00_AdabWaAdhkar.mp3',
      tayyibAudioFileName: '00_AdabWaAdhkar.mp3',
      totalParagraphs: 24,
    ),
    'bk_nawaqid_islam': MutunAudioEntry(
      bookId: 'bk_nawaqid_islam',
      title: 'نواقض الإسلام',
      siniAudioFileName: '00_NawaqidAlIslam.mp3',
      tayyibAudioFileName: '00_NawaqidAlIslam.mp3',
      totalParagraphs: 10,
    ),
    'bk_qawaid_arba': MutunAudioEntry(
      bookId: 'bk_qawaid_arba',
      title: 'القواعد الأربع',
      siniAudioFileName: '01_FourRules.mp3',
      tayyibAudioFileName: '01_FourRules.mp3',
      totalParagraphs: 8,
    ),
    'bk_usul_thalatha': MutunAudioEntry(
      bookId: 'bk_usul_thalatha',
      title: 'ثلاثة الأصول وأدلتها',
      siniAudioFileName: '02_ThreePrinciples.mp3',
      tayyibAudioFileName: '02_ThreePrinciples.mp3',
      totalParagraphs: 28,
    ),
    'bk_shurut_salah': MutunAudioEntry(
      bookId: 'bk_shurut_salah',
      title: 'شروط الصلاة وأركانها وواجباتها',
      siniAudioFileName: '01_ShurootAlSalah.mp3',
      tayyibAudioFileName: '01_ShurootAlSalah.mp3',
      totalParagraphs: 14,
    ),
    'bk_kitab_tawheed': MutunAudioEntry(
      bookId: 'bk_kitab_tawheed',
      title: 'كتاب التوحيد',
      siniAudioFileName: '04_KitabAlTawheed.mp3',
      tayyibAudioFileName: '04_KitabAlTawheed.mp3',
      totalParagraphs: 67,
    ),
    'bk_kashf_shubuhat': MutunAudioEntry(
      bookId: 'bk_kashf_shubuhat',
      title: 'كشف الشبهات',
      siniAudioFileName: '03_KashfShubuhat.mp3',
      tayyibAudioFileName: '03_KashfShubuhat.mp3',
      totalParagraphs: 20,
    ),
    'bk_wasitiyya': MutunAudioEntry(
      bookId: 'bk_wasitiyya',
      title: 'العقيدة الواسطية',
      siniAudioFileName: '05_AlAqeedahAlWasitiyyah.mp3',
      tayyibAudioFileName: '05_AlAqeedahAlWasitiyyah.mp3',
      totalParagraphs: 35,
    ),
    'bk_arbaeen_nawawi': MutunAudioEntry(
      bookId: 'bk_arbaeen_nawawi',
      title: 'الأربعون النووية',
      siniAudioFileName: '07_FortyHadithNawawi.mp3',
      tayyibAudioFileName: '07_FortyHadithNawawi.mp3',
      totalParagraphs: 42,
    ),
    'bk_umdat_ahkam': MutunAudioEntry(
      bookId: 'bk_umdat_ahkam',
      title: 'عمدة الأحكام',
      siniAudioFileName: '08_UmdatAlAhkam.mp3',
      tayyibAudioFileName: '08_UmdatAlAhkam.mp3',
      totalParagraphs: 85,
    ),
    'bk_manzooma_bayquniyya': MutunAudioEntry(
      bookId: 'bk_manzooma_bayquniyya',
      title: 'المنظومة البيقونية',
      siniAudioFileName: '09_AlManzumahAlBayquniyyah.mp3',
      tayyibAudioFileName: '09_AlManzumahAlBayquniyyah.mp3',
      totalParagraphs: 34,
    ),
    'bk_waraqat': MutunAudioEntry(
      bookId: 'bk_waraqat',
      title: 'الورقات في أصول الفقه',
      siniAudioFileName: '11_AlWaraqat.mp3',
      tayyibAudioFileName: '11_AlWaraqat.mp3',
      totalParagraphs: 22,
    ),
    'bk_ajrumiyya': MutunAudioEntry(
      bookId: 'bk_ajrumiyya',
      title: 'الآجرومية',
      siniAudioFileName: '12_AlAjrumiyyah.mp3',
      tayyibAudioFileName: '12_AlAjrumiyyah.mp3',
      totalParagraphs: 30,
    ),
    'bk_tuhfat_atfal': MutunAudioEntry(
      bookId: 'bk_tuhfat_atfal',
      title: 'تحفة الأطفال في تجويد القرآن',
      siniAudioFileName: '14_TuhfatAlAtfal.mp3',
      tayyibAudioFileName: '14_TuhfatAlAtfal.mp3',
      totalParagraphs: 61,
    ),
    'bk_bulugh_maram': MutunAudioEntry(
      bookId: 'bk_bulugh_maram',
      title: 'بلوغ المرام من أدلة الأحكام',
      siniAudioFileName: '10_BulughAlMaram.mp3',
      tayyibAudioFileName: '10_BulughAlMaram.mp3',
      totalParagraphs: 120,
    ),
    'bk_qawaid_fiqhiyya': MutunAudioEntry(
      bookId: 'bk_qawaid_fiqhiyya',
      title: 'القواعد والأصول الجامعة',
      siniAudioFileName: '13_AlQawaidAlFiqhiyyah.mp3',
      tayyibAudioFileName: '13_AlQawaidAlFiqhiyyah.mp3',
      totalParagraphs: 18,
    ),
    'bk_tahawiyya': MutunAudioEntry(
      bookId: 'bk_tahawiyya',
      title: 'العقيدة الطحاوية',
      siniAudioFileName: '06_AlAqeedahAlTahawiyyah.mp3',
      tayyibAudioFileName: '06_AlAqeedahAlTahawiyyah.mp3',
      totalParagraphs: 50,
    ),
    'bk_zad_mustaqni': MutunAudioEntry(
      bookId: 'bk_zad_mustaqni',
      title: 'زاد المستقنع في اختصار المقنع',
      siniAudioFileName: '15_ZadAlMustaqni.mp3',
      tayyibAudioFileName: '15_ZadAlMustaqni.mp3',
      totalParagraphs: 140,
    ),
  };

  /// Check whether authentic audio recitation is available for this matn ID.
  static bool hasAudio(String bookId) => _entries.containsKey(bookId);

  /// Get audio recitation entry.
  static MutunAudioEntry? getEntry(String bookId) => _entries[bookId];

  /// Get streaming audio URL for the specified matn and reciter.
  static String? getAudioUrl(String bookId, {String reciterId = 'sini'}) {
    final entry = _entries[bookId];
    if (entry == null) return null;

    if (reciterId == 'tayyib') {
      return '$tayyibBaseUrl/${entry.tayyibAudioFileName}';
    }
    return '$siniBaseUrl/${entry.siniAudioFileName}';
  }

  /// Get total paragraphs / lines for reader synchronization.
  static int getTotalParagraphs(String bookId) {
    return _entries[bookId]?.totalParagraphs ?? 1;
  }
}
