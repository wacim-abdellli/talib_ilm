class QuranReciter {
  final String id;
  final String name;
  final String subfolder;

  const QuranReciter({
    required this.id,
    required this.name,
    required this.subfolder,
  });

  static const List<QuranReciter> defaultReciters = [
    QuranReciter(
      id: 'alafasy',
      name: 'مشاري راشد العفاسي',
      subfolder: 'Alafasy_128kbps',
    ),
    QuranReciter(
      id: 'qatami',
      name: 'ناصر القطامي',
      subfolder: 'Nasser_Alqatami_128kbps',
    ),
    QuranReciter(
      id: 'dossari',
      name: 'ياسر الدوسري',
      subfolder: 'Yasser_Ad-Dussary_128kbps',
    ),
    QuranReciter(
      id: 'muaiqly',
      name: 'ماهر المعيقلي',
      subfolder: 'MaherAlMuaiqly128kbps',
    ),
    QuranReciter(
      id: 'husary',
      name: 'محمود خليل الحصري',
      subfolder: 'Husary_128kbps',
    ),
    QuranReciter(
      id: 'minshawi',
      name: 'محمد صديق المنشاوي',
      subfolder: 'Minshawy_Murattal_128kbps',
    ),
    QuranReciter(
      id: 'abdulbasit',
      name: 'عبد الباسط عبد الصمد',
      subfolder: 'AbdulSamad_64kbps_QuranExplorer.Com',
    ),
    QuranReciter(
      id: 'ghamadi',
      name: 'سعد الغامدي',
      subfolder: 'Ghamadi_40kbps',
    ),
    QuranReciter(
      id: 'shatri',
      name: 'أبو بكر الشاطري',
      subfolder: 'Abu_Bakr_Ash-Shaatree_128kbps',
    ),
    QuranReciter(
      id: 'shuraym',
      name: 'سعود الشريم',
      subfolder: 'Saood_ash-Shuraym_128kbps',
    ),
  ];
}
