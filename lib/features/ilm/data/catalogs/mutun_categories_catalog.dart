/// Pure data catalog for categorized Mutun mirroring the authentic scholarly reference app.
class MutunItem {
  final String id;
  final String title;
  final String author;
  final String categoryId;
  final String countLabel; // e.g. "17 سطر" or "16 بيت"
  final bool isPoem;
  final int totalLinesOrVerses;
  final String description;
  final String? pdfPath;
  final int? shamelaId;
  final String audioUrlSini;
  final String audioUrlTayyib;

  const MutunItem({
    required this.id,
    required this.title,
    required this.author,
    required this.categoryId,
    required this.countLabel,
    required this.isPoem,
    required this.totalLinesOrVerses,
    required this.description,
    this.pdfPath,
    this.shamelaId,
    required this.audioUrlSini,
    required this.audioUrlTayyib,
  });
}

class MutunCategory {
  final String id;
  final String title;
  final String subtitle;
  final List<MutunItem> items;

  const MutunCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
  });
}

class MutunCategoriesCatalog {
  const MutunCategoriesCatalog._();

  static const String siniBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini';
  static const String tayyibBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/MuadhAlTayyib';

  static final List<MutunCategory> categories = [
    MutunCategory(
      id: 'talib_ilm',
      title: 'متون طالب العلم',
      subtitle: 'البرنامج المنهجي التأصيلي بمستوياته الخمسة',
      items: [
        const MutunItem(
          id: 'bk_adhkar_adab',
          title: 'الآداب والأذكار',
          author: 'جمع وترتيب الشيخ د. عبدالمحسن القاسم',
          categoryId: 'talib_ilm',
          countLabel: 'المستوى التمهيدي',
          isPoem: false,
          totalLinesOrVerses: 153,
          description:
              'كتاب يجمع الأذكار اليومية والآداب الشرعية التي يحتاجها طالب العلم، وقد اعتمدنا في إثبات النص على نشرة القاسم.',
          pdfPath: 'assets/pdfs/mutun/bk_adhkar_adab.pdf',
          shamelaId: 31307,
          audioUrlSini: '$siniBaseUrl/0101AlAthkaar_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0101AlAthkaar.mp3',
        ),
        const MutunItem(
          id: 'bk_nawaqid_islam',
          title: 'نواقض الإسلام',
          author: 'الإمام محمد بن عبد الوهاب',
          categoryId: 'talib_ilm',
          countLabel: '17 سطر',
          isPoem: false,
          totalLinesOrVerses: 17,
          description:
              'عبارة عن عشرة من نواقض الإسلام جمعها الإمام محمد بن عبد الوهاب نصيحة للمسلمين كي يعلموها ويحذروها. وقد اعتمدنا في إثبات النص على نشرة القاسم.',
          pdfPath: 'assets/pdfs/mutun/bk_nawaqid_islam.pdf',
          shamelaId: 30869,
          audioUrlSini:
              '$siniBaseUrl/0203NawaaqidAlIslaam_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0203NawaaqidAlIslaam.mp3',
        ),
        const MutunItem(
          id: 'bk_qawaid_arba',
          title: 'القواعد الأربع',
          author: 'الإمام محمد بن عبد الوهاب',
          categoryId: 'talib_ilm',
          countLabel: '31 سطر',
          isPoem: false,
          totalLinesOrVerses: 31,
          description:
              'أربع قواعد عظيمة في معرفة حقيقة التوحيد والشرك المستفادة من نصوص القرآن الكريم والسنة النبوية.',
          pdfPath: 'assets/pdfs/mutun/bk_qawaid_arba.pdf',
          shamelaId: 8524,
          audioUrlSini: '$siniBaseUrl/0202AlQawaidAlArba_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0202AlQawaidAlArba.mp3',
        ),
        const MutunItem(
          id: 'bk_usul_thalatha',
          title: 'الأصول الثلاثة وأدلتها',
          author: 'الإمام محمد بن عبد الوهاب',
          categoryId: 'talib_ilm',
          countLabel: '123 سطر',
          isPoem: false,
          totalLinesOrVerses: 123,
          description:
              'معرفة العبد ربه ودينه ونبيه محمداً ﷺ، وهي الأصول الثلاثة التي يُسأل عنها العبد في قبره.',
          pdfPath: 'assets/pdfs/mutun/bk_usul_thalatha.pdf',
          shamelaId: 239,
          audioUrlSini:
              '$siniBaseUrl/0201ThalaathatAlUsul_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0201ThalaathatAlUsul.mp3',
        ),
        const MutunItem(
          id: 'bk_arbaeen_nawawi',
          title: 'الأربعون النووية مع زيادة ابن رجب',
          author: 'الإمام يحيى بن شرف النووي',
          categoryId: 'talib_ilm',
          countLabel: '50 حديثاً',
          isPoem: false,
          totalLinesOrVerses: 50,
          description:
              'جوامع الكلم وقواعد الدين من الأحاديث النبوية الصحيحة التي عليها مدار الإسلام.',
          pdfPath: 'assets/pdfs/mutun/bk_arbaeen_nawawi.pdf',
          shamelaId: 147927,
          audioUrlSini:
              '$siniBaseUrl/0204AlArbaunAnNawawiyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0204AlArbaunAnNawawiyah.mp3',
        ),
        const MutunItem(
          id: 'bk_tuhfat_atfal',
          title: 'تحفة الأطفال والغلمان في تجويد القرآن',
          author: 'سليمان بن حسين الجمزوري',
          categoryId: 'talib_ilm',
          countLabel: '61 بيت',
          isPoem: true,
          totalLinesOrVerses: 61,
          description:
              'منظومة بديعة ميسرة في أحكام التجويد الأساسية: النون الساكنة والتنوين والميم والمدود.',
          pdfPath: 'assets/pdfs/mutun/bk_tuhfat_atfal.pdf',
          shamelaId: 9632,
          audioUrlSini:
              '$siniBaseUrl/0301TuhfatAlAtfaal_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0301TuhfatAlAtfaal.mp3',
        ),
        const MutunItem(
          id: 'bk_shuroot_salah',
          title: 'شروط الصلاة وأركانها وواجباتها',
          author: 'الإمام محمد بن عبد الوهاب',
          categoryId: 'talib_ilm',
          countLabel: '40 سطر',
          isPoem: false,
          totalLinesOrVerses: 40,
          description:
              'بيان شروط الصلاة التسعة، وأركانها الأربعة عشر، وواجباتها الثمانية بأدلتها الشرعية.',
          pdfPath: 'assets/pdfs/mutun/bk_shuroot_salah.pdf',
          shamelaId: 239,
          audioUrlSini: '$siniBaseUrl/0302ShurutAsSalah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0302ShurutAsSalah.mp3',
        ),
        const MutunItem(
          id: 'bk_kitab_tawheed',
          title: 'كتاب التوحيد الذي هو حق الله على العبيد',
          author: 'الإمام محمد بن عبد الوهاب',
          categoryId: 'talib_ilm',
          countLabel: '66 باباً',
          isPoem: false,
          totalLinesOrVerses: 147,
          description:
              'عمدة كتب التوحيد والعبادة وإخلاص الدين لله ونبذ الشرك وذرائعه بالأدلة من الكتاب والسنة.',
          pdfPath: 'assets/pdfs/mutun/bk_kitab_tawheed.pdf',
          shamelaId: 11318,
          audioUrlSini: '$siniBaseUrl/0303KitaabAtTawheed_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0303KitaabAtTawheed.mp3',
        ),
        const MutunItem(
          id: 'bk_manzumah_baiquoni',
          title: 'المنظومة البيقونية في مصطلح الحديث',
          author: 'عمر بن محمد البيقوني',
          categoryId: 'talib_ilm',
          countLabel: '34 بيت',
          isPoem: true,
          totalLinesOrVerses: 34,
          description:
              'منظومة رشيقة جامعة لأقسام الحديث ومصطلحات المحدثين وضوابط الرواية.',
          pdfPath: 'assets/pdfs/mutun/bk_manzumah_baiquoni.pdf',
          shamelaId: 8567,
          audioUrlSini: '$siniBaseUrl/0401AlBayqooni_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0401AlBayqooni.mp3',
        ),
        const MutunItem(
          id: 'bk_manzumah_albiri',
          title: 'قصيدة أبي إسحاق الإلبيري (تائية الزهد)',
          author: 'إبراهيم بن مسعود الإلبيري',
          categoryId: 'talib_ilm',
          countLabel: '115 بيت',
          isPoem: true,
          totalLinesOrVerses: 115,
          description:
              'قصيدة بديعة في الحث على طلب العلم وبيان فضله والزهد في فاني الدنيا والموعظة الحسنة.',
          pdfPath: 'assets/pdfs/mutun/bk_manzumah_albiri.pdf',
          shamelaId: 6869,
          audioUrlSini: '$siniBaseUrl/0402AlIlbiri_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0402AlIlbiri.mp3',
        ),
        const MutunItem(
          id: 'bk_ajrumiyyah',
          title: 'المقدمة الآجرومية في مبادئ علم العربية',
          author: 'ابن آجروم الصنهاجي',
          categoryId: 'talib_ilm',
          countLabel: '31 صفحة',
          isPoem: false,
          totalLinesOrVerses: 31,
          description:
              'المتن التأسيسي الأصيل في قواعد الإعراب والنحو العربي لكل مبتدئ في العربية.',
          pdfPath: 'assets/pdfs/mutun/bk_ajrumiyyah.pdf',
          shamelaId: 11371,
          audioUrlSini:
              '$siniBaseUrl/0403AlAajurrumiyyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0403AlAajurrumiyyah.mp3',
        ),
        const MutunItem(
          id: 'bk_wasitiyyah',
          title: 'العقيدة الواسطية',
          author: 'شيخ الإسلام ابن تيمية',
          categoryId: 'talib_ilm',
          countLabel: '257 سطر',
          isPoem: false,
          totalLinesOrVerses: 257,
          description:
              'تحرير اعتقاد أهل السنة والجماعة في أسماء الله وصفاته واليوم الآخر والقدر والصحابة الكرام.',
          pdfPath: 'assets/pdfs/mutun/bk_wasitiyyah.pdf',
          shamelaId: 22665,
          audioUrlSini: '$siniBaseUrl/0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0404AlWaasitiyyah.mp3',
        ),
        const MutunItem(
          id: 'bk_waraqat',
          title: 'الورقات في أصول الفقه',
          author: 'إمام الحرمين الجويني',
          categoryId: 'talib_ilm',
          countLabel: '165 سطر',
          isPoem: false,
          totalLinesOrVerses: 165,
          description:
              'مقدمة وجيزة جامعة في أبواب أصول الفقه، والأحكام الشرعية، والدلالات والاجتهاد.',
          pdfPath: 'assets/pdfs/mutun/bk_waraqat.pdf',
          shamelaId: 6297,
          audioUrlSini: '$siniBaseUrl/0501AlWaraqat_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0501AlWaraqat.mp3',
        ),
        const MutunItem(
          id: 'bk_unwan_al_hukm',
          title: 'قصيدة عنوان الحكم (زيادة المرء)',
          author: 'أبو الفتح البستي',
          categoryId: 'talib_ilm',
          countLabel: '45 بيت',
          isPoem: true,
          totalLinesOrVerses: 45,
          description:
              'من عيون الشعر العربي والحكمة الأخلاقية وحسن معاملة الناس وتربية النفس.',
          pdfPath: 'assets/pdfs/mutun/bk_unwan_al_hukm.pdf',
          shamelaId: 6873,
          audioUrlSini: '$siniBaseUrl/0502UnwanAlHikm_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0502UnwanAlHikm.mp3',
        ),
        const MutunItem(
          id: 'bk_rahibiyyah',
          title: 'بغية الباحث عن جمل الموارث (الرحبية)',
          author: 'محمد بن علي الرحبي',
          categoryId: 'talib_ilm',
          countLabel: '175 بيت',
          isPoem: true,
          totalLinesOrVerses: 175,
          description:
              'عمدة منظومات علم الفرائض والمواريث وقسمة التركات في الفقه الإسلامي.',
          pdfPath: 'assets/pdfs/mutun/bk_rahibiyyah.pdf',
          shamelaId: 11372,
          audioUrlSini: '$siniBaseUrl/0503ArRahbiyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0503ArRahbiyah.mp3',
        ),
        const MutunItem(
          id: 'bk_aqidah_tahawiyyah',
          title: 'العقيدة الطحاوية (بيان عقيدة أهل السنة)',
          author: 'الإمام أحمد بن محمد الطحاوي',
          categoryId: 'talib_ilm',
          countLabel: '124 سطر',
          isPoem: false,
          totalLinesOrVerses: 124,
          description:
              'بيان عقيدة أهل السنة والجماعة على مذهب فقهاء الملة سلف الأمة الصالحين.',
          pdfPath: 'assets/pdfs/mutun/bk_aqidah_tahawiyyah.pdf',
          shamelaId: 9568,
          audioUrlSini: '$siniBaseUrl/0504AtTahawiyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0504AtTahawiyah.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'aqidah',
      title: 'العقيدة',
      subtitle: 'متون التوحيد وأصول الدين والإيمان',
      items: [
        const MutunItem(
          id: 'bk_nawaqid_islam',
          title: 'نواقض الإسلام',
          author: 'محمد بن عبد الوهاب',
          categoryId: 'aqidah',
          countLabel: '17 سطر',
          isPoem: false,
          totalLinesOrVerses: 17,
          description:
              'عبارة عن عشرة من نواقض الإسلام جمعها الإمام محمد بن عبد الوهاب نصيحة للمسلمين كي يعلموها ويحذروها. وقد اعتمدنا في إثبات النص على نشرة القاسم.',
          pdfPath: 'assets/pdfs/mutun/bk_nawaqid_islam.pdf',
          shamelaId: 30869,
          audioUrlSini:
              '$siniBaseUrl/0203NawaaqidAlIslaam_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0203NawaaqidAlIslaam.mp3',
        ),
        const MutunItem(
          id: 'bk_usul_thalatha',
          title: 'الأصول الثلاثة',
          author: 'محمد بن عبد الوهاب',
          categoryId: 'aqidah',
          countLabel: '123 سطر',
          isPoem: false,
          totalLinesOrVerses: 123,
          description:
              'معرفة العبد ربه ودينه ونبيه محمداً ﷺ، وهي الأصول الثلاثة التي يُسأل عنها العبد في قبره.',
          pdfPath: 'assets/pdfs/mutun/bk_usul_thalatha.pdf',
          shamelaId: 239,
          audioUrlSini:
              '$siniBaseUrl/0201ThalaathatAlUsul_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0201ThalaathatAlUsul.mp3',
        ),
        const MutunItem(
          id: 'bk_qawaid_arba',
          title: 'القواعد الأربع',
          author: 'محمد بن عبد الوهاب',
          categoryId: 'aqidah',
          countLabel: '31 سطر',
          isPoem: false,
          totalLinesOrVerses: 31,
          description:
              'أربع قواعد عظيمة في معرفة حقيقة التوحيد والشرك المستفادة من نصوص القرآن الكريم.',
          pdfPath: 'assets/pdfs/mutun/bk_qawaid_arba.pdf',
          shamelaId: 8524,
          audioUrlSini: '$siniBaseUrl/0202AlQawaidAlArba_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0202AlQawaidAlArba.mp3',
        ),
        const MutunItem(
          id: 'bk_lamiyyah_ibntaimiyah',
          title: 'القصيدة اللامية',
          author: 'شيخ الإسلام ابن تيمية',
          categoryId: 'aqidah',
          countLabel: '16 بيت',
          isPoem: true,
          totalLinesOrVerses: 16,
          description:
              'لامية شيخ الإسلام الشهيرة في بيان عقيدته ومحبته لصحابة رسول الله ﷺ.',
          pdfPath: 'assets/pdfs/mutun/bk_wasitiyyah.pdf',
          shamelaId: 22665,
          audioUrlSini: '$siniBaseUrl/0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0404AlWaasitiyyah.mp3',
        ),
        const MutunItem(
          id: 'bk_raiyyah_sunnah',
          title: 'القصيدة الرائية في السنة',
          author: 'أبو القاسم الزنجاني',
          categoryId: 'aqidah',
          countLabel: '44 بيت',
          isPoem: true,
          totalLinesOrVerses: 44,
          description:
              'رائية الزنجاني في اتباع السنة والتمسك بالأثر ومجانبة أهل الأهواء والبدع.',
          pdfPath: 'assets/pdfs/mutun/bk_aqidah_tahawiyyah.pdf',
          shamelaId: 9568,
          audioUrlSini: '$siniBaseUrl/0504AtTahawiyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0504AtTahawiyah.mp3',
        ),
        const MutunItem(
          id: 'bk_manzumah_haiyyah',
          title: 'المنظومة الحائية',
          author: 'ابن أبي داود السجستاني',
          categoryId: 'aqidah',
          countLabel: '34 بيت',
          isPoem: true,
          totalLinesOrVerses: 34,
          description:
              'تمسك بحبل الله واتبع الهدى... حائية ابن أبي داود في السنة والاتباع.',
          pdfPath: 'assets/pdfs/mutun/bk_aqidah_tahawiyyah.pdf',
          shamelaId: 9568,
          audioUrlSini: '$siniBaseUrl/0504AtTahawiyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0504AtTahawiyah.mp3',
        ),
        const MutunItem(
          id: 'bk_aqidah_raziyayn',
          title: 'عقيدة الرازيين',
          author: 'أبو حاتم وأبو زرعة الرازيان',
          categoryId: 'aqidah',
          countLabel: '35 سطر',
          isPoem: false,
          totalLinesOrVerses: 35,
          description:
              'ما أدرك عليه إماما أهل الحديث في كل الأمصار من أصول السنة والجماعة.',
          pdfPath: 'assets/pdfs/mutun/bk_wasitiyyah.pdf',
          shamelaId: 22665,
          audioUrlSini: '$siniBaseUrl/0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0404AlWaasitiyyah.mp3',
        ),
        const MutunItem(
          id: 'bk_kashf_shubuhat',
          title: 'كشف الشبهات',
          author: 'الإمام محمد بن عبد الوهاب',
          categoryId: 'aqidah',
          countLabel: '260 سطر',
          isPoem: false,
          totalLinesOrVerses: 260,
          description:
              'كشف الشبهات وتفنيد المزاعم حول إخلاص العبادة لله وحده لا شريك له.',
          pdfPath: 'assets/pdfs/mutun/bk_kitab_tawheed.pdf',
          shamelaId: 11318,
          audioUrlSini: '$siniBaseUrl/0303KitaabAtTawheed_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0303KitaabAtTawheed.mp3',
        ),
        const MutunItem(
          id: 'bk_wasitiyyah',
          title: 'العقيدة الواسطية',
          author: 'شيخ الإسلام ابن تيمية',
          categoryId: 'aqidah',
          countLabel: '257 سطر',
          isPoem: false,
          totalLinesOrVerses: 257,
          description:
              'تحرير اعتقاد أهل السنة والجماعة في أسماء الله وصفاته واليوم الآخر والقدر.',
          pdfPath: 'assets/pdfs/mutun/bk_wasitiyyah.pdf',
          shamelaId: 22665,
          audioUrlSini: '$siniBaseUrl/0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0404AlWaasitiyyah.mp3',
        ),
        const MutunItem(
          id: 'bk_aqidah_tahawiyyah',
          title: 'العقيدة الطحاوية',
          author: 'الإمام أبو جعفر الطحاوي',
          categoryId: 'aqidah',
          countLabel: '124 سطر',
          isPoem: false,
          totalLinesOrVerses: 124,
          description:
              'بيان عقيدة أهل السنة والجماعة على مذهب فقهاء الملة سلف الأمة الصالحين.',
          pdfPath: 'assets/pdfs/mutun/bk_aqidah_tahawiyyah.pdf',
          shamelaId: 9568,
          audioUrlSini: '$siniBaseUrl/0504AtTahawiyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0504AtTahawiyah.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'hadith',
      title: 'الحديث',
      subtitle: 'متون السنة ومصطلح الحديث النبوي',
      items: [
        const MutunItem(
          id: 'bk_arbaeen_nawawi',
          title: 'الأربعون النووية مع زيادة ابن رجب',
          author: 'الإمام يحيى بن شرف النووي',
          categoryId: 'hadith',
          countLabel: '50 حديثاً',
          isPoem: false,
          totalLinesOrVerses: 50,
          description:
              'جوامع الكلم وقواعد الدين من الأحاديث النبوية الصحيحة التي عليها مدار الإسلام.',
          pdfPath: 'assets/pdfs/mutun/bk_arbaeen_nawawi.pdf',
          shamelaId: 147927,
          audioUrlSini:
              '$siniBaseUrl/0204AlArbaunAnNawawiyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0204AlArbaunAnNawawiyah.mp3',
        ),
        const MutunItem(
          id: 'bk_manzumah_baiquoni',
          title: 'المنظومة البيقونية في المصطلح',
          author: 'عمر بن محمد البيقوني',
          categoryId: 'hadith',
          countLabel: '34 بيت',
          isPoem: true,
          totalLinesOrVerses: 34,
          description:
              'منظومة رشيقة جامعة لأقسام الحديث ومصطلحات المحدثين وضوابط الرواية.',
          pdfPath: 'assets/pdfs/mutun/bk_manzumah_baiquoni.pdf',
          shamelaId: 8567,
          audioUrlSini: '$siniBaseUrl/0401AlBayqooni_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0401AlBayqooni.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'fiqh',
      title: 'الفقه',
      subtitle: 'أحكام العبادات والمعاملات الفقهية',
      items: [
        const MutunItem(
          id: 'bk_shuroot_salah',
          title: 'شروط الصلاة وأركانها وواجباتها',
          author: 'محمد بن عبد الوهاب',
          categoryId: 'fiqh',
          countLabel: '40 سطر',
          isPoem: false,
          totalLinesOrVerses: 40,
          description:
              'بيان شروط الصلاة وأركانها وواجباتها وسننها ومبطلاتها بالأدلة الشرعية.',
          pdfPath: 'assets/pdfs/mutun/bk_shuroot_salah.pdf',
          shamelaId: 239,
          audioUrlSini: '$siniBaseUrl/0302ShurutAsSalah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0302ShurutAsSalah.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'usul_fiqh',
      title: 'أصول الفقه',
      subtitle: 'قواعد الاستنباط والأدلة الشرعية',
      items: [
        const MutunItem(
          id: 'bk_waraqat',
          title: 'الورقات في أصول الفقه',
          author: 'إمام الحرمين الجويني',
          categoryId: 'usul_fiqh',
          countLabel: '165 سطر',
          isPoem: false,
          totalLinesOrVerses: 165,
          description:
              'مقدمة وجيزة جامعة في أبواب أصول الفقه، والأحكام الشرعية، والدلالات والاجتهاد.',
          pdfPath: 'assets/pdfs/mutun/bk_waraqat.pdf',
          shamelaId: 6297,
          audioUrlSini: '$siniBaseUrl/0501AlWaraqat_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0501AlWaraqat.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'faraid',
      title: 'الفرائض',
      subtitle: 'علم المواريث وقسمة التركات',
      items: [
        const MutunItem(
          id: 'bk_rahibiyyah',
          title: 'متن الرحبية (بغية الباحث)',
          author: 'محمد بن علي الرحبي',
          categoryId: 'faraid',
          countLabel: '175 بيت',
          isPoem: true,
          totalLinesOrVerses: 175,
          description:
              'عمدة منظومات علم الفرائض والمواريث وقسمة التركات في الفقه الإسلامي.',
          pdfPath: 'assets/pdfs/mutun/bk_rahibiyyah.pdf',
          shamelaId: 11372,
          audioUrlSini: '$siniBaseUrl/0503ArRahbiyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0503ArRahbiyah.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'adab',
      title: 'الآداب الإسلامية',
      subtitle: 'منظومات الزهد والحكمة والأخلاق',
      items: [
        const MutunItem(
          id: 'bk_manzumah_albiri',
          title: 'قصيدة أبي إسحاق الإلبيري',
          author: 'إبراهيم بن مسعود الإلبيري',
          categoryId: 'adab',
          countLabel: '115 بيت',
          isPoem: true,
          totalLinesOrVerses: 115,
          description:
              'قصيدة بديعة في الحث على طلب العلم وبيان فضله والزهد في فاني الدنيا.',
          pdfPath: 'assets/pdfs/mutun/bk_manzumah_albiri.pdf',
          shamelaId: 6869,
          audioUrlSini: '$siniBaseUrl/0402AlIlbiri_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0402AlIlbiri.mp3',
        ),
        const MutunItem(
          id: 'bk_unwan_al_hukm',
          title: 'عنوان الحكم (زيادة المرء)',
          author: 'أبو الفتح البستي',
          categoryId: 'adab',
          countLabel: '45 بيت',
          isPoem: true,
          totalLinesOrVerses: 45,
          description:
              'من عيون الشعر العربي والحكمة الأخلاقية وحسن معاملة الناس.',
          pdfPath: 'assets/pdfs/mutun/bk_unwan_al_hukm.pdf',
          shamelaId: 6873,
          audioUrlSini: '$siniBaseUrl/0502UnwanAlHikm_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0502UnwanAlHikm.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'adhkar',
      title: 'الأذكار',
      subtitle: 'أذكار اليوم والليلة والأدعية المأثورة',
      items: [
        const MutunItem(
          id: 'bk_adhkar_adab',
          title: 'الآداب والأذكار',
          author: 'جمع وترتيب الشيخ د. عبدالمحسن القاسم',
          categoryId: 'adhkar',
          countLabel: 'المستوى التمهيدي',
          isPoem: false,
          totalLinesOrVerses: 153,
          description:
              'كتاب يجمع الأذكار اليومية والآداب الشرعية التي يحتاجها طالب العلم.',
          pdfPath: 'assets/pdfs/mutun/bk_adhkar_adab.pdf',
          shamelaId: 31307,
          audioUrlSini: '$siniBaseUrl/0101AlAthkaar_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0101AlAthkaar.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'children',
      title: 'قسم الأطفال',
      subtitle: 'متون التجويد والعقيدة المبسطة للناشئة',
      items: [
        const MutunItem(
          id: 'bk_tuhfat_atfal',
          title: 'تحفة الأطفال والغلمان',
          author: 'سليمان بن حسين الجمزوري',
          categoryId: 'children',
          countLabel: '61 بيت',
          isPoem: true,
          totalLinesOrVerses: 61,
          description:
              'منظومة بديعة ميسرة في أحكام التجويد الأساسية للأطفال والناشئة.',
          pdfPath: 'assets/pdfs/mutun/bk_tuhfat_atfal.pdf',
          shamelaId: 9632,
          audioUrlSini:
              '$siniBaseUrl/0301TuhfatAlAtfaal_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0301TuhfatAlAtfaal.mp3',
        ),
      ],
    ),
    MutunCategory(
      id: 'additional',
      title: 'المتون الإضافية',
      subtitle: 'المطولات والمنظومات في علوم الشريعة والعربية',
      items: [
        const MutunItem(
          id: 'bk_ajrumiyyah',
          title: 'المقدمة الآجرومية في النحو',
          author: 'ابن آجروم الصنهاجي',
          categoryId: 'additional',
          countLabel: '31 صفحة',
          isPoem: false,
          totalLinesOrVerses: 31,
          description:
              'المتن التأسيسي الأصيل في قواعد الإعراب والنحو العربي.',
          pdfPath: 'assets/pdfs/mutun/bk_ajrumiyyah.pdf',
          shamelaId: 11371,
          audioUrlSini:
              '$siniBaseUrl/0403AlAajurrumiyyah_AbdulAzizAsSini.mp3',
          audioUrlTayyib: '$tayyibBaseUrl/0403AlAajurrumiyyah.mp3',
        ),
      ],
    ),
  ];

  static MutunItem? getItemById(String id) {
    for (final cat in categories) {
      for (final item in cat.items) {
        if (item.id == id) return item;
      }
    }
    return null;
  }
}
