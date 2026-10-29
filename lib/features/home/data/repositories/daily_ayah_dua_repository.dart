import 'dart:math';
import '../models/daily_ayah_dua.dart';

class DailyAyahDuaRepository {
  DailyAyahDuaRepository._();
  static final DailyAyahDuaRepository instance = DailyAyahDuaRepository._();

  static const List<DailyAyahDua> _items = [
    DailyAyahDua(
      id: 'ad_1',
      type: AyahDuaType.ayah,
      text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      source: 'سورة البقرة: 201',
      topic: 'جامع الخيرين',
    ),
    DailyAyahDua(
      id: 'ad_2',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
      source: 'صحيح ابن ماجه',
      topic: 'البركة والعمل',
    ),
    DailyAyahDua(
      id: 'ad_3',
      type: AyahDuaType.ayah,
      text: 'رَبِّ اشْرَحْ لِي صَدْرِي ۝ وَيَسِّرْ لِي أَمْرِي',
      source: 'سورة طه: 25-26',
      topic: 'انشراح الصدر',
    ),
    DailyAyahDua(
      id: 'ad_4',
      type: AyahDuaType.dua,
      text: 'يَا مُقَلِّبَ القُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
      source: 'جامع الترمذي',
      topic: 'الثبات على الحق',
    ),
    DailyAyahDua(
      id: 'ad_5',
      type: AyahDuaType.ayah,
      text: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً',
      source: 'سورة آل عمران: 8',
      topic: 'سؤال الهداية',
    ),
    DailyAyahDua(
      id: 'ad_6',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      source: 'سنن أبي داود',
      topic: 'العون على الطاعة',
    ),
    DailyAyahDua(
      id: 'ad_7',
      type: AyahDuaType.ayah,
      text: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
      source: 'سورة طه: 114',
      topic: 'طلب العلم',
    ),
    DailyAyahDua(
      id: 'ad_8',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الهُدَى وَالتُّقَى وَالعَفَافَ وَالغِنَى',
      source: 'صحيح مسلم',
      topic: 'التقوى والعفاف',
    ),
    DailyAyahDua(
      id: 'ad_9',
      type: AyahDuaType.ayah,
      text: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      source: 'سورة آل عمران: 173',
      topic: 'التوكل والكفاية',
    ),
    DailyAyahDua(
      id: 'ad_10',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي',
      source: 'صحيح مسلم',
      topic: 'صلاح الحال',
    ),
    DailyAyahDua(
      id: 'ad_11',
      type: AyahDuaType.ayah,
      text: 'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
      source: 'سورة القصص: 24',
      topic: 'الافتقار إلى الله',
    ),
    DailyAyahDua(
      id: 'ad_12',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ زَوَالِ نِعْمَتِكَ، وَتَحَوُّلِ عَافِيَتِكَ، وَفُجَاءَةِ نِقْمَتِكَ، وَجَمِيعِ سَخَطِكَ',
      source: 'صحيح مسلم',
      topic: 'دوام النعمة والعافية',
    ),
    DailyAyahDua(
      id: 'ad_13',
      type: AyahDuaType.ayah,
      text: 'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
      source: 'سورة الأنبياء: 87',
      topic: 'تفريج الكروب',
    ),
    DailyAyahDua(
      id: 'ad_14',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ العَجْزِ وَالكَسَلِ، وَالجُبْنِ وَالبُخْلِ، وَالهَرَمِ وَعَذَابِ القَبْرِ',
      source: 'صحيح البخاري',
      topic: 'الاستعاذة النبوية',
    ),
    DailyAyahDua(
      id: 'ad_15',
      type: AyahDuaType.ayah,
      text: 'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      source: 'سورة البقرة: 250',
      topic: 'الصبر والنصر',
    ),
    DailyAyahDua(
      id: 'ad_16',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي، وَعَلِّمْنِي مَا يَنْفَعُنِي، وَزِدْنِي عِلْمًا',
      source: 'سنن الترمذي',
      topic: 'بركة العلم',
    ),
    DailyAyahDua(
      id: 'ad_17',
      type: AyahDuaType.ayah,
      text: 'رَبِّ هَبْ لِي حُكْمًا وَأَلْحِقْنِي بِالصَّالِحِينَ ۝ وَاجْعَل لِّي لِسَانَ صِدْقٍ فِي الْآخِرِينَ',
      source: 'سورة الشعراء: 83-84',
      topic: 'دعاء الصالحين',
    ),
    DailyAyahDua(
      id: 'ad_18',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي',
      source: 'سنن أبي داود',
      topic: 'العافية التامة',
    ),
    DailyAyahDua(
      id: 'ad_19',
      type: AyahDuaType.ayah,
      text: 'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ',
      source: 'سورة البقرة: 127',
      topic: 'قبول العمل',
    ),
    DailyAyahDua(
      id: 'ad_20',
      type: AyahDuaType.dua,
      text: 'اللَّهُمَّ حَاسِبْنِي حِسَابًا يَسِيرًا',
      source: 'مسند أحمد',
      topic: 'النجاة يوم القيامة',
    ),
  ];

  List<DailyAyahDua> getAll() => _items;

  DailyAyahDua getDailyItem([DateTime? date]) {
    final now = date ?? DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = (now.year * 365 + dayOfYear).abs() % _items.length;
    return _items[index];
  }

  DailyAyahDua getRandomItem({String? excludingId}) {
    final available = excludingId != null
        ? _items.where((i) => i.id != excludingId).toList()
        : _items;
    if (available.isEmpty) return _items.first;
    final random = Random();
    return available[random.nextInt(available.length)];
  }
}
