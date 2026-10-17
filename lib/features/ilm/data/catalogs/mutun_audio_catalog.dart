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

  const MatnAudioSource({
    required this.reciter,
    required this.audioUrl,
    this.fallbackUrl,
    this.totalParagraphs = 1,
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
}
