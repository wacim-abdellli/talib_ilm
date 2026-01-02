enum AdhkarCategory {
  morning,
  evening,
  afterPrayer,
  beforePrayer,
  general,
}

extension AdhkarCategoryLabel on AdhkarCategory {
  String get label {
    switch (this) {
      case AdhkarCategory.morning:
        return 'أذكار الصباح';
      case AdhkarCategory.evening:
        return 'أذكار المساء';
      case AdhkarCategory.afterPrayer:
        return 'أذكار بعد الصلاة';
      case AdhkarCategory.beforePrayer:
        return 'أذكار قبل الصلاة';
      case AdhkarCategory.general:
        return 'أذكار متنوعة';
    }
  }

  String get id => name;
}

class DhikrItem {
  final String text;
  final String? reference;
  final int repeat;

  const DhikrItem({
    required this.text,
    this.reference,
    this.repeat = 1,
  });
}
