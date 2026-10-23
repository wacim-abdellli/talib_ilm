import 'package:flutter/widgets.dart';
import '../../../app/constants/app_strings.dart';

enum AdhkarCategory {
  morning,
  evening,
  afterPrayer,
  prayerSunan,
  prayerOpening,
  prayerRukuhSujud,
  tashahhudSalat,
  prayerBeforeSalam,
  witrIstikharah,
  beforePrayer,
  general,
  tasbeeh,
  istighfar,
  duas,
  sleeping,
  waking,
  home,
  mosqueAdhan,
  adhanIqamah,
  mosqueEtiquette,
  wuduFood,
  wuduTaharah,
  foodDrink,
  distress,
  distressRelief,
  protectionRuqyah,
  travel,
  sicknessFunerals,
  sicknessRuqyah,
  funeralsGraves,
  natureWeather,
  socialManners,
  fastingHajj,
  fastingAdhkar,
  hajjUmrah,
  quranicDuas,
  propheticDuas,
}

extension AdhkarCategoryLabel on AdhkarCategory {
  String get label {
    switch (this) {
      case AdhkarCategory.morning:
        return AppStrings.adhkarMorning;
      case AdhkarCategory.evening:
        return AppStrings.adhkarEvening;
      case AdhkarCategory.afterPrayer:
        return AppStrings.adhkarAfterPrayer;
      case AdhkarCategory.prayerSunan:
        return 'سنن وأدعية الصلاة';
      case AdhkarCategory.prayerOpening:
        return 'أدعية الاستفتاح في الصلاة';
      case AdhkarCategory.prayerRukuhSujud:
        return 'أذكار الركوع والسجود والاعتدال';
      case AdhkarCategory.tashahhudSalat:
        return 'التشهد والصلاة الإبراهيمية';
      case AdhkarCategory.prayerBeforeSalam:
        return 'أدعية قبل السلام وبعد التشهد';
      case AdhkarCategory.witrIstikharah:
        return 'قنوت الوتر وصلاة الاستخارة';
      case AdhkarCategory.beforePrayer:
        return AppStrings.adhkarBeforePrayer;
      case AdhkarCategory.general:
        return AppStrings.adhkarGeneral;
      case AdhkarCategory.tasbeeh:
        return AppStrings.tasbeehTab;
      case AdhkarCategory.istighfar:
        return AppStrings.istighfarTab;
      case AdhkarCategory.duas:
        return AppStrings.duasTitle;
      case AdhkarCategory.sleeping:
        return 'أذكار النوم';
      case AdhkarCategory.waking:
        return 'أذكار الاستيقاظ';
      case AdhkarCategory.home:
        return 'أذكار المنزل';
      case AdhkarCategory.mosqueAdhan:
        return 'أذكار المسجد والأذان';
      case AdhkarCategory.adhanIqamah:
        return 'أذكار الأذان والإقامة';
      case AdhkarCategory.mosqueEtiquette:
        return 'أذكار المسجد وآدابه';
      case AdhkarCategory.wuduFood:
      case AdhkarCategory.wuduTaharah:
        return 'أذكار الطهارة والوضوء';
      case AdhkarCategory.foodDrink:
        return 'أذكار الطعام والشراب';
      case AdhkarCategory.distress:
      case AdhkarCategory.distressRelief:
        return 'أدعية الكرب وتفريج الهم';
      case AdhkarCategory.protectionRuqyah:
        return 'الاستعاذة والحفظ من العين';
      case AdhkarCategory.travel:
        return 'أذكار السفر';
      case AdhkarCategory.sicknessFunerals:
        return 'أدعية المرض والجنائز';
      case AdhkarCategory.sicknessRuqyah:
        return 'أدعية المرض والرقية الشرعية';
      case AdhkarCategory.funeralsGraves:
        return 'الجنائز والتعزية وزيارة القبور';
      case AdhkarCategory.natureWeather:
        return 'أذكار المطر والظواهر';
      case AdhkarCategory.socialManners:
        return 'أذكار المجالس والآداب';
      case AdhkarCategory.fastingHajj:
        return 'أذكار الصيام والحج';
      case AdhkarCategory.fastingAdhkar:
        return 'أذكار الصيام والإفطار ورمضان';
      case AdhkarCategory.hajjUmrah:
        return 'أذكار الحج والعمرة والمناسك';
      case AdhkarCategory.quranicDuas:
        return 'أدعية القرآن الكريم';
      case AdhkarCategory.propheticDuas:
        return 'جوامع الدعاء النبوي الشريف';
    }
  }

  String get id => name;
}

AdhkarCategory? adhkarCategoryFromId(String id) {
  switch (id) {
    case 'morning':
      return AdhkarCategory.morning;
    case 'evening':
      return AdhkarCategory.evening;
    case 'after_prayer':
    case 'afterPrayer':
      return AdhkarCategory.afterPrayer;
    case 'prayer_sunan':
    case 'prayerSunan':
      return AdhkarCategory.prayerSunan;
    case 'prayer_opening':
    case 'prayerOpening':
      return AdhkarCategory.prayerOpening;
    case 'prayer_rukuh_sujud':
    case 'prayerRukuhSujud':
      return AdhkarCategory.prayerRukuhSujud;
    case 'tashahhud_salat':
    case 'tashahhudSalat':
      return AdhkarCategory.tashahhudSalat;
    case 'prayer_before_salam':
    case 'prayerBeforeSalam':
      return AdhkarCategory.prayerBeforeSalam;
    case 'witr_istikharah':
    case 'witrIstikharah':
      return AdhkarCategory.witrIstikharah;
    case 'before_prayer':
    case 'beforePrayer':
      return AdhkarCategory.beforePrayer;
    case 'tasbih':
    case 'tasbeeh':
      return AdhkarCategory.tasbeeh;
    case 'istighfar':
      return AdhkarCategory.istighfar;
    case 'duas':
    case 'misc':
      return AdhkarCategory.duas;
    case 'general':
      return AdhkarCategory.general;
    case 'sleeping':
      return AdhkarCategory.sleeping;
    case 'waking':
      return AdhkarCategory.waking;
    case 'home':
      return AdhkarCategory.home;
    case 'mosque_adhan':
    case 'mosqueAdhan':
      return AdhkarCategory.mosqueAdhan;
    case 'adhan_iqamah':
    case 'adhanIqamah':
      return AdhkarCategory.adhanIqamah;
    case 'mosque_etiquette':
    case 'mosqueEtiquette':
      return AdhkarCategory.mosqueEtiquette;
    case 'wudu_food':
    case 'wuduFood':
      return AdhkarCategory.wuduFood;
    case 'wudu_taharah':
    case 'wuduTaharah':
      return AdhkarCategory.wuduTaharah;
    case 'food_drink':
    case 'foodDrink':
      return AdhkarCategory.foodDrink;
    case 'distress':
      return AdhkarCategory.distress;
    case 'distress_relief':
    case 'distressRelief':
      return AdhkarCategory.distressRelief;
    case 'protection_ruqyah':
    case 'protectionRuqyah':
      return AdhkarCategory.protectionRuqyah;
    case 'travel':
      return AdhkarCategory.travel;
    case 'sickness_funerals':
    case 'sicknessFunerals':
      return AdhkarCategory.sicknessFunerals;
    case 'sickness_ruqyah':
    case 'sicknessRuqyah':
      return AdhkarCategory.sicknessRuqyah;
    case 'funerals_graves':
    case 'funeralsGraves':
      return AdhkarCategory.funeralsGraves;
    case 'nature_weather':
    case 'natureWeather':
      return AdhkarCategory.natureWeather;
    case 'social_manners':
    case 'socialManners':
      return AdhkarCategory.socialManners;
    case 'fasting_hajj':
    case 'fastingHajj':
      return AdhkarCategory.fastingHajj;
    case 'fasting_adhkar':
    case 'fastingAdhkar':
      return AdhkarCategory.fastingAdhkar;
    case 'hajj_umrah':
    case 'hajjUmrah':
      return AdhkarCategory.hajjUmrah;
    case 'quranic_duas':
    case 'quranicDuas':
      return AdhkarCategory.quranicDuas;
    case 'prophetic_duas':
    case 'propheticDuas':
      return AdhkarCategory.propheticDuas;
  }
  return null;
}

class AthkarItem {
  final String id;
  final String arabic;
  final String transliteration;
  final String meaning;
  final int target;
  final String countDescription;
  final String fadl;
  final String source;
  final String audio;
  final String hadithText;
  final String hadithExplanation;
  final int order;
  final int type;

  const AthkarItem({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.target,
    required this.countDescription,
    required this.fadl,
    required this.source,
    required this.audio,
    required this.hadithText,
    required this.hadithExplanation,
    required this.order,
    required this.type,
  });

  factory AthkarItem.fromJson(Map<String, dynamic> json) {
    final orderValue = _asInt(json['order']);
    final typeValue = _asInt(json['type']) ?? 0;
    final id =
        json['id']?.toString() ??
        (orderValue != null ? 'order_$orderValue' : '');
    return AthkarItem(
      id: id,
      arabic: json['arabic']?.toString() ?? json['content']?.toString() ?? '',
      transliteration: json['transliteration']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      target: _asInt(json['target']) ?? _asInt(json['count']) ?? 0,
      countDescription:
          json['count_description']?.toString() ??
          json['countDescription']?.toString() ??
          '',
      fadl: json['fadl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      audio: json['audio']?.toString() ?? '',
      hadithText:
          json['hadith_text']?.toString() ??
          json['hadithText']?.toString() ??
          '',
      hadithExplanation:
          json['explanation_of_hadith_vocabulary']?.toString() ??
          json['hadithExplanation']?.toString() ??
          '',
      order: orderValue ?? 0,
      type: typeValue,
    );
  }
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class AthkarCategoryData {
  final String id;
  final String title;
  final String subtitle;
  final List<AthkarItem> items;

  const AthkarCategoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  factory AthkarCategoryData.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AthkarItem.fromJson)
        .toList();
    return AthkarCategoryData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      items: items,
    );
  }
}

class AthkarCatalog {
  final List<AthkarCategoryData> categories;

  const AthkarCatalog({required this.categories});

  AthkarCategoryData? byId(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    if (id == 'wudu_food') {
      return byId('wudu_taharah');
    }

    // Backward compatibility aggregation for composite categories:
    if (id == 'prayer_sunan' || id == 'prayerSunan') {
      const subCatIds = [
        'prayer_opening',
        'prayer_rukuh_sujud',
        'tashahhud_salat',
        'prayer_before_salam',
        'witr_istikharah',
      ];
      final items = <AthkarItem>[];
      for (final subId in subCatIds) {
        final sub = byId(subId);
        if (sub != null) items.addAll(sub.items);
      }
      if (items.isNotEmpty) {
        return AthkarCategoryData(
          id: 'prayer_sunan',
          title: 'سنن وأدعية الصلاة',
          subtitle: 'أدعية الاستفتاح والركوع والسجود والتشهد وقنوت الوتر',
          items: items,
        );
      }
    }

    if (id == 'mosque_adhan' || id == 'mosqueAdhan') {
      const subCatIds = ['adhan_iqamah', 'mosque_etiquette'];
      final items = <AthkarItem>[];
      for (final subId in subCatIds) {
        final sub = byId(subId);
        if (sub != null) items.addAll(sub.items);
      }
      if (items.isNotEmpty) {
        return AthkarCategoryData(
          id: 'mosque_adhan',
          title: 'أذكار المسجد والأذان',
          subtitle: 'إجابة المؤذن والدعاء والمشي إلى المسجد ودخوله',
          items: items,
        );
      }
    }

    if (id == 'sickness_funerals' || id == 'sicknessFunerals') {
      const subCatIds = ['sickness_ruqyah', 'funerals_graves'];
      final items = <AthkarItem>[];
      for (final subId in subCatIds) {
        final sub = byId(subId);
        if (sub != null) items.addAll(sub.items);
      }
      if (items.isNotEmpty) {
        return AthkarCategoryData(
          id: 'sickness_funerals',
          title: 'أدعية المرض والجنائز',
          subtitle: 'عيادة المريض، الرقية النبوية، وصلاة الجنائز والقبور',
          items: items,
        );
      }
    }

    if (id == 'fasting_hajj' || id == 'fastingHajj') {
      const subCatIds = ['fasting_adhkar', 'hajj_umrah'];
      final items = <AthkarItem>[];
      for (final subId in subCatIds) {
        final sub = byId(subId);
        if (sub != null) items.addAll(sub.items);
      }
      if (items.isNotEmpty) {
        return AthkarCategoryData(
          id: 'fasting_hajj',
          title: 'أذكار الصيام والحج',
          subtitle: 'سنن الصيام والإفطار وليلة القدر ومناسك الحج والعمرة',
          items: items,
        );
      }
    }

    if (id == 'distress') {
      const subCatIds = ['distress_relief', 'protection_ruqyah'];
      final items = <AthkarItem>[];
      for (final subId in subCatIds) {
        final sub = byId(subId);
        if (sub != null) items.addAll(sub.items);
      }
      if (items.isNotEmpty) {
        return AthkarCategoryData(
          id: 'distress',
          title: 'أذكار الكرب والهم والحفظ',
          subtitle: 'تفريج الهموم والغموم والاستعاذة من الشرور والعين',
          items: items,
        );
      }
    }

    if (id == 'duas') {
      const subCatIds = ['quranic_duas', 'prophetic_duas'];
      final items = <AthkarItem>[];
      for (final subId in subCatIds) {
        final sub = byId(subId);
        if (sub != null) items.addAll(sub.items);
      }
      if (items.isNotEmpty) {
        return AthkarCategoryData(
          id: 'duas',
          title: 'الأدعية المأثورة',
          subtitle: 'أدعية القرآن الكريم وجوامع الدعاء النبوي الشريف',
          items: items,
        );
      }
    }

    return null;
  }
}

class DailyDhikrPayload {
  final AthkarItem item;
  final String categoryLabel;
  final AdhkarCategory category;
  final int categoryTotal;
  final IconData categoryIcon;

  const DailyDhikrPayload({
    required this.item,
    required this.categoryLabel,
    required this.category,
    required this.categoryTotal,
    required this.categoryIcon,
  });
}

