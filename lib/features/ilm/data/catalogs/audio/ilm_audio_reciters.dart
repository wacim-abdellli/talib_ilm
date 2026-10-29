import '../../models/book_audio_models.dart';

class MutunReciterDefaults {
  const MutunReciterDefaults._();

  static const sini = MutunReciter(
    id: 'sini',
    name: 'د. عبد العزيز الصيني',
    description: 'قراءة محققة متقنة وفق منهج متون طالب العلم بالمسجد النبوي',
  );

  static const haliba = MutunReciter(
    id: 'haliba',
    name: 'د. راشد بن فهد الحليبة',
    description: 'تسجيلات كتب صوتية استوديوية هادئة ومتقنة (مشروع بوح)',
  );

  static const shaydzmi = MutunReciter(
    id: 'shaydzmi',
    name: 'القارئ أبو أحمد رشيد الشيظمي',
    description: 'قراءة صوتية محققة وواضحة للمتون والرسائل العلمية',
  );

  static const fahad = MutunReciter(
    id: 'fahad',
    name: 'الشيخ طه الفهد',
    description: 'قراءة المنظومات العلمية بضبط عروضي وأداء شجي متقن',
  );

  static const suwaid = MutunReciter(
    id: 'suwaid',
    name: 'د. أيمن رشدي سويد',
    description: 'قراءة تعليمية محررة لمتون التجويد والقراءات',
  );

  static const ghamdi = MutunReciter(
    id: 'ghamdi',
    name: 'الشيخ سعد بن سعيد الغامدي',
    description: 'أداء صوتي ندي ومقسم على الأبواب لمنظومات التجويد',
  );

  static const afasy = MutunReciter(
    id: 'afasy',
    name: 'الشيخ مشاري راشد العفاسي',
    description: 'قراءة متون التجويد والمنظومات الكبرى مقسمة على الأبواب',
  );

  static const nafees = MutunReciter(
    id: 'nafees',
    name: 'القارئ أحمد النفيس',
    description: 'إلقاء صوتي مؤثر لمنظومات الآداب وطلب العلم',
  );

  static const sunaid = MutunReciter(
    id: 'sunaid',
    name: 'القارئ عادل السنيد',
    description: 'قراءة متأنية مقسمة على أبواب منظومات التجويد للحفظ',
  );

  static const hashem = MutunReciter(
    id: 'hashem',
    name: 'القارئ صلاح الهاشم',
    description: 'أداء صوتي رصين لمنظومات التجويد والأحكام',
  );

  static const wazzan = MutunReciter(
    id: 'wazzan',
    name: 'القارئ عمر الوزان',
    description: 'قراءة حديثية متأنية مقسمة حديثاً بحديث',
  );

  static const shulaimi = MutunReciter(
    id: 'shulaimi',
    name: 'القارئ خالد الشليمي',
    description: 'قراءة مقسمة على الفصول لمنظومة سلم الوصول في العقيدة',
  );

  static const shuwaihi = MutunReciter(
    id: 'shuwaihi',
    name: 'الشيخ سليمان الشويهي',
    description: 'قراءة باباً بباب لكتاب التوحيد بأداء واضح ومضبوط',
  );

  static const ayouni = MutunReciter(
    id: 'ayouni',
    name: 'أ.د. سليمان العيوني',
    description: 'قراءة علمية محققة مقسمة على أبواب ألفية ابن مالك',
  );

  static const basati = MutunReciter(
    id: 'basati',
    name: 'الشيخ عمرو البساطي',
    description: 'قراءة كاملة متقنة لأمهات كتب الفقه والسيرة والرقائق',
  );

  static const duraihim = MutunReciter(
    id: 'duraihim',
    name: 'الشيخ حمد الدريهم',
    description: 'قراءة كاملة لأبواب رياض الصالحين بضبط وإتقان',
  );

  static const khazaen = MutunReciter(
    id: 'khazaen',
    name: 'مؤسسة خزائن الرحمن العلمية',
    description: 'إنتاج صوتي علمي كامل لكتب التفسير والسيرة والتراث',
  );

  static const badr = MutunReciter(
    id: 'badr',
    name: 'الشيخ د. عبد الرزاق البدر',
    description: 'مجالس قراءة المتن والشرح بالمسجد النبوي الشريف',
  );

  static const sunnahMasmuah = MutunReciter(
    id: 'sunnah_masmuah',
    name: 'مشروع السنة المقروءة',
    description: 'قراءة صوتية حديثية كاملة لكتب الصحاح والسنن',
  );

  static const faqeeh = MutunReciter(
    id: 'faqeeh',
    name: 'القارئ عبد الغني الفقيه',
    description: 'تسجيل صوتي معتمد لنخبة من المتون العلمية',
  );

  static const bahour = MutunReciter(
    id: 'bahour',
    name: 'القارئ عبد الرحمن بحور',
    description: 'تسجيل صوتي معتمد في منصة حفاظ المتون',
  );

  static const List<MutunReciter> all = [
    sini,
    haliba,
    shaydzmi,
    fahad,
    suwaid,
    ghamdi,
    afasy,
    nafees,
    sunaid,
    hashem,
    wazzan,
    shulaimi,
    shuwaihi,
    ayouni,
    basati,
    duraihim,
    khazaen,
    badr,
    sunnahMasmuah,
    faqeeh,
    bahour,
  ];
}
