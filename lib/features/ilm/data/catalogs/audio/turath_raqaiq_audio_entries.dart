import '../../models/book_audio_models.dart';
import 'haliba_audiobooks_catalog.dart';
import 'ilm_audio_reciters.dart';

/// Audio catalog for Raqaiq / Zuhd / Tazkiyah Shamela heritage books (< 420 lines).
/// Imported and spread into [TurathSunnahTafsirAudioEntries.entries].
class TurathRaqaiqAudioEntries {
  const TurathRaqaiqAudioEntries._();

  static final Map<String, MutunAudioEntry> entries = {
    // ── الرقائق والزهد ─────────────────────────────────────────

    /// الوابل الصيب لابن القيم
    'shamela_216': MutunAudioEntry(
      bookId: 'shamela_216',
      title: 'الوابل الصيب من الكلم الطيب',
      sources: [
        HalibaAudiobooksCatalog.playlistSource(
          ['dhawq_salah', 'risalat_ibn_qayyim'],
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.jazaeri,
          audioUrl:
              'https://archive.org/download/Kitab_Wabil_Sayyibh_Mp3_uP_bY_mUSLEm/01.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl:
                'https://archive.org/download/Kitab_Wabil_Sayyibh_Mp3_uP_bY_mUSLEm',
            count: 10,
            titlePrefix: 'فصل الوابل الصيب',
            padWidth: 2,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.ibnBaz,
          audioUrl:
              'https://archive.org/download/Char7_Kitab_Wabil_Sayyibh_Ibn_Bazz_uP_bY_mUSLEm/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl:
                'https://archive.org/download/Char7_Kitab_Wabil_Sayyibh_Ibn_Bazz_uP_bY_mUSLEm',
            count: 8,
            titlePrefix: 'شرح الوابل الصيب',
            padWidth: 2,
          ),
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/105.mp3',
        ),
      ],
    ),

    /// مدارج السالكين
    'shamela_8370': MutunAudioEntry(
      bookId: 'shamela_8370',
      title: 'مدارج السالكين بين منازل إياك نعبد وإياك نستعين',
      sources: [
        HalibaAudiobooksCatalog.playlistSource([
          'mukhtasar_hadi_arwah',
          'dhawq_salah',
          'risalat_ibn_qayyim',
          'mukhtasar_tariq_hijratayn',
        ]),
        MatnAudioSource(
          reciter: MutunReciterDefaults.ibnHajj,
          audioUrl: 'https://archive.org/download/Hajj-madarij/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Hajj-madarij',
            count: 65,
            titlePrefix: 'مجلس مدارج السالكين',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// صيد الخاطر لابن الجوزي
    'shamela_12028': MutunAudioEntry(
      bookId: 'shamela_12028',
      title: 'صيد الخاطر لابن الجوزي',
      sources: [
        HalibaAudiobooksCatalog.playlistSource(
            ['laftat_kabid', 'araj_fil_faraj']),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/238.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 4,
            titlePrefix: 'جزء صيد الخاطر',
            startNumber: 238,
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// جامع العلوم والحكم لابن رجب
    'shamela_4268': MutunAudioEntry(
      bookId: 'shamela_4268',
      title: 'جامع العلوم والحكم في شرح خمسين حديثاً من جوامع الكلم',
      sources: [
        HalibaAudiobooksCatalog.playlistSource([
          'warathat_anbiya',
          'sharh_ma_dhiban',
          'dhull_inkisar',
          'mahajjah_sayr_duljah',
          'istighna_bil_quran',
        ]),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/107.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 5,
            titlePrefix: 'جزء جامع العلوم والحكم',
            startNumber: 107,
            padWidth: 3,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.uthaymin,
          audioUrl: 'https://archive.org/download/Sharh_J_O_Hekam/000.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Sharh_J_O_Hekam',
            count: 100,
            titlePrefix: 'شرح جامع العلوم والحكم',
            startNumber: 0,
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// حلية طالب العلم
    'shamela_9884': MutunAudioEntry(
      bookId: 'shamela_9884',
      title: 'حلية طالب العلم للشيخ بكر أبو زيد',
      sources: [
        HalibaAudiobooksCatalog.playlistSource(
            ['wasaya_salaf_shabab', 'nasihah_ibn_habbal', 'warathat_anbiya']),
        MatnAudioSource(
          reciter: MutunReciterDefaults.uthaymin,
          audioUrl: 'https://archive.org/download/Hilyat_Talib_Elm/01A.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/Hilyat_Talib_Elm',
            items: const [
              (file: '01A.mp3', title: 'الدرس ١أ'),
              (file: '01B.mp3', title: 'الدرس ١ب'),
              (file: '02A.mp3', title: 'الدرس ٢أ'),
              (file: '02B.mp3', title: 'الدرس ٢ب'),
              (file: '03A.mp3', title: 'الدرس ٣أ'),
              (file: '03B.mp3', title: 'الدرس ٣ب'),
              (file: '04A.mp3', title: 'الدرس ٤أ'),
              (file: '04B.mp3', title: 'الدرس ٤ب'),
              (file: '05A.mp3', title: 'الدرس ٥أ'),
              (file: '05B.mp3', title: 'الدرس ٥ب'),
              (file: '06A.mp3', title: 'الدرس ٦أ'),
              (file: '06B.mp3', title: 'الدرس ٦ب'),
              (file: '07A.mp3', title: 'الدرس ٧أ'),
              (file: '07B.mp3', title: 'الدرس ٧ب'),
              (file: '08A.mp3', title: 'الدرس ٨أ'),
              (file: '08B.mp3', title: 'الدرس ٨ب'),
              (file: '09A.mp3', title: 'الدرس ٩أ'),
              (file: '09B.mp3', title: 'الدرس ٩ب'),
              (file: '10A.mp3', title: 'الدرس ١٠أ'),
              (file: '10B.mp3', title: 'الدرس ١٠ب'),
              (file: '11A.mp3', title: 'الدرس ١١أ'),
              (file: '11B.mp3', title: 'الدرس ١١ب'),
              (file: '12A.mp3', title: 'الدرس ١٢أ'),
              (file: '12B.mp3', title: 'الدرس ١٢ب'),
            ],
          ),
        ),
      ],
    ),

    /// التذكرة في أحوال الموتى للقرطبي
    'shamela_21536': MutunAudioEntry(
      bookId: 'shamela_21536',
      title: 'التذكرة في أحوال الموتى وأمور الآخرة',
      sources: [
        HalibaAudiobooksCatalog.playlistSource([
          'fitan_ashrat_saah',
          'ahwal_qiyamah_targheeb',
          'sifat_jannah_targheeb',
          'mukhtasar_hadi_arwah',
        ]),
        MatnAudioSource(
          reciter: MutunReciterDefaults.bilalMansour,
          audioUrl: Uri.encodeFull(
              'https://archive.org/download/islami-211_202504/كتاب صوتى  كتاب التذكرة  [ ١ ]تأليف  الإمام القرطبى رحمه الله تعالى.mp3'),
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-211_202504',
            items: const [
              (
                file: 'كتاب صوتى  كتاب التذكرة  [ ١ ]تأليف  الإمام القرطبى رحمه الله تعالى.mp3',
                title: 'التذكرة في أحوال الموتى - الجزء الأول'
              ),
              (
                file: 'كتاب صوتى  كتاب التذكرة  [ ٢ ] تأليف  الإمام القرطبى رحمه الله تعالى.mp3',
                title: 'التذكرة في أحوال الموتى - الجزء الثاني'
              ),
              (
                file: 'كتاب التذكرة ( ٣ ) للإمام القرطبي رحمه الله تعالى.mp3',
                title: 'التذكرة في أحوال الموتى - الجزء الثالث'
              ),
            ],
          ),
        ),
      ],
    ),
  };
}

