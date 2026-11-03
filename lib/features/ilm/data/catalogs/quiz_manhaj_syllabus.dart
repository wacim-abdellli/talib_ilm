import '../models/islamic_quiz_models.dart';

/// Descriptor for a sequential scholarly level in an authentic Islamic curriculum (منهج تأصيلي تدريجي).
class ManhajLevelDescriptor {
  final String title;
  final String description;
  final String stage; // 'المرحلة التأسيسية', 'المرحلة التأصيلية', 'مرحلة التمكين والإتقان'

  const ManhajLevelDescriptor({
    required this.title,
    required this.description,
    required this.stage,
  });
}

/// Comprehensive master syllabus defining structured curriculum levels across all 11 Islamic sciences.
class QuizManhajSyllabus {
  QuizManhajSyllabus._();

  static const String stageFoundation = 'المرحلة التأسيسية';
  static const String stageIntermediate = 'المرحلة التأصيلية';
  static const String stageMastery = 'مرحلة التمكين والإتقان';

  static const Map<String, List<ManhajLevelDescriptor>> descriptors = {
    'aqidah': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: أصول التوحيد والإيمان',
        description: 'أقسام التوحيد الثلاثة، شروط الشهادتين، وأركان الإيمان الستة',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: توحيد الأسماء والصفات وقواعدها',
        description: 'منهج السلف الصالح في الإثبات بلا تمثيل والتنزيه بلا تعطيل',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: مسائل القدر واليوم الآخر',
        description: 'مراتب القدر الأربع، أشراط الساعة، والحساب والميزان والجنة والنار',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: حقيقة الإيمان ومسائل الكفر والفسوق',
        description: 'قول وعمل يزيد وينقص، والرد المحكم على الخوارج والمرجئة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: الولاء والبراء وحقوق الصحابة وولاة الأمور',
        description: 'محبة المؤمنين، البراءة من الشرك، حقوق الصحابة، والسمع والطاعة بالمعروف',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: الشرك ونواقض الإسلام والبدع',
        description: 'الشرك الأكبر والأصغر، الشفاعة المثبتة والمنفية، والتحذير من المحدثات',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: التمكين العقدي وقواعد الاستدلال السلفي',
        description: 'إعمال النقل الصحيح الموافق للعقل الصريح ورد شبهات أهل الزيغ',
        stage: stageMastery,
      ),
    ],

    'fiqh': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: فقه الطهارة والوضوء والغسل',
        description: 'أحكام المياه، سنن الفطرة، صفة الوضوء، ونواقض الطهارة وموجبات الغسل',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: فقه الصلاة وأركانها وشروطها',
        description: 'شروط الصلاة، أركانها، واجباتها، وسننها وآداب الخشوع فيها',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: سجود السهو وصلاة الجماعة وأهل الأعذار',
        description: 'أحكام سجود السهو، صلاة الجماعة، القصر والجمع، وصلاة الخوف والمريض',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: فقه الجنائز والزكاة ومصارفها',
        description: 'أحكام غسل الميت وتكفينه، وأنصبة الزكاة ومصارفها الشرعية الثمانية',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: فقه الصيام والاعتكاف وزكاة الفطر',
        description: 'شروط وجوب الصيام، مفسداته، الكفارات، أحكام الاعتكاف وزكاة الفطر',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: فقه الحج والعمرة والأضاحي والذبائح',
        description: 'المواقيت المكانية والزمانية، أركان الحج، الفدية، وسنن الأضاحي والعقيقة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: فقه البيوع والمعاملات المالية والربا',
        description: 'شروط البيع الصحيح، البيوع المحرمة، أحكام الربا، والخيارات والرهن',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثامن: فقه النكاح والطلاق ومبادئ المواريث والفرائض',
        description: 'شروط عقد النكاح، الحقوق الزوجية، أحكام الطلاق، والتركات وأصحاب الفروض',
        stage: stageMastery,
      ),
    ],

    'usul': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: مبادئ الأصول والأحكام التكليفية والوضعية',
        description: 'تعريف أصول الفقه، الواجب والمندوب والمحظور والمكروه والمباح والسبب والشرط والمانع',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: الأدلة الشرعية المتفق عليها',
        description: 'الكتاب العزيز، السنة النبوية، الإجماع القطعي والظني، والقياس وأركانه',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: الأدلة الشرعية المختلف فيها',
        description: 'الاستصحاب، المصالح المرسلة، الاستحسان، سد الذرائع، وعمل أهل المدينة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: دلالات الألفاظ والقواعد الأصولية',
        description: 'صيغ الأمر والنهي، العام والخاص، ودلالات المنطوق والمفهوم',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: المطلق والمقيد والمجمل والمبين والنسخ',
        description: 'حمل المطلق على المقيد، البيان بعد الإجمال، وشروط النسخ وأقسامه',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: مقاصد الشريعة وشروط الاجتهاد والترجيح',
        description: 'الضروريات الخمس، مراتب المصالح، شروط المجتهد، وطرق الجمع والترجيح بين الأدلة',
        stage: stageMastery,
      ),
    ],

    'hadith': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: جوامع الكلم والأربعون النووية',
        description: 'الأحاديث الكبرى التي عليها مدار الإسلام وقواعد الأحكام والأخلاق',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: مصطلح الحديث وأقسام الأخبار',
        description: 'الصحيح لذاته ولغيره، الحسن، الضعيف، المتواتر، والآحاد وأقسام السند',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: أئمة الحديث وأصحاب الكتب الستة',
        description: 'الإمام البخاري، مسلم، أبو داود، الترمذي، النسائي، وابن ماجه وتراجمهم ومصنفاتهم',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: علوم الإسناد ورجال الحديث والجرح والتعديل',
        description: 'قواعد الجرح والتعديل، طبقات الرواة، صيغ الأداء، والتدليس والعدالة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: فقه الأحاديث ودفع التعارض المتوهم',
        description: 'الجمع بين النصوص النبوية، الناسخ والمنسوخ، وغريب الحديث ومشكل الآثار',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: مناهج التخريج ودراسة الأسانيد',
        description: 'طرق تخريج الحديث، معرفة المدار، واستخراج الشواهد والمتابعات',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: علل الحديث وتخريجه ودقائقه المتقنة',
        description: 'العلل الخفية القادحة، مناهج جهابذة النقد الحديثي، ودقائق الاختلاف السندي',
        stage: stageMastery,
      ),
    ],

    'quran': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: فضائل سور وآيات القرآن الكريم',
        description: 'أم الكتاب، آية الكرسي، المعوذات، وفضائل سور التنزيل الحكيم',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: معاني غريب المفردات القرآنية (1)',
        description: 'معاني الألفاظ المشكلة في جزء عمّ وسور المفصل',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: معاني غريب المفردات القرآنية (2)',
        description: 'مفردات السور المتوسطة وغريب الألفاظ والتراكيب القرآنية',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: أسباب النزول والمكي والمدني',
        description: 'السياق التاريخي لنزول الآيات وضوابط المكي والمدني في السور',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: مبادئ التلاوة وضبط حروف المصحف',
        description: 'أحكام الاستعاذة والبسملة، وترتيل كتاب الله ترتيلاً متقناً',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: أحكام الوقف والابتداء في التلاوة',
        description: 'أقسام الوقف الأربعة: التام والكافي والحسن والقبيح',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: الناسخ والمنسوخ والمحكم والمتشابه',
        description: 'أقسام النسخ في القرآن وحكمة التدرج والتشريع الإلهي',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثامن: تدبر سورة الفاتحة وسور المفصل',
        description: 'مقاصد السور، هدايات الآيات الكريمة، وأسرار افتتاحياتها',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى التاسع: أوجه الإعجاز البياني والتشريعي',
        description: 'إعجاز النظم، بلاغة التعبير، وتوافق آيات القرآن الكريم',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى العاشر: تاريخ جمع القرآن وتدوين المصحف',
        description: 'الجمع النبوي الشريف، جمع الصديق، والمصحف العثماني الإمام',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الحادي عشر: تدبر آيات العقيدة والتوحيد',
        description: 'دلائل الربوبية والألوهية وعظمة الخالق سبحانه في الآيات',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني عشر: تدبر آيات الأحكام والتشريع',
        description: 'أحكام العبادات والمعاملات وقواعد الاستنباط القرآني الرصين',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث عشر: قصص الأنبياء وأمثال القرآن',
        description: 'الدروس الدعوية والعبر التربوية العظيمة في قصص المرسلين',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع عشر: بلاغة الفواصل القرآنية والنظم',
        description: 'جماليات الفواصل القرآنية والتقديم والتأخير والتكرار البلاغي',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس عشر: علوم الرسم العثماني والضبط',
        description: 'قواعد الحذف والزيادة والبدل والوصل والفصل في خط المصحف',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس عشر: طبقات المفسرين ومناهج التأويل',
        description: 'أصول التفسير بالمأثور، ومناهج الصحابة والتابعين والأئمة',
        stage: stageMastery,
      ),
    ],

    'tajweed': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: أحكام النون الساكنة والتنوين',
        description: 'الإظهار الحلقي، الإدغام بغنة وبغير غنة، الإقلاب، والإخفاء الحقيقي',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: أحكام الميم الساكنة والنون والميم المشددتين',
        description: 'الإخفاء الشفوي، الإدغام الشفوي، الإظهار الشفوي، وغنة المشددتين',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: أحكام المدود وأقسامها ومقاديرها',
        description: 'المد الأصلي الطبيعي والفرعي بسبب الهمز أو السكون، وأزمنة المدود',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: مخارج الحروف العربية وضبطها',
        description: 'المخارج العامة الخمسة والمخارج الخاصة السبعة عشر للحروف بالتفصيل',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: صفات الحروف والتفخيم والترقيق',
        description: 'الصفات المتضادة وغير المتضادة، وحروف الاستعلاء والاستفال، وأحكام الراء واللام',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: الوقف والابتداء ورسم المصحف وضبطه',
        description: 'المقطوع والموصول، تاءات التأنيث، همزات الوصل والقطع، وعلامات الضبط',
        stage: stageMastery,
      ),
    ],

    'seerah': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: المولد النبوي الشريف والنشأة والعهد المكي',
        description: 'نسب النبي ﷺ الشريف، طفولته المباركة، حلف الفضول، وزواجه بخديجة رضي الله عنها',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: بعثة النبي ﷺ والدعوة المكية والابتلاء',
        description: 'نزول الوحي في غار حراء، الدعوة السرية والجهرية، وصبر المستضعفين والهجرة إلى الحبشة',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: الإسراء والمعراج والهجرة المباركة للمدينة',
        description: 'حادثة الإسراء والمعراج، بيعة العقبة الأولى والثانية، ومعالم طريق الهجرة النبوية',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: تأسيس المجتمع المدني والغزوات الكبرى الأولى',
        description: 'بناء المسجد والمؤاخاة ووثيقة المدينة، وغزوة بدر الكبرى وغزوة أحد',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: غزوة الأحزاب وصلح الحديبية التاريخي',
        description: 'حصار الخندق، يهود بني قريظة، بيعة الرضوان المباركة، وشروط صلح الحديبية ومكاسبه',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: فتح مكة الأعظم وغزوة حنين والوفود',
        description: 'فتح مكة وتطهير البيت الحرام، ثبات النبي ﷺ بحنين، وعام الوفود وانتشار الإسلام',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: حجة الوداع والرفيق الأعلى والشمائل النبوية',
        description: 'خطبة حجة الوداع، إكمال الدين، وفاته ﷺ، وأخلاقه وشمائله الزكية العطرة',
        stage: stageMastery,
      ),
    ],

    'sahaba': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: الخلفاء الراشدون الأربعة ومناقبهم العظيمة',
        description: 'سير ومناقب أبي بكر الصديق، عمر الفاروق، عثمان ذي النورين، وعلي المرتضى رضي الله عنهم',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: العشرة المبشرون بالجنة وكبار المهاجرين',
        description: 'طلحة بن عبيد الله، الزبير بن العوام، سعد بن أبي وقاص، سعيد بن زيد، أبو عبيدة، وابن عوف',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: فضلاء الأنصار وأهل بدر الأبرار',
        description: 'سعد بن معاذ، أسيد بن حضير، أهل بدر الكرام، ومواقف النصرة والتضحية الخالدة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: أمهات المؤمنين وآل البيت الأطهار',
        description: 'خديجة الكبرى، عائشة الصديقة، فاطمة الزهراء، والحسن والحسين سيدا شباب أهل الجنة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: أبطال الفتوحات والشهداء في سبيل الله',
        description: 'خالد بن الوليد، حمزة بن عبد المطلب، جعفر الطيار، ومصعب بن عمير رضي الله عنهم',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: فقهاء الصحابة وقراء القرآن الكريم',
        description: 'عبد الله بن مسعود، معاذ بن جبل، أبي بن كعب، وزيد بن ثابت رضي الله عنهم',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: رواة الحديث وحفاظ السنن النبوية المطهرة',
        description: 'أبو هريرة، عبد الله بن عباس، عبد الله بن عمر، أنس بن مالك، وجابر بن عبد الله',
        stage: stageMastery,
      ),
    ],

    'prophets_names': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: آدم، إدريس، نوح، وهود عليهم السلام',
        description: 'أبو البشر وتوبة الله عليه، أول من خط بالقلم، شيخ المرسلين والطوفان، ونبي عاد',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: صالح، إبراهيم الخليل، ولوط عليهم السلام',
        description: 'نبي ثمود وناقة الله، إمام الحنفاء وبناء الكعبة، وبلاء المؤتفكات ونجاة لوط',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: إسماعيل، إسحاق، يعقوب، ويوسف عليهم السلام',
        description: 'الذبيح وبئر زمزم، وبشرى إسحاق، والصبر الجميل وملك مصر في أحسن القصص',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: أيوب، ذو الكفل، شعيب، وموسى عليه السلام',
        description: 'ضرب المثل في الصبر، خطيب الأنبياء وتوفية الكيل، وكليم الله في مواجهة فرعون',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: هارون، داود، سليمان، ويونس عليهم السلام',
        description: 'وزير موسى وفصاحة لسانه، الزبور وتسبيح الجبال، ملك سليمان، وصاحب الحوت والتسبيح',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: زكريا، يحيى، عيسى، ومحمد ﷺ خاتم النبيين',
        description: 'دعاء زكريا بالمحراب، يحيى الحليم، المسيح كلمة الله ومعجزاته، وسيد ولد آدم ﷺ',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: أدعية وتضرعات الأنبياء في القرآن الكريم',
        description: 'أدعية التوبة والنجاة والذرية الصالحة والاستنصار المستجابة في كتاب الله',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثامن: أسماء الله الحسنى: معاني الجمال والرحمة والعفو',
        description: 'الرحمن، الرحيم، الملك، القدوس، السلام، المؤمن، المهيمن، والعفو والودود',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى التاسع: أسماء الله الحسنى: معاني الجلال والعظمة والقدرة',
        description: 'العزيز، الجبار، المتكبر، الخالق، البارئ، المصور، العلي، والعظيم والقادر',
        stage: stageMastery,
      ),
    ],

    'adab': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: حلية طالب العلم وآداب الطلب',
        description: 'إخلاص النية، توقير العلماء، حفظ الوقت، علو الهمة، والعمل بالعلم النافع',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: أعمال القلوب والورع والخشوع والإخلاص',
        description: 'محبة الله ورجاؤه وخوفه، التوكل، الإنابة، وتطهير القلب من الغل والحسد والرياء',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: حفظ اللسان وحقوق الإخوة والمعاشرة',
        description: 'آفات اللسان من الغيبة والنميمة، حسن الخلق، الوفاء بالعهود، وبشاشة الوجه',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: بر الوالدين وصلة الأرحام ومكارم الأخلاق',
        description: 'الإحسان إلى الوالدين، صلة الرحم، إكرام الجار والضيف، والحلم والأناة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: مدارج السالكين ورقائق السلف الصالح',
        description: 'منارات الزهد المشروع، تذكر الموت وقصر الأمل، ومحطات السير والمجاهدة إلى الله',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: محاسبة النفس ولزوم الاستقامة',
        description: 'شروط التوبة النصوح، المراقبة الدائمة، الثبات على الحق، ومصاحبة الأخيار',
        stage: stageMastery,
      ),
    ],

    'arabic': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: أقسام الكلمة وعلامات الإعراب الأصلية والفرعية',
        description: 'الاسم والفعل والحرف، علامات الرفع والنصب والجر والجزم في الكلام',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: مرفوعات الأسماء وضوابطها النحوية',
        description: 'الفاعل ونائبه، المبتدأ والخبر، كان وأخواتها، وإن وأخواتها',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: منصوبات الأسماء وتطبيقاتها القرآنية',
        description: 'المفاعيل الخمسة، الحال، التمييز، المستثنى، واسم لا النافية للجنس',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: مجرورات الأسماء وإعراب الأفعال',
        description: 'الجر بالحرف وبالإضافة وبالتبعية، نواصب وجوازم الفعل المضارع والأفعال الخمسة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: أبواب الصرف وبنية الكلمة العربية',
        description: 'الميزان الصرفي، الفعل المجرد والمزيد، الإعلال والإبدال، واسما الفاعل والمفعول',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: علوم البلاغة (علم المعاني وأسرار التركيب)',
        description: 'الخبر والإنشاء، التقديم والتأخير، القصر، الإيجاز والإطناب والمساواة',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: علوم البلاغة (البيان والبديع والإعجاز)',
        description: 'التشبيه، الاستعارة، الكناية، المحسنات البديعية اللفظية والمعنوية، وبلاغة القرآن',
        stage: stageMastery,
      ),
    ],
  };

  /// Partitions a combined question bank (base + dump) for a discipline into sequential
  /// bite-sized curriculum levels of 15 to 20 questions each.
  static List<QuizLevel> partitionQuestionsIntoManhajLevels({
    required String fanId,
    required List<QuizQuestion> allQuestions,
  }) {
    final specs = descriptors[fanId];
    if (specs == null || specs.isEmpty || allQuestions.isEmpty) {
      return const [];
    }

    final nLevels = specs.length;
    final total = allQuestions.length;
    final baseSize = total ~/ nLevels;
    final remainder = total % nLevels;

    final levels = <QuizLevel>[];
    int cursor = 0;

    for (int i = 0; i < nLevels; i++) {
      final chunkSize = baseSize + (i < remainder ? 1 : 0);
      final chunkEnd = (cursor + chunkSize).clamp(0, total);
      final levelQuestions = allQuestions.sublist(cursor, chunkEnd);
      cursor = chunkEnd;

      final spec = specs[i];
      levels.add(
        QuizLevel(
          id: '${fanId}_l${i + 1}',
          levelNumber: i + 1,
          title: spec.title,
          description: spec.description,
          questions: levelQuestions,
          passingPercentage: 70,
        ),
      );
    }

    return levels;
  }
}
