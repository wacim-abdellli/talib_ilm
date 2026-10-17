/// Scholarly audio recitations catalog linking syllabus and classical mutun
/// to verified high-quality streaming audio sources across prominent reciters.
class MutunReciter {
  final String id;
  final String name;
  final String description;

  const MutunReciter({
    required this.id,
    required this.name,
    required this.description,
  });
}

class MutunReciterDefaults {
  static const sini = MutunReciter(
    id: 'sini',
    name: 'د. عبد العزيز الصيني',
    description: 'قراءة محققة متقنة وفق منهج متون طالب العلم بالمسجد النبوي',
  );

  static const fahad = MutunReciter(
    id: 'fahad',
    name: 'الشيخ طه الفهد',
    description: 'قراءة المنظومات العلمية بضبط عروضي وشجي متقن',
  );

  static const faqeeh = MutunReciter(
    id: 'faqeeh',
    name: 'القارئ عبد الغني الفقيه',
    description: 'تسجيل صوتي معتمد لنخبة من المتون العلمية',
  );

  static const shaydzmi = MutunReciter(
    id: 'shaydzmi',
    name: 'القارئ أبو أحمد الشيظمي',
    description: 'قراءة صوتية مسجلة وواضحة للمتون والمنظومات',
  );

  static const afasy = MutunReciter(
    id: 'afasy',
    name: 'الشيخ مشاري راشد العفاسي',
    description: 'قراءة متون التجويد والمنظومات الكبرى',
  );

  static const bahour = MutunReciter(
    id: 'bahour',
    name: 'القارئ عبد الرحمن بحور',
    description: 'تسجيل صوتي معتمد في منصة حفاظ المتون',
  );
}

class MatnAudioSource {
  final MutunReciter reciter;
  final String audioUrl;
  final String? fallbackUrl;
  final int totalParagraphs;

  /// Paragraph start times in milliseconds from the beginning of the audio.
  /// Index 0 = paragraph 1 start, index 1 = paragraph 2 start, etc.
  /// If null, falls back to proportional estimation.
  final List<int>? paragraphTimestamps;

  const MatnAudioSource({
    required this.reciter,
    required this.audioUrl,
    this.fallbackUrl,
    this.totalParagraphs = 1,
    this.paragraphTimestamps,
  });
}

class MutunAudioEntry {
  final String bookId;
  final String title;
  final List<MatnAudioSource> sources;

  const MutunAudioEntry({
    required this.bookId,
    required this.title,
    required this.sources,
  });

  MatnAudioSource? getSource([String? reciterId]) {
    if (sources.isEmpty) return null;
    if (reciterId == null) return sources.first;
    return sources.firstWhere(
      (s) => s.reciter.id == reciterId,
      orElse: () => sources.first,
    );
  }

  // Backwards compatibility properties
  String get siniAudioFileName => sources.first.audioUrl;
  String? get archiveFileName => null;
  String? get directUrl => sources.first.audioUrl;
  String? get fallbackUrl => sources.first.fallbackUrl;
  int get totalParagraphs => sources.first.totalParagraphs;
}

class MutunAudioCatalog {
  const MutunAudioCatalog._();

  static const String archiveBaseUrl =
      'https://archive.org/download/Mottoon_Talib_Elm';
  static const String siniBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini';

  static const Map<String, MutunAudioEntry> _entries = {
    // ── المستوى التمهيدي ──────────────────────────────────────
    'bk_adhkar_adab': MutunAudioEntry(
      bookId: 'bk_adhkar_adab',
      title: 'الآداب والأذكار',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0101AlAthkaar_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/03.mp3',
          totalParagraphs: 24,
          paragraphTimestamps: [
            0, // 1: فضل طلب العلم 1
            10000, // 2: فضل طلب العلم 2
            18000, // 3: فضل طلب العلم 3
            28000, // 4: فضل تعلم القرآن 1
            35000, // 5: فضل تعلم القرآن 2
            48000, // 6: فضل تعلم القرآن 3
            57000, // 7: فضل الذكر 1
            65000, // 8: فضل الذكر 2
            80000, // 9: فضل الذكر 3
            92000, // 10: فضل مجالس الذكر 1
            110000, // 11: فضل مجالس الذكر 2
            122000, // 12: فضل مجالس الذكر 3
            138000, // 13: أذكار الصباح والمساء - آية الكرسي
            168000, // 14: المعوذات
            185000, // 15: أصبحنا وأصبح الملك لله
            212000, // 16: سيد الاستغفار
            236000, // 17: أذكار النوم والاستيقاظ 1
            256000, // 18: أذكار النوم والاستيقاظ 2
            265000, // 19: أذكار الخروج من المنزل
            280000, // 20: أذكار الدخول
            290000, // 21: آداب الطعام والشراب 1
            300000, // 22: آداب الطعام والشراب 2
            312000, // 23: آداب السلام 1
            326000, // 24: آداب قضاء الحاجة 2
          ],
        ),
      ],
    ),

    // ── المستوى الأول ─────────────────────────────────────────
    'bk_nawaqid_islam': MutunAudioEntry(
      bookId: 'bk_nawaqid_islam',
      title: 'نواقض الإسلام',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0203NawaaqidAlIslaam_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/04.mp3',
          totalParagraphs: 10,
          paragraphTimestamps: [
            0,
            28000,
            46000,
            60000,
            82000,
            98000,
            118000,
            134000,
            148000,
            160000,
          ],
        ),
      ],
    ),
    'bk_qawaid_arba': MutunAudioEntry(
      bookId: 'bk_qawaid_arba',
      title: 'القواعد الأربع',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0202AlQawaidAlArba_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/05.mp3',
          totalParagraphs: 8,
          paragraphTimestamps: [
            0,
            22000,
            40000,
            58000,
            75000,
            90000,
            106000,
            116000,
          ],
        ),
      ],
    ),
    'bk_usul_thalatha': MutunAudioEntry(
      bookId: 'bk_usul_thalatha',
      title: 'ثلاثة الأصول وأدلتها',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0201AlUsulAtThalaath_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/06.mp3',
          totalParagraphs: 28,
          paragraphTimestamps: [
            0, // 1: المسائل الأربع
            30000, // 2: كلام الشافعي والبخاري
            52000, // 3: المسائل الثلاث - الأولى
            78000, // 4: الثانية - عدم الشرك
            92000, // 5: الثالثة - الولاء والبراء
            112000, // 6: الحنيفية والتوحيد
            150000, // 7: الأصل الأول - معرفة الرب
            180000, // 8: الآيات والمخلوقات
            207000, // 9: الرب هو المعبود
            239000, // 10: أنواع العبادة
            271000, // 11: دليل الدعاء والخوف
            289000, // 12: دليل الرجاء والتوكل
            306000, // 13: دليل الرغبة والرهبة والخشية
            324000, // 14: دليل الاستعانة والاستعاذة
            340000, // 15: دليل الذبح والنذر
            362000, // 16: الأصل الثاني - مراتب الدين
            381000, // 17: أركان الإسلام ودليل الشهادة
            403000, // 18: معنى لا إله إلا الله وتفسيرها
            430000, // 19: دليل شهادة أن محمدا رسول الله
            455000, // 20: دليل الصلاة والزكاة والصيام والحج
            488000, // 21: المرتبة الثانية - الإيمان وأركانه
            520000, // 22: المرتبة الثالثة - الإحسان وأدلته
            554000, // 23: الأصل الثالث - معرفة النبي ﷺ
            588000, // 24: النذارة عن الشرك والهجرة
            618000, // 25: الهجرة وحكمها وأدلتها
            645000, // 26: شرائع الإسلام في المدينة والوفاة
            676000, // 27: عموم الرسالة ودلائل الموت
            705000, // 28: البعث والجزاء ورؤوس الطواغيت
          ],
        ),
      ],
    ),
    'bk_arbaeen_nawawi': MutunAudioEntry(
      bookId: 'bk_arbaeen_nawawi',
      title: 'الأربعون النووية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0204AlArbaunAnNawawiyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/07.mp3',
          totalParagraphs: 42,
        ),
      ],
    ),

    // ── المستوى الثاني ─────────────────────────────────────────
    'bk_tuhfat_atfal': MutunAudioEntry(
      bookId: 'bk_tuhfat_atfal',
      title: 'تحفة الأطفال في تجويد القرآن',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0301ThufatUlAtfaal_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/08.mp3',
          totalParagraphs: 61,
        ),
      ],
    ),
    'bk_shuroot_salah': MutunAudioEntry(
      bookId: 'bk_shuroot_salah',
      title: 'شروط الصلاة وأركانها وواجباتها',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0302ShurutAsSalaah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/09.mp3',
          totalParagraphs: 14,
          paragraphTimestamps: [
            0,
            12000,
            22000,
            31000,
            40000,
            52000,
            70000,
            88000,
            108000,
            124000,
            138000,
            146000,
            165000,
            180000,
          ],
        ),
      ],
    ),
    'bk_shurut_salah': MutunAudioEntry(
      bookId: 'bk_shurut_salah',
      title: 'شروط الصلاة وأركانها وواجباتها',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0302ShurutAsSalaah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/09.mp3',
          totalParagraphs: 14,
          paragraphTimestamps: [
            0,
            12000,
            22000,
            31000,
            40000,
            52000,
            70000,
            88000,
            108000,
            124000,
            138000,
            146000,
            165000,
            180000,
          ],
        ),
      ],
    ),
    'bk_kitab_tawheed': MutunAudioEntry(
      bookId: 'bk_kitab_tawheed',
      title: 'كتاب التوحيد',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0303KitaabAtTawheed_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/10.mp3',
          totalParagraphs: 67,
        ),
      ],
    ),
    'bk_kashf_shubuhat': MutunAudioEntry(
      bookId: 'bk_kashf_shubuhat',
      title: 'كشف الشبهات',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.faqeeh,
          audioUrl:
              'https://files.a-alqasim.com/audio/Mutoon/AbdulGhaniSaadiqAlFaqeeh/0804Kashf_AbdulGhaniSaadiqAlFaqeeh.mp3',
          totalParagraphs: 20,
        ),
      ],
    ),

    // ── المستوى الثالث ─────────────────────────────────────────
    'bk_manzumah_baiquoni': MutunAudioEntry(
      bookId: 'bk_manzumah_baiquoni',
      title: 'المنظومة البيقونية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0401AlBayqooni_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/11.mp3',
          totalParagraphs: 34,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_elm_al-Hadeeth/albaykoneya.mp3',
          fallbackUrl: '$archiveBaseUrl/11.mp3',
          totalParagraphs: 34,
        ),
      ],
    ),
    'bk_manzooma_bayquniyya': MutunAudioEntry(
      bookId: 'bk_manzooma_bayquniyya',
      title: 'المنظومة البيقونية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0401AlBayqooni_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/11.mp3',
          totalParagraphs: 34,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_elm_al-Hadeeth/albaykoneya.mp3',
          fallbackUrl: '$archiveBaseUrl/11.mp3',
          totalParagraphs: 34,
        ),
      ],
    ),
    'bk_manzumah_albiri': MutunAudioEntry(
      bookId: 'bk_manzumah_albiri',
      title: 'منظومة أبي إسحاق الإلبيري',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0402AlIlbiri_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/12.mp3',
          totalParagraphs: 25,
        ),
      ],
    ),
    'bk_ilbiri': MutunAudioEntry(
      bookId: 'bk_ilbiri',
      title: 'منظومة أبي إسحاق الإلبيري',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0402AlIlbiri_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/12.mp3',
          totalParagraphs: 25,
        ),
      ],
    ),
    'bk_ajrumiyyah': MutunAudioEntry(
      bookId: 'bk_ajrumiyyah',
      title: 'الآجرومية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0403AlAajurrumiyyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/13.mp3',
          totalParagraphs: 30,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_al-Arabiya/ajromyah.mp3',
          totalParagraphs: 30,
        ),
      ],
    ),
    'bk_ajrumiyya': MutunAudioEntry(
      bookId: 'bk_ajrumiyya',
      title: 'الآجرومية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0403AlAajurrumiyyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/13.mp3',
          totalParagraphs: 30,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_al-Arabiya/ajromyah.mp3',
          totalParagraphs: 30,
        ),
      ],
    ),
    'bk_wasitiyyah': MutunAudioEntry(
      bookId: 'bk_wasitiyyah',
      title: 'العقيدة الواسطية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/14.mp3',
          totalParagraphs: 35,
        ),
      ],
    ),
    'bk_wasitiyya': MutunAudioEntry(
      bookId: 'bk_wasitiyya',
      title: 'العقيدة الواسطية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/14.mp3',
          totalParagraphs: 35,
        ),
      ],
    ),

    // ── المستوى الرابع ─────────────────────────────────────────
    'bk_waraqat': MutunAudioEntry(
      bookId: 'bk_waraqat',
      title: 'الورقات في أصول الفقه',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0501AlWaraqat_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/15.mp3',
          totalParagraphs: 22,
        ),
      ],
    ),
    'bk_unwan_al_hukm': MutunAudioEntry(
      bookId: 'bk_unwan_al_hukm',
      title: 'عنوان الحكم',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0502UnwanAlHikm_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/16.mp3',
          totalParagraphs: 20,
        ),
      ],
    ),
    'bk_unwan_alhikam': MutunAudioEntry(
      bookId: 'bk_unwan_alhikam',
      title: 'عنوان الحكم',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0502UnwanAlHikm_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/16.mp3',
          totalParagraphs: 20,
        ),
      ],
    ),
    'bk_rahibiyyah': MutunAudioEntry(
      bookId: 'bk_rahibiyyah',
      title: 'الرحبية في علم الفرائض',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0503ArRahbiyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/17.mp3',
          totalParagraphs: 30,
        ),
      ],
    ),
    'bk_rahbiyya': MutunAudioEntry(
      bookId: 'bk_rahbiyya',
      title: 'الرحبية في علم الفرائض',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0503ArRahbiyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/17.mp3',
          totalParagraphs: 30,
        ),
      ],
    ),
    'bk_aqidah_tahawiyyah': MutunAudioEntry(
      bookId: 'bk_aqidah_tahawiyyah',
      title: 'العقيدة الطحاوية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0504AtTahawiyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/18.mp3',
          totalParagraphs: 50,
        ),
      ],
    ),
    'bk_tahawiyya': MutunAudioEntry(
      bookId: 'bk_tahawiyya',
      title: 'العقيدة الطحاوية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0504AtTahawiyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/18.mp3',
          totalParagraphs: 50,
        ),
      ],
    ),

    // ── المطولات المتقدمة والمنظومات الكبرى ────────────────────
    'bk_bulugh_maram': MutunAudioEntry(
      bookId: 'bk_bulugh_maram',
      title: 'بلوغ المرام من أدلة الأحكام',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl:
              'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0601Buloogh_AbdulAzizAsSini.mp3',
          totalParagraphs: 120,
        ),
      ],
    ),
    'bk_zad_mustaqni': MutunAudioEntry(
      bookId: 'bk_zad_mustaqni',
      title: 'زاد المستقنع في اختصار المقنع',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl:
              'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0602Zaad/0602Zaad_01_KitaabAtTahaarah_AbdulAzizAsSini.mp3',
          totalParagraphs: 140,
        ),
      ],
    ),
    'bk_jawhar_maknoon': MutunAudioEntry(
      bookId: 'bk_jawhar_maknoon',
      title: 'الجوهر المكنون في صدف الثلاثة الفنون',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_al-Arabiya/aljawhar.mp3',
          totalParagraphs: 50,
        ),
      ],
    ),
    'bk_nokhbat_al_fikar': MutunAudioEntry(
      bookId: 'bk_nokhbat_al_fikar',
      title: 'نظم نخبة الفكر في مصطلح أهل الأثر',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_elm_al-Hadeeth/nokbatulfeekar.mp3',
          totalParagraphs: 35,
        ),
      ],
    ),
    'bk_alfiyyah_ibn_malik': MutunAudioEntry(
      bookId: 'bk_alfiyyah_ibn_malik',
      title: 'ألفية ابن مالك في النحو والتصريف',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_al-Arabiya/ebnmalek.mp3',
          totalParagraphs: 100,
        ),
      ],
    ),
    'bk_shatibiyyah': MutunAudioEntry(
      bookId: 'bk_shatibiyyah',
      title: 'حرز الأماني ووجه التهاني (الشاطبية)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_kiraat_mujtami3a/shatbeya.mp3',
          totalParagraphs: 110,
        ),
      ],
    ),
    'bk_umdat_ahkam': MutunAudioEntry(
      bookId: 'bk_umdat_ahkam',
      title: 'عمدة الأحكام من كلام خير الأنام',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl:
              'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0802AlUmdatuFilAhkaam_AbdulAzizAsSini.mp3',
          totalParagraphs: 85,
        ),
      ],
    ),
    'bk_qawaid_fiqhiyya': MutunAudioEntry(
      bookId: 'bk_qawaid_fiqhiyya',
      title: 'منظومة القواعد الفقهية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl:
              'https://archive.org/download/shaydzmi111/Mandhoumat_al-qawid_al-fiqhiyah_As-saady.mp3',
          totalParagraphs: 18,
        ),
      ],
    ),
    'bk_lamiyyat_al_afal': MutunAudioEntry(
      bookId: 'bk_lamiyyat_al_afal',
      title: 'لامية الأفعال لابن مالك',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_al-Arabiya/malk.mp3',
          totalParagraphs: 20,
        ),
      ],
    ),
  };

  /// Check whether authentic audio recitation is available for this matn ID.
  static bool hasAudio(String bookId) => _entries.containsKey(bookId);

  /// Get audio recitation entry.
  static MutunAudioEntry? getEntry(String bookId) => _entries[bookId];

  /// Get list of available reciters for a given book ID.
  static List<MutunReciter> getRecitersForBook(String? bookId) {
    if (bookId == null) {
      return [
        MutunReciterDefaults.sini,
        MutunReciterDefaults.fahad,
        MutunReciterDefaults.faqeeh,
        MutunReciterDefaults.shaydzmi,
      ];
    }
    final entry = _entries[bookId];
    if (entry == null || entry.sources.isEmpty) {
      return [MutunReciterDefaults.sini];
    }
    return entry.sources.map((s) => s.reciter).toList();
  }

  /// Get primary streaming audio URL for the specified matn and reciter.
  static String? getAudioUrl(String bookId, {String? reciterId}) {
    final entry = _entries[bookId];
    if (entry == null) return null;
    return entry.getSource(reciterId)?.audioUrl;
  }

  /// Get backup fallback URL in case of network or mirror failure.
  static String? getFallbackAudioUrl(String bookId, {String? reciterId}) {
    final entry = _entries[bookId];
    if (entry == null) return null;
    return entry.getSource(reciterId)?.fallbackUrl;
  }

  /// Get total paragraphs / lines for reader synchronization.
  static int getTotalParagraphs(String bookId, {String? reciterId}) {
    final entry = _entries[bookId];
    if (entry == null) return 1;
    return entry.getSource(reciterId)?.totalParagraphs ?? 1;
  }

  /// Get precise paragraph timestamps in milliseconds if available.
  static List<int>? getParagraphTimestamps(String bookId, {String? reciterId}) {
    final entry = _entries[bookId];
    if (entry == null) return null;
    return entry.getSource(reciterId)?.paragraphTimestamps;
  }
}
