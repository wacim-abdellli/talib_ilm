import '../../../app/constants/app_strings.dart';

enum AdhkarCategory {
  morning,
  evening,
  afterPrayer,
  beforePrayer,
  general,
  tasbeeh,
  istighfar,
  duas,
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
    final id = json['id']?.toString() ??
        (orderValue != null ? 'order_$orderValue' : '');
    return AthkarItem(
      id: id,
      arabic: json['arabic']?.toString() ??
          json['content']?.toString() ??
          '',
      transliteration: json['transliteration']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      target: _asInt(json['target']) ??
          _asInt(json['count']) ??
          0,
      countDescription: json['count_description']?.toString() ??
          json['countDescription']?.toString() ??
          '',
      fadl: json['fadl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      audio: json['audio']?.toString() ?? '',
      hadithText: json['hadith_text']?.toString() ??
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
    return null;
  }
}
