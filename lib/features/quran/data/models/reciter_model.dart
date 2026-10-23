// Reciter and QuranEdition Models

class Reciter {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String identifier;

  const Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.identifier,
  });

  static const List<Reciter> availableReciters = [
    Reciter(
      id: '1',
      nameArabic: 'مشاري العفاسي',
      nameEnglish: 'Mishary Alafasy',
      identifier: 'ar.alafasy',
    ),
    Reciter(
      id: '2',
      nameArabic: 'محمد المنشاوي',
      nameEnglish: 'Mohamed El-Minshawi',
      identifier: 'ar.minshawi',
    ),
    Reciter(
      id: '3',
      nameArabic: 'محمود الحصري',
      nameEnglish: 'Mahmoud Al-Husary',
      identifier: 'ar.husary',
    ),
    Reciter(
      id: '4',
      nameArabic: 'عبد الباسط',
      nameEnglish: 'Abdul Basit',
      identifier: 'ar.abdulbasit',
    ),
    Reciter(
      id: '5',
      nameArabic: 'ماهر المعيقلي',
      nameEnglish: 'Maher Al Muaiqly',
      identifier: 'ar.mahermuaiqly',
    ),
    Reciter(
      id: '6',
      nameArabic: 'عبد الرحمن السديس',
      nameEnglish: 'Abdul Rahman Al-Sudais',
      identifier: 'ar.abdurrahmaansudais',
    ),
  ];
}

class QuranEdition {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String identifier; // API identifier
  final String format; // text or audio
  final String type; // translation, quran, etc
  final String? fontName; // Required font for this edition

  const QuranEdition({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.identifier,
    required this.format,
    required this.type,
    this.fontName,
  });

  static const List<QuranEdition> availableEditions = [
    QuranEdition(
      id: 'hafs',
      nameArabic: 'حفص عن عاصم',
      nameEnglish: 'Hafs',
      identifier: 'quran-uthmani',
      format: 'text',
      type: 'quran',
      fontName: 'ScheherazadeNew', // Standard font
    ),
    QuranEdition(
      id: 'warsh',
      nameArabic: 'ورش عن نافع',
      nameEnglish: 'Warsh',
      identifier: 'quran-warsh',
      format: 'text',
      type: 'quran',
      fontName: 'Warsh', // Needs custom font bundle
    ),
    QuranEdition(
      id: 'tajweed',
      nameArabic: 'مصحف التجويد',
      nameEnglish: 'Tajweed',
      identifier: 'quran-tajweed',
      format: 'text',
      type: 'quran',
      fontName: 'ScheherazadeNew', // Usually works with standard but colors matter
    ),
  ];
}
