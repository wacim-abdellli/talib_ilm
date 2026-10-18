/// Catalog linking syllabus mutun (bk_*) to their authentic digitized editions.
class MutunDigitalEntry {
  final String id;
  final int shamelaId;
  final String title;
  final String author;
  final int totalPages;
  final bool isPoem;
  final int startPage;

  const MutunDigitalEntry({
    required this.id,
    required this.shamelaId,
    required this.title,
    required this.author,
    required this.totalPages,
    this.isPoem = false,
    this.startPage = 1,
  });
}

class MutunDigitalCatalog {
  static const Map<String, MutunDigitalEntry> entries = {
    'bk_adhkar_adab': MutunDigitalEntry(
      id: 'bk_adhkar_adab',
      shamelaId: 31307,
      title: 'الأذكار والآداب',
      author: 'د. عبد المحسن بن محمد القاسم',
      totalPages: 24,
    ),
    'bk_nawaqid_islam': MutunDigitalEntry(
      id: 'bk_nawaqid_islam',
      shamelaId: 30869,
      title: 'نواقض الإسلام',
      author: 'محمد بن عبد الوهاب',
      totalPages: 2,
    ),
    'bk_qawaid_arba': MutunDigitalEntry(
      id: 'bk_qawaid_arba',
      shamelaId: 8524,
      title: 'القواعد الأربع',
      author: 'محمد بن عبد الوهاب',
      totalPages: 4,
    ),
    'bk_usul_thalatha': MutunDigitalEntry(
      id: 'bk_usul_thalatha',
      shamelaId: 239,
      title: 'ثلاثة الأصول وأدلتها',
      author: 'محمد بن عبد الوهاب',
      totalPages: 25,
      startPage: 2,
    ),
    'bk_arbaeen_nawawi': MutunDigitalEntry(
      id: 'bk_arbaeen_nawawi',
      shamelaId: 147927,
      title: 'الأربعون النووية مع زيادات ابن رجب',
      author: 'يحيى بن شرف النووي',
      totalPages: 67,
    ),
    'bk_tuhfat_atfal': MutunDigitalEntry(
      id: 'bk_tuhfat_atfal',
      shamelaId: 9632,
      title: 'تحفة الأطفال والغلمان في تجويد القرآن',
      author: 'سليمان بن حسين الجمزوري',
      totalPages: 8,
      isPoem: true,
    ),
    'bk_shuroot_salah': MutunDigitalEntry(
      id: 'bk_shuroot_salah',
      shamelaId: 11266,
      title: 'شروط الصلاة وأركانها وواجباتها',
      author: 'محمد بن عبد الوهاب',
      totalPages: 10,
    ),
    'bk_kitab_tawheed': MutunDigitalEntry(
      id: 'bk_kitab_tawheed',
      shamelaId: 11318,
      title: 'كتاب التوحيد الذي هو حق الله على العبيد',
      author: 'محمد بن عبد الوهاب',
      totalPages: 147,
    ),
    'bk_manzumah_baiquoni': MutunDigitalEntry(
      id: 'bk_manzumah_baiquoni',
      shamelaId: 8567,
      title: 'المنظومة البيقونية في مصطلح الحديث',
      author: 'عمر بن محمد البيقوني',
      totalPages: 6,
      isPoem: true,
    ),
    'bk_manzumah_albiri': MutunDigitalEntry(
      id: 'bk_manzumah_albiri',
      shamelaId: 6869,
      title: 'منظومة أبي إسحاق الإلبيري (تائية الإلبيري)',
      author: 'إبراهيم بن مسعود الإلبيري',
      totalPages: 18,
      isPoem: true,
    ),
    'bk_ajrumiyyah': MutunDigitalEntry(
      id: 'bk_ajrumiyyah',
      shamelaId: 11371,
      title: 'المقدمة الآجرومية في مبادئ علم العربية',
      author: 'ابن آجروم الصنهاجي',
      totalPages: 31,
    ),
    'bk_wasitiyyah': MutunDigitalEntry(
      id: 'bk_wasitiyyah',
      shamelaId: 22665,
      title: 'العقيدة الواسطية',
      author: 'أحمد بن عبد الحليم بن تيمية',
      totalPages: 72,
    ),
    'bk_waraqat': MutunDigitalEntry(
      id: 'bk_waraqat',
      shamelaId: 6297,
      title: 'الورقات في أصول الفقه',
      author: 'عبد الملك بن عبد الله الجويني (إمام الحرمين)',
      totalPages: 25,
    ),
    'bk_unwan_al_hukm': MutunDigitalEntry(
      id: 'bk_unwan_al_hukm',
      shamelaId: 6873,
      title: 'قصيدة عنوان الحكم (زيادة المرء في دنياه نقصان)',
      author: 'علي بن محمد البستي (أبو الفتح البستي)',
      totalPages: 10,
      isPoem: true,
    ),
    'bk_rahibiyyah': MutunDigitalEntry(
      id: 'bk_rahibiyyah',
      shamelaId: 11372,
      title: 'بغية الباحث عن جُمل الموارث (متن الرحبية)',
      author: 'محمد بن علي الرحبي',
      totalPages: 30,
      isPoem: true,
    ),
    'bk_aqidah_tahawiyyah': MutunDigitalEntry(
      id: 'bk_aqidah_tahawiyyah',
      shamelaId: 9568,
      title: 'العقيدة الطحاوية (بيان عقيدة أهل السنة والجماعة)',
      author: 'أحمد بن محمد الطحاوي',
      totalPages: 124,
    ),
    'bk_bulugh_maram': MutunDigitalEntry(
      id: 'bk_bulugh_maram',
      shamelaId: 17757,
      title: 'بلوغ المرام من أدلة الأحكام',
      author: 'أحمد بن علي بن حجر العسقلاني',
      totalPages: 1805,
    ),
    'bk_zad_mustaqni': MutunDigitalEntry(
      id: 'bk_zad_mustaqni',
      shamelaId: 11230,
      title: 'زاد المستقنع في اختصار المقنع',
      author: 'موسى بن أحمد الحجاوي',
      totalPages: 323,
    ),
  };

  /// Lookup digital entry by syllabus book ID
  static MutunDigitalEntry? getEntry(String bookId) => entries[bookId];

  /// Check if digital text is supported
  static bool hasDigitalText(String bookId) => entries.containsKey(bookId);
}
