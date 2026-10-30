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
      id: 'ibn_taymiyyah',
      displayName: 'شيخ الإسلام ابن تيمية',
      queryKeyword: 'ابن تيمية',
      role: 'إمام مجدد وفقيه محقق',
    ),
    SalafScholarItem(
      id: 'ibn_al_qayyim',
      displayName: 'الإمام ابن القيم الجوزية',
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
      displayName: 'الإمام شمس الدين الذهبي',
      queryKeyword: 'الذهبي',
      role: 'مؤرخ الإسلام ومحدث العصر',
    ),
    SalafScholarItem(
      id: 'al_shafii',
      displayName: 'الإمام محمد بن إدريس الشافعي',
      queryKeyword: 'الشافعي',
      role: 'إمام المذهب وناصر السنة',
    ),
    SalafScholarItem(
      id: 'al_hasan_al_basri',
      displayName: 'الحسن البصري',
      queryKeyword: 'الحسن البصري',
      role: 'سيد التابعين وزاهد عصره',
    ),
    SalafScholarItem(
      id: 'sufyan_al_thawri',
      displayName: 'سفيان الثوري',
      queryKeyword: 'سفيان الثوري',
      role: 'أمير المؤمنين في الحديث',
    ),
    SalafScholarItem(
      id: 'al_fudayl',
      displayName: 'الفضيل بن عياض',
      queryKeyword: 'الفضيل بن عياض',
      role: 'عابد الحرمين وقدوة الزهاد',
    ),
    SalafScholarItem(
      id: 'malik_bin_dinar',
      displayName: 'مالك بن دينار',
      queryKeyword: 'مالك بن دينار',
      role: 'علم الزهاد وأحد أئمة البصرة',
    ),
    SalafScholarItem(
      id: 'ibn_al_mubarak',
      displayName: 'عبد الله بن المبارك',
      queryKeyword: 'بن المبارك',
      role: 'إمام الجهاد والزهد والحديث',
    ),
    SalafScholarItem(
      id: 'umar_bin_abdulaziz',
      displayName: 'عمر بن عبد العزيز',
      queryKeyword: 'عمر بن عبد العزيز',
      role: 'الخليفة الراشد والزاهد التقي',
    ),
    SalafScholarItem(
      id: 'abu_bakr',
      displayName: 'أبو بكر الصديق رضي الله عنه',
      queryKeyword: 'أبو بكر',
      role: 'خليفة رسول الله ﷺ وصديق الأمة',
    ),
    SalafScholarItem(
      id: 'umar_bin_khattab',
      displayName: 'عمر بن الخطاب رضي الله عنه',
      queryKeyword: 'عمر بن الخطاب',
      role: 'أمير المؤمنين والفاروق',
    ),
    SalafScholarItem(
      id: 'ali_bin_abi_talib',
      displayName: 'علي بن أبي طالب رضي الله عنه',
      queryKeyword: 'علي بن أبي طالب',
      role: 'رابع الخلفاء الراشدين وباب العلم',
    ),
    SalafScholarItem(
      id: 'ibn_masud',
      displayName: 'عبد الله بن مسعود رضي الله عنه',
      queryKeyword: 'بن مسعود',
      role: 'فقيه الأمة وصاحب سر رسول الله ﷺ',
    ),
    SalafScholarItem(
      id: 'abu_hurairah',
      displayName: 'أبو هريرة رضي الله عنه',
      queryKeyword: 'أبو هريرة',
      role: 'حافظ الصحابة وراوية الإسلام',
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
      id: 'ibn_abbas',
      displayName: 'عبد الله بن عباس رضي الله عنهما',
      queryKeyword: 'بن عباس',
      role: 'حبر الأمة وترجمان القرآن',
    ),
    SalafScholarItem(
      id: 'ibn_umar',
      displayName: 'عبد الله بن عمر رضي الله عنهما',
      queryKeyword: 'بن عمر',
      role: 'المتبع الحريص على هدي النبوة',
    ),
    SalafScholarItem(
      id: 'abu_sulayman_al_darani',
      displayName: 'أبو سليمان الداراني',
      queryKeyword: 'أبو سليمان الداراني',
      role: 'أحد أئمة أهل الشام في الزهد',
    ),
    SalafScholarItem(
      id: 'yahya_bin_muadh',
      displayName: 'يحيى بن معاذ الرازي',
      queryKeyword: 'يحيى بن معاذ',
      role: 'واعظ القلوب ولطيف الإشارات',
    ),
    SalafScholarItem(
      id: 'prophet_hadith',
      displayName: 'رسول الله ﷺ (الوصايا النبوية)',
      queryKeyword: 'رسول الله ﷺ',
      role: 'سيد الخلق وإمام المتقين',
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

