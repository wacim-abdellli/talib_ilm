import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_policy.dart';
import '../../../../core/utils/arabic_digits.dart' show getVocalizedSurahName;
import '../models/surah_objectives_card.dart';

/// Compact metadata record for a Surah.
class SurahMeta {
  final int number;
  final int revelationOrder;
  final String type; // 'مكية' / 'مدنية'
  final String en;
  final String meaning;

  const SurahMeta(
    this.number,
    this.revelationOrder,
    this.type,
    this.en,
    this.meaning,
  );
}

/// Service providing comprehensive Surah Introductions, Objectives,
/// Thematic Divisions, and Virtues (مقاصد السور ومحاورها).
class QuranSurahObjectivesService {
  static final QuranSurahObjectivesService _instance =
      QuranSurahObjectivesService._internal();
  factory QuranSurahObjectivesService() => _instance;
  QuranSurahObjectivesService._internal();

  static const String _source65Url = 'https://web.wahy.net/api/source/65';
  static const String _prefsPrefix = 'quran_surah_objectives_v1';

  final Map<int, SurahObjectivesCard> _ramCache = {};
  http.Client? _client;

  @visibleForTesting
  void setHttpClient(http.Client? client) {
    _client = client;
  }

  http.Client get _effectiveClient => _client ?? http.Client();

  /// Retrieve full objectives card for a Surah.
  Future<SurahObjectivesCard> getSurahObjectives(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) {
      return _generateBundledObjectives(1);
    }

    // 1. RAM Cache
    if (_ramCache.containsKey(surahNumber)) {
      return _ramCache[surahNumber]!;
    }

    // 2. Persistent Storage Cache
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString('${_prefsPrefix}_$surahNumber');
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final decoded = json.decode(cachedStr) as Map<String, dynamic>;
        final card = SurahObjectivesCard.fromJson(decoded);
        _ramCache[surahNumber] = card;
        return card;
      } catch (_) {}
    }

    // 3. Network Fetch from Markaz Tafsir (Source 65)
    try {
      final card = await _fetchFromSource65(surahNumber);
      if (card != null) {
        _ramCache[surahNumber] = card;
        await prefs.setString(
          '${_prefsPrefix}_$surahNumber',
          json.encode(card.toJson()),
        );
        return card;
      }
    } catch (_) {}

    // 4. Bundled Scholarly Fallback
    final fallback = _generateBundledObjectives(surahNumber);
    _ramCache[surahNumber] = fallback;
    return fallback;
  }

  Future<SurahObjectivesCard?> _fetchFromSource65(int surahNumber) async {
    final url = Uri.parse('$_source65Url/$surahNumber');
    final response =
        await _effectiveClient.get(url).timeout(AppPolicy.networkTimeout);

    if (response.statusCode != 200) {
      return null;
    }

    final decoded =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final firstAyahObj = decoded['1'] as Map<String, dynamic>?;
    final firstAyahText = firstAyahObj?['t'] as String? ?? '';

    final extractedObjective = _extractMainObjective(firstAyahText);

    return _generateBundledObjectives(
      surahNumber,
      overrideObjective: extractedObjective,
    );
  }

  String? _extractMainObjective(String text) {
    if (!text.contains('من مقاصد السورة')) return null;
    final lines = text.split('\n');
    bool capturing = false;
    final buffer = StringBuffer();
    for (final line in lines) {
      if (line.contains('من مقاصد السورة')) {
        capturing = true;
        continue;
      }
      if (capturing) {
        if (line.trim().startsWith('*') ||
            line.trim().startsWith('التفسير') ||
            line.trim().startsWith('(1)')) {
          break;
        }
        if (line.trim().isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(line.trim());
        }
      }
    }
    final result = buffer.toString().trim();
    return result.isNotEmpty ? result : null;
  }

  SurahObjectivesCard _generateBundledObjectives(
    int surahNumber, {
    String? overrideObjective,
  }) {
    final meta = surahMetadata[surahNumber] ??
        SurahMeta(
          surahNumber,
          surahNumber,
          'مكية',
          quran.getSurahName(surahNumber),
          '',
        );

    final surahName = quran.getSurahNameArabic(surahNumber);
    final vocalized = getVocalizedSurahName(surahNumber, fallback: surahName);
    final versesCount = quran.getVerseCount(surahNumber);
    final startPage = quran.getSurahPages(surahNumber)[0];

    // Classical Objectives per Surah
    final objective = overrideObjective ??
        _defaultObjectives[surahNumber] ??
        'بيان أصول التوحيد وتثبيت الإيمان وتقرير دلائل الوحي وأحكام الشريعة.';

    final naming = _defaultNamingReasons[surahNumber] ??
        'سُميت السورة الكريمة بهذا الاسم لورود اللفظ أو المعنى الدال على مقصدها في آياتها الشريفة.';

    final otherNames = _defaultOtherNames[surahNumber] ?? const <String>[];
    final virtues = _defaultVirtues[surahNumber] ?? const <String>[];
    final sections = _buildThematicSections(surahNumber, versesCount);
    final connection = _defaultConnections[surahNumber] ??
        'ارتباط وثيق بحسب نسق المصحف الشريف في تتميم المعاني وإحكام البيان بين السور.';

    return SurahObjectivesCard(
      surahNumber: surahNumber,
      name: surahName,
      vocalizedName: vocalized,
      englishName: meta.en,
      englishMeaning: meta.meaning,
      revelationPlace: meta.type,
      revelationOrder: meta.revelationOrder,
      versesCount: versesCount,
      startPage: startPage,
      otherNames: otherNames,
      mainObjective: objective,
      namingReason: naming,
      thematicSections: sections,
      virtues: virtues,
      connectionWithPrevious: connection,
    );
  }

  List<SurahThematicSection> _buildThematicSections(
    int surahNumber,
    int verseCount,
  ) {
    if (_customThematicSections.containsKey(surahNumber)) {
      return _customThematicSections[surahNumber]!;
    }

    if (verseCount <= 10) {
      return [
        SurahThematicSection(
          title: 'محور السورة ومقصدها الشامل',
          startAyah: 1,
          endAyah: verseCount,
          description: 'تقرير دعائم العقيدة وبيان دلائل قدرة الله ووحدانيته.',
        ),
      ];
    }

    final mid = (verseCount / 2).floor();
    return [
      SurahThematicSection(
        title: 'المقدمة وتقرير أصول الهداية والدلائل',
        startAyah: 1,
        endAyah: mid,
        description: 'افتتاح السورة بالثناء على الله وتقرير دلائل التوحيد والرسالة.',
      ),
      SurahThematicSection(
        title: 'أحكام التشريع والتحذير من عواقب التكذيب وخاتمة السورة',
        startAyah: mid + 1,
        endAyah: verseCount,
        description: 'بيان أحكام الإيمان والدعوة إلى العمل والاستسلام لأمر الله.',
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Classical Thematic Divisions for Major Surahs
  // ---------------------------------------------------------------------------
  static const Map<int, List<SurahThematicSection>> _customThematicSections = {
    1: [
      SurahThematicSection(
        title: 'الثناء والتمجيد لله تعالى',
        startAyah: 1,
        endAyah: 4,
        description: 'افتتاح بالحمد والثناء على الله بصفات الكمال والرحمة وبيان ملكه ليوم الدين.',
      ),
      SurahThematicSection(
        title: 'إخلاص العبادة والاستعانة',
        startAyah: 5,
        endAyah: 5,
        description: 'حصر العبادة والاستعانة بالله وحده وتجريد التوحيد الخالص.',
      ),
      SurahThematicSection(
        title: 'دعاء الهداية إلى الصراط المستقيم',
        startAyah: 6,
        endAyah: 7,
        description: 'طلب سلوك صراط المنعم عليهم من النبيين والصديقين وتجنب سبيل المغضوب عليهم والضالين.',
      ),
    ],
    2: [
      SurahThematicSection(
        title: 'أصناف الناس وموقفهم من الوحي',
        startAyah: 1,
        endAyah: 20,
        description: 'صفات المتقين والكافرين والمنافقين وبيان هداية القرآن الكريم.',
      ),
      SurahThematicSection(
        title: 'دلائل التوحيد وقصة استخلاف آدم',
        startAyah: 21,
        endAyah: 39,
        description: 'الدعوة العامة لعبادة الله وبيان قصة بدء الخلق واستخلاف الإنسان في الأرض.',
      ),
      SurahThematicSection(
        title: 'محاججة بني إسرائيل والتذكير بنعم الله',
        startAyah: 40,
        endAyah: 141,
        description: 'تفصيل نعم الله على بني إسرائيل ومواقفهم والتحذير من اتباع مسلكهم.',
      ),
      SurahThematicSection(
        title: 'تحويل القبلة ومنهاج الأمة الوسط',
        startAyah: 142,
        endAyah: 167,
        description: 'استقلال الأمة الإسلامية بالقبلة وميثاق الشهادة على الأمم.',
      ),
      SurahThematicSection(
        title: 'أحكام التشريع والعبادات والمعاملات',
        startAyah: 168,
        endAyah: 254,
        description: 'أحكام القصاص، الوصية، الصيام، الحج، الجهاد، الإنفاق، والأسرة.',
      ),
      SurahThematicSection(
        title: 'آية الكرسي ودلائل القدرة وأحكام الأموال والربا',
        startAyah: 255,
        endAyah: 286,
        description: 'أعظم آية في كتاب الله، دلائل إحياء الموتى، تحريم الربا، أحكام المداينة، ودعاء الختام.',
      ),
    ],
    3: [
      SurahThematicSection(
        title: 'تثبيت عقيدة التوحيد وإحكام القرآن',
        startAyah: 1,
        endAyah: 32,
        description: 'تقرير وحدانية الله وبيان المحكم والمتشابه ومحبة الله باتباع رسوله.',
      ),
      SurahThematicSection(
        title: 'اصطفاء آل عمران وقصة مريم وعيسى عليه السلام',
        startAyah: 33,
        endAyah: 63,
        description: 'بيان حقيقة ولادة عيسى عليه السلام ودحض عقائد الغلو ومباهلة النصارى.',
      ),
      SurahThematicSection(
        title: 'دعوة أهل الكتاب وبيان ميثاق النبيين',
        startAyah: 64,
        endAyah: 99,
        description: 'الدعوة إلى كلمة سواء والدفاع عن ملة إبراهيم الحنيفية.',
      ),
      SurahThematicSection(
        title: 'الاعتصام بحبل الله والأمر بالمعروف',
        startAyah: 100,
        endAyah: 120,
        description: 'توحيد صف المؤمنين وبيان خيرية هذه الأمة.',
      ),
      SurahThematicSection(
        title: 'غزوة أحد ودروس الابتلاء والتمحيص',
        startAyah: 121,
        endAyah: 189,
        description: 'عبر الهزيمة والتمحيص وأثر طاعة القيادة وفضل الشهداء.',
      ),
      SurahThematicSection(
        title: 'التفكر في خلق السماوات والأرض والوصية بالصبر والرباط',
        startAyah: 190,
        endAyah: 200,
        description: 'أولو الألباب ودعاؤهم الجامع، والختام بالأمر بالصبر والمصابرة والتقوى.',
      ),
    ],
    18: [
      SurahThematicSection(
        title: 'مقدمة السورة وقصة أصحاب الكهف (فتنة الدين)',
        startAyah: 1,
        endAyah: 31,
        description: 'حمد الله على إنزال الكتاب، وقصة فتية آمنوا بربهم فزادهم هدى، وثواب المتمسكين بدينهم.',
      ),
      SurahThematicSection(
        title: 'قصة صاحب الجنتين (فتنة المال)',
        startAyah: 32,
        endAyah: 44,
        description: 'ضرب مثل الغرور بالدنيا والأموال وزوال النعم عند جحود فضل الله.',
      ),
      SurahThematicSection(
        title: 'حقيقة الحياة الدنيا ومشاهد يوم القيامة',
        startAyah: 45,
        endAyah: 59,
        description: 'زوال متاع الدنيا، وعرض الصحف، وتذكير بعداوة إبليس.',
      ),
      SurahThematicSection(
        title: 'قصة موسى مع الخضر (فتنة العلم)',
        startAyah: 60,
        endAyah: 82,
        description: 'رحلة طلب العلم، وأدب التواضع مع المعلم، وحِكم الأقدار الإلهية الخفية.',
      ),
      SurahThematicSection(
        title: 'قصة ذي القرنين ويأجوج ومأجوج (فتنة السلطان والقوة)',
        startAyah: 83,
        endAyah: 110,
        description: 'التمكين في الأرض بالعدل والإيمان وبناء السد، وإخلاص العمل لله في الختام.',
      ),
    ],
    67: [
      SurahThematicSection(
        title: 'مظاهر قدرة الله وعظمته في الكون',
        startAyah: 1,
        endAyah: 5,
        description: 'تبارك الذي بيده الملك، خلق الموت والحياة للابتلاء، وإتقان خلق السماوات.',
      ),
      SurahThematicSection(
        title: 'مصير المكذبين واعترافهم في النار',
        startAyah: 6,
        endAyah: 14,
        description: 'عذاب الكافرين وخوف المؤمنين بالغيب وسعة علم الله بالسرائر.',
      ),
      SurahThematicSection(
        title: 'تذكير بنعم الله ودلائل البعث',
        startAyah: 15,
        endAyah: 26,
        description: 'تذليل الأرض للمشي في مناكبها، والأمن من مكر الله، وبداية الخلق والنشور.',
      ),
      SurahThematicSection(
        title: 'التحذير من عذاب الله وحصر النجاة في رحمته',
        startAyah: 27,
        endAyah: 30,
        description: 'قرب الوعد، والتوكل على الرحمن، ونعمة الماء المعين.',
      ),
    ],
  };

  // ---------------------------------------------------------------------------
  // Classical Objectives (مركز تفسير / المختصر في تفسير القرآن الكريم)
  // ---------------------------------------------------------------------------
  static const Map<int, String> _defaultObjectives = {
    1: 'تحقيق العبودية الخالصة لله تعالى وطلب الهداية إلى الصراط المستقيم.',
    2: 'الأمر بتحقيق الاستخلاف في الأرض بإقامة الإسلام، والاستسلام لله، والتحذير من حال بني إسرائيل.',
    3: 'إثبات أن دين الإسلام هو الحق ردًّا على شبهات أهل الكتاب، وتثبيتاً للمؤمنين عند الشدائد.',
    4: 'تنظيم المجتمع المسلم بحفظ حقوق الضعفاء (اليتامى والنساء)، وإرساء قواعد العدل والتشريع.',
    5: 'الوفاء بالعقود والعهود، وإكمال التشريعات وتطهير المجتمع وبيان أحكام الحلال والحرام.',
    6: 'تقرير عقيدة التوحيد ودحض الشرك وإقامة الحجج والبراهين العقلية على نبوة محمد ﷺ.',
    7: 'الصراع بين الحق والباطل ومصير الأمم السابقة من خلال قصص الأنبياء، وسنة الابتلاء.',
    8: 'بيان السنن الربانية في النصر والهزيمة، وأحكام الغنائم والجهاد في سبيل الله.',
    9: 'إعلان البراءة من المشركين والعهود الفاسدة، وفضح المنافقين وبيان أحكام قتال المعتدين.',
    10: 'إثبات نبوة النبي ﷺ وحقيقة الوحي، وسنة الله في نجاة المؤمنين وإهلاك المكذبين.',
    11: 'تسلية قلب النبي ﷺ بالأمر بالاستقامة وعرض عواقب الأمم المكذبة لأنبيائها.',
    12: 'بيان حكمة الله وتدبيره ولطفه بأوليائه من خلال قصة يوسف عليه السلام: من المحنة إلى المنحة.',
    13: 'إثبات قدرة الله في الكون ووحدانيته، وأن الحق ثابت أصيل والباطل زاهق زائل.',
    14: 'بيان وظيفة الرسل في إخراج الناس من الظلمات إلى النور، وتذكير بنعم الله وتوحيده.',
    15: 'حفظ الله لكتابه ودينه، وتسفيه كبر المشركين واستهزائهم بالرسالة.',
    16: 'تعداد نعم الله الظاهرة والباطنة على العباد والدعوة إلى شكرها وإفراده بالعبادة.',
    17: 'تمجيد الله وإعلاء شأن رسوله برحلة الإسراء، وبيان قواعد السلوك والأخلاق والقرآن المعجز.',
    18: 'الاعتصام بالإيمان والعلم الصالح للنجاة من فتن الدنيا الكبرى الأربع (الدين، المال، العلم، السلطان).',
    19: 'إظهار رحمة الله ولطفه بأنبيائه وأصفيائه (زكريا، يحيى، مريم، عيسى، إبراهيم) وتقرير التوحيد.',
    20: 'تسلية الرسول ﷺ وبيان أن القرآن ما أُنزل للشقاء، وقصة موسى في مواجهة فرعون.',
    21: 'اقتراب الحساب وغفلة الناس، وبيان وحدة رسالة الأنبياء جميعاً في الدعوة إلى التوحيد.',
    22: 'استشعار عظمة يوم القيامة، وإظهار شعائر الحج ومقاصدها والجهاد لرد العدوان.',
    23: 'بيان صفات المؤمنين الفائزين بالفلاح، ومراحل خلق الإنسان، وبطلان دعوى الشرك.',
    24: 'حماية الأعراض وتطهير المجتمع بالحدود والآداب، ونور الله المشرق في بيوته.',
    25: 'إثبات نزول الفرقان لهداية العالمين، ودحض أباطيل المشركين، وبيان صفات عباد الرحمن.',
    26: 'تطمين الرسول ﷺ بمواقف الرسل مع أممهم الشاكة في الوحي، وإعجاز القرآن على الشعر.',
    27: 'بيان كمال علم الله وقدرته، وقصص داود وسليمان وصالح ولوط، وتسبيح الكون للخالق.',
    28: 'بيان نصر الله للمستضعفين وإهلاك الطغاة والجبابرة من خلال قصة موسى وفرعون وقارون.',
    29: 'سنة الابتلاء والتمحيص لأهل الإيمان، وبيان وهن الشرك كبيت العنكبوت.',
    30: 'صدق وعد الله في نصرة المؤمنين، وسننه الجارية في الآفاق والكون وحركة التاريخ.',
    31: 'ترسيخ الحكمة والتربية الإيمانية من خلال وصايا لقمان الحكيم لابنه.',
    32: 'الخضوع والاستسلام لله بالدلائل الكونية والبعث بعد الموت ومصير الساجدين والمستكبرين.',
    33: 'امتثال أمر الله والتوكل عليه، ومواقف غزوة الأحزاب، ومكانة النبي ﷺ وأزواجه أمهات المؤمنين.',
    34: 'شكر النعم والتحذير من كفرانها (قصة سبأ وآل داود)، وإثبات البعث والجزاء.',
    35: 'التعريف بعظمة الخالق فاطر السماوات والأرض، وعزة الإسلام وغنى الله عن خلقه.',
    36: 'قلب القرآن: إثبات الرسالة والبعث والنشور وسنة الهداية والضلال وموت القلوب وحياتها.',
    37: 'تنزيه الله عن الشرك والولد، واصطفاف الملائكة في عبادته، وتسليم العاقبة للمرسلين.',
    38: 'عاقبة الاستكبار والخصومة في الباطل، وقصص داود وسليمان وأيوب في الصبر والتوبة والإنابة.',
    39: 'إخلاص الدين لله وحده والتحذير من الشرك، ومشاهد زمر الأبرار إلى الجنة والفجار إلى النار.',
    40: 'سعة مغفرة الله وشدة عقابه، ومجادلة المكذبين، وقصة مؤمن آل فرعون ناصراً للحق.',
    41: 'بيان فضل القرآن العربي المبين، وموقف المكذبين، وشهادة الجوارح عليهم يوم القيامة.',
    42: 'وحدة الوحي الإلهي للرسل، والشورى بين المؤمنين، والتوكل على الله في تدبير الأمور.',
    43: 'مكانة القرآن وعلوه، وبطلان دعوى اتخاذ الولد، ونعيم المتقين في الجنان.',
    44: 'نزول القرآن في الليلة المباركة، وإنذار قريش بالدخان والعذاب، ومصير فرعون وقومه.',
    45: 'الآيات الكونية الدالة على وحدانية الله، وجثو الأمم على ركبها يوم القيامة للحساب.',
    46: 'إثبات صدق القرآن، وبر الوالدين، وقصة إهلاك عاد بالأحقاف، وإيمان وفد الجن.',
    47: 'إحباط أعمال الكفار ونصر المؤمنين وأحكام قتال أعداء الدين والتحريض على الجهاد.',
    48: 'بشارة الفتح المبين للمسلمين، ورضوان الله على بيعة الرضوان، وعظمة رسول الله ﷺ وأصحابه.',
    49: 'أدب التعامل مع الرسول ﷺ، وتطهير المجتمع بالأخلاق الفاضلة، ووحدة الأخوة الإيمانية.',
    50: 'إثبات البعث والجزاء بالقرآن المجيد، وقرب الله من خلقه وإحاطة ملائكته بأعمالهم.',
    51: 'تحقيق وعد الله وقسمه بالرياح والكون، وأن رزق العباد مقسوم، وغاية الخلق هي العبادة.',
    52: 'تحقيق وقوع عذاب الله بالمكذبين ونعيم المتقين في جنات ونهر، ودحض شبهات الكفار.',
    53: 'تأكيد صدق الوحي من خلال المعراج، وبطلان عبادة الأصنام، وأن للإنسان ما سعى.',
    54: 'اقتراب الساعة وانشقاق القمر، وتيسير القرآن للذكر، والاعتبار بمصارع الأمم الخالية.',
    55: 'بيان آلاء الله ونعمه العظيمة على الثقلين (الإنس والجن) في الدنيا والآخرة.',
    56: 'تحقيق وقوع القيامة وقسمة الناس فيها إلى ثلاثة أصناف: السابقون، وأصحاب اليمين، وأصحاب الشمال.',
    57: 'حث المؤمنين على الإنفاق والجهاد، وتبيان حقيقة الدنيا والآخرة ووزن القسط والميزان.',
    58: 'سمع الله لشكوى الضعفاء، والتحذير من التناجي بالإثم، وفضل أهل العلم والإيمان.',
    59: 'إجلاء بني النضير، وأحكام الفيء، وعظمة القرآن وأسماء الله الحسنى وصفاته العلا.',
    60: 'بيان الولاء والبراء، ووجوب مباينة أعداء الله، وأحكام امتحان المؤمنات المهاجرات.',
    61: 'الحث على وحدة الصف والصدق في الجهاد، وبشارة عيسى عليه السلام بمحمد ﷺ.',
    62: 'فضل بعثة النبي ﷺ بالهدى، وفرض صلاة الجمعة، والنهي عن الاشتغال بالتجارة عنها.',
    63: 'فضح المنافقين وكشف خبث طواياهم وأقوالهم، والتحذير من فتنة الأموال والأولاد.',
    64: 'التحذير من يوم التغابن، والإيمان بقضاء الله وقدره، وتجنب الشح والبخل.',
    65: 'تشريع أحكام الطلاق والعدة والنفقة والسكنى، والتأكيد على التقوى وتيسير الأمور.',
    66: 'توجيهات لبيت النبوة، والتحذير من معصية الله بضرب المثل بامرأة نوح ولوط وامرأة فرعون ومريم.',
    67: 'إظهار ملك الله وقهره وعظمته، والابتلاء بالحياة والموت لبيان أي الناس أحسن عملاً.',
    68: 'تزكية خلق النبي ﷺ العظيم، والتنديد بأخلاق الكافرين، وقصة أصحاب الجنة.',
    69: 'تحقيق هول يوم القيامة والحاقة، وصدق القرآن الكريم وأنه قول رسول كريم.',
    70: 'بيان صبر النبي ﷺ على أذى الكفار، واستعجالهم للعذاب، وطبيعة النفس الإنسانية في الهلع والجزع.',
    71: 'جهاد نوح عليه السلام في دعوة قومه، وأثر الاستغفار في فتح بركات السماء والأرض.',
    72: 'إيمان الجن بالقرآن وتوحيدهم لله، وحفظ الوحي من استراق السمع وحراسة السماء.',
    73: 'الأمر بقيام الليل وترتيل القرآن والاستعداد لحمل القول الثقيل وأعباء الرسالة.',
    74: 'النداء بالقيام والإنذار وتطهير الثياب وهجران الرجز، والتحذير من سقر وعذابها.',
    75: 'إثبات البعث بالقسم بيوم القيامة والنفس اللوامة، وأدب تلقي الوحي، وحال المحتضر.',
    76: 'تذكير الإنسان بأصله ونشأته، وثواب الأبرار في الجنة لإطعامهم الطعام لوجه الله.',
    77: 'القسم بالمرسلات على صدق البعث والوعيد، وترديد ويل يومئذ للمكذبين.',
    78: 'بيان النبأ العظيم (البعث والقرآن) ودلائل قدرة الله في الكون وأهوال يوم الفصل.',
    79: 'نزع أرواح العباد، وقصة موسى وفرعون، ومآل الطاغين ومقام الخائفين من ربه.',
    80: 'أدب الدعوة وتوقير أهل القرآن والحرص على هدايتهم، وهول يوم يفر المرء من أخيه وأمه وأبيه.',
    81: 'انقلاب الكون وأهوال القيامة بالتكوير، وصدق الرسالة وأمانة جبريل ومحمد عليهما السلام.',
    82: 'انفطار السماء وانتثار الكواكب، وتذكير الإنسان بربه الكريم ومراقبة الكرام الكاتبين.',
    83: 'الوعيل للمطففين في الكيل والميزان، وجزاء الفجار في سجين ونعيم الأبرار في عليين.',
    84: 'انشقاق السماء وخضوعها لربها، وكدح الإنسان إلى ربه حتى يلاقيه بكتابه إما بيمينه أو وراء ظهره.',
    85: 'ثبات أصحاب الأخدود على الإيمان في وجه الطغيان، وعزة الله وبطشه بالمجرمين.',
    86: 'القسم بالطارق على حفظ كل نفس، والدلالة على البعث بخلق الإنسان من ماء دافق.',
    87: 'تسبيح اسم الرب الأعلى وتنزيهه، وتيسير النبي ﷺ لليسرى، وفضل من تزكى وذكر ربه.',
    88: 'مشاهد يوم القيامة الغاشية: وجوه خاشعة في النار، ووجوه ناعمة في الجنة، والتأمل في خلق الإبل والسماء والجبال.',
    89: 'القسم بالفجر وليال عشر، والاعتبار بمصارع عاد وثمود وفرعون، وتطمين النفس المطمئنة بالرجوع لربها راضية مرضية.',
    90: 'القسم بالبلد الحرام على كبد الإنسان ومشاقه، والحث على اقتحام العقبة بإطعام ذي مسغبة وفك الرقاب.',
    91: 'القسم بآيات الكون على فلاح من زكى نفسه وخيبة من دساها، وقصة قوم ثمود وناقة الله.',
    92: 'اختلاف مساعي الناس بين معطٍ ومتقٍ ومصدقٍ باليسرى، ومستغنٍ ومكذبٍ بالعسرى.',
    93: 'تطمين النبي ﷺ وتثبيته برعاية ربه له، والنهي عن قهر اليتيم ونهر السائل والتحدث بنعمة الله.',
    94: 'شرح صدر النبي ﷺ ووضع وزره ورفع ذكره، وأن مع العسر يسراً.',
    95: 'تكريم الله للإنسان بخلقه في أحسن تقويم، ومصير من يرد إلى أسفل سافلين إلا الذين آمنوا.',
    96: 'الأمر بالقراءة باسم الله وبدء نزول الوحي، والتحذير من طغيان الإنسان واستكباره بالمال.',
    97: 'فضل ليلة القدر وعظمتها، ونزول القرآن فيها وتنزل الملائكة والروح بالسلام.',
    98: 'وضوح البينة ببعثة النبي ﷺ، وانقسام الناس إلى شر البرية وخير البرية جزاؤهم جنات عدن.',
    99: 'هول زلزال الساعة وإخراج الأرض لأثقالها، ووزن الذرة من الخير والشر في الحساب.',
    100: 'القسم بخيل الجهاد العاديات ضبحاً، والتنديد بكنود الإنسان وحبه الشديد للمال وغفلته عن بعثرة القبور.',
    101: 'هول القارعة وقرعها لقلوب الناس، ومصير من خفت موازينه ومن ثقلت موازينه.',
    102: 'ذم التكاثر والتفاخر بالدنيا حتى زيارة المقابر، والوعيد برؤية الجحيم والسؤال عن النعيم.',
    103: 'قسم الله بالعصر على خسران الإنسان كله إلا من جمع بين الإيمان والعمل الصالح والتواصي بالحق والصبر.',
    104: 'الوعيد بالويل والهلاك لكل همزة لمزة يجمع مالاً ويعدده، وإلقائه في نار الحطمة الموصدة.',
    105: 'إظهار نصرة الله لحرمه وبيته المعظم بإهلاك أصحاب الفيل وجعل كيدهم في تضليل.',
    106: 'تذكير قريش بنعمة الأمن والرزق في رحلتي الشتاء والصيف ودعوتهم لإفراد رب هذا البيت بالعبادة.',
    107: 'ذم المكذبين بالدين المانعين للماعون الساهين عن صلاتهم المراءين في أعمالهم.',
    108: 'تثبيت النبي ﷺ بنعمة الكوثر العظيم، والأمر بالنحر لله وإخلاص العبادة وبتر شأن شانئه.',
    109: 'البراءة القاطعة من الشرك وأهله، وإعلان استقلال التوحيد والعبادة: لكم دينكم ولي دين.',
    110: 'بشارة النصر ودخول الناس في دين الله أفواجاً، وإشعار بقرب أجل النبي ﷺ والأمر بالتسبيح والاستغفار.',
    111: 'هلاك أبي لهب وامرأته حمالة الحطب وجزاؤهم في نار ذات لهب لشدة عداوتهم لدين الله.',
    112: 'إخلاص التوحيد الصافي لله الأحد الصمد الذي لم يلد ولم يولد ولم يكن له كفواً أحد.',
    113: 'الاعتصام والاستعاذة برب الفلق من شرور المخلوقات والظلمات والسحرة والحاسدين.',
    114: 'الاستعاذة برب الناس ملكهم وإلههم من شر الوسواس الخناس من الجنة والناس.',
  };

  // ---------------------------------------------------------------------------
  // Classical Naming Reasons (أسباب التسمية)
  // ---------------------------------------------------------------------------
  static const Map<int, String> _defaultNamingReasons = {
    1: 'سُميت الفاتحة لافتتاح المصحف الشريف بها في الترتيب، وافتتاح القراءة بها في الصلاة.',
    2: 'سُميت البقرة لورود قصة البقرة التي أُمر بنو إسرائيل بذبحها دلالةً على قدرة الله على إحياء الموتى.',
    3: 'سُميت آل عمران لورود ذكر أسرة عمران الصالحة واصطفائها وقصة نذر امرأة عمران وولادة مريم وعيسى.',
    4: 'سُميت النساء لكثرة ما ورد فيها من الأحكام التشريعية الخاصة بالمرأة وحقوقها وتنظيم الأسرة.',
    5: 'سُميت المائدة لورود قصة نزول المائدة من السماء على الحواريين عيسى بن مريم عليه السلام آيةً وبرهاناً.',
    6: 'سُميت الأنعام لتفصيل أحكام بهيمة الأنعام وما كان يبتدعه أهل الجاهلية من تحريمها بالباطل كالبحيرة والسائبة.',
    7: 'سُميت الأعراف لذكر أصحاب الأعراف وهم قوم استوت حسناتهم وسيئاتهم يوقفون على سور عالٍ بين الجنة والنار.',
    8: 'سُميت الأنفال لبيان أحكام الغنائم الحربية (الأنفال) وقسمتها بعد معركة بدر الكبرى.',
    9: 'سُميت التوبة لبيان توبة الله على النبي والمهاجرين والأنصار والثلاثة الذين خُلّفوا، وتسمى براءة للبراءة من المشركين.',
    10: 'سُميت يونس لذكر قصة نبي الله يونس عليه السلام مع قومه الذين آمنوا فكشف الله عنهم عذاب الخزي.',
    18: 'سُميت الكهف لقصة الفتية المؤمنين الذين أووا إلى الكهف فراراً بدينهم فحفظهم الله بحفظه العجيب.',
    67: 'سُميت الملك لافتتاحها بتمجيد الله الذي بيده الملك وله التصرف المطلق في خلقه، وتسمى تبارك والمنجية.',
    112: 'سُميت الإخلاص لأنها أخلصت لبيان صفات الرب سبحانه وتجريد التوحيد، وتخلص تاليها من الشرك والنار.',
    113: 'سُميت الفلق لافتتاحها بالاستعاذة برب الفلق وهو الصبح وما ينفلق عنه من خلق الله.',
    114: 'سُميت الناس لتكرار ذكر صفة ربوبية الله وملكه وإلهيته للبشر واستعاذتهم به من وساوس الشيطان.',
  };

  // ---------------------------------------------------------------------------
  // Classical Other Names (أسماء السور الأخرى)
  // ---------------------------------------------------------------------------
  static const Map<int, List<String>> _defaultOtherNames = {
    1: ['أم الكتاب', 'السبع المثاني', 'القرآن العظيم', 'الشافية', 'الوافية', 'الكافية', 'الصلاة'],
    2: ['فسطاط القرآن', 'الزهراء', 'سنام القرآن'],
    3: ['الزهراء', 'الأمان', 'الكنز'],
    9: ['براءة', 'الفاضحة', 'المقشقشة', 'المبعثرة', 'البحوث'],
    17: ['بني إسرائيل', 'سبحان'],
    18: ['الحائلة'],
    32: ['المضاجع', 'سجدة لقمان'],
    36: ['حبيبة', 'المُعِمّة', 'المدافعة'],
    40: ['المؤمن', 'ذي الطول'],
    67: ['تبارك', 'المانعة', 'المنجية', 'الواقية'],
    112: ['الأساس', 'التوحيد', 'الصمد', 'المقشقشة', 'المعوذة'],
    113: ['المعوذة الأولى', 'المقشقشة'],
    114: ['المعوذة الثانية', 'المقشقشة'],
  };

  // ---------------------------------------------------------------------------
  // Classical Virtues (فضائل السور)
  // ---------------------------------------------------------------------------
  static const Map<int, List<String>> _defaultVirtues = {
    1: [
      'أعظم سورة في كتاب الله تعالى (حديث أبي سعيد بن المعلى في صحيح البخاري).',
      'السبع المثاني والقرآن العظيم الذي أوتيه رسول الله ﷺ.',
      'لم ينزل في التوراة ولا في الإنجيل ولا في الزبور ولا في الفرقان مثلها.',
      'قسمها الله بينه وبين عبده نصفين: نصف ثناء وتمجيد، ونصف دعاء واستعانة.',
    ],
    2: [
      'سنام القرآن وذروته، من قرأها في بيته لم يدخله شيطان ثلاث ليالٍ.',
      'فيها آية الكرسي، وهي أعظم آية في كتاب الله بنص الحديث الصحيح.',
      'خواتيمها (الآيتان الأخيرتان) كنز من تحت العرش من قرأهما في ليلة كفتاه.',
      'تأتي مع آل عمران يوم القيامة كأنهما غمامتان أو غيايتان تحاجان عن أصحابهما.',
    ],
    3: [
      'إحدى الزهراوين تظلان صاحبهما يوم القيامة كأنهما طيران صواف.',
      'فيها اسم الله الأعظم في قوله: ﴿الم * اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ﴾.',
      'في خواتيمها عشر آيات كان النبي ﷺ يستيقظ في الليل يقرأها ويتفكر في خلق السماوات والأرض.',
    ],
    18: [
      'من حفظ عشر آيات من أولها (وفي رواية من آخرها) عُصم من فتنة الدجال.',
      'من قرأ سورة الكهف في يوم الجمعة أضاء له من النور ما بين الجمعتين.',
      'تنزلت السكينة والملائكة لقراءتها في عهد رسول الله ﷺ.',
    ],
    67: [
      'سورة ثلاثون آية شفعت لرجل حتى غُفر له: تبارك الذي بيده الملك.',
      'المانعة من عذاب القبر والمنجية لصاحبها يوم القيامة.',
      'كان النبي ﷺ لا ينام حتى يقرأ ﴿الم * تَنْزِيلُ﴾ السجدة و﴿تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ﴾.',
    ],
    112: [
      'تعدل ثلث القرآن الكريم في الأجر والفضل لتمحيضها لصفات الرحمن.',
      'حبها يوجب دخول الجنة، وبها بنى الله لصحابيها بيتاً في الجنة.',
    ],
    113: [
      'إحدى المعوذتين اللتين قال فيهما النبي ﷺ: «ما تعوذ متعوذ بمثلهما».',
      'كان النبي ﷺ يتعوذ بهما عند النوم وفي الصباح والمساء ودبر كل صلاة.',
    ],
    114: [
      'المعوذة الجامعة لعصمة النفس من وساوس شياطين الإنس والجن.',
      'من قرأ الإخلاص والمعوذتين حين يمسي وحين يصبح ثلاث مرات كفته من كل شيء.',
    ],
  };

  // ---------------------------------------------------------------------------
  // Canonical Connections (مناسبة السورة لما قبلها)
  // ---------------------------------------------------------------------------
  static const Map<int, String> _defaultConnections = {
    1: 'فاتحة كتاب الله ورأس القرآن العظيم ومفتاح الهداية لكل ما بعدها من سور وتفاصيل.',
    2: 'ختمت الفاتحة بطلب الهداية ﴿اهدِنَا الصِّرَاطَ المُستَقِيمَ﴾ فافتتحت البقرة ببيان موضع الهداية ﴿ذَٰلِكَ الكِتَابُ لَا رَيبَ فِيهِ هُدًى لِّلمُتَّقِينَ﴾.',
    3: 'ختمت البقرة بطلب النصرة على القوم الكافرين ﴿فَانصُرنَا عَلَى القَومِ الكَافِرِينَ﴾ فجاءت آل عمران تفصل نصرة المؤمنين ومحاججة الكافرين ودروس أحد.',
    4: 'ختمت آل عمران بالأمر بالتقوى ﴿وَاتَّقُوا اللَّهَ لَعَلَّكُمْ تُفْلِحُونَ﴾ فافتتحت النساء بالأمر نفسه ﴿يَا أَيُّهَا النَّاسُ اتَّقُوا رَبَّكُمُ الَّذِي خَلَقَكُم مِّن نَّفْسٍ وَاحِدَةٍ﴾.',
    5: 'ختمت النساء بأحكام الكلالة والعهود، وافتتحت المائدة بالأمر الصريح بالوفاء بالعهود كلها ﴿يَا أَيُّهَا الَّذِينَ آمَنُوا أَوْفُوا بِالْعُقُودِ﴾.',
    114: 'ختمت سورة الفلق بالاستعاذة من الشرور الظاهرة كالليل والحسد والسحر، وجاءت سورة الناس لتستعيذ من الشر الخفي الداخلي الأعظم وهو وسواس الصدور.',
  };

  // ---------------------------------------------------------------------------
  // All 114 Surahs Metadata Map
  // ---------------------------------------------------------------------------
  static const Map<int, SurahMeta> surahMetadata = {
    1: SurahMeta(1, 5, 'مكية', 'Al-Faatiha', 'The Opening'),
    2: SurahMeta(2, 87, 'مدنية', 'Al-Baqara', 'The Cow'),
    3: SurahMeta(3, 89, 'مدنية', 'Aal-i-Imraan', 'The Family of Imraan'),
    4: SurahMeta(4, 92, 'مدنية', 'An-Nisaa', 'The Women'),
    5: SurahMeta(5, 112, 'مدنية', 'Al-Maaida', 'The Table'),
    6: SurahMeta(6, 55, 'مكية', 'Al-An\'aam', 'The Cattle'),
    7: SurahMeta(7, 39, 'مكية', 'Al-A\'raaf', 'The Heights'),
    8: SurahMeta(8, 88, 'مدنية', 'Al-Anfaal', 'The Spoils of War'),
    9: SurahMeta(9, 113, 'مدنية', 'At-Tawba', 'The Repentance'),
    10: SurahMeta(10, 51, 'مكية', 'Yunus', 'Jonas'),
    11: SurahMeta(11, 52, 'مكية', 'Hud', 'Hud'),
    12: SurahMeta(12, 53, 'مكية', 'Yusuf', 'Joseph'),
    13: SurahMeta(13, 96, 'مدنية', 'Ar-Ra\'d', 'The Thunder'),
    14: SurahMeta(14, 72, 'مكية', 'Ibrahim', 'Abraham'),
    15: SurahMeta(15, 54, 'مكية', 'Al-Hijr', 'The Rock'),
    16: SurahMeta(16, 70, 'مكية', 'An-Nahl', 'The Bee'),
    17: SurahMeta(17, 50, 'مكية', 'Al-Israa', 'The Night Journey'),
    18: SurahMeta(18, 69, 'مكية', 'Al-Kahf', 'The Cave'),
    19: SurahMeta(19, 44, 'مكية', 'Maryam', 'Mary'),
    20: SurahMeta(20, 45, 'مكية', 'Taa-Haa', 'Taa-Haa'),
    21: SurahMeta(21, 73, 'مكية', 'Al-Anbiyaa', 'The Prophets'),
    22: SurahMeta(22, 103, 'مدنية', 'Al-Hajj', 'The Pilgrimage'),
    23: SurahMeta(23, 74, 'مكية', 'Al-Muminoon', 'The Believers'),
    24: SurahMeta(24, 102, 'مدنية', 'An-Noor', 'The Light'),
    25: SurahMeta(25, 42, 'مكية', 'Al-Furqaan', 'The Criterion'),
    26: SurahMeta(26, 47, 'مكية', 'Ash-Shu\'araa', 'The Poets'),
    27: SurahMeta(27, 48, 'مكية', 'An-Naml', 'The Ant'),
    28: SurahMeta(28, 49, 'مكية', 'Al-Qasas', 'The Stories'),
    29: SurahMeta(29, 85, 'مكية', 'Al-Ankaboot', 'The Spider'),
    30: SurahMeta(30, 84, 'مكية', 'Ar-Room', 'The Romans'),
    31: SurahMeta(31, 57, 'مكية', 'Luqman', 'Luqman'),
    32: SurahMeta(32, 75, 'مكية', 'As-Sajda', 'The Prostration'),
    33: SurahMeta(33, 90, 'مدنية', 'Al-Ahzaab', 'The Clans'),
    34: SurahMeta(34, 58, 'مكية', 'Saba', 'Sheba'),
    35: SurahMeta(35, 43, 'مكية', 'Faatir', 'The Originator'),
    36: SurahMeta(36, 41, 'مكية', 'Yaseen', 'Yaseen'),
    37: SurahMeta(37, 56, 'مكية', 'As-Saaffaat', 'Those drawn up in Ranks'),
    38: SurahMeta(38, 38, 'مكية', 'Saad', 'The letter Saad'),
    39: SurahMeta(39, 59, 'مكية', 'Az-Zumar', 'The Groups'),
    40: SurahMeta(40, 60, 'مكية', 'Al-Ghaafir', 'The Forgiver'),
    41: SurahMeta(41, 61, 'مكية', 'Fussilat', 'Explained in detail'),
    42: SurahMeta(42, 62, 'مكية', 'Ash-Shura', 'Consultation'),
    43: SurahMeta(43, 63, 'مكية', 'Az-Zukhruf', 'Ornaments of gold'),
    44: SurahMeta(44, 64, 'مكية', 'Ad-Dukhaan', 'The Smoke'),
    45: SurahMeta(45, 65, 'مكية', 'Al-Jaathiya', 'Crouching'),
    46: SurahMeta(46, 66, 'مكية', 'Al-Ahqaf', 'The Dunes'),
    47: SurahMeta(47, 95, 'مدنية', 'Muhammad', 'Muhammad'),
    48: SurahMeta(48, 111, 'مدنية', 'Al-Fath', 'The Victory'),
    49: SurahMeta(49, 106, 'مدنية', 'Al-Hujuraat', 'The Inner Apartments'),
    50: SurahMeta(50, 34, 'مكية', 'Qaaf', 'The letter Qaaf'),
    51: SurahMeta(51, 67, 'مكية', 'Adh-Dhaariyaat', 'The Winnowing Winds'),
    52: SurahMeta(52, 76, 'مكية', 'At-Toor', 'The Mount'),
    53: SurahMeta(53, 23, 'مكية', 'An-Najm', 'The Star'),
    54: SurahMeta(54, 37, 'مكية', 'Al-Qamar', 'The Moon'),
    55: SurahMeta(55, 97, 'مدنية', 'Ar-Rahmaan', 'The Beneficent'),
    56: SurahMeta(56, 46, 'مكية', 'Al-Waaqia', 'The Inevitable'),
    57: SurahMeta(57, 94, 'مدنية', 'Al-Hadid', 'The Iron'),
    58: SurahMeta(58, 105, 'مدنية', 'Al-Mujaadila', 'The Pleading Woman'),
    59: SurahMeta(59, 101, 'مدنية', 'Al-Hashr', 'The Exile'),
    60: SurahMeta(60, 91, 'مدنية', 'Al-Mumtahana', 'She that is to be examined'),
    61: SurahMeta(61, 109, 'مدنية', 'As-Saff', 'The Ranks'),
    62: SurahMeta(62, 110, 'مدنية', 'Al-Jumu\'a', 'Friday'),
    63: SurahMeta(63, 104, 'مدنية', 'Al-Munaafiqoon', 'The Hypocrites'),
    64: SurahMeta(64, 108, 'مدنية', 'At-Taghaabun', 'Mutual Disillusion'),
    65: SurahMeta(65, 99, 'مدنية', 'At-Talaaq', 'Divorce'),
    66: SurahMeta(66, 107, 'مدنية', 'At-Tahrim', 'The Prohibition'),
    67: SurahMeta(67, 77, 'مكية', 'Al-Mulk', 'The Sovereignty'),
    68: SurahMeta(68, 2, 'مكية', 'Al-Qalam', 'The Pen'),
    69: SurahMeta(69, 78, 'مكية', 'Al-Haaqqa', 'The Reality'),
    70: SurahMeta(70, 79, 'مكية', 'Al-Ma\'aarij', 'The Ascending Stairways'),
    71: SurahMeta(71, 71, 'مكية', 'Nooh', 'Noah'),
    72: SurahMeta(72, 40, 'مكية', 'Al-Jinn', 'The Jinn'),
    73: SurahMeta(73, 3, 'مكية', 'Al-Muzzammil', 'The Enshrouded One'),
    74: SurahMeta(74, 4, 'مكية', 'Al-Muddaththir', 'The Cloaked One'),
    75: SurahMeta(75, 31, 'مكية', 'Al-Qiyaama', 'The Resurrection'),
    76: SurahMeta(76, 98, 'مدنية', 'Al-Insaan', 'Man'),
    77: SurahMeta(77, 33, 'مكية', 'Al-Mursalaat', 'The Emissaries'),
    78: SurahMeta(78, 80, 'مكية', 'An-Naba', 'The Announcement'),
    79: SurahMeta(79, 81, 'مكية', 'An-Naazi\'aat', 'Those who drag forth'),
    80: SurahMeta(80, 24, 'مكية', 'Abasa', 'He frowned'),
    81: SurahMeta(81, 7, 'مكية', 'At-Takwir', 'The Overthrowing'),
    82: SurahMeta(82, 82, 'مكية', 'Al-Infitaar', 'The Cleaving'),
    83: SurahMeta(83, 86, 'مكية', 'Al-Mutaffifin', 'Defrauding'),
    84: SurahMeta(84, 83, 'مكية', 'Al-Inshiqaaq', 'The Splitting Open'),
    85: SurahMeta(85, 27, 'مكية', 'Al-Burooj', 'The Constellations'),
    86: SurahMeta(86, 36, 'مكية', 'At-Taariq', 'The Morning Star'),
    87: SurahMeta(87, 8, 'مكية', 'Al-A\'laa', 'The Most High'),
    88: SurahMeta(88, 68, 'مكية', 'Al-Ghaashiya', 'The Overwhelming'),
    89: SurahMeta(89, 10, 'مكية', 'Al-Fajr', 'The Dawn'),
    90: SurahMeta(90, 35, 'مكية', 'Al-Balad', 'The City'),
    91: SurahMeta(91, 26, 'مكية', 'Ash-Shams', 'The Sun'),
    92: SurahMeta(92, 9, 'مكية', 'Al-Lail', 'The Night'),
    93: SurahMeta(93, 11, 'مكية', 'Ad-Duhaa', 'The Morning Hours'),
    94: SurahMeta(94, 12, 'مكية', 'Ash-Sharh', 'The Relief'),
    95: SurahMeta(95, 28, 'مكية', 'At-Tin', 'The Fig'),
    96: SurahMeta(96, 1, 'مكية', 'Al-Alaq', 'The Clot'),
    97: SurahMeta(97, 25, 'مكية', 'Al-Qadr', 'The Power'),
    98: SurahMeta(98, 100, 'مدنية', 'Al-Bayyina', 'The Clear Proof'),
    99: SurahMeta(99, 93, 'مدنية', 'Az-Zalzala', 'The Earthquake'),
    100: SurahMeta(100, 14, 'مكية', 'Al-Aadiyaat', 'The Courser'),
    101: SurahMeta(101, 30, 'مكية', 'Al-Qaari\'a', 'The Calamity'),
    102: SurahMeta(102, 16, 'مكية', 'At-Takaathur', 'The Rivalry in world increase'),
    103: SurahMeta(103, 13, 'مكية', 'Al-Asr', 'The Declining Day'),
    104: SurahMeta(104, 32, 'مكية', 'Al-Humaza', 'The Traducer'),
    105: SurahMeta(105, 19, 'مكية', 'Al-Fil', 'The Elephant'),
    106: SurahMeta(106, 29, 'مكية', 'Quraish', 'Quraysh'),
    107: SurahMeta(107, 17, 'مكية', 'Al-Maa\'oon', 'Small Kindnesses'),
    108: SurahMeta(108, 15, 'مكية', 'Al-Kawthar', 'The Abundance'),
    109: SurahMeta(109, 18, 'مكية', 'Al-Kaafiroon', 'The Disbelievers'),
    110: SurahMeta(110, 114, 'مدنية', 'An-Nasr', 'The Divine Support'),
    111: SurahMeta(111, 6, 'مكية', 'Al-Masad', 'The Palm Fibre'),
    112: SurahMeta(112, 22, 'مكية', 'Al-Ikhlaas', 'Sincerity'),
    113: SurahMeta(113, 20, 'مكية', 'Al-Falaq', 'The Daybreak'),
    114: SurahMeta(114, 21, 'مكية', 'An-Naas', 'Mankind'),
  };
}

