import '../../models/book_audio_models.dart';
import 'haliba_audiobooks_catalog.dart';
import 'ilm_audio_reciters.dart';
import 'turath_raqaiq_audio_entries.dart';

/// Audio catalog for Hadith / Sunnah books and Tafsir classics (< 580 lines).
class TurathSunnahTafsirAudioEntries {
  const TurathSunnahTafsirAudioEntries._();

  static final Map<String, MutunAudioEntry> entries = {
    // ── الصحاح والسنن ──────────────────────────────────────────

    /// صحيح مسلم
    'shamela_1727': MutunAudioEntry(
      bookId: 'shamela_1727',
      title: 'صحيح مسلم بن الحجاج القشيري',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunnahMasmuah,
          audioUrl: 'https://archive.org/download/ar_Moslem_Reading_16/ar_Moslem_Reading_01.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/ar_Moslem_Reading_16',
            count: 55,
            titlePrefix: 'كتاب صحيح مسلم',
            filePrefix: 'ar_Moslem_Reading_',
            padWidth: 2,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl: 'https://archive.org/download/islami-458_202507/01.mp3',
          edition: BookAudioEdition.mukhtasar,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/islami-458_202507',
            count: 50,
            titlePrefix: 'مجلس مختصر مسلم',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// سنن أبي داود
    'shamela_1726': MutunAudioEntry(
      bookId: 'shamela_1726',
      title: 'سنن أبي داود',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunnahMasmuah,
          audioUrl: 'https://archive.org/download/0002ArAboDawoodAudiobook02_201406/0001-ar_Abo_Dawood_audiobook_01.mp3',
          chapters: BookAudioChapter.dualNumbered(
            baseUrl:
                'https://archive.org/download/0002ArAboDawoodAudiobook02_201406',
            count: 42,
            titlePrefix: 'كتاب سنن أبي داود',
            middleToken: 'ar_Abo_Dawood_audiobook',
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/217.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 11,
            titlePrefix: 'جزء سنن أبي داود',
            startNumber: 217,
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// جامع الترمذي
    'shamela_7895': MutunAudioEntry(
      bookId: 'shamela_7895',
      title: 'الجامع الكبير (سنن الترمذي)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunnahMasmuah,
          audioUrl: 'https://archive.org/download/0063ArSonanTermetheAB63/0001-ar_Sonan_Termethe_A_B_01.mp3',
          chapters: BookAudioChapter.dualNumbered(
            baseUrl: 'https://archive.org/download/0063ArSonanTermetheAB63',
            count: 63,
            titlePrefix: 'كتاب الترمذي',
            middleToken: 'ar_Sonan_Termethe_A_B',
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/095.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 8,
            titlePrefix: 'جزء سنن الترمذي',
            startNumber: 95,
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// سنن النسائي
    'shamela_829': MutunAudioEntry(
      bookId: 'shamela_829',
      title: 'السنن الصغرى (سنن النسائي)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunnahMasmuah,
          audioUrl: 'https://archive.org/download/0011ArSonanNasa2eeAB11/0001-ar_Sonan_Nasa2ee_A_B_01.mp3',
          chapters: BookAudioChapter.dualNumbered(
            baseUrl: 'https://archive.org/download/0011ArSonanNasa2eeAB11',
            count: 50,
            titlePrefix: 'كتاب سنن النسائي',
            middleToken: 'ar_Sonan_Nasa2ee_A_B',
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/208.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 9,
            titlePrefix: 'جزء سنن النسائي',
            startNumber: 208,
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// سنن ابن ماجه
    'shamela_1198': MutunAudioEntry(
      bookId: 'shamela_1198',
      title: 'سنن ابن ماجه',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunnahMasmuah,
          audioUrl: 'https://archive.org/download/0006ArSonanIbnMajahAB06/0001-ar_Sonan_Ibn_Majah_A_B_01.mp3',
          chapters: BookAudioChapter.dualNumbered(
            baseUrl: 'https://archive.org/download/0006ArSonanIbnMajahAB06',
            count: 36,
            titlePrefix: 'كتاب سنن ابن ماجه',
            middleToken: 'ar_Sonan_Ibn_Majah_A_B',
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/086.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 9,
            titlePrefix: 'جزء سنن ابن ماجه',
            startNumber: 86,
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// موطأ الإمام مالك
    'shamela_1699': MutunAudioEntry(
      bookId: 'shamela_1699',
      title: 'موطأ الإمام مالك بن أنس',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.usaymi,
          audioUrl: 'https://archive.org/download/islami-244_20250429/001.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/islami-244_20250429',
            count: 12,
            titlePrefix: 'مجلس الموطأ',
            padWidth: 3,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.khudayr,
          audioUrl: 'https://archive.org/download/Sharh_Al-Muwatta_mp3_pdf/Muwatta_001.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Sharh_Al-Muwatta_mp3_pdf',
            count: 100,
            titlePrefix: 'شرح الموطأ مجلس',
            filePrefix: 'Muwatta_',
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// مسند الإمام أحمد
    'shamela_25794': MutunAudioEntry(
      bookId: 'shamela_25794',
      title: 'مسند الإمام أحمد بن حنبل',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.usaymi,
          audioUrl: 'https://archive.org/download/musnadahmad_201810/0001.1-66.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/musnadahmad_201810',
            items: const [
              (file: '0001.1-66.mp3', title: 'مسند أحمد: الأحاديث ١ - ٦٦'),
              (file: '0002.67-81.mp3', title: 'مسند أحمد: الأحاديث ٦٧ - ٨١'),
              (file: '0003.82-164.mp3', title: 'مسند أحمد: الأحاديث ٨٢ - ١٦٤'),
              (file: '0004.165-235.mp3', title: 'مسند أحمد: الأحاديث ١٦٥ - ٢٣٥'),
              (file: '0005.236-319.mp3', title: 'مسند أحمد: الأحاديث ٢٣٦ - ٣١٩'),
              (file: '0006.319-398.mp3', title: 'مسند أحمد: الأحاديث ٣١٩ - ٣٩٨'),
              (file: '0007.399-484.mp3', title: 'مسند أحمد: الأحاديث ٣٩٩ - ٤٨٤'),
              (file: '0008.484-561.mp3', title: 'مسند أحمد: الأحاديث ٤٨٤ - ٥٦١'),
              (file: '0009.562-656.mp3', title: 'مسند أحمد: الأحاديث ٥٦٢ - ٦٥٦'),
              (file: '0010.656-753.mp3', title: 'مسند أحمد: الأحاديث ٦٥٦ - ٧٥٣'),
            ],
          ),
        ),
      ],
    ),

    /// سنن الدارمي
    'shamela_21795': MutunAudioEntry(
      bookId: 'shamela_21795',
      title: 'سنن الدارمي (المسند الجامع)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.usaymi,
          audioUrl: 'https://archive.org/download/004_20200804_20200804/001.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/004_20200804_20200804',
            count: 9,
            titlePrefix: 'كتاب سنن الدارمي',
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// فتح الباري
    'shamela_1673': MutunAudioEntry(
      bookId: 'shamela_1673',
      title: 'فتح الباري بشرح صحيح البخاري',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.bilalMansour,
          audioUrl: 'https://archive.org/download/islami-207_202504/%D8%B3%D9%8A%D8%B1%D8%A9%20%D8%A7%D9%84%D8%A5%D9%85%D8%A7%D9%85%20%D8%A7%D9%84%D8%AD%D8%A7%D9%81%D8%B8%20%D8%A7%D8%A8%D9%86%20%D8%AD%D8%AC%D8%B1%20%D8%A7%D9%84%D8%B9%D8%B3%D9%82%D9%84%D8%A7%D9%86%D9%8A%20%20%D8%B5%D9%88%D8%AA%20%D8%A8%D9%84%D8%A7%D9%84%20%D9%85%D9%86%D8%B5%D9%88%D8%B1.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-207_202504',
            items: const [
              (file: 'سيرة الإمام الحافظ ابن حجر العسقلاني  صوت بلال منصور.mp3', title: 'سيرة الإمام الحافظ ابن حجر العسقلاني  صوت بلال منصور'),
              (file: 'كتاب فتح الباري بشرح البخاري - المجلد الأول｜تأليف. الحافظ ابن حجر｜الجزء الأول.mp3', title: 'كتاب فتح الباري بشرح البخاري - المجلد الأول｜تأليف. الحافظ ابن حجر｜الجزء الأول'),
              (file: 'كتاب فتح الباري بشرح البخاري - المجلد الثالث｜تأليف. الحافظ ابن حجر｜الجزء الأول.mp3', title: 'كتاب فتح الباري بشرح البخاري - المجلد الثالث｜تأليف. الحافظ ابن حجر｜الجزء الأول'),
              (file: 'كتاب فتح الباري بشرح البخاري - المجلد الثاني｜تأليف. الحافظ ابن حجر｜الجزء الأول.mp3', title: 'كتاب فتح الباري بشرح البخاري - المجلد الثاني｜تأليف. الحافظ ابن حجر｜الجزء الأول'),
              (file: 'كتاب فتح الباري بشرح البخاري - المجلد الرابع｜تأليف. الحافظ ابن حجر｜الجزء الأول _.mp3', title: 'كتاب فتح الباري بشرح البخاري - المجلد الرابع｜تأليف. الحافظ ابن حجر｜الجزء الأول _'),
              (file: 'كتاب فتح الباري بشرح صحيح البخاري - المجلد الخامس｜تأليف. الحافظ ابن حجر｜الجزء الأول.mp3', title: 'كتاب فتح الباري بشرح صحيح البخاري - المجلد الخامس｜تأليف. الحافظ ابن حجر｜الجزء الأول'),
              (file: 'كتاب فتح الباري بشرح صحيح البخاري - المجلد السادس｜تأليف. الحافظ ابن حجر｜الجزء الأول.mp3', title: 'كتاب فتح الباري بشرح صحيح البخاري - المجلد السادس｜تأليف. الحافظ ابن حجر｜الجزء الأول'),
              (file: 'مدخل لقراءة فتح الباري لابن حجر.mp3', title: 'مدخل لقراءة فتح الباري لابن حجر'),
            ],
          ),
        ),
      ],
    ),

    // ── علوم الحديث ────────────────────────────────────────────

    /// الباعث الحثيث
    'shamela_21571': MutunAudioEntry(
      bookId: 'shamela_21571',
      title: 'الباعث الحثيث شرح اختصار علوم الحديث',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.subayhin,
          audioUrl: 'https://archive.org/download/islami-438_202507/1.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/islami-438_202507',
            count: 8,
            titlePrefix: 'مجلس الباعث الحثيث',
            padWidth: 1,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.khudayr,
          audioUrl: 'https://archive.org/download/Olum_al-Hadith/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Olum_al-Hadith',
            count: 19,
            titlePrefix: 'درس علوم الحديث',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// الإتقان في علوم القرآن
    'shamela_11728': MutunAudioEntry(
      bookId: 'shamela_11728',
      title: 'الإتقان في علوم القرآن',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.khudayr,
          audioUrl: 'https://archive.org/download/AlItqanFiOlomAlQuran/itqan_fi_olom_quran_01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/AlItqanFiOlomAlQuran',
            count: 12,
            titlePrefix: 'مجلس الإتقان',
            filePrefix: 'itqan_fi_olom_quran_',
            padWidth: 2,
          ),
        ),
      ],
    ),

    // ── التفسير ────────────────────────────────────────────────

    /// تفسير ابن كثير
    'shamela_8473': MutunAudioEntry(
      bookId: 'shamela_8473',
      title: 'تفسير القرآن العظيم لابن كثير',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/113.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 52,
            titlePrefix: 'جزء تفسير ابن كثير',
            startNumber: 113,
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// تفسير الطبري
    'shamela_7798': MutunAudioEntry(
      bookId: 'shamela_7798',
      title: 'جامع البيان عن تأويل آي القرآن (الطبري)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl: 'https://archive.org/download/islami-41_20240506/01.%20%D8%AA%D9%81%D8%B3%D9%8A%D8%B1%20%D8%A7%D9%84%D8%B7%D8%A8%D8%B1%D9%8A%20%D8%A7%D9%84%D9%85%D8%AC%D9%84%D8%B3%201%20%28%20%D9%85%D9%82%D8%AF%D9%85%D8%A9%20%D8%A7%D9%84%D9%85%D8%A4%D9%84%D9%81%20%29%20%D9%85%D9%86%20%D8%A8%D8%AF%D8%A7%D9%8A%D8%A9%20%D8%A7%D9%84%D9%85%D8%AC%D9%84%D8%AF%20%D8%A7%D9%84%D8%A3%D9%88%D9%84%20%D8%AD%D8%AA%D9%89%20%D8%B5%D9%81%D8%AD%D8%A9%2013.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-41_20240506',
            items: const [
              (file: '01. تفسير الطبري المجلس 1 ( مقدمة المؤلف ) من بداية المجلد الأول حتى صفحة 13.mp3', title: '01. تفسير الطبري المجلس 1 ( مقدمة المؤلف ) من بداية المجلد الأول حتى صفحة 13'),
              (file: '02. تفسير الطبري المجلس 2 من صفحة 13 حتى صفحة 20.mp3', title: '02. تفسير الطبري المجلس 2 من صفحة 13 حتى صفحة 20'),
              (file: '03. تفسير الطبري المجلس 3 من صفحة 20 حتى صفحة 67.mp3', title: '03. تفسير الطبري المجلس 3 من صفحة 20 حتى صفحة 67'),
              (file: '04. تفسير الطبري المجلس 4 من صفحة 67 حتى صفحة 84.mp3', title: '04. تفسير الطبري المجلس 4 من صفحة 67 حتى صفحة 84'),
              (file: '05. تفسير الطبري المجلس 5 من صفحة 84 حتى صفحة 108.mp3', title: '05. تفسير الطبري المجلس 5 من صفحة 84 حتى صفحة 108'),
              (file: '06. تفسير الطبري المجلس 6 من صفحة 109 حتى صفحة 134.mp3', title: '06. تفسير الطبري المجلس 6 من صفحة 109 حتى صفحة 134'),
              (file: '07. تفسير الطبري المجلس  7 سورة الفاتحة حتى قوله وإياك نستعين من صفحة 135 حتى صفحة 165.mp3', title: '07. تفسير الطبري المجلس  7 سورة الفاتحة حتى قوله وإياك نستعين من صفحة 135 حتى صفحة 165'),
              (file: '08. تفسير الطبري المجلس  8 سورة الفاتحة من قوله اهدنا الصراط إلى آخرها  من صفحة 165حتى صفحة 203.mp3', title: '08. تفسير الطبري المجلس  8 سورة الفاتحة من قوله اهدنا الصراط إلى آخرها  من صفحة 165حتى صفحة 203'),
              (file: '09. تفسير الطبري المجلس 9 أول سورة البقرة الم المجلد الأول من صفحة 204 حتى 228.mp3', title: '09. تفسير الطبري المجلس 9 أول سورة البقرة الم المجلد الأول من صفحة 204 حتى 228'),
              (file: '10. تفسير الطبري المجلس 10 من قوله ذلك الكتاب   وأولئك هم المفلحون المجلد 1 من صفحة 228 حتى 25.mp3', title: '10. تفسير الطبري المجلس 10 من قوله ذلك الكتاب   وأولئك هم المفلحون المجلد 1 من صفحة 228 حتى 25'),
              (file: '11. تفسير الطبري المجلس 11 سورة البقرة آية6 إلى 9 المجلد 1 من ص 258 إلى 286.mp3', title: '11. تفسير الطبري المجلس 11 سورة البقرة آية6 إلى 9 المجلد 1 من ص 258 إلى 286'),
              (file: '12. تفسير الطبري المجلس 12 سورة البقرة من الآية 10 حتى 16 المجلد 1 من صفحة 286 حتى 332.mp3', title: '12. تفسير الطبري المجلس 12 سورة البقرة من الآية 10 حتى 16 المجلد 1 من صفحة 286 حتى 332'),
              (file: '13. تفسير الطبري المجلس 13 سورة البقرة من آية17 حتى 20 المجلد 1 من ص 332 حتى 384.mp3', title: '13. تفسير الطبري المجلس 13 سورة البقرة من آية17 حتى 20 المجلد 1 من ص 332 حتى 384'),
              (file: '14. تفسير الطبري 14 سورة البقرة من آية 21 حتى آية 25 المجلد 1 ص 384 حتى ص 422.mp3', title: '14. تفسير الطبري 14 سورة البقرة من آية 21 حتى آية 25 المجلد 1 ص 384 حتى ص 422'),
              (file: '15. تفسير الطبري 15 سورة البقرة آية 26 حتى آية 29 المجلد 1 ص422 حتى 466.mp3', title: '15. تفسير الطبري 15 سورة البقرة آية 26 حتى آية 29 المجلد 1 ص422 حتى 466'),
              (file: '16. تفسير الطبري 16 سورة البقرة آية 30 المجلد 1 من ص 466 حتى ص 511.mp3', title: '16. تفسير الطبري 16 سورة البقرة آية 30 المجلد 1 من ص 466 حتى ص 511'),
              (file: '17. تفسير الطبري 17 سورة البقرة آية من آية 31 حتى آية 34 المجلد 1 من ص 511 حتى ص 547.mp3', title: '17. تفسير الطبري 17 سورة البقرة آية من آية 31 حتى آية 34 المجلد 1 من ص 511 حتى ص 547'),
            ],
          ),
        ),
      ],
    ),

    /// تفسير البغوي
    'shamela_12217': MutunAudioEntry(
      bookId: 'shamela_12217',
      title: 'معالم التنزيل (تفسير البغوي)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.abdulMajid,
          audioUrl: 'https://archive.org/download/islami-55_202405/10.%2010%20%D8%AC%D8%B1%D8%AF%20%D8%AA%D9%81%D8%B3%D9%8A%D8%B1%20%D8%A7%D9%84%D8%A8%D8%BA%D9%88%D9%8A%20%20%D8%A7%D9%84%D8%A8%D9%82%D8%B1%D8%A9%20%D8%A7%D9%84%D8%A2%D9%8A%D8%A7%D8%AA%20224-242%20%20%D9%85%D8%AD%D9%85%D8%AF%20%D9%85%D8%B5%D8%B7%D9%81%D9%89%20%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%85%D8%AC%D9%8A%D8%AF.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-55_202405',
            items: const [
              (file: '10. 10 جرد تفسير البغوي  البقرة الآيات 224-242  محمد مصطفى عبد المجيد.mp3', title: '10. 10 جرد تفسير البغوي  البقرة الآيات 224-242  محمد مصطفى عبد المجيد'),
              (file: '11. 11 جرد تفسير البغوي  البقرة الآيات 243-258  محمد مصطفى عبد المجيد.mp3', title: '11. 11 جرد تفسير البغوي  البقرة الآيات 243-258  محمد مصطفى عبد المجيد'),
              (file: '12. 12 جرد تفسير البغوي  البقرة الآيات 259-281  محمد مصطفى عبد المجيد.mp3', title: '12. 12 جرد تفسير البغوي  البقرة الآيات 259-281  محمد مصطفى عبد المجيد'),
              (file: '1257101501.mp3', title: '1257101501'),
              (file: '13. 13 جرد تفسير البغوي  من البقرة 282 إلى آل عمران 19  محمد مصطفى عبد المجيد.mp3', title: '13. 13 جرد تفسير البغوي  من البقرة 282 إلى آل عمران 19  محمد مصطفى عبد المجيد'),
              (file: '14. 14 جرد تفسير البغوي  آل عمران الآيات 20-63  محمد مصطفى عبد المجيد.mp3', title: '14. 14 جرد تفسير البغوي  آل عمران الآيات 20-63  محمد مصطفى عبد المجيد'),
              (file: '15. 15 جرد تفسير البغوي  آل عمران الآيات 64-97  محمد مصطفى عبد المجيد.mp3', title: '15. 15 جرد تفسير البغوي  آل عمران الآيات 64-97  محمد مصطفى عبد المجيد'),
              (file: '16. 16 جرد تفسير البغوي  آل عمران الآيات 98-143  محمد مصطفى عبد المجيد.mp3', title: '16. 16 جرد تفسير البغوي  آل عمران الآيات 98-143  محمد مصطفى عبد المجيد'),
              (file: '1654417548.mp3', title: '1654417548'),
              (file: '17. 17 جرد تفسير البغوي  آل عمران من 144 إلى آخرها  محمد مصطفى عبد المجيد.mp3', title: '17. 17 جرد تفسير البغوي  آل عمران من 144 إلى آخرها  محمد مصطفى عبد المجيد'),
              (file: '18. 18 جرد تفسير البغوي  النساء الآيات 1-18  محمد مصطفى عبد المجيد.mp3', title: '18. 18 جرد تفسير البغوي  النساء الآيات 1-18  محمد مصطفى عبد المجيد'),
              (file: '19. 19 جرد تفسير البغوي  النساء الآيات 19-42  محمد مصطفى عبد المجيد.mp3', title: '19. 19 جرد تفسير البغوي  النساء الآيات 19-42  محمد مصطفى عبد المجيد'),
              (file: '20. 20 جرد تفسير البغوي  النساء الآيات 43-85  محمد مصطفى عبد المجيد.mp3', title: '20. 20 جرد تفسير البغوي  النساء الآيات 43-85  محمد مصطفى عبد المجيد'),
              (file: '21. 21 جرد تفسير البغوي  النساء الآيات 86-122  محمد مصطفى عبد المجيد.mp3', title: '21. 21 جرد تفسير البغوي  النساء الآيات 86-122  محمد مصطفى عبد المجيد'),
              (file: '22. 22 جرد تفسير البغوي  من النساء 123 إلى المائدة 4  محمد مصطفى عبد المجيد.mp3', title: '22. 22 جرد تفسير البغوي  من النساء 123 إلى المائدة 4  محمد مصطفى عبد المجيد'),
              (file: '23. 23 جرد تفسير البغوي  المائدة الآيات 5-32  محمد مصطفى عبد المجيد.mp3', title: '23. 23 جرد تفسير البغوي  المائدة الآيات 5-32  محمد مصطفى عبد المجيد'),
              (file: '24. 24 جرد تفسير البغوي  المائدة الآيات 33-76  محمد مصطفى عبد المجيد.mp3', title: '24. 24 جرد تفسير البغوي  المائدة الآيات 33-76  محمد مصطفى عبد المجيد'),
              (file: '25. 25 جرد تفسير البغوي  المائدة من 77 إلى آخرها  محمد مصطفى عبد المجيد.mp3', title: '25. 25 جرد تفسير البغوي  المائدة من 77 إلى آخرها  محمد مصطفى عبد المجيد'),
              (file: '26. 26 جرد تفسير البغوي  الأنعام الآيات 1-90  محمد مصطفى عبد المجيد.mp3', title: '26. 26 جرد تفسير البغوي  الأنعام الآيات 1-90  محمد مصطفى عبد المجيد'),
              (file: '27. 27 جرد تفسير البغوي  الأنعام الآيات 91-145  محمد مصطفى عبد المجيد.mp3', title: '27. 27 جرد تفسير البغوي  الأنعام الآيات 91-145  محمد مصطفى عبد المجيد'),
              (file: '28. 28 جرد تفسير البغوي  من الأنعام 146 إلى الأعراف 39  محمد مصطفى عبد المجيد.mp3', title: '28. 28 جرد تفسير البغوي  من الأنعام 146 إلى الأعراف 39  محمد مصطفى عبد المجيد'),
              (file: '29. 29 جرد تفسير البغوي  الأعراف الآيات 40-102  محمد مصطفى عبد المجيد.mp3', title: '29. 29 جرد تفسير البغوي  الأعراف الآيات 40-102  محمد مصطفى عبد المجيد'),
              (file: '30. 30 جرد تفسير البغوي  الأعراف الآيات 103-158  محمد مصطفى عبد المجيد.mp3', title: '30. 30 جرد تفسير البغوي  الأعراف الآيات 103-158  محمد مصطفى عبد المجيد'),
              (file: '31. 31 جرد تفسير البغوي  الأعراف من 159 إلى آخرها  محمد مصطفى عبد المجيد.mp3', title: '31. 31 جرد تفسير البغوي  الأعراف من 159 إلى آخرها  محمد مصطفى عبد المجيد'),
              (file: '32. 32 جرد تفسير البغوي  الأنفال الآيات 1-28  محمد مصطفى عبد المجيد.mp3', title: '32. 32 جرد تفسير البغوي  الأنفال الآيات 1-28  محمد مصطفى عبد المجيد'),
              (file: '33. 33 جرد تفسير البغوي  الأنفال من 29 إلى آخرها  محمد مصطفى عبد المجيد.mp3', title: '33. 33 جرد تفسير البغوي  الأنفال من 29 إلى آخرها  محمد مصطفى عبد المجيد'),
              (file: '34. 34 جرد تفسير البغوي  التوبة الآيات 1-29  محمد مصطفى عبد المجيد.mp3', title: '34. 34 جرد تفسير البغوي  التوبة الآيات 1-29  محمد مصطفى عبد المجيد'),
              (file: '35. 35 جرد تفسير البغوي  التوبة الآيات 30-55  محمد مصطفى عبد المجيد.mp3', title: '35. 35 جرد تفسير البغوي  التوبة الآيات 30-55  محمد مصطفى عبد المجيد'),
              (file: '36. 36 جرد تفسير البغوي  التوبة الآيات 56-96  محمد مصطفى عبد المجيد.mp3', title: '36. 36 جرد تفسير البغوي  التوبة الآيات 56-96  محمد مصطفى عبد المجيد'),
              (file: '37. 37 جرد تفسير البغوي  التوبة من 79 إلى آخرها  محمد مصطفى عبد المجيد.mp3', title: '37. 37 جرد تفسير البغوي  التوبة من 79 إلى آخرها  محمد مصطفى عبد المجيد'),
            ],
          ),
        ),
      ],
    ),

    /// تفسير القرطبي
    'shamela_20855': MutunAudioEntry(
      bookId: 'shamela_20855',
      title: 'الجامع لأحكام القرآن (تفسير القرطبي)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.duwayshi,
          audioUrl: 'https://archive.org/download/islami-50_202405/01.%20%D9%83%D8%AA%D8%A7%D8%A8%20%D8%B5%D9%88%D8%AA%D9%8A%20%D8%A7%D9%84%D8%AC%D8%A7%D9%85%D8%B9%20%D9%84%D8%A3%D8%AD%D9%83%D8%A7%D9%85%20%D8%A7%D9%84%D9%82%D8%B1%D8%A2%D9%86%20%D9%84%D9%84%D9%82%D8%B1%D8%B7%D8%A8%D9%8A%20%D8%A8%D8%B5%D9%88%D8%AA%20%D9%85%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D8%AF%D9%88%D9%8A%D8%B4%D9%8A%20%D8%A7%D9%84%D8%AD%D9%84%D9%82%D8%A9%20%D8%A7%D9%84%D8%A3%D9%88%D9%84%D9%89%20%D9%85%D9%82%D8%AF%D9%85%D8%A9%20%D8%A7%D9%84%D9%85%D8%A4%D9%84%D9%81.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-50_202405',
            items: const [
              (file: '01. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الأولى مقدمة المؤلف.mp3', title: '01.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الأولى مقدمة المؤلف'),
              (file: '02. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الثانية.mp3', title: '02.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الثانية'),
              (file: '03. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الثالثة.mp3', title: '03.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الثالثة'),
              (file: '04. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الرابعة.mp3', title: '04.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الرابعة'),
              (file: '05. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الخامسة.mp3', title: '05.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الخامسة'),
              (file: '06. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة السادسة.mp3', title: '06.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة السادسة'),
              (file: '07. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة السابعة.mp3', title: '07.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة السابعة'),
              (file: '08. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة التاسعة الجزء الثاني من سورة الف.mp3', title: '08.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة التاسعة الجزء الثاني من سورة الف'),
              (file: '09. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الثامنة الجزء الأول من  سورة الف.mp3', title: '09.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الثامنة الجزء الأول من  سورة الف'),
              (file: '10. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة العاشرة أول البقرة.mp3', title: '10.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة العاشرة أول البقرة'),
              (file: '11. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الحادية عشرة سورة البقرة من 6 ال.mp3', title: '11.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة الحادية عشرة سورة البقرة من 6 ال'),
              (file: '12. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة 12سورة البقرة من 21 الى 29.mp3', title: '12.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة 12سورة البقرة من 21 الى 29'),
              (file: '13. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة13سورة البقرة  من الاية 30 الى 34.mp3', title: '13.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة13سورة البقرة  من الاية 30 الى 34'),
              (file: '14. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة14 من الاية 35 الى الاية 39.mp3', title: '14.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة14 من الاية 35 الى الاية 39'),
              (file: '15. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة 15  البقرة من الاية  40 الى الاي.mp3', title: '15.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة 15  البقرة من الاية  40 الى الاي'),
              (file: '16. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة16 البقرة من الاية  45الى 50.mp3', title: '16.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة16 البقرة من الاية  45الى 50'),
              (file: '17. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة17 البقرة من الاية51 الى59.mp3', title: '17.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة17 البقرة من الاية51 الى59'),
              (file: '18. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة18 سورة البقرة من الاية60 الى66.mp3', title: '18.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة18 سورة البقرة من الاية60 الى66'),
              (file: '19. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة19 سورة البقرة من الاية67  الى 74.mp3', title: '19.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة19 سورة البقرة من الاية67  الى 74'),
              (file: '20. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة20 سورة البقرة من لاية75 الى88.mp3', title: '20.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة20 سورة البقرة من لاية75 الى88'),
              (file: '21. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة21 سورة البقرة من لاية89 الى103.mp3', title: '21.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة21 سورة البقرة من لاية89 الى103'),
              (file: '22. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة22 سورة البقرة من لاية104 الى114.mp3', title: '22.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة22 سورة البقرة من لاية104 الى114'),
              (file: '23. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة23 سورة البقرة من لاية115 الى123.mp3', title: '23.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة23 سورة البقرة من لاية115 الى123'),
              (file: '24. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة24 سورة  البقرة من لاية124 الى126.mp3', title: '24.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة24 سورة  البقرة من لاية124 الى126'),
              (file: '25. مفاجأة, الجامعة تتخذ قرار جديد والتنفيذ فوري على الشان وتفاصيل مسار الطائرة  ابو البيس _ abo al.mp3', title: '25. مفاجأة, الجامعة تتخذ قرار جديد والتنفيذ فوري على الشان وتفاصيل مسار الطائرة  ابو البيس _ abo al'),
              (file: '26. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة25 سورة البقرة من لاية127 الى141.mp3', title: '26.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة25 سورة البقرة من لاية127 الى141'),
              (file: '27. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة26 سورة البقرة من لاية142الى157.mp3', title: '27.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة26 سورة البقرة من لاية142الى157'),
              (file: '28. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة27 سورة البقرة  من لاية158 الى 16.mp3', title: '28.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة27 سورة البقرة  من لاية158 الى 16'),
              (file: '29. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة28 سورة البقرة من لاية166 الى 173.mp3', title: '29.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة28 سورة البقرة من لاية166 الى 173'),
              (file: '30. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة29 سورة البقرة من الاية 174 الى 1.mp3', title: '30.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة29 سورة البقرة من الاية 174 الى 1'),
              (file: '31. كتاب صوتي الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة30 سورة البقرة من الاية 183 الى 1.mp3', title: '31.  الجامع لأحكام القرآن للقرطبي بصوت محمد الدويشي الحلقة30 سورة البقرة من الاية 183 الى 1'),
            ],
          ),
        ),
      ],
    ),

    /// أضواء البيان
    'shamela_22918': MutunAudioEntry(
      bookId: 'shamela_22918',
      title: 'أضواء البيان في إيضاح القرآن بالقرآن',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.muqhim,
          audioUrl: 'https://archive.org/download/adhwaa_al-bayan/001.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/adhwaa_al-bayan',
            count: 30,
            titlePrefix: 'مجلس أضواء البيان',
            padWidth: 3,
          ),
        ),
      ],
    ),

    // ── السيرة والتراجم ────────────────────────────────────────

    /// الشمائل المحمدية
    'shamela_13037': MutunAudioEntry(
      bookId: 'shamela_13037',
      title: 'الشمائل المحمدية للترمذي',
      sources: [
        HalibaAudiobooksCatalog.playlistSource(
          ['shifa_part1', 'shifa_part2', 'shifa_part3', 'wafat_nabi'],
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunnahMasmuah,
          audioUrl: 'https://archive.org/download/0002ArShama2elMohamadiaSB02/0001-ar_Shama2el_Mohamadia_S_B_01.mp3',
          chapters: BookAudioChapter.dualNumbered(
            baseUrl:
                'https://archive.org/download/0002ArShama2elMohamadiaSB02',
            count: 6,
            titlePrefix: 'كتاب الشمائل باب',
            middleToken: 'ar_Shama2el_Mohamadia_S_B',
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.ahmadIzzat,
          audioUrl: 'https://archive.org/download/islami-442_202507/01.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/islami-442_202507',
            count: 12,
            titlePrefix: 'مجلس الشمائل',
            padWidth: 2,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl: 'https://archive.org/download/islami-300_202505/1.%20%D9%83%D8%AA%D8%A7%D8%A8%20%D8%A7%D9%84%D8%B4%D9%85%D8%A7%D8%A6%D9%84%20%D8%A7%D9%84%D9%85%D8%AD%D9%85%D8%AF%D9%8A%D8%A9%20%D9%84%D9%84%D8%AA%D8%B1%D9%85%D8%B0%D9%8A%20%D8%A7%D9%84%D9%85%D8%AC%D9%84%D8%B3%20%D8%A7%D9%84%D8%A3%D9%88%D9%84%20%D8%A8%D8%B5%D9%88%D8%AA%20%D8%A7%D9%84%D8%B4%D9%8A%D8%AE%20%D8%B9%D9%85%D8%B1%D9%88%20%D8%A7%D9%84%D8%A8%D8%B3%D8%A7%D8%B7%D9%8A%20%D9%85%D9%86%20%D8%A7%D9%84%D8%A8%D8%A7%D8%A8%201%20%D8%AD%D8%AA%D9%89%203.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-300_202505',
            items: const [
              (file: '1. كتاب الشمائل المحمدية للترمذي المجلس الأول بصوت الشيخ عمرو البساطي من الباب 1 حتى 3.mp3', title: '1. كتاب الشمائل المحمدية للترمذي المجلس الأول بصوت الشيخ عمرو البساطي من الباب 1 حتى 3'),
              (file: '2. كتاب الشمائل المحمدية المجلس الثاني  بصوت الشيخ عمرو البساطي من الباب 4 حتى 11.mp3', title: '2. كتاب الشمائل المحمدية المجلس الثاني  بصوت الشيخ عمرو البساطي من الباب 4 حتى 11'),
              (file: '3. كتاب الشمائل المحمدية المجلس الثالث  بصوت الشيخ عمرو البساطي من الباب 12 حتى 20.mp3', title: '3. كتاب الشمائل المحمدية المجلس الثالث  بصوت الشيخ عمرو البساطي من الباب 12 حتى 20'),
              (file: '4. كتاب الشمائل المحمدية المجلس الرابع بصوت الشيخ عمرو البساطي من الباب 21 حتى 30.mp3', title: '4. كتاب الشمائل المحمدية المجلس الرابع بصوت الشيخ عمرو البساطي من الباب 21 حتى 30'),
              (file: '5. كتاب الشمائل المحمدية المجلس الخامس بصوت الشيخ عمرو البساطي من الباب 31 حتى 40.mp3', title: '5. كتاب الشمائل المحمدية المجلس الخامس بصوت الشيخ عمرو البساطي من الباب 31 حتى 40'),
              (file: '6. كتاب الشمائل المحمدية المجلس السادس بصوت الشيخ عمرو البساطي من الباب 41 حتى 49.mp3', title: '6. كتاب الشمائل المحمدية المجلس السادس بصوت الشيخ عمرو البساطي من الباب 41 حتى 49'),
              (file: '7. كتاب الشمائل المحمدية المجلس السابع والأخير بصوت الشيخ عمرو البساطي من الباب 50  حتى  56.mp3', title: '7. كتاب الشمائل المحمدية المجلس السابع والأخير بصوت الشيخ عمرو البساطي من الباب 50  حتى  56'),
            ],
          ),
        ),
      ],
    ),

    /// البداية والنهاية
    'shamela_8376': MutunAudioEntry(
      bookId: 'shamela_8376',
      title: 'البداية والنهاية لابن كثير',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/038.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 5,
            titlePrefix: 'جزء البداية والنهاية',
            startNumber: 38,
            padWidth: 3,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.ibnBaz,
          audioUrl: 'https://archive.org/download/asdasmd22014-04-25/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/asdasmd22014-04-25',
            count: 8,
            titlePrefix: 'مجلس البداية والنهاية',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// سير أعلام النبلاء
    'shamela_10906': MutunAudioEntry(
      bookId: 'shamela_10906',
      title: 'سير أعلام النبلاء للذهبي',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Siyar_alam_nobala/01%20-%20%D9%8A%D9%88%D8%B3%D9%81%20%D8%A7%D9%84%D8%B5%D8%AF%D9%8A%D9%82.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/Siyar_alam_nobala',
            items: const [
              (file: '01 - يوسف الصديق.mp3', title: 'يوسف الصديق'),
              (file: '02 - موسى.mp3', title: 'موسى عليه السلام'),
              (file: '03 - عمر بن الخطاب.mp3', title: 'عمر بن الخطاب'),
              (file: '04 - عثمان بن عفان.mp3', title: 'عثمان بن عفان'),
              (file: '05 - علي بن أبي طالب.mp3', title: 'علي بن أبي طالب'),
              (file: '06 - الإمام البخاري.mp3', title: 'الإمام البخاري'),
              (file: '07 - الإمام مسلم.mp3', title: 'الإمام مسلم'),
              (file: '08 - الإمام أحمد.mp3', title: 'الإمام أحمد'),
              (file: '09 - ابن تيمية.mp3', title: 'ابن تيمية'),
              (file: '10 - إبن تيمية.mp3', title: 'ابن تيمية (إكمال)'),
            ],
          ),
        ),
      ],
    ),

    // pull in raqaiq/zuhd entries
    ...TurathRaqaiqAudioEntries.entries,
  };
}
