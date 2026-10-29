import '../../models/book_audio_models.dart';
import 'haliba_audiobooks_catalog.dart';
import 'ilm_audio_reciters.dart';

/// Audio catalog linking Shamela classical heritage books (`خزانة التراث الإسلامي`)
/// to verified multi-reciter and multi-chapter streaming recordings.
class TurathBooksAudioEntries {
  const TurathBooksAudioEntries._();

  static const String _sawtiya = 'https://archive.org/download/Mutun_Sawtiya';
  static const String _aqidah = 'https://archive.org/download/motoun_al3aqeedah';

  /// Maps Shamela book IDs directly to existing multi-reciter syllabus entries.
  static const Map<int, String> shamelaToSyllabusAliases = {
    11126: 'bk_usul_thalatha',
    8524: 'bk_qawaid_arba',
    11318: 'bk_kitab_tawheed',
    11381: 'bk_kashf_shubuhat',
    9568: 'bk_aqidah_tahawiyyah',
    22665: 'bk_wasitiyyah',
    11371: 'bk_ajrumiyyah',
    356: 'bk_alfiyyah_ibn_malik',
    11230: 'bk_zad_mustaqni',
    147927: 'bk_arbaeen_nawawi',
    17103: 'bk_umdat_ahkam',
    17757: 'bk_bulugh_maram',
    8567: 'bk_manzumah_baiquoni',
    616: 'bk_nokhbat_al_fikar',
    6297: 'bk_waraqat',
    1956: 'bk_adhkar_adab',
  };

  static const List<String> _surahNames = [
    'سورة الفاتحة', 'سورة البقرة', 'سورة آل عمران', 'سورة النساء', 'سورة المائدة',
    'سورة الأنعام', 'سورة الأعراف', 'سورة الأنفال', 'سورة التوبة', 'سورة يونس',
    'سورة هود', 'سورة يوسف', 'سورة الرعد', 'سورة إبراهيم', 'سورة الحجر',
    'سورة النحل', 'سورة الإسراء', 'سورة الكهف', 'سورة مريم', 'سورة طه',
    'سورة الأنبياء', 'سورة الحج', 'سورة المؤمنون', 'سورة النور', 'سورة الفرقان',
    'سورة الشعراء', 'سورة النمل', 'سورة القصص', 'سورة العنكبوت', 'سورة الروم',
    'سورة لقمان', 'سورة السجدة', 'سورة الأحزاب', 'سورة سبأ', 'سورة فاطر',
    'سورة يس', 'سورة الصافات', 'سورة ص', 'سورة الزمر', 'سورة غافر',
    'سورة فصلت', 'سورة الشورى', 'سورة الزخرف', 'سورة الدخان', 'سورة الجاثية',
    'سورة الأحقاف', 'سورة محمد', 'سورة الفتح', 'سورة الحجرات', 'سورة ق',
    'سورة الذاريات', 'سورة الطور', 'سورة النجم', 'سورة القمر', 'سورة الرحمن',
    'سورة الواقعة', 'سورة الحديد', 'سورة المجادلة', 'سورة الحشر', 'سورة الممتحنة',
    'سورة الصف', 'سورة الجمعة', 'سورة المنافقون', 'سورة التغابن', 'سورة الطلاق',
    'سورة التحريم', 'سورة الملك', 'سورة القلم', 'سورة الحاقة', 'سورة المعارج',
    'سورة نوح', 'سورة الجن', 'سورة المزمل', 'سورة المدثر', 'سورة القيامة',
    'سورة الإنسان', 'سورة المرسلات', 'سورة النبأ', 'سورة النازعات', 'سورة عبس',
    'سورة التكوير', 'سورة الانفطار', 'سورة المطففين', 'سورة الانشقاق', 'سورة البروج',
    'سورة الطارق', 'سورة الأعلى', 'سورة الغاشية', 'سورة الفجر', 'سورة البلد',
    'سورة الشمس', 'سورة الليل', 'سورة الضحى', 'سورة الشرح', 'سورة التين',
    'سورة العلق', 'سورة القدر', 'سورة البينة', 'سورة الزلزلة', 'سورة العاديات',
    'سورة القارعة', 'سورة التكاثر', 'سورة العصر', 'سورة الهمزة', 'سورة الفيل',
    'سورة قريش', 'سورة الماعون', 'سورة الكوثر', 'سورة الكافرون', 'سورة النصر',
    'سورة المسد', 'سورة الإخلاص', 'سورة الفلق', 'سورة الناس',
  ];

  static String shamelaKey(int shamelaId) => 'shamela_$shamelaId';

  static final Map<String, MutunAudioEntry> entries = {
    // ── العقيدة ───────────────────────────────────────────────
    'shamela_11366': MutunAudioEntry(
      bookId: 'shamela_11366',
      title: 'لمعة الاعتقاد الهادي إلى سبيل الرشاد',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_aqidah/lomaat_ali3tiqad.mp3',
          fallbackUrl: '$_sawtiya/040-Lomaat_ali3tiqad.mp3',
        ),
        HalibaAudiobooksCatalog.sourceFor('wasiyyat_ibn_qudamah'),
      ],
    ),
    'shamela_6418': const MutunAudioEntry(
      bookId: 'shamela_6418',
      title: 'أصول السنة للإمام أحمد بن حنبل',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/045-Oussoul_assuna.mp3',
          fallbackUrl: '$_sawtiya/049-Oussoul_sunna_abibakr.mp3',
        ),
      ],
    ),
    'shamela_20854': MutunAudioEntry(
      bookId: 'shamela_20854',
      title: 'سلم الوصول إلى علم الأصول (متن معارج القبول)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shulaimi,
          audioUrl:
              'https://archive.org/download/Mandhoumat_Solam_Woossoul_uP_bY_mUSLEm/01_uP_bY_mUSLEm.mp3',
          edition: BookAudioEdition.nadhm,
          chapters: BookAudioChapter.numbered(
            baseUrl:
                'https://archive.org/download/Mandhoumat_Solam_Woossoul_uP_bY_mUSLEm',
            count: 16,
            titlePrefix: 'فصل سلم الوصول',
            padWidth: 2,
            fileSuffix: '_uP_bY_mUSLEm.mp3',
          ),
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_al-Aqida/sullaam.mp3',
          edition: BookAudioEdition.nadhm,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/080-Sollam_alwossoul_ila_ilm_al-ossoul.mp3',
          edition: BookAudioEdition.nadhm,
        ),
      ],
    ),

    // ── اللغة العربية ──────────────────────────────────────────
    'shamela_11376': const MutunAudioEntry(
      bookId: 'shamela_11376',
      title: 'متن قطر الندى وبل الصدى',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/090-Qatr_annada_ibn_hisham.mp3',
        ),
      ],
    ),

    // ── الفقه ─────────────────────────────────────────────────
    'shamela_1679': MutunAudioEntry(
      bookId: 'shamela_1679',
      title: 'الروض المربع بشرح زاد المستقنع',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl: 'https://archive.org/download/Rawdh_Murbi3/001.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Rawdh_Murbi3',
            count: 103,
            titlePrefix: 'باب الروض المربع',
            padWidth: 3,
          ),
        ),
      ],
    ),
    'shamela_11315': MutunAudioEntry(
      bookId: 'shamela_11315',
      title: 'عمدة الفقه في المذهب الحنبلي',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/075-Omdat_al-fiqh_ibn_qodaamah_1.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: _sawtiya,
            count: 6,
            titlePrefix: 'الجزء',
            filePrefix: '075-Omdat_al-fiqh_ibn_qodaamah_',
            padWidth: 1,
          ),
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_al-Fiqh/mom.mp3',
          fallbackUrl: 'https://archive.org/download/Mutun_al-Fiqh/omdah.mp3',
          edition: BookAudioEdition.nadhm,
        ),
      ],
    ),
    'shamela_11370': const MutunAudioEntry(
      bookId: 'shamela_11370',
      title: 'نهاية التدريب في نظم غاية التقريب (متن أبي شجاع)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_al-Fiqh/nehaya.mp3',
          edition: BookAudioEdition.nadhm,
        ),
      ],
    ),
    'shamela_11373': const MutunAudioEntry(
      bookId: 'shamela_11373',
      title: 'مقدمة الرسالة لابن أبي زيد القيرواني',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/043-Nathr_qayrawanuiya.mp3',
          fallbackUrl: '$_sawtiya/044-Nadhm_qayrawaniya.mp3',
          edition: BookAudioEdition.mukhtasar,
        ),
      ],
    ),

    // ── الحديث ومصطلحه ─────────────────────────────────────────
    'shamela_735': MutunAudioEntry(
      bookId: 'shamela_735',
      title: 'صحيح البخاري (الجامع المسند الصحيح)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunnahMasmuah,
          audioUrl:
              'https://archive.org/download/Bokharee_up_by_ayoub-islam/01.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Bokharee_up_by_ayoub-islam',
            count: 94,
            titlePrefix: 'كتاب صحيح البخاري',
            padWidth: 2,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/069.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 10,
            titlePrefix: 'جزء صحيح البخاري',
            startNumber: 69,
            padWidth: 3,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.usaymi,
          audioUrl:
              'https://archive.org/download/islami-240_202504/001.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/islami-240_202504',
            count: 32,
            titlePrefix: 'مجلس صحيح البخاري',
            padWidth: 3,
          ),
        ),
      ],
    ),
    'shamela_12014': MutunAudioEntry(
      bookId: 'shamela_12014',
      title: 'رياض الصالحين من كلام سيد المرسلين',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.duraihim,
          audioUrl:
              'https://archive.org/download/Riad_Alsalheen__AlDuraihim/001.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Riad_Alsalheen__AlDuraihim',
            count: 372,
            titlePrefix: 'باب رياض الصالحين',
            padWidth: 3,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/103.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 2,
            titlePrefix: 'جزء رياض الصالحين',
            startNumber: 103,
            padWidth: 3,
          ),
        ),
      ],
    ),
    'shamela_171': MutunAudioEntry(
      bookId: 'shamela_171',
      title: 'صحيح الترغيب والترهيب',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: 'https://archive.org/download/sahih_attargheeb/01.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/sahih_attargheeb',
            count: 74,
            titlePrefix: 'الجزء',
            padWidth: 2,
          ),
        ),
        HalibaAudiobooksCatalog.sahihTargheebSelectionsSource,
      ],
    ),
    'shamela_1768': const MutunAudioEntry(
      bookId: 'shamela_1768',
      title: 'ألفية السيوطي في علم الحديث',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_elm_al-Hadeeth/alsewte.mp3',
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/065.mp3',
        ),
      ],
    ),

    // ── الرقائق والآداب ────────────────────────────────────────
    'shamela_158': MutunAudioEntry(
      bookId: 'shamela_158',
      title: 'الداء والدواء (الجواب الكافي)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl: 'https://archive.org/download/Daa_Dawaa/01.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Daa_Dawaa',
            count: 12,
            titlePrefix: 'المجلس',
            padWidth: 2,
          ),
        ),
        HalibaAudiobooksCatalog.sourceFor('mukhtasar_daa_dawaa'),
      ],
    ),
    'shamela_212': MutunAudioEntry(
      bookId: 'shamela_212',
      title: 'الفوائد لابن قيم الجوزية',
      sources: [
        HalibaAudiobooksCatalog.sourceFor('mukhtasar_fawaid'),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/234.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 2,
            titlePrefix: 'جزء الفوائد',
            startNumber: 234,
            padWidth: 3,
          ),
        ),
      ],
    ),
    'shamela_251': MutunAudioEntry(
      bookId: 'shamela_251',
      title: 'طريق الهجرتين وباب السعادتين',
      sources: [HalibaAudiobooksCatalog.sourceFor('mukhtasar_tariq_hijratayn')],
    ),
    'shamela_252': MutunAudioEntry(
      bookId: 'shamela_252',
      title: 'عدة الصابرين وذخيرة الشاكرين',
      sources: [HalibaAudiobooksCatalog.sourceFor('mukhtasar_uddat_sabirin')],
    ),
    'shamela_1151': MutunAudioEntry(
      bookId: 'shamela_1151',
      title: 'لطائف المعارف فيما لمواسم العام من الوظائف',
      sources: [HalibaAudiobooksCatalog.sourceFor('lataif_ramadan')],
    ),
    'shamela_98087': MutunAudioEntry(
      bookId: 'shamela_98087',
      title: 'مختصر منهاج القاصدين لابن قدامة',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.khazaen,
          audioUrl: Uri.encodeFull(
            'https://archive.org/download/khaled_alridwany_31_201710/منهاج الأقاصدين (1).mp3',
          ),
          chapters: List<BookAudioChapter>.unmodifiable([
            for (int i = 1; i <= 32; i++)
              BookAudioChapter(
                index: i,
                title: 'المجلس $i من مختصر منهاج القاصدين',
                audioUrl: Uri.encodeFull(
                  'https://archive.org/download/khaled_alridwany_31_201710/منهاج الأقاصدين ($i).mp3',
                ),
              ),
          ]),
        ),
      ],
    ),
    'shamela_6848': MutunAudioEntry(
      bookId: 'shamela_6848',
      title: 'كتاب الكبائر للإمام الذهبي',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.badr,
          audioUrl:
              'https://archive.org/download/sedratalmontha_gmail_0_201409/0.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl:
                'https://archive.org/download/sedratalmontha_gmail_0_201409',
            count: 78,
            startNumber: 0,
            padWidth: 1,
            titlePrefix: 'الكبيرة',
          ),
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/060-Mandhoumat_alkabair_alhajjawi.mp3',
          edition: BookAudioEdition.nadhm,
        ),
      ],
    ),

    // ── السيرة والتاريخ ────────────────────────────────────────
    'shamela_9820': MutunAudioEntry(
      bookId: 'shamela_9820',
      title: 'الرحيق المختوم في السيرة النبوية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.khazaen,
          audioUrl:
              'https://archive.org/download/022_20210927_202109/001.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/022_20210927_202109',
            count: 22,
            titlePrefix: 'المجلس',
            padWidth: 3,
          ),
        ),
      ],
    ),
    'shamela_21713': MutunAudioEntry(
      bookId: 'shamela_21713',
      title: 'زاد المعاد في هدي خير العباد',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl: 'https://archive.org/download/Zad_al-Ma3ad/01.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Zad_al-Ma3ad',
            count: 80,
            titlePrefix: 'المجلس',
            padWidth: 2,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/043.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 10,
            titlePrefix: 'جزء زاد المعاد',
            startNumber: 43,
            padWidth: 3,
          ),
        ),
      ],
    ),
    'shamela_31465': MutunAudioEntry(
      bookId: 'shamela_31465',
      title: 'مختصر سيرة الرسول ﷺ',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/064-Mokhtassar_sirat_annaby.mp3',
          fallbackUrl: '$_sawtiya/027-Sittat_mawadi_sira.mp3',
        ),
        HalibaAudiobooksCatalog.sourceFor('ishrun_seerah'),
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl: Uri.encodeFull(
              'https://archive.org/download/islami-352_202505/مختصر سيرة الرسول 1 من بداية الكتاب إلى المرحلة المكية للدعوة.mp3'),
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-352_202505',
            items: const [
              (
                file: 'مختصر سيرة الرسول 1 من بداية الكتاب إلى المرحلة المكية للدعوة.mp3',
                title: 'مختصر السيرة: من البداية إلى المرحلة المكية'
              ),
              (
                file: 'مختصر سيرة الرسول 2 من المرحلة المكية للدعوة إلى مقاطعة قريش بني هاشم.mp3',
                title: 'مختصر السيرة: إلى مقاطعة قريش بني هاشم'
              ),
              (
                file: 'مختصر سيرة الرسول 3 من مقاطعة قريش بني هاشم إلى فصل في الهجرة.mp3',
                title: 'مختصر السيرة: إلى فصل في الهجرة'
              ),
              (
                file: 'مختصر سيرة الرسول 4  فصل في الهجرة إلى المرحلة المدنية للدعوة الإسلامية.mp3',
                title: 'مختصر السيرة: فصل في الهجرة إلى المرحلة المدنية'
              ),
              (
                file: 'مختصر سيرة الرسول 5 المرحلة المدنية للدعوة الإسلامية إلى أسارى بدر.mp3',
                title: 'مختصر السيرة: المرحلة المدنية إلى أسارى بدر'
              ),
              (
                file: 'مختصر سيرة الرسول 6 أسارى بدر إلى حوادث السنة السابعة من الهجرة.mp3',
                title: 'مختصر السيرة: أسارى بدر إلى السنة السابعة'
              ),
              (
                file: 'مختصر سيرة الرسول 7  حوادث السنة السابعة من الهجرة إلى هدم الأوثان.mp3',
                title: 'مختصر السيرة: السنة السابعة إلى هدم الأوثان'
              ),
              (
                file: 'مختصر سيرة الرسول 8  هدم الأوثان إلى غزوة تبوك.mp3',
                title: 'مختصر السيرة: هدم الأوثان إلى غزوة تبوك'
              ),
              (
                file: 'مختصر سيرة الرسول 9  غزوة تبوك إلى نهاية الكتاب.mp3',
                title: 'مختصر السيرة: غزوة تبوك إلى نهاية الكتاب'
              ),
            ],
          ),
        ),
      ],
    ),

    // ── التفسير وعلوم القرآن ───────────────────────────────────
    'shamela_42': MutunAudioEntry(
      bookId: 'shamela_42',
      title: 'تيسير الكريم الرحمن في تفسير كلام المنان (تفسير السعدي)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.khazaen,
          audioUrl: 'https://archive.org/download/002_20210904/001.mp3',
          chapters: BookAudioChapter.fromTitles(
            baseUrl: 'https://archive.org/download/002_20210904',
            titles: _surahNames,
            padWidth: 3,
          ),
        ),
      ],
    ),
    'shamela_12081': const MutunAudioEntry(
      bookId: 'shamela_12081',
      title: 'مقدمة في أصول التفسير لابن تيمية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/092-Moqadimah_fi_osol_attafsir.mp3',
        ),
      ],
    ),
    'shamela_1969': MutunAudioEntry(
      bookId: 'shamela_1969',
      title: 'التبيان وآداب حملة القرآن',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.haliba,
          audioUrl:
              HalibaAudiobooksCatalog.items['fath_karim_mannan']!.cloudFrontUrl,
          fallbackUrl: HalibaAudiobooksCatalog
              .items['fath_karim_mannan']!.anchorFallbackUrl,
          edition: BookAudioEdition.mukhtasar,
          chapters: [
            BookAudioChapter(
              index: 1,
              title: HalibaAudiobooksCatalog.items['fath_karim_mannan']!.title,
              audioUrl: HalibaAudiobooksCatalog
                  .items['fath_karim_mannan']!.cloudFrontUrl,
              fallbackUrl: HalibaAudiobooksCatalog
                  .items['fath_karim_mannan']!.anchorFallbackUrl,
            ),
            BookAudioChapter(
              index: 2,
              title:
                  HalibaAudiobooksCatalog.items['akhlaq_hamalat_quran']!.title,
              audioUrl: HalibaAudiobooksCatalog
                  .items['akhlaq_hamalat_quran']!.cloudFrontUrl,
              fallbackUrl: HalibaAudiobooksCatalog
                  .items['akhlaq_hamalat_quran']!.anchorFallbackUrl,
            ),
          ],
        ),
      ],
    ),
    'shamela_23606': MutunAudioEntry(
      bookId: 'shamela_23606',
      title: 'فضائل القرآن ومعالمه وآدابه',
      sources: [
        HalibaAudiobooksCatalog.playlistSource(
          [
            'fadail_quran_sahihayn',
            'istighna_bil_quran',
            'fadail_quran_ibn_abdulwahhab',
          ],
        ),
      ],
    ),

    // ── أصول الفقه ─────────────────────────────────────────────
    'shamela_20892': const MutunAudioEntry(
      bookId: 'shamela_20892',
      title: 'مراقي السعود لمبتغي الرقي والصعود',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_osol_al-Fiqh/mraqi.mp3',
        ),
      ],
    ),
  };
}
