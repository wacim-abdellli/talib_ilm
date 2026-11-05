// Reciter model.

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
