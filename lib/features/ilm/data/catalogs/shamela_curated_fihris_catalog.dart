import '../models/shamela_models.dart';

/// Curated, high-fidelity table of contents (فهارس معتمدة محققة) for classical and
/// syllabus books where Shamela.ws has sparse, incomplete, or 1-entry indexes.
class ShamelaCuratedFihrisCatalog {
  const ShamelaCuratedFihrisCatalog._();

  static final Map<int, List<ShamelaChapter>> _curatedCatalog = {
    // ── ثلاثة الأصول وأدلتها (نسخة الـ 12 صفحة - الشاملة 11126) ──
    11126: const [
      ShamelaChapter(
        pageNumber: 1,
        title: 'المقدمة: المسائل الأربع (العلم، والعمل به، والدعوة إليه، والصبر عليه)',
      ),
      ShamelaChapter(
        pageNumber: 2,
        title: 'المسائل الثلاث التي يجب على كل مسلم ومسلمة تعلمها',
      ),
      ShamelaChapter(
        pageNumber: 3,
        title: 'الحنيفية ملة إبراهيم ومدخل الأصول الثلاثة',
      ),
      ShamelaChapter(
        pageNumber: 4,
        title: 'الأصل الأول: معرفة العبد ربه وبيان أنواع العبادة',
      ),
      ShamelaChapter(
        pageNumber: 5,
        title: 'أدلة العبادات (الاستعانة، الاستعاذة، الاستغاثة، الذبح، النذر)',
      ),
      ShamelaChapter(
        pageNumber: 6,
        title: 'الأصل الثاني: معرفة دين الإسلام ومرتبة الإسلام وأركانه',
      ),
      ShamelaChapter(
        pageNumber: 7,
        title: 'المرتبة الثانية: الإيمان وأركانه الستة وشعبه',
      ),
      ShamelaChapter(
        pageNumber: 8,
        title: 'المرتبة الثالثة: الإحسان وحديث جبريل في مراتب الدين',
      ),
      ShamelaChapter(
        pageNumber: 9,
        title: 'الأصل الثالث: معرفة نبيكم محمد ﷺ ونبوته ورسالته',
      ),
      ShamelaChapter(
        pageNumber: 10,
        title: 'الهجرة إلى المدينة وبقية شرائع الإسلام',
      ),
      ShamelaChapter(
        pageNumber: 11,
        title: 'وفاة النبي ﷺ والبعث والجزاء والحساب بعد الموت',
      ),
      ShamelaChapter(
        pageNumber: 12,
        title: 'الكفر بالطاغوت ورؤوس الطواغيت وخاتمة الرسالة',
      ),
    ],

    // ── ثلاثة الأصول وأدلتها (نسخة المتون الرقمية - الشاملة 239) ──
    239: const [
      ShamelaChapter(pageNumber: 1, title: 'مقدمة المحقق وتقسيم الرسالة'),
      ShamelaChapter(pageNumber: 2, title: 'مقدمة الناشر ومصادر المتن'),
      ShamelaChapter(
        pageNumber: 6,
        title: 'المسائل الأربع التي يجب على كل مسلم تعلمها',
      ),
      ShamelaChapter(
        pageNumber: 7,
        title: 'المسائل الثلاث في التوحيد والولاء والبراء',
      ),
      ShamelaChapter(
        pageNumber: 8,
        title: 'الحنيفية ملة إبراهيم وإفراد الله بالعبادة',
      ),
      ShamelaChapter(pageNumber: 9, title: 'الأصل الأول: معرفة العبد ربه'),
      ShamelaChapter(pageNumber: 10, title: 'بيان أدلة الربوبية والخلق والتدبير'),
      ShamelaChapter(
        pageNumber: 11,
        title: 'أنواع العبادة التي أمر الله بها (الدعاء، الخوف، الرجاء، التوكل)',
      ),
      ShamelaChapter(
        pageNumber: 12,
        title: 'أدلة الرغبة والرهبة والخشوع والخشية والإنابة',
      ),
      ShamelaChapter(
        pageNumber: 13,
        title: 'أدلة الاستعانة والاستعاذة والاستغاثة والذبح والنذر',
      ),
      ShamelaChapter(
        pageNumber: 14,
        title: 'الأصل الثاني: معرفة دين الإسلام بالأدلة (المرتبة الأولى: الإسلام)',
      ),
      ShamelaChapter(
        pageNumber: 15,
        title: 'شروط شهادة أن لا إله إلا الله ودليل الصلاة والزكاة والصيام',
      ),
      ShamelaChapter(
        pageNumber: 16,
        title: 'المرتبة الثانية: الإيمان وأركانه الستة',
      ),
      ShamelaChapter(
        pageNumber: 17,
        title: 'أدلة أركان الإيمان من القرآن الكريم',
      ),
      ShamelaChapter(
        pageNumber: 18,
        title: 'المرتبة الثالثة: الإحسان وركنه الواحد',
      ),
      ShamelaChapter(
        pageNumber: 19,
        title: 'حديث جبريل عليه السلام في بيان مراتب الدين',
      ),
      ShamelaChapter(
        pageNumber: 20,
        title: 'الأصل الثالث: معرفة نبيكم محمد ﷺ ونسبه وبداية الوحي',
      ),
      ShamelaChapter(
        pageNumber: 21,
        title: 'الدعوة إلى التوحيد في مكة والإنذار عن الشرك',
      ),
      ShamelaChapter(
        pageNumber: 22,
        title: 'فرض الهجرة من مكة إلى المدينة بالأدلة',
      ),
      ShamelaChapter(
        pageNumber: 23,
        title: 'استقرار النبي ﷺ بالمدينة وبقية شرائع الإسلام',
      ),
      ShamelaChapter(
        pageNumber: 24,
        title: 'وفاة النبي ﷺ وتقرير البعث والنشور والجزاء',
      ),
      ShamelaChapter(
        pageNumber: 25,
        title: 'إرسال الرسل والبراءة من الطاغوت ورؤوس الطواغيت',
      ),
    ],

    // ── القواعد الأربع (الشاملة 8524) ──
    8524: const [
      ShamelaChapter(pageNumber: 1, title: 'المقدمة والدعاء للمتعلم والحنيفية'),
      ShamelaChapter(
        pageNumber: 2,
        title: 'القاعدة الأولى: إقرار كفار قريش بتوحيد الربوبية',
      ),
      ShamelaChapter(
        pageNumber: 2,
        title: 'القاعدة الثانية: شبهة الشفاعة والتقرب إلى الأولياء',
      ),
      ShamelaChapter(
        pageNumber: 3,
        title: 'القاعدة الثالثة: تنوع معبودات المشركين وعدم تفريق النبي ﷺ بينهم',
      ),
      ShamelaChapter(
        pageNumber: 4,
        title: 'القاعدة الرابعة: شرك المتأخرين أغلظ من شرك الأولين وخاتمة القواعد',
      ),
    ],

    // ── نواقض الإسلام (الشاملة 30869) ──
    30869: const [
      ShamelaChapter(pageNumber: 1, title: 'المقدمة: التحذير من نواقض الإسلام'),
      ShamelaChapter(pageNumber: 1, title: 'الناقض الأول: الشرك في عبادة الله تعالى'),
      ShamelaChapter(pageNumber: 1, title: 'الناقض الثاني: اتخاذ الوسائط ودعاؤهم والتوكل عليهم'),
      ShamelaChapter(pageNumber: 1, title: 'الناقض الثالث: من لم يكفر المشركين أو شك في كفرهم'),
      ShamelaChapter(pageNumber: 1, title: 'الناقض الرابع: اعتقاد أن هدي غير النبي ﷺ أكمل من هديه'),
      ShamelaChapter(pageNumber: 2, title: 'الناقض الخامس: من أبغض شيئاً مما جاء به الرسول ﷺ'),
      ShamelaChapter(pageNumber: 2, title: 'الناقض السادس: الاستهزاء بشيء من دين الرسول ﷺ أو ثوابه أو عقابه'),
      ShamelaChapter(pageNumber: 2, title: 'الناقض السابع: السحر ومنه الصرف والعطف'),
      ShamelaChapter(pageNumber: 2, title: 'الناقض الثامن: مظاهرة المشركين ومعاونتهم على المسلمين'),
      ShamelaChapter(pageNumber: 2, title: 'الناقض التاسع: اعتقاد جواز الخروج عن شريعة محمد ﷺ'),
      ShamelaChapter(pageNumber: 2, title: 'الناقض العاشر: الإعراض عن دين الله والخاتمة'),
    ],

    // ── المنظومة البيقونية في مصطلح الحديث (الشاملة 8567) ──
    8567: const [
      ShamelaChapter(pageNumber: 1, title: 'المقدمة وبداية النظم'),
      ShamelaChapter(pageNumber: 1, title: 'تعريف الحديث الصحيح'),
      ShamelaChapter(pageNumber: 2, title: 'الحديث الحسن'),
      ShamelaChapter(pageNumber: 2, title: 'الحديث الضعيف'),
      ShamelaChapter(pageNumber: 3, title: 'المرفوع والموقوف والمقطوع'),
      ShamelaChapter(pageNumber: 3, title: 'المسند والمتصل'),
      ShamelaChapter(pageNumber: 4, title: 'المسلسل والعزيز والمشهور'),
      ShamelaChapter(pageNumber: 4, title: 'المعنعن والمبهم'),
      ShamelaChapter(pageNumber: 5, title: 'الغريب والمدرج والمضمر'),
      ShamelaChapter(pageNumber: 5, title: 'المنقطع والمعضل والمدلس'),
      ShamelaChapter(pageNumber: 6, title: 'الموضوع وخاتمة المنظومة'),
    ],

    // ── شروط الصلاة وأركانها وواجباتها (الشاملة 11266) ──
    11266: const [
      ShamelaChapter(pageNumber: 1, title: 'المقدمة والشروط التسعة (الإسلام، العقل، التمييز، رفع الحدث)'),
      ShamelaChapter(pageNumber: 2, title: 'إزالة النجاسة وستر العورة ودخول الوقت'),
      ShamelaChapter(pageNumber: 3, title: 'استقبال القبلة والنية'),
      ShamelaChapter(pageNumber: 4, title: 'أركان الصلاة الأربعة عشر (القيام، تكبيرة الإحرام، قراءة الفاتحة)'),
      ShamelaChapter(pageNumber: 6, title: 'الركوع والاعتدال والسجود على الأعضاء السبعة'),
      ShamelaChapter(pageNumber: 7, title: 'الجلسة بين السجدتين والطمأنينة والتشهد الأخير'),
      ShamelaChapter(pageNumber: 8, title: 'التسليمتان وترتيب الأركان'),
      ShamelaChapter(pageNumber: 10, title: 'واجبات الصلاة الثمانية وسجود السهو'),
    ],

    // ── تحفة الأطفال في تجويد القرآن (الشاملة 9632) ──
    9632: const [
      ShamelaChapter(pageNumber: 1, title: 'المقدمة وبداية النظم'),
      ShamelaChapter(pageNumber: 2, title: 'أحكام النون الساكنة والتنوين (الإظهار والإدغام)'),
      ShamelaChapter(pageNumber: 3, title: 'الإقلاب والإخفاء الحقيقي'),
      ShamelaChapter(pageNumber: 4, title: 'أحكام النون والميم المشددتين والميم الساكنة'),
      ShamelaChapter(pageNumber: 5, title: 'أحكام لام ال ولام الفعل'),
      ShamelaChapter(pageNumber: 6, title: 'في المثلين والمتقاربين والمتجانسين'),
      ShamelaChapter(pageNumber: 7, title: 'أقسام المد (الأصلي والفرعي) وأحكامه'),
      ShamelaChapter(pageNumber: 8, title: 'أقسام المد اللازم وخاتمة النظم'),
    ],

    // ── متن العقيدة الطحاوية (الشاملة 9568) ──
    9568: const [
      ShamelaChapter(pageNumber: 1, title: 'خطبة الكتاب وبيان عقيدة أهل السنة والجماعة'),
      ShamelaChapter(pageNumber: 1, title: 'توحيد الله وتنزيهه عن الشبيه والند والمثيل'),
      ShamelaChapter(pageNumber: 1, title: 'صفات الرب تعالى الذاتية والفعلية'),
      ShamelaChapter(pageNumber: 2, title: 'نبوة محمد ﷺ وخاتم الرسل وسيد المرسلين'),
      ShamelaChapter(pageNumber: 2, title: 'القرآن كلام الله تعالى منزل غير مخلوق'),
      ShamelaChapter(pageNumber: 2, title: 'إثبات رؤية المؤمنين لربهم في الآخرة'),
      ShamelaChapter(pageNumber: 3, title: 'الإسراء والمعراج والحوض والشفاعة'),
      ShamelaChapter(pageNumber: 3, title: 'الميثاق والقدر وسابق علم الله بخلقه'),
      ShamelaChapter(pageNumber: 3, title: 'اللوح والقلم وأفعال العباد وخلق الله لها'),
      ShamelaChapter(pageNumber: 4, title: 'العرش والكرسي وعوالم الملائكة والكتب والرسل'),
      ShamelaChapter(pageNumber: 4, title: 'البعث والنشور والحساب والجزاء والجنة والنار'),
      ShamelaChapter(pageNumber: 4, title: 'حقيقة الإيمان وعدم تكفير أهل القبلة بذنب دون الشرك'),
      ShamelaChapter(pageNumber: 5, title: 'المسح على الخفين والحج والجهاد مع كل إمام'),
      ShamelaChapter(pageNumber: 5, title: 'فضل الصحابة الكرام وترتيب الخلفاء الراشدين'),
      ShamelaChapter(pageNumber: 6, title: 'عصمة الأمة ولزوم السنة والجماعة وخاتمة العقيدة'),
    ],

    // ── لمعة الاعتقاد الهادي إلى سبيل الرشاد (الشاملة 11366) ──
    11366: const [
      ShamelaChapter(pageNumber: 1, title: 'المقدمة ومنهج السلف الصالح في نصوص الصفات'),
      ShamelaChapter(pageNumber: 2, title: 'إثبات أسماء الله وصفاته وإمرارها كما جاءت بلا تكييف'),
      ShamelaChapter(pageNumber: 3, title: 'صفة الاستواء والعلو والنزول الإلهي'),
      ShamelaChapter(pageNumber: 4, title: 'إثبات صفة الوجه واليدين والأصابع'),
      ShamelaChapter(pageNumber: 5, title: 'إثبات الكلام الإلهي وأن القرآن كلام الله غير مخلوق'),
      ShamelaChapter(pageNumber: 6, title: 'إثبات رؤية المؤمنين لربهم تبارك وتعالى يوم القيامة'),
      ShamelaChapter(pageNumber: 7, title: 'الإيمان بالقضاء والقدر خيره وشره من الله تعالى'),
      ShamelaChapter(pageNumber: 8, title: 'الإيمان قول وعمل ونية يزيد بالطاعة وينقص بالمعصية'),
      ShamelaChapter(pageNumber: 9, title: 'أشراط الساعة وأحوال البرزخ وعذاب القبر ونعيمه'),
      ShamelaChapter(pageNumber: 10, title: 'الشفاعة العظمى والحوض والميزان والصراط والجنة والنار'),
      ShamelaChapter(pageNumber: 11, title: 'حقوق الصحابة الكرام والترضي عنهم ومكانة الخلفاء'),
      ShamelaChapter(pageNumber: 12, title: 'لزوم السنة ومجانبة البدع ومفارقة أهل الأهواء'),
    ],

    // ── كشف الشبهات في التوحيد (الشاملة 11381) ──
    11381: const [
      ShamelaChapter(pageNumber: 1, title: 'المقدمة وبيان حقيقة دعوة الرسل إلى التوحيد'),
      ShamelaChapter(pageNumber: 5, title: 'تقرير توحيد الربوبية وبيان شرك المشركين في الألوهية'),
      ShamelaChapter(pageNumber: 10, title: 'شبهة: المشركون يقرون بأن الله هو الخالق الرازق'),
      ShamelaChapter(pageNumber: 15, title: 'الجواب المجمل على شبه المشركين'),
      ShamelaChapter(pageNumber: 20, title: 'الجواب المفصل ودحض شبهة التوسل بالأموات والصالحين'),
      ShamelaChapter(pageNumber: 30, title: 'شبهة الشفاعة والفرق بين الشفاعة المثبتة والمنفية'),
      ShamelaChapter(pageNumber: 40, title: 'الرد على شبهة: إن الأولياء والصالحين لهم جاه وقربة'),
      ShamelaChapter(pageNumber: 50, title: 'بيان أن شرك المتأخرين أغلظ من شرك الأولين من وجوه'),
      ShamelaChapter(pageNumber: 60, title: 'وجوب إخلاص الدين كله لله وحده وخاتمة الرسالة'),
    ],

    // ── الأربعون النووية مع زيادات ابن رجب (الشاملة 147927 / 672) ──
    147927: const [
      ShamelaChapter(pageNumber: 1, title: 'المقدمة وفضل جمع الأحاديث الأربعين'),
      ShamelaChapter(pageNumber: 2, title: 'الحديث 1: إنما الأعمال بالنيات'),
      ShamelaChapter(pageNumber: 3, title: 'الحديث 2: مراتب الدين والإسلام والإيمان والإحسان'),
      ShamelaChapter(pageNumber: 4, title: 'الحديث 3: بني الإسلام على خمس'),
      ShamelaChapter(pageNumber: 5, title: 'الحديث 4: إن أحدكم يجمع خلقه في بطن أمه'),
      ShamelaChapter(pageNumber: 6, title: 'الحديث 5: من أحدث في أمرنا هذا ما ليس منه فهو رد'),
      ShamelaChapter(pageNumber: 7, title: 'الحديث 6: الحلال بين والحرام بين'),
      ShamelaChapter(pageNumber: 8, title: 'الحديث 7: الدين النصيحة'),
      ShamelaChapter(pageNumber: 9, title: 'الحديث 8: أمرت أن أقاتل الناس حتى يشهدوا'),
      ShamelaChapter(pageNumber: 10, title: 'الحديث 9: ما نهيتكم عنه فاجتنبوه'),
      ShamelaChapter(pageNumber: 11, title: 'الحديث 10: إن الله طيب لا يقبل إلا طيبا'),
      ShamelaChapter(pageNumber: 12, title: 'الحديث 11: دع ما يريبك إلى ما لا يريبك'),
      ShamelaChapter(pageNumber: 13, title: 'الحديث 12: من حسن إسلام المرء تركه ما لا يعنيه'),
      ShamelaChapter(pageNumber: 14, title: 'الحديث 13: لا يؤمن أحدكم حتى يحب لأخيه'),
      ShamelaChapter(pageNumber: 15, title: 'الحديث 14: لا يحل دم امرئ مسلم'),
      ShamelaChapter(pageNumber: 16, title: 'الحديث 15: من كان يؤمن بالله واليوم الآخر'),
      ShamelaChapter(pageNumber: 17, title: 'الحديث 16: لا تغضب'),
      ShamelaChapter(pageNumber: 18, title: 'الحديث 17: إن الله كتب الإحسان على كل شيء'),
      ShamelaChapter(pageNumber: 19, title: 'الحديث 18: اتق الله حيثما كنت'),
      ShamelaChapter(pageNumber: 20, title: 'الحديث 19: احفظ الله يحفظك'),
      ShamelaChapter(pageNumber: 21, title: 'الحديث 20: إذا لم تستح فاصنع ما شئت'),
      ShamelaChapter(pageNumber: 22, title: 'الحديث 21: قل آمنت بالله ثم استقم'),
      ShamelaChapter(pageNumber: 23, title: 'الحديث 22: أرأيت إذا صليت المكتوبات'),
      ShamelaChapter(pageNumber: 24, title: 'الحديث 23: الطهور شطر الإيمان'),
      ShamelaChapter(pageNumber: 25, title: 'الحديث 24: يا عبادي إني حرمت الظلم'),
      ShamelaChapter(pageNumber: 26, title: 'الحديث 25: ذهب أهل الدثور بالأجور'),
      ShamelaChapter(pageNumber: 27, title: 'الحديث 26: كل سلامى من الناس عليه صدقة'),
      ShamelaChapter(pageNumber: 28, title: 'الحديث 27: البر حسن الخلق والإثم ما حاك في الصدر'),
      ShamelaChapter(pageNumber: 29, title: 'الحديث 28: أوصيكم بتقوى الله والسمع والطاعة'),
      ShamelaChapter(pageNumber: 30, title: 'الحديث 29: دلني على عمل يدخلني الجنة'),
      ShamelaChapter(pageNumber: 31, title: 'الحديث 30: إن الله فرض فرائض فلا تضيعوها'),
      ShamelaChapter(pageNumber: 32, title: 'الحديث 31: ازهد في الدنيا يحبك الله'),
      ShamelaChapter(pageNumber: 33, title: 'الحديث 32: لا ضرر ولا ضرار'),
      ShamelaChapter(pageNumber: 34, title: 'الحديث 33: لو يعطى الناس بدعواهم'),
      ShamelaChapter(pageNumber: 35, title: 'الحديث 34: من رأى منكم منكرا فليغيره'),
      ShamelaChapter(pageNumber: 36, title: 'الحديث 35: لا تحاسدوا ولا تباغضوا'),
      ShamelaChapter(pageNumber: 37, title: 'الحديث 36: من نفس عن مؤمن كربة'),
      ShamelaChapter(pageNumber: 38, title: 'الحديث 37: إن الله كتب الحسنات والسيئات'),
      ShamelaChapter(pageNumber: 39, title: 'الحديث 38: من عادى لي وليا فقد آذنته بالحرب'),
      ShamelaChapter(pageNumber: 40, title: 'الحديث 39: إن الله تجاوز لي عن أمتي الخطأ'),
      ShamelaChapter(pageNumber: 41, title: 'الحديث 40: كن في الدنيا كأنك غريب'),
      ShamelaChapter(pageNumber: 42, title: 'الحديث 41: لا يؤمن أحدكم حتى يكون هواه تبعا'),
      ShamelaChapter(pageNumber: 43, title: 'الحديث 42: يا ابن آدم إنك ما دعوتني ورجوتني'),
      ShamelaChapter(pageNumber: 44, title: 'الحديث 43 (زيادة ابن رجب): ألحقوا الفرائض بأهلها'),
      ShamelaChapter(pageNumber: 45, title: 'الحديث 44: الرضاعة تحرم ما تحرم الولادة'),
      ShamelaChapter(pageNumber: 46, title: 'الحديث 45: إن الله ورسوله حرم بيع الخمر والميتة'),
      ShamelaChapter(pageNumber: 47, title: 'الحديث 46: كل مسكر حرام'),
      ShamelaChapter(pageNumber: 48, title: 'الحديث 47: ما ملأ آدمي وعاء شرا من بطن'),
      ShamelaChapter(pageNumber: 49, title: 'الحديث 48: أربع من كن فيه كان منافقا خالصا'),
      ShamelaChapter(pageNumber: 50, title: 'الحديث 49: لو أنكم توكلون على الله حق توكله'),
      ShamelaChapter(pageNumber: 51, title: 'الحديث 50: لا يزال لسانك رطبا من ذكر الله تعالى'),
    ],
  };

  /// Returns true if a verified curated table of contents exists for [bookId].
  static bool hasCuratedFihris(int bookId) => _curatedCatalog.containsKey(bookId);

  /// Returns the curated list of chapters for [bookId] or an empty list if none.
  static List<ShamelaChapter> getCuratedFihris(int bookId) {
    return _curatedCatalog[bookId] ?? const [];
  }
}
