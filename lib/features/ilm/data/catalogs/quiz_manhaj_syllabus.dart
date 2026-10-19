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
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: مسائل القدر، اليوم الآخر، ونواقض الإسلام',
        description: 'مراتب القدر الأربع، أشراط الساعة، والتحذير من نواقض التوحيد',
        stage: stageMastery,
      ),
    ],

    'fiqh': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: فقه الطهارة والوضوء والغسل',
        description: 'أحكام المياه، سنن الفطرة، صفة الوضوء، ونواقض الطهارة',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: فقه الصلاة وأركانها وسننها',
        description: 'شروط الصلاة، أركانها، واجباتها، وسجود السهو وصلاة الجماعة',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: فقه الجنائز والزكاة ومصارفها',
        description: 'أحكام غسل الميت وتكفينه، وأنصبة الزكاة، ومصارفها الثمانية',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: فقه الصيام والاعتكاف',
        description: 'شروط وجوب الصيام، مفسداته، زكاة الفطر، وأحكام الاعتكاف',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: فقه الحج والعمرة والأضاحي',
        description: 'مواقيت الحج، أركانه، واجباته، فدية الأذى، وسنن الأضاحي',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: فقه البيوع والمعاملات والفرائض',
        description: 'شروط البيع الصحيح، الربا، العقود المالية، ومبادئ المواريث',
        stage: stageMastery,
      ),
    ],

    'usul': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: مبادئ الأصول والأحكام التكليفية',
        description: 'تعريف أصول الفقه، الواجب، المندوب، المحظور، والمكروه والمباح',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: الأدلة الشرعية المتفق عليها والمختلف فيها',
        description: 'الكتاب، السنة، الإجماع، القياس، الاستصحاب، والمصالح المرسلة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: دلالات الألفاظ والقواعد الأصولية',
        description: 'الأمر والنهي، العام والخاص، المطلق والمقيد، والمجمل والمبين',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: مقاصد الشريعة والاجتهاد والترجيح',
        description: 'الضروريات الخمس، شروط المجتهد، والجمع والترجيح بين الأدلة',
        stage: stageMastery,
      ),
    ],

    'hadith': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: جوامع الكلم والأربعون النووية',
        description: 'الأحاديث الكبرى التي عليها مدار الإسلام وقواعد الأحكام',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: مصطلح الحديث وأقسام الأخبار',
        description: 'الصحيح، الحسن، الضعيف، المتواتر، والآحاد وأقسام السند',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: أئمة الحديث وأصحاب الكتب الستة',
        description: 'البخاري، مسلم، أبو داود، الترمذي، النسائي، وابن ماجه',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: علوم الإسناد ورجال الحديث',
        description: 'قواعد الجرح والتعديل، طبقات الرواة، والتدليس والعدالة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: فقه الأحاديث ودفع التعارض المتوهم',
        description: 'الجمع بين النصوص النبوية، ناسخ الحديث ومنسوخه، ومشكله',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: علل الحديث وتخريجه ودقائقه',
        description: 'العلل الخفية القادحة، مناهج النقد الحديثي، وطرق التخريج',
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
        title: 'المستوى الثاني: أحكام الميم الساكنة والمدود',
        description: 'الإخفاء الشفوي، الإدغام الشفوي، والمد الأصلي والفرعي وأسبابه',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: مخارج الحروف العربية وضبطها',
        description: 'المخارج العامة الخمسة والمخارج الخاصة السبعة عشر للحروف',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: صفات الحروف والتفخيم والترقيق',
        description: 'الصفات المتضادة وغير المتضادة، وأحكام الراء واللام وألف المد',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: الوقف والابتداء ورسم المصحف',
        description: 'المقطوع والموصول، تاءات التأنيث، وعلامات المصحف الشريف',
        stage: stageMastery,
      ),
    ],

    'seerah': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: المولد النبوي والعهد المكي',
        description: 'نسب النبي ﷺ الشريف، نشأته، نزول الوحي، والدعوة المكية والصبر',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: الهجرة النبوية وبناء المجتمع المدني',
        description: 'بيعة العقبة، طريق الهجرة المباركة، المؤاخاة، ووثيقة المدينة',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: الغزوات الكبرى وفتح مكة المبارك',
        description: 'غزوات بدر وأحد والأحزاب، صلح الحديبية، وفتح مكة الأعظم',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: حجة الوداع والرفيق الأعلى والشمائل',
        description: 'خطبة الوداع، وفاته ﷺ، وأخلاقه وشمائله الزكية العطرة',
        stage: stageMastery,
      ),
    ],

    'sahaba': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: الخلفاء الراشدون الأربعة',
        description: 'سير ومناقب أبي بكر الصديق، عمر، عثمان، وعلي رضي الله عنهم',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: العشرة المبشرون بالجنة وكبار المهاجرين',
        description: 'طلحة، الزبير، سعد، سعيد، عبد الرحمن بن عوف، وأبو عبيدة',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: فضلاء الأنصار وأهل بدر والبيعة',
        description: 'أهل بدر الكرام، نقباء الأنصار، وأبطال بيعة الرضوان المباركة',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: أمهات المؤمنين ورواة الحديث والتابعين',
        description: 'خديجة وعائشة رضي الله عنهما، حفاظ الحديث، وسادات التابعين',
        stage: stageMastery,
      ),
    ],

    'prophets_names': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: آدم، إدريس، نوح، وهود عليهم السلام',
        description: 'أبو البشر، أول من خط بالقلم، شيخ المرسلين، ونبي عاد',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: صالح، إبراهيم الخليل، ولوط عليهم السلام',
        description: 'نبي ثمود وناقة الله، إمام الحنفاء وخليل الرحمن، وبلاء المؤتفكات',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: إسماعيل، إسحاق، يعقوب، ويوسف عليهم السلام',
        description: 'الذبيح وبناء الكعبة، وبشرى إسحاق، والصبر الجميل في أحسن القصص',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: أيوب، ذو الكفل، شعيب، وموسى عليه السلام',
        description: 'ضرب المثل في الصبر، خطيب الأنبياء، وكليم الله في مواجهة فرعون',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: هارون، داود، سليمان، ويونس عليهم السلام',
        description: 'وزير موسى، الملك النيّر وتسبيح الجبال، ملك سليمان، وصاحب الحوت',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السادس: زكريا، يحيى، عيسى، ومحمد ﷺ خاتم النبيين',
        description: 'دعاء زكريا، يحيى الحليم، المسيح كلمة الله، وسيد ولد آدم ﷺ',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى السابع: أسماء الله الحسنى: معاني الجمال والرحمة والعفو',
        description: 'الرحمن، الرحيم، الملك، القدوس، السلام، المؤمن، المهيمن، والعفو',
        stage: stageMastery,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثامن: أسماء الله الحسنى: معاني الجلال والعظمة والقدرة',
        description: 'العزيز، الجبار، المتكبر، الخالق، البارئ، المصور، العلي، والعظيم',
        stage: stageMastery,
      ),
    ],

    'adab': [
      ManhajLevelDescriptor(
        title: 'المستوى الأول: حلية طالب العلم وآداب الطلب',
        description: 'إخلاص النية، توقير العلماء، حفظ الوقت، وعلو الهمة في التحصيل',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثاني: أعمال القلوب والورع والخشوع',
        description: 'محبة الله ورجاؤه وخوفه، التوكل، الإنابة، وتطهير القلب من الغل',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: حفظ اللسان وحقوق الإخوة والمعاشرة',
        description: 'آفات اللسان من الغيبة والنميمة، حسن الخلق، والوفاء بالعهود',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: مدارج السالكين ورقائق السلف الصالح',
        description: 'منارات الزهد المشروع، محاسبة النفس، ومحطات السير إلى الله',
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
        title: 'المستوى الثاني: مرفوعات الأسماء ومنصوباتها',
        description: 'الفاعل والمبتدأ والخبر، والمفاعيل الخمسة والحال والتمييز',
        stage: stageFoundation,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الثالث: مجرورات الأسماء وإعراب الأفعال',
        description: 'الجر بالحرف وبالإضافة، جوازم الفعل المضارع ونواصبه وبناؤه',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الرابع: أبواب الصرف وبنية الكلمة العربية',
        description: 'الميزان الصرفي، المجرد والمزيد، والإعلال والإبدال والمصادر',
        stage: stageIntermediate,
      ),
      ManhajLevelDescriptor(
        title: 'المستوى الخامس: علوم البلاغة وأسرار البيان القرآني',
        description: 'علم المعاني والبيان والبديع، التشبيه والاستعارة والمجاز',
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
