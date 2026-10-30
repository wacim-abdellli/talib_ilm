import 'package:flutter/material.dart';

@immutable
class SalafScholarItem {
  final String id;
  final String displayName;
  final String queryKeyword;
  final String role;

  const SalafScholarItem({
    required this.id,
    required this.displayName,
    required this.queryKeyword,
    required this.role,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalafScholarItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class SalafTopicItem {
  final String id;
  final String title;
  final IconData icon;
  final List<String> matchKeywords;

  const SalafTopicItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.matchKeywords,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalafTopicItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SalafFilterData {
  const SalafFilterData._();

  static const List<SalafScholarItem> scholars = [
    SalafScholarItem(
      id: 'all',
      displayName: 'الكل (جميع الأعلام والأئمة)',
      queryKeyword: 'الكل',
      role: 'جميع الرواة والأئمة والصحابة',
    ),
    SalafScholarItem(
      id: 'prophet_hadith',
      displayName: 'رسول الله ﷺ (الوصايا النبوية)',
      queryKeyword: 'رسول الله ﷺ',
      role: 'سيد الخلق وإمام المتقين',
    ),
    SalafScholarItem(
      id: 'abu_bakr',
      displayName: 'أبو بكر الصديق رضي الله عنه',
      queryKeyword: 'أبو بكر الصديق',
      role: 'خليفة رسول الله ﷺ وصديق الأمة',
    ),
    SalafScholarItem(
      id: 'umar_bin_khattab',
      displayName: 'عمر بن الخطاب رضي الله عنه',
      queryKeyword: 'عمر بن الخطاب',
      role: 'أمير المؤمنين والفاروق',
    ),
    SalafScholarItem(
      id: 'uthman_bin_affan',
      displayName: 'عثمان بن عفان رضي الله عنه',
      queryKeyword: 'عثمان بن عفان',
      role: 'ذو النورين وثالث الخلفاء الراشدين',
    ),
    SalafScholarItem(
      id: 'ali_bin_abi_talib',
      displayName: 'علي بن أبي طالب رضي الله عنه',
      queryKeyword: 'علي بن أبي طالب',
      role: 'رابع الخلفاء الراشدين وباب العلم',
    ),
    SalafScholarItem(
      id: 'aisha',
      displayName: 'عائشة أم المؤمنين رضي الله عنها',
      queryKeyword: 'عائشة أم المؤمنين',
      role: 'الصديقة بنت الصديق وأفقه النساء',
    ),
    SalafScholarItem(
      id: 'ibn_masud',
      displayName: 'عبد الله بن مسعود رضي الله عنه',
      queryKeyword: 'عبد الله بن مسعود',
      role: 'فقيه الأمة وصاحب سر رسول الله ﷺ',
    ),
    SalafScholarItem(
      id: 'abu_hurairah',
      displayName: 'أبو هريرة رضي الله عنه',
      queryKeyword: 'أبو هريرة',
      role: 'حافظ الصحابة وراوية الإسلام',
    ),
    SalafScholarItem(
      id: 'ibn_umar',
      displayName: 'عبد الله بن عمر رضي الله عنهما',
      queryKeyword: 'عبد الله بن عمر',
      role: 'المتبع الحريص على هدي النبوة',
    ),
    SalafScholarItem(
      id: 'ibn_abbas',
      displayName: 'عبد الله بن عباس رضي الله عنهما',
      queryKeyword: 'عبد الله بن عباس',
      role: 'حبر الأمة وترجمان القرآن',
    ),
    SalafScholarItem(
      id: 'abu_al_darda',
      displayName: 'أبو الدرداء رضي الله عنه',
      queryKeyword: 'أبو الدرداء',
      role: 'حكيم الأمة وسيد القراء',
    ),
    SalafScholarItem(
      id: 'muadh_bin_jabal',
      displayName: 'معاذ بن جبل رضي الله عنه',
      queryKeyword: 'معاذ بن جبل',
      role: 'أعلم الأمة بالحلال والحرام',
    ),
    SalafScholarItem(
      id: 'anas_bin_malik',
      displayName: 'أنس بن مالك رضي الله عنه',
      queryKeyword: 'أنس بن مالك',
      role: 'خادم رسول الله ﷺ',
    ),
    SalafScholarItem(
      id: 'hudhayfah',
      displayName: 'حذيفة بن اليمان رضي الله عنه',
      queryKeyword: 'حذيفة بن اليمان',
      role: 'صاحب سر رسول الله ﷺ',
    ),
    SalafScholarItem(
      id: 'al_hasan_al_basri',
      displayName: 'الحسن البصري',
      queryKeyword: 'الحسن البصري',
      role: 'سيد التابعين وزاهد عصره',
    ),
    SalafScholarItem(
      id: 'umar_bin_abdulaziz',
      displayName: 'عمر بن عبد العزيز',
      queryKeyword: 'عمر بن عبد العزيز',
      role: 'الخليفة الراشد والزاهد التقي',
    ),
    SalafScholarItem(
      id: 'said_bin_al_musayyib',
      displayName: 'سعيد بن المسيب',
      queryKeyword: 'سعيد بن المسيب',
      role: 'سيد التابعين وفقيه المدينة',
    ),
    SalafScholarItem(
      id: 'al_zuhri',
      displayName: 'ابن شهاب الزهري',
      queryKeyword: 'الزهري',
      role: 'إمام الحفاظ وأول مدون للحديث',
    ),
    SalafScholarItem(
      id: 'sufyan_al_thawri',
      displayName: 'سفيان الثوري',
      queryKeyword: 'سفيان الثوري',
      role: 'أمير المؤمنين في الحديث وزاهد الكوفة',
    ),
    SalafScholarItem(
      id: 'sufyan_bin_uyaynah',
      displayName: 'سفيان بن عيينة',
      queryKeyword: 'سفيان بن عيينة',
      role: 'إمام الحرم المكي ومحدث العصر',
    ),
    SalafScholarItem(
      id: 'al_fudayl',
      displayName: 'الفضيل بن عياض',
      queryKeyword: 'الفضيل بن عياض',
      role: 'عابد الحرمين وقدوة الزهاد',
    ),
    SalafScholarItem(
      id: 'ibn_al_mubarak',
      displayName: 'عبد الله بن المبارك',
      queryKeyword: 'عبد الله بن المبارك',
      role: 'إمام الجهاد والزهد والحديث',
    ),
    SalafScholarItem(
      id: 'malik_bin_dinar',
      displayName: 'مالك بن دينار',
      queryKeyword: 'مالك بن دينار',
      role: 'علم الزهاد وأحد أئمة البصرة',
    ),
    SalafScholarItem(
      id: 'ibrahim_bin_adham',
      displayName: 'إبراهيم بن أدهم',
      queryKeyword: 'إبراهيم بن أدهم',
      role: 'زاهد خراسان وقدوة الصالحين',
    ),
    SalafScholarItem(
      id: 'bishr_al_hafi',
      displayName: 'بشر بن الحارث الحافي',
      queryKeyword: 'بشر بن الحارث الحافي',
      role: 'الزاهد المشهور والقدوة في الورع',
    ),
    SalafScholarItem(
      id: 'yahya_bin_muadh',
      displayName: 'يحيى بن معاذ الرازي',
      queryKeyword: 'يحيى بن معاذ الرازي',
      role: 'واعظ القلوب ولطيف الإشارات',
    ),
    SalafScholarItem(
      id: 'abu_sulayman_al_darani',
      displayName: 'أبو سليمان الداراني',
      queryKeyword: 'أبو سليمان الداراني',
      role: 'أحد أئمة أهل الشام في الزهد',
    ),
    SalafScholarItem(
      id: 'al_awzai',
      displayName: 'الإمام عبد الرحمن الأوزاعي',
      queryKeyword: 'الأوزاعي',
      role: 'إمام أهل الشام وفقيههم الكبير',
    ),
    SalafScholarItem(
      id: 'mujahid',
      displayName: 'مجاهد بن جبر المكي',
      queryKeyword: 'مجاهد بن جبر',
      role: 'إمام التفسير وتلميذ ابن عباس',
    ),
    SalafScholarItem(
      id: 'qutadah',
      displayName: 'قتادة بن دعامة السدوسي',
      queryKeyword: 'قتادة بن دعامة',
      role: 'حافظ أهل البصرة ومفسرهم',
    ),
    SalafScholarItem(
      id: 'dhu_al_nun',
      displayName: 'ذو النون المصري',
      queryKeyword: 'ذو النون المصري',
      role: 'حكيم الصالحين وأحد زهاد مصر',
    ),
    SalafScholarItem(
      id: 'abu_hanifah',
      displayName: 'الإمام أبو حنيفة النعمان',
      queryKeyword: 'أبو حنيفة',
      role: 'إمام أهل الرأي وأحد الأئمة الأربعة',
    ),
    SalafScholarItem(
      id: 'malik_bin_anas',
      displayName: 'الإمام مالك بن أنس',
      queryKeyword: 'مالك بن أنس',
      role: 'إمام دار الهجرة وصاحب الموطأ',
    ),
    SalafScholarItem(
      id: 'al_shafii',
      displayName: 'الإمام الشافعي',
      queryKeyword: 'الشافعي',
      role: 'إمام المذهب وناصر السنة',
    ),
    SalafScholarItem(
      id: 'ahmad_bin_hanbal',
      displayName: 'الإمام أحمد بن حنبل',
      queryKeyword: 'أحمد بن حنبل',
      role: 'إمام أهل السنة والجماعة',
    ),
    SalafScholarItem(
      id: 'al_bukhari',
      displayName: 'الإمام البخاري',
      queryKeyword: 'البخاري',
      role: 'أمير المؤمنين في الحديث وصاحب الصحيح',
    ),
    SalafScholarItem(
      id: 'al_nawawi',
      displayName: 'الإمام محيي الدين النووي',
      queryKeyword: 'النووي',
      role: 'حافظ المذهب وصاحب رياض الصالحين',
    ),
    SalafScholarItem(
      id: 'ibn_hajar',
      displayName: 'الحافظ ابن حجر العسقلاني',
      queryKeyword: 'ابن حجر',
      role: 'أمير المؤمنين في الحديث وشارح البخاري',
    ),
    SalafScholarItem(
      id: 'al_khatib_al_baghdadi',
      displayName: 'الحافظ الخطيب البغدادي',
      queryKeyword: 'الخطيب البغدادي',
      role: 'مؤرخ بغداد وإمام علم الرواية',
    ),
    SalafScholarItem(
      id: 'ibn_abd_al_barr',
      displayName: 'الإمام ابن عبد البر الأندلسي',
      queryKeyword: 'ابن عبد البر',
      role: 'حافظ المغرب ومؤلف التمهيد',
    ),
    SalafScholarItem(
      id: 'ibn_hazm',
      displayName: 'الإمام ابن حزم الأندلسي',
      queryKeyword: 'ابن حزم',
      role: 'فقيه قرطبة وإمام الظاهرية',
    ),
    SalafScholarItem(
      id: 'ibn_taymiyyah',
      displayName: 'شيخ الإسلام ابن تيمية',
      queryKeyword: 'ابن تيمية',
      role: 'إمام مجدد وفقيه محقق',
    ),
    SalafScholarItem(
      id: 'ibn_al_qayyim',
      displayName: 'الإمام ابن القيم',
      queryKeyword: 'ابن القيم',
      role: 'طبيب القلوب ومحقق السلوك',
    ),
    SalafScholarItem(
      id: 'ibn_al_jawzi',
      displayName: 'الإمام ابن الجوزي',
      queryKeyword: 'ابن الجوزي',
      role: 'إمام الوعظ ورقائق القلوب',
    ),
    SalafScholarItem(
      id: 'ibn_rajab',
      displayName: 'الإمام ابن رجب الحنبلي',
      queryKeyword: 'ابن رجب',
      role: 'حافظ زاهد وشارح جوامع الكلم',
    ),
    SalafScholarItem(
      id: 'al_dhahabi',
      displayName: 'الإمام الذهبي',
      queryKeyword: 'الذهبي',
      role: 'مؤرخ الإسلام ومحدث العصر',
    ),
    SalafScholarItem(
      id: 'al_saadi',
      displayName: 'العلامة عبد الرحمن السعدي',
      queryKeyword: 'السعدي',
      role: 'مفسر العصر وفقيه القصيم',
    ),
    SalafScholarItem(
      id: 'ibn_uthaymeen',
      displayName: 'العلامة ابن عثيمين',
      queryKeyword: 'العثيمين',
      role: 'فقيه العصر والمربي الفاضل',
    ),
    SalafScholarItem(
      id: 'ibn_baz',
      displayName: 'الشيخ عبد العزيز بن باز',
      queryKeyword: 'بن باز',
      role: 'إمام أهل السنة ومفتي الديار',
    ),
    SalafScholarItem(
      id: 'bakr_abu_zayd',
      displayName: 'العلامة بكر أبو زيد',
      queryKeyword: 'بكر بن عبد الله أبو زيد',
      role: 'عضو هيئة كبار العلماء وصاحب الحلية',
    ),
    SalafScholarItem(
      id: 'al_albani',
      displayName: 'العلامة ناصر الدين الألباني',
      queryKeyword: 'الألباني',
      role: 'محدث العصر وناصر السنة',
    ),
    SalafScholarItem(
      id: 'al_turifi',
      displayName: 'الشيخ عبد العزيز الطريفي',
      queryKeyword: 'الطريفي',
      role: 'باحث ومحقق معاصر',
    ),
    SalafScholarItem(
      id: 'al_fawzan',
      displayName: 'معالي الشيخ صالح الفوزان',
      queryKeyword: 'الفوزان',
      role: 'عضو هيئة كبار العلماء',
    ),
    SalafScholarItem(
      id: 'al_badr',
      displayName: 'الشيخ عبد الرزاق البدر',
      queryKeyword: 'البدر',
      role: 'أستاذ العقيدة ومدرس المسجد النبوي',
    ),
    SalafScholarItem(
      id: 'al_shanqeeti',
      displayName: 'الشيخ محمد المختار الشنقيطي',
      queryKeyword: 'الشنقيطي',
      role: 'عضو هيئة كبار العلماء ومدرس الحرمين',
    ),
    SalafScholarItem(
      id: 'al_khamis',
      displayName: 'الشيخ عثمان الخميس',
      queryKeyword: 'الخميس',
      role: 'داعية ومحقق معاصر',
    ),
    SalafScholarItem(
      id: 'al_sheikh',
      displayName: 'معالي الشيخ صالح آل الشيخ',
      queryKeyword: 'آل الشيخ',
      role: 'باحث ومحقق في كتب العقيدة',
    ),
  ];

  static const List<SalafTopicItem> topics = [
    SalafTopicItem(
      id: 'all',
      title: 'الكل (جميع الموضوعات)',
      icon: Icons.all_inclusive_rounded,
      matchKeywords: [],
    ),
    SalafTopicItem(
      id: 'turifi_aql_naql',
      title: 'أسطر في العقل والنقل للطريفي',
      icon: Icons.auto_stories_rounded,
      matchKeywords: ['العقل والنقل', 'الطريفي'],
    ),
    SalafTopicItem(
      id: 'ibn_taymiyyah_books',
      title: 'فوائد من كتب ابن تيمية',
      icon: Icons.menu_book_rounded,
      matchKeywords: ['ابن تيمية', 'مجموع الفتاوى', 'الاستقامة', 'منهاج السنة', 'درء تعارض'],
    ),
    SalafTopicItem(
      id: 'ibn_al_qayyim_books',
      title: 'فوائد من كتب ابن القيم',
      icon: Icons.library_books_rounded,
      matchKeywords: ['ابن القيم', 'الفوائد', 'مدارج السالكين', 'زاد المعاد', 'الوابل الصيب', 'الداء والدواء'],
    ),
    SalafTopicItem(
      id: 'tadabbur_quran',
      title: 'خواطر قرآنية ووقفات تدبرية',
      icon: Icons.chrome_reader_mode_rounded,
      matchKeywords: ['خواطر قرآنية', 'وقفات تدبرية', 'تدبر', 'القرآن'],
    ),
    SalafTopicItem(
      id: 'sifat_al_safwah',
      title: 'صفة الصفوة وأخبار الصالحين',
      icon: Icons.import_contacts_rounded,
      matchKeywords: ['صفة الصفوة'],
    ),
    SalafTopicItem(
      id: 'hayat_al_salaf',
      title: 'حياة السلف وسيرهم',
      icon: Icons.history_edu_rounded,
      matchKeywords: ['حياة السلف', 'سير السلف'],
    ),
    SalafTopicItem(
      id: 'talab_ilm',
      title: 'في طلب العلم وآدابه',
      icon: Icons.menu_book_rounded,
      matchKeywords: ['طلب العلم', 'في طلب العلم', 'العلم'],
    ),
    SalafTopicItem(
      id: 'fadail_amal',
      title: 'فضائل الأعمال وجوامع الكلم',
      icon: Icons.workspace_premium_rounded,
      matchKeywords: ['فضائل الأعمال', 'فضائل', 'وصايا نبوية'],
    ),
    SalafTopicItem(
      id: 'akhlaq_adab',
      title: 'الأخلاق ومكارم الشيم',
      icon: Icons.favorite_border_rounded,
      matchKeywords: ['أخلاق', 'الأخلاق', 'آداب', 'الآداب', 'الحياء', 'الصدق'],
    ),
    SalafTopicItem(
      id: 'salawat_ibadat',
      title: 'الصلوات والعبادات والقيام',
      icon: Icons.mosque_rounded,
      matchKeywords: ['صلاة', 'الصلوات', 'قيام الليل', 'الصيام', 'عبادة'],
    ),
    SalafTopicItem(
      id: 'zuhd_raqaeq',
      title: 'الزهد والرقائق وتزكية النفوس',
      icon: Icons.spa_rounded,
      matchKeywords: ['الزهد والرقائق', 'الزهد', 'زهد', 'رقائق', 'ورع', 'الورع', 'الدنيا'],
    ),
    SalafTopicItem(
      id: 'mawaith_salaf',
      title: 'مواعظ وحكم السلف والصحابة',
      icon: Icons.format_quote_rounded,
      matchKeywords: ['مواعظ', 'موعظة', 'حكم', 'مختارات وحكم', 'حكم متنوعة'],
    ),
    SalafTopicItem(
      id: 'nahy_fitan',
      title: 'التحذير من المنهيات والفتن',
      icon: Icons.shield_outlined,
      matchKeywords: ['التحذير من المنهيات', 'المنهيات', 'فتن', 'الفتن', 'معصية', 'نفاق'],
    ),
    SalafTopicItem(
      id: 'quran_tadabbur',
      title: 'حال السلف مع القرآن وتدبره',
      icon: Icons.auto_stories_rounded,
      matchKeywords: ['حال السلف مع القرآن', 'القرآن', 'قرآن', 'تدبر'],
    ),
    SalafTopicItem(
      id: 'dhikr_dua',
      title: 'الذكر والدعاء والاستغفار',
      icon: Icons.volunteer_activism_rounded,
      matchKeywords: ['ذكر', 'الذكر', 'الذكـر', 'دعاء', 'الدعاء', 'استغفار'],
    ),
    SalafTopicItem(
      id: 'birr_walidayn',
      title: 'بر الوالدين وحقوق المسلم',
      icon: Icons.people_outline_rounded,
      matchKeywords: ['بر الوالدين', 'حقوق المسلم', 'صلة الرحم'],
    ),
  ];
}
