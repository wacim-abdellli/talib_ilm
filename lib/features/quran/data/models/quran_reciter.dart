class QuranReciter {
  final String id;
  final String name;
  final String subfolder;
  final String? surahBaseUrl;

  const QuranReciter({
    required this.id,
    required this.name,
    this.subfolder = '',
    this.surahBaseUrl,
  });

  bool get isSurahBased => surahBaseUrl != null && surahBaseUrl!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranReciter && other.id == id);

  @override
  int get hashCode => id.hashCode;

  static const List<QuranReciter> defaultReciters = [
    QuranReciter(
      id: 'alafasy',
      name: 'مشاري راشد العفاسي',
      subfolder: 'Alafasy_128kbps',
    ),
    QuranReciter(
      id: 'luhaidan',
      name: 'محمد اللحيدان',
      surahBaseUrl: 'https://cdn.mp3quran.net/audio/muhammad-luhaidan/r1/',
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
      id: 'sudais',
      name: 'عبد الرحمن السديس',
      subfolder: 'Abdurrahmaan_As-Sudais_192kbps',
    ),
    QuranReciter(
      id: 'shuraym',
      name: 'سعود الشريم',
      subfolder: 'Saood_ash-Shuraym_128kbps',
    ),
    QuranReciter(
      id: 'ajamy',
      name: 'أحمد بن علي العجمي',
      subfolder: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
    ),
    QuranReciter(
      id: 'abbad',
      name: 'فارس عباد',
      subfolder: 'Fares_Abbad_64kbps',
    ),
    QuranReciter(
      id: 'ali_jaber',
      name: 'علي جابر',
      subfolder: 'Ali_Jaber_64kbps',
    ),
    QuranReciter(
      id: 'juhaynee',
      name: 'عبد الله عواد الجهني',
      subfolder: 'Abdullaah_3awwaad_Al-Juhaynee_128kbps',
    ),
    QuranReciter(
      id: 'ayyoub',
      name: 'محمد أيوب',
      subfolder: 'Muhammad_Ayyoub_128kbps',
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
      id: 'hudhaify',
      name: 'علي بن عبد الرحمن الحذيفي',
      subfolder: 'Hudhaify_128kbps',
    ),
    QuranReciter(
      id: 'budair',
      name: 'صلاح البدير',
      subfolder: 'Salah_Al_Budair_128kbps',
    ),
    QuranReciter(
      id: 'qasim',
      name: 'عبد المحسن القاسم',
      subfolder: 'Muhsin_Al_Qasim_192kbps',
    ),
    QuranReciter(
      id: 'rifai',
      name: 'هاني الرفاعي',
      subfolder: 'Hani_Rifai_192kbps',
    ),
    QuranReciter(
      id: 'jibreel',
      name: 'محمد جبريل',
      subfolder: 'Muhammad_Jibreel_128kbps',
    ),
    QuranReciter(
      id: 'basfar',
      name: 'عبد الله بصفر',
      subfolder: 'Abdullah_Basfar_192kbps',
    ),
    QuranReciter(
      id: 'matroud',
      name: 'عبد الله مطرود',
      subfolder: 'Abdullah_Matroud_128kbps',
    ),
    QuranReciter(
      id: 'tunaiji',
      name: 'خليفة الطنيجي',
      subfolder: 'khalefa_al_tunaiji_64kbps',
    ),
    QuranReciter(
      id: 'minshawi',
      name: 'محمد صديق المنشاوي',
      subfolder: 'Minshawy_Murattal_128kbps',
    ),
    QuranReciter(
      id: 'minshawi_mujawwad',
      name: 'محمد صديق المنشاوي (المجود)',
      subfolder: 'Minshawy_Mujawwad_192kbps',
    ),
    QuranReciter(
      id: 'husary',
      name: 'محمود خليل الحصري',
      subfolder: 'Husary_128kbps',
    ),
    QuranReciter(
      id: 'husary_mujawwad',
      name: 'محمود خليل الحصري (المجود)',
      subfolder: 'Husary_128kbps_Mujawwad',
    ),
    QuranReciter(
      id: 'husary_muallim',
      name: 'محمود خليل الحصري (المعلم)',
      subfolder: 'Husary_Muallim_128kbps',
    ),
    QuranReciter(
      id: 'abdulbasit',
      name: 'عبد الباسط عبد الصمد',
      subfolder: 'AbdulSamad_64kbps_QuranExplorer.Com',
    ),
    QuranReciter(
      id: 'abdulbasit_mujawwad',
      name: 'عبد الباسط عبد الصمد (المجود)',
      subfolder: 'Abdul_Basit_Mujawwad_128kbps',
    ),
    QuranReciter(
      id: 'tablaway',
      name: 'محمد محمود الطبلاوي',
      subfolder: 'Mohammad_al_Tablaway_128kbps',
    ),
    QuranReciter(
      id: 'banna',
      name: 'محمود علي البنا',
      subfolder: 'mahmoud_ali_al_banna_32kbps',
    ),
    QuranReciter(
      id: 'mustafa_ismail',
      name: 'مصطفى إسماعيل',
      subfolder: 'Mustafa_Ismail_48kbps',
    ),
  ];
}
