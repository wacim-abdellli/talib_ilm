import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_palette.dart';
import 'notification_service.dart';

enum DhikrMomentContent { names, adhkar, mixed, duas, quran, hadith }

class DhikrMomentItem {
  final String text;
  final String meaning;
  final String categoryLabel;

  const DhikrMomentItem({
    required this.text,
    required this.meaning,
    required this.categoryLabel,
  });

  String get notificationBody =>
      meaning.isNotEmpty ? '$text\n$meaning' : text;
}

class DhikrMomentSettings {
  final bool enabled;
  final int timesPerDay;
  final int startMinutes;
  final int endMinutes;
  final DhikrMomentContent content;

  const DhikrMomentSettings({
    this.enabled = false,
    this.timesPerDay = 20,
    this.startMinutes = 8 * 60,
    this.endMinutes = 22 * 60,
    this.content = DhikrMomentContent.mixed,
    int? intervalHours,
  });

  int get intervalHours =>
      timesPerDay > 0 ? (24 ~/ timesPerDay).clamp(1, 24) : 6;

  DhikrMomentSettings copyWith({
    bool? enabled,
    int? timesPerDay,
    int? intervalHours,
    int? startMinutes,
    int? endMinutes,
    DhikrMomentContent? content,
  }) => DhikrMomentSettings(
    enabled: enabled ?? this.enabled,
    timesPerDay:
        timesPerDay ??
        (intervalHours != null && intervalHours > 0
            ? (24 ~/ intervalHours).clamp(1, DhikrMomentService.maxAppearancesPerDay)
            : this.timesPerDay),
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    content: content ?? this.content,
  );
}

class DhikrMomentService {
  static const maxAppearancesPerDay = 50;
  static bool? _supportsFloatingOverlayOverride;
  @visibleForTesting
  static set supportsFloatingOverlayOverride(bool? value) =>
      _supportsFloatingOverlayOverride = value;
  static bool get supportsFloatingOverlay =>
      _supportsFloatingOverlayOverride ?? Platform.isAndroid;
  static const _overlayChannel = MethodChannel(
    'com.talibilm.app/dhikr_overlay',
  );
  static const _enabledKey = 'dhikr_moment_enabled';
  static const _timesKey = 'dhikr_moment_times_per_day';
  static const _startKey = 'dhikr_moment_start_minutes';
  static const _endKey = 'dhikr_moment_end_minutes';
  static const _contentKey = 'dhikr_moment_content';
  static const _notificationBaseId = 8300;

  static const List<DhikrMomentItem> _names = [
    DhikrMomentItem(text: 'الرَّحْمَنُ', meaning: 'واسع الرحمة بجميع خلقه في الدنيا والآخرة', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الرَّحِيمُ', meaning: 'ذو الرحمة الخاصة بعباده المؤمنين إحسانًا وتوفيقًا', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْمَلِكُ', meaning: 'المتصرّف في ملكه بلا منازع، المالك لكل شيء', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْقُدُّوسُ', meaning: 'المنزَّه عن كل عيب ونقص، الطاهر المبارك', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'السَّلَامُ', meaning: 'السالم من كل آفة، وواهب الأمان والسلام لعباده', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْمُؤْمِنُ', meaning: 'المصدّق لوعده، الذي يؤمّن عباده من الخوف والظلم', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْمُهَيْمِنُ', meaning: 'الرقيب الحافظ لكل شيء، الشاهد المطلع على خلقه', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْعَزِيزُ', meaning: 'القوي الغالب الذي لا يُعجزه شيءٌ في الأرض ولا في السماء', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْجَبَّارُ', meaning: 'العليّ القاهر، وجابر قلوب المنكسرين بلطفه ورحمته', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْغَفَّارُ', meaning: 'السَّتّار لذنوب عباده، المتجاوز عن خطاياهم تكرارًا', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْوَهَّابُ', meaning: 'كثير النعم والمنح بلا مقابل ولا عوض', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الرَّزَّاقُ', meaning: 'المتكفّل بأرزاق خلقه، المفيض عليهم بالخيرات', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْفَتَّاحُ', meaning: 'يفتح أبواب رحمته وخزائن رزقه، ويحكم بين خلقه بالعدل', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْعَلِيمُ', meaning: 'المحيط بكل شيء ظاهرًا وباطنًا، دقيقًا وجليلاً', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْحَكِيمُ', meaning: 'الذي يضع الأشياء في مواضعها بعدل تام وحكمة بالغة', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْوَدُودُ', meaning: 'المحب لأوليائه، والمحبوب في قلوب عباده الصالحين', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْغَفُورُ', meaning: 'عظيم المغفرة والستر، يغفر الذنب ويعفو عن العقوبة', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الشَّكُورُ', meaning: 'الذي يزكو عنده القليل من العمل فيضاعف الجزاء عليه', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْقَرِيبُ الْمُجِيبُ', meaning: 'القريب بعلمه، يجيب دعوة المضطر إذا دعاه', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْحَيُّ الْقَيُّومُ', meaning: 'الدائم الباقي، القائم بنفسه المقيم لكل ما سواه', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْكَرِيمُ', meaning: 'الذي يعطي بلا سؤال، ويجود بأفضل مما يؤمّل السائل', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'اللَّطِيفُ', meaning: 'البارّ بعباده، الموصل للخيرات برفق وإحسان خفي', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'التَّوَّابُ', meaning: 'الذي يقبل توبة التائبين ويفرح بأوبتهم واستغفارهم', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
    DhikrMomentItem(text: 'الْوَكِيلُ', meaning: 'الكافي لمن توكل عليه، القائم بمصالح خلقه', categoryLabel: 'مِنْ أَسْمَاءِ اللَّهِ'),
  ];

  static const List<DhikrMomentItem> _adhkar = [
    DhikrMomentItem(text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', meaning: 'تُحَطُّ خطاياه وإن كانت مثل زبد البحر', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ', meaning: 'غُرست له بها نخلةٌ في الجنة', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ', meaning: 'أحبُّ الكلام إلى الله، وهنّ الباقيات الصالحات', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ', meaning: 'تعدل عتق رقاب، وحرزٌ تام من الشيطان', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', meaning: 'كنزٌ من كنوز الجنة، وباب عظيم لدفع الهم', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ', meaning: 'مغفرةٌ للذنوب وسعةٌ في الرزق وتفريجٌ للكروب', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ', meaning: 'من صلّى عليه صلاةً صلّى الله عليه بها عشرًا', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ', meaning: 'دعوة ذي النون، لم يدعُ بها مكروب إلا فرّج الله عنه', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا', meaning: 'وجبت له الجنة وذاق حلاوة الإيمان', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ', meaning: 'صلاح الشأن كله وتمام التوكل والافتقار', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ', meaning: 'أمانٌ من كل خوف وكفايةٌ من كل هم', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ', meaning: 'غُفرت ذنوبه وإن كان فرّ من الزحف', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ', meaning: 'ثقل في الميزان وأجر عظيم تتسابق الملائكة لكتابته', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ', meaning: 'حفظٌ وحرزٌ تام لا يضره شيء معه', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'سُبْحَانَ اللَّهِ عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ', meaning: 'تسبيحٌ مضاعف يزن عبادة ساعات طويلة', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ', meaning: 'سيد الاستغفار، من قاله موقنًا به دخل الجنة', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', meaning: 'أفضل الدعاء، تملأ ميزان العبد يوم القيامة', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ', meaning: 'كفارة للمجلس ومحوٌ لما سواه', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', meaning: 'يُقال له: كُفيتَ ووُقيتَ وهُديتَ وتنحى عنه الشيطان', categoryLabel: 'ذِكْرٌ مَأْثُور'),
    DhikrMomentItem(text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ', meaning: 'السلامة التامة في الدين والنفس والأهل والمال', categoryLabel: 'ذِكْرٌ مَأْثُور'),
  ];

  static const List<DhikrMomentItem> _duas = [
    DhikrMomentItem(text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ', meaning: 'دعاءٌ جامع لخيري الدنيا والآخرة والوقاية من النار', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ', meaning: 'طلب معونة الله وتوفيقه على دوام الطاعة', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ', meaning: 'طلب المغفرة والتوبة الصادقة', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي', meaning: 'سؤال الله المحو التام للذنوب والصفح الجميل', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'رَبِّ زِدْنِي عِلْمًا', meaning: 'سؤال البركة والزيادة في العلم النافع', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي', meaning: 'انشراح الصدر وتيسير الأمور وزوال العسر', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى', meaning: 'جوامع الخير في الدين والدنيا وغنى النفس', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ', meaning: 'استجلاب فضل الله والافتقار إلى جوده', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ', meaning: 'استعاذة جامعة من آفات النفس وثقل الحياة', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً', meaning: 'الثبات على الإيمان والهدى حتى الممات', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا', meaning: 'دعاء الصباح المبارك لبركة اليوم ورزقه', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ', meaning: 'سؤال الثبات والاستقامة في زمن الفتن', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي', meaning: 'سؤال الله السداد في القول والعمل والهدى', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'اللَّهُمَّ آتِ نَفْسِي تَقْوَاهَا، وَزَكِّهَا أَنْتَ خَيْرُ مَنْ زَكَّاهَا', meaning: 'تزكية النفس وصلاح السريرة والأخلاق', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا', meaning: 'صلاح الأهل والذرية والقدوة في الخير', categoryLabel: 'دُعَاءٌ مُبَارَك'),
    DhikrMomentItem(text: 'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي سَمْعِي نُورًا، وَفِي بَصَرِي نُورًا', meaning: 'سؤال النور والبركة في الحواس والأركان', categoryLabel: 'دُعَاءٌ مُبَارَك'),
  ];

  static const List<DhikrMomentItem> _quran = [
    DhikrMomentItem(text: '﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾', meaning: 'سورة الرعد • ٢٨', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ﴾', meaning: 'سورة البقرة • ١٥٢', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ﴾', meaning: 'سورة البقرة • ١٨٦', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿إِنَّ مَعَ الْعُسْرِ يُسْرًا﴾', meaning: 'سورة الشرح • ٦', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ﴾', meaning: 'سورة الطلاق • ٣', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا • وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ﴾', meaning: 'سورة الطلاق • ٢-٣', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَى أَنْفُسِهِمْ لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ﴾', meaning: 'سورة الزمر • ٥٣', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَهُوَ مَعَكُمْ أَيْنَ مَا كُنْتُمْ﴾', meaning: 'سورة الحديد • ٤', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا﴾', meaning: 'سورة الطور • ٤٨', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿إِنَّ اللَّهَ مَعَ الصَّابِرِينَ﴾', meaning: 'سورة البقرة • ١٥٣', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لَا يَمُوتُ وَسَبِّحْ بِحَمْدِهِ﴾', meaning: 'سورة الفرقان • ٥٨', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ﴾', meaning: 'سورة غافر • ٦٠', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ﴾', meaning: 'سورة الأعراف • ١٥٦', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿فَصَبْرٌ جَمِيلٌ وَاللَّهُ الْمُسْتَعَانُ﴾', meaning: 'سورة يوسف • ١٨', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ﴾', meaning: 'سورة هود • ٦١', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
    DhikrMomentItem(text: '﴿وَمَا كَانَ اللَّهُ لِيُعْجِزَهُ مِنْ شَيْءٍ فِي السَّمَاوَاتِ وَلَا فِي الْأَرْضِ﴾', meaning: 'سورة فاطر • ٤٤', categoryLabel: 'آيَةٌ قُرْآنِيَّة'),
  ];

  static const List<DhikrMomentItem> _hadith = [
    DhikrMomentItem(text: '«إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى»', meaning: 'صحيح البخاري • ١', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«الدِّينُ النَّصِيحَةُ: لِلَّهِ، وَلِكِتَابِهِ، وَلِرَسُولِهِ، وَلِأَئِمَّةِ الْمُسْلِمِينَ وَعَامَّتِهِمْ»', meaning: 'صحيح مسلم • ٥٥', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ»', meaning: 'متفق عليه', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ»', meaning: 'متفق عليه', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ»', meaning: 'متفق عليه', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ»', meaning: 'صحيح مسلم', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ»', meaning: 'سنن الترمذي', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ»', meaning: 'متفق عليه', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«احْفَظِ اللَّهَ يَحْفَظْكَ، احْفَظِ اللَّهَ تَجِدْهُ تُجَاهَكَ، إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ»', meaning: 'سنن الترمذي', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللَّهُ عَلَيْهِ بِهَا عَشْرًا»', meaning: 'صحيح مسلم', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ»', meaning: 'صحيح البخاري', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
    DhikrMomentItem(text: '«عَجَبًا لِأَمْرِ الْمُؤْمِنِ، إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ؛ إِنْ أَصَابَتْهُ سَرَّاءُ شَكَرَ فَكَانَ خَيْرًا لَهُ، وَإِنْ أَصَابَتْهُ ضَرَّاءُ صَبَرَ فَكَانَ خَيْرًا لَهُ»', meaning: 'صحيح مسلم', categoryLabel: 'حَدِيثٌ نَبَوِيّ'),
  ];

  static List<DhikrMomentItem> itemsFor(DhikrMomentContent content) => switch (content) {
    DhikrMomentContent.names => _names,
    DhikrMomentContent.adhkar => _adhkar,
    DhikrMomentContent.duas => _duas,
    DhikrMomentContent.quran => _quran,
    DhikrMomentContent.hadith => _hadith,
    DhikrMomentContent.mixed => [
      ..._names,
      ..._adhkar,
      ..._duas,
      ..._quran,
      ..._hadith,
    ],
  };

  static final ValueNotifier<DhikrMomentSettings> settingsNotifier =
      ValueNotifier(const DhikrMomentSettings());
  static final ValueNotifier<DhikrMomentItem> cardItemNotifier = ValueNotifier(
    _adhkar[0],
  );
  static final ValueNotifier<String> cardTextNotifier = ValueNotifier(
    _adhkar[0].text,
  );
  static int _rotation = 0;
  static Future<bool>? _inFlightSchedule;

  static DhikrMomentItem getItemForSlot(
    DhikrMomentContent content,
    int slotIndex,
  ) {
    final list = itemsFor(content);
    if (list.isEmpty) return _adhkar[0];
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = (dayOfYear * 7 + slotIndex) % list.length;
    return list[index];
  }

  static Future<bool> scheduleTestNotification() async {
    final notifications = NotificationService();
    await notifications.init();
    await notifications.requestPermissions();
    if (!await notifications.arePermissionsGranted()) return false;
    final result = await notifications.scheduleAdhkarTestNotification(
      id: 8399,
      scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
    );
    return result.status == ScheduleOutcomeStatus.exact ||
        result.status == ScheduleOutcomeStatus.inexactFallback;
  }

  static Future<DhikrMomentSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawContent =
        prefs.getInt(_contentKey) ?? DhikrMomentContent.mixed.index;
    final content =
        rawContent >= 0 && rawContent < DhikrMomentContent.values.length
        ? DhikrMomentContent.values[rawContent]
        : DhikrMomentContent.mixed;
    final settings = DhikrMomentSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      timesPerDay: (prefs.getInt(_timesKey) ?? 20).clamp(
        1,
        maxAppearancesPerDay,
      ),
      startMinutes: (prefs.getInt(_startKey) ?? 480).clamp(0, 1439),
      endMinutes: (prefs.getInt(_endKey) ?? 1320).clamp(1, 1440),
      content: content,
    );
    settingsNotifier.value = settings;
    rotate(settings.content);
    return settings;
  }

  static void rotate(DhikrMomentContent content) {
    final source = itemsFor(content);
    final item = source[_rotation++ % source.length];
    cardItemNotifier.value = item;
    cardTextNotifier.value = item.text;
  }

  static List<int> scheduledMinutes(DhikrMomentSettings settings) {
    final span = settings.endMinutes - settings.startMinutes;
    if (span <= 0) return const [];
    final count = settings.timesPerDay.clamp(1, span);
    final uniqueMinutes = <int>{};
    for (var i = 0; i < count; i++) {
      final minute = settings.startMinutes +
          (span * (i + 1) / (count + 1)).round();
      uniqueMinutes.add(minute);
    }
    final list = uniqueMinutes.toList()..sort();
    return list;
  }

  static Future<bool> save(DhikrMomentSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_timesKey, settings.timesPerDay);
    await prefs.setInt(_startKey, settings.startMinutes);
    await prefs.setInt(_endKey, settings.endMinutes);
    await prefs.setInt(_contentKey, settings.content.index);
    settingsNotifier.value = settings;

    while (_inFlightSchedule != null) {
      await _inFlightSchedule;
    }
    final completer = Completer<bool>();
    _inFlightSchedule = completer.future;
    try {
      final ready = await _schedule(settings);
      completer.complete(ready);
      return ready;
    } catch (e) {
      completer.complete(false);
      return false;
    } finally {
      _inFlightSchedule = null;
    }
  }

  static Future<bool> _schedule(DhikrMomentSettings settings) async {
    final notifications = NotificationService();
    await _cancelScheduled(notifications);
    if (!settings.enabled) {
      await _stopOverlay();
      return true;
    }
    if (Platform.isAndroid) {
      final permission = await hasOverlayPermission();
      if (permission) {
        return await _overlayChannel.invokeMethod<bool>(
              'startOverlayService',
            ) ??
            false;
      }
    }
    return _scheduleNotifications(settings, notifications);
  }

  static Future<void> _cancelScheduled(
    NotificationService notifications,
  ) async {
    await notifications.init();
    for (var i = 0; i < 100; i++) {
      await notifications.cancelNotification(_notificationBaseId + i);
    }
  }

  static Future<bool> _scheduleNotifications(
    DhikrMomentSettings settings,
    NotificationService notifications,
  ) async {
    await notifications.init();
    await notifications.requestPermissions();
    if (!await notifications.arePermissionsGranted()) return false;

    final schedule = scheduledMinutes(settings);
    if (schedule.isEmpty) return false;

    var allScheduled = true;
    for (var index = 0; index < schedule.length; index++) {
      final totalMinute = schedule[index];
      final item = getItemForSlot(settings.content, index);

      final outcome = await notifications.scheduleDailyAdhkarNotification(
        id: _notificationBaseId + index,
        title: 'لحظة ذكر',
        body: item.notificationBody,
        hour: totalMinute ~/ 60,
        minute: totalMinute % 60,
        payload: 'dhikr_moment',
      );
      allScheduled =
          allScheduled &&
          (outcome.status == ScheduleOutcomeStatus.exact ||
              outcome.status == ScheduleOutcomeStatus.inexactFallback);
    }
    return allScheduled;
  }

  static Future<bool> hasOverlayPermission() async {
    if (!supportsFloatingOverlay) return false;
    try {
      return await _overlayChannel.invokeMethod<bool>('hasOverlayPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestOverlayPermission() async {
    if (!supportsFloatingOverlay) return false;
    try {
      return await _overlayChannel.invokeMethod<bool>(
            'requestOverlayPermission',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> showOverlayTest({
    String? categoryLabel,
    String? text,
    String? meaning,
  }) async {
    if (!supportsFloatingOverlay || !await hasOverlayPermission()) return false;
    try {
      return await _overlayChannel.invokeMethod<bool>('showOverlayTest', {
            if (categoryLabel != null) 'label': categoryLabel,
            if (text != null) 'text': text,
            if (meaning != null) 'meaning': meaning,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncOverlayService() async {
    if (!supportsFloatingOverlay) return;
    final settings = settingsNotifier.value;
    try {
      if (settings.enabled && await hasOverlayPermission()) {
        final notifications = NotificationService();
        await _cancelScheduled(notifications);
        await _overlayChannel.invokeMethod<bool>('startOverlayService');
      }
    } catch (_) {}
  }

  static Future<void> _stopOverlay() async {
    if (!supportsFloatingOverlay) return;
    try {
      await _overlayChannel.invokeMethod<bool>('stopOverlayService');
    } catch (_) {}
  }
}

class DhikrMomentOverlay extends StatefulWidget {
  final Widget child;
  const DhikrMomentOverlay({super.key, required this.child});

  @override
  State<DhikrMomentOverlay> createState() => _DhikrMomentOverlayState();
}

class _DhikrMomentOverlayState extends State<DhikrMomentOverlay>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _visible = false;
  int? _lastShownMinuteKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DhikrMomentService.settingsNotifier.addListener(_configureTimer);
    DhikrMomentService.load().then((_) {
      _configureTimer();
      unawaited(DhikrMomentService.syncOverlayService());
    });
  }

  void _configureTimer() {
    _timer?.cancel();
    final settings = DhikrMomentService.settingsNotifier.value;
    if (!settings.enabled) return;
    if (DhikrMomentService.scheduledMinutes(settings).isEmpty) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final now = DateTime.now();
      final minute = now.hour * 60 + now.minute;
      final minuteKey =
          now.year * 100000000 + now.month * 1000000 + now.day * 10000 + minute;
      if (!DhikrMomentService.scheduledMinutes(settings).contains(minute) ||
          _lastShownMinuteKey == minuteKey) {
        return;
      }
      _lastShownMinuteKey = minuteKey;
      DhikrMomentService.rotate(settings.content);
      setState(() => _visible = true);
      Future<void>.delayed(const Duration(seconds: 18), () { // ui-lint: allow auto-dismiss timer
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(DhikrMomentService.syncOverlayService());
    }
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DhikrMomentService.settingsNotifier.removeListener(_configureTimer);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (!Platform.isAndroid &&
          _visible &&
          DhikrMomentService.settingsNotifier.value.enabled)
        PositionedDirectional(
          start: AppSpace.lg,
          end: AppSpace.lg,
          bottom: AppSpace.xl,
          child: SafeArea(
            child: Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.lgRadius,
              child: ListTile(
                leading: const Icon(Icons.spa_rounded),
                title: ValueListenableBuilder<DhikrMomentItem>(
                  valueListenable: DhikrMomentService.cardItemNotifier,
                  builder: (_, item, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(item.text, textAlign: TextAlign.center),
                      if (item.meaning.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          item.meaning,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'إخفاء',
                  onPressed: () => setState(() => _visible = false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
