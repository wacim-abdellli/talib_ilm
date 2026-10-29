import '../../models/book_audio_models.dart';
import 'haliba_audiobooks_catalog.dart';
import 'ilm_audio_reciters.dart';

/// Advanced mutawalat and major poetic systems audio catalog (< 400 lines).
class MutunAdvancedAudioEntries {
  const MutunAdvancedAudioEntries._();

  static const String siniBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini';
  static const String shaydzmiSawtiyaUrl =
      'https://archive.org/download/Mutun_Sawtiya';

  static const List<String> _bulughMaramTitles = [
    'كتاب الطهارة (١)', 'كتاب الطهارة (٢)', 'كتاب الصلاة (١)', 'كتاب الصلاة (٢)',
    'كتاب الجنائز', 'كتاب الزكاة', 'كتاب الصيام', 'كتاب الحج',
    'كتاب البيوع (١)', 'كتاب البيوع (٢)', 'كتاب النكاح', 'كتاب الطلاق',
    'كتاب الجنايات', 'كتاب الحدود', 'كتاب الجهاد', 'كتاب الأطعمة',
    'كتاب الأيمان والنذور', 'كتاب القضاء', 'كتاب العتق', 'كتاب الجامع',
  ];
  static const List<String> _zadMustaqniTitles = [
    'المقدمة', 'كتاب الطهارة', 'كتاب الصلاة', 'كتاب الجنائز', 'كتاب الزكاة',
    'كتاب الصيام', 'كتاب المناسك', 'كتاب الجهاد', 'كتاب البيع', 'كتاب الغصب',
    'كتاب الوقف', 'كتاب الوصايا', 'كتاب الفرائض', 'كتاب العتق', 'كتاب النكاح',
    'كتاب الطلاق', 'كتاب الإيلاء', 'كتاب الظهار', 'كتاب اللعان', 'كتاب العِدد',
    'كتاب الرضاع', 'كتاب النفقات', 'كتاب الجنايات', 'كتاب الديات',
    'كتاب الحدود', 'كتاب الأطعمة', 'كتاب الأيمان', 'كتاب القضاء',
    'كتاب الشهادات', 'كتاب الإقرار',
  ];

  static const List<String> _jazariyyah17Titles = [
    'مقدمة المتن', 'باب مخارج الحروف', 'باب الصفات', 'باب التجويد',
    'باب التفخيم والترقيق', 'باب الراءات', 'باب اللامات',
    'باب الإدغام والإظهار', 'باب الضاد والظاء',
    'باب الميم والنون المشددتين والميم الساكنة',
    'باب حكم التنوين والنون الساكنة', 'باب المد والقصر', 'باب معرفة الوقوف',
    'باب المقطوع والموصول وحكم التاء', 'باب التاءات', 'باب همز الوصل',
    'الخاتمة',
  ];

  static final Map<String, MutunAudioEntry> entries = {
    'bk_bulugh_maram': MutunAudioEntry(
      bookId: 'bk_bulugh_maram',
      title: 'بلوغ المرام من أدلة الأحكام',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: 'https://archive.org/download/Boulough_al-Maram/01.mp3',
          fallbackUrl: '$siniBaseUrl/0601Buloogh_AbdulAzizAsSini.mp3',
          totalParagraphs: 120,
          chapters: BookAudioChapter.fromTitles(
            baseUrl: 'https://archive.org/download/Boulough_al-Maram',
            titles: _bulughMaramTitles,
            padWidth: 2,
          ),
        ),
      ],
    ),
    'bk_zad_mustaqni': MutunAudioEntry(
      bookId: 'bk_zad_mustaqni',
      title: 'زاد المستقنع في اختصار المقنع',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: 'https://archive.org/download/Al-Zaad/00.mp3',
          fallbackUrl:
              '$siniBaseUrl/0602Zaad/0602Zaad_01_KitaabAtTahaarah_AbdulAzizAsSini.mp3',
          totalParagraphs: 140,
          chapters: BookAudioChapter.fromTitles(
            baseUrl: 'https://archive.org/download/Al-Zaad',
            titles: _zadMustaqniTitles,
            startNumber: 0,
            padWidth: 2,
          ),
        ),
      ],
    ),
    'bk_jawhar_maknoon': const MutunAudioEntry(
      bookId: 'bk_jawhar_maknoon',
      title: 'الجوهر المكنون في صدف الثلاثة الفنون',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_al-Arabiya/aljawhar.mp3',
          totalParagraphs: 50,
        ),
      ],
    ),
    'bk_nokhbat_al_fikar': const MutunAudioEntry(
      bookId: 'bk_nokhbat_al_fikar',
      title: 'نخبة الفكر في مصطلح أهل الأثر',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/071-Nokhbat_al-fikr.mp3',
          totalParagraphs: 35,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_elm_al-Hadeeth/nokbatulfeekar.mp3',
          edition: BookAudioEdition.nadhm,
          totalParagraphs: 35,
        ),
      ],
    ),
    'bk_alfiyyah_ibn_malik': MutunAudioEntry(
      bookId: 'bk_alfiyyah_ibn_malik',
      title: 'ألفية ابن مالك في النحو والتصريف',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_al-Arabiya/ebnmalek.mp3',
          totalParagraphs: 100,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.ayouni,
          audioUrl: 'https://archive.org/download/Alfiyat_ibn-Malik/01.mp3',
          totalParagraphs: 100,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Alfiyat_ibn-Malik',
            count: 85,
            titlePrefix: 'باب',
            padWidth: 2,
          ),
        ),
      ],
    ),
    'bk_shatibiyyah': MutunAudioEntry(
      bookId: 'bk_shatibiyyah',
      title: 'حرز الأماني ووجه التهاني (الشاطبية)',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.suwaid,
          audioUrl:
              'https://archive.org/download/sh-ayman-sowaid-matn-ashshatebiih/00.mp3',
          fallbackUrl:
              'https://archive.org/download/Mutun_kiraat_mujtami3a/shatbeya.mp3',
          totalParagraphs: 110,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_kiraat_mujtami3a/shatbeya.mp3',
          fallbackUrl:
              'https://archive.org/download/Moutoun_Tajwid_uP_bY_mUSLEm/032-_up_by_muslem.mp3',
          totalParagraphs: 110,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.afasy,
          audioUrl:
              'https://archive.org/download/Chatibia_uP_bY_mUSLEm/01_uP_bY_mUSLEm.mp3',
          totalParagraphs: 110,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Chatibia_uP_bY_mUSLEm',
            count: 78,
            titlePrefix: 'باب الشاطبية',
            padWidth: 2,
            fileSuffix: '_uP_bY_mUSLEm.mp3',
          ),
        ),
      ],
    ),
    'bk_jazariyyah': MutunAudioEntry(
      bookId: 'bk_jazariyyah',
      title: 'المقدمة الجزرية في التجويد',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.suwaid,
          audioUrl:
              'https://archive.org/download/sh-ayman-sowaid-matn-aljazareiiah/00.mp3',
          fallbackUrl: 'https://archive.org/download/Mutun_Tajweed/jazarya.mp3',
          totalParagraphs: 109,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_Tajweed/jazarya.mp3',
          totalParagraphs: 109,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.ghamdi,
          audioUrl:
              'https://archive.org/download/Matn_Jazaria_uP_bY_mUSLEm/001_uP_bY_mUSLEm.mp3',
          totalParagraphs: 109,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Matn_Jazaria_uP_bY_mUSLEm',
            count: 20,
            titlePrefix: 'باب الجزرية',
            padWidth: 3,
            fileSuffix: '_uP_bY_mUSLEm.mp3',
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunaid,
          audioUrl:
              'https://archive.org/download/2.Matn_Jazaria_uP_bY_mUSLEm/001_uP_bY_mUSLEm.mp3',
          totalParagraphs: 109,
          chapters: BookAudioChapter.fromTitles(
            baseUrl: 'https://archive.org/download/2.Matn_Jazaria_uP_bY_mUSLEm',
            titles: _jazariyyah17Titles,
            padWidth: 3,
            fileSuffix: '_uP_bY_mUSLEm.mp3',
          ),
        ),
      ],
    ),
    'bk_umdat_ahkam': MutunAudioEntry(
      bookId: 'bk_umdat_ahkam',
      title: 'عمدة الأحكام من كلام خير الأنام',
      sources: [
        HalibaAudiobooksCatalog.sourceFor('umdat_ahkam', totalParagraphs: 85),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/069-Omdat-al-ahkam-01.mp3',
          totalParagraphs: 85,
          chapters: BookAudioChapter.numbered(
            baseUrl: shaydzmiSawtiyaUrl,
            count: 8,
            titlePrefix: 'الجزء',
            filePrefix: '069-Omdat-al-ahkam-',
            padWidth: 2,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0802AlUmdatuFilAhkaam_AbdulAzizAsSini.mp3',
          fallbackUrl:
              HalibaAudiobooksCatalog.items['umdat_ahkam']!.cloudFrontUrl,
          totalParagraphs: 85,
        ),
      ],
    ),
    'bk_qawaid_fiqhiyya': const MutunAudioEntry(
      bookId: 'bk_qawaid_fiqhiyya',
      title: 'منظومة القواعد الفقهية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl:
              '$shaydzmiSawtiyaUrl/078-Mandhoumat_al-qawid_al-fiqhiyah_as-saady.mp3',
          fallbackUrl:
              'https://archive.org/download/shaydzmi111/Mandhoumat_al-qawid_al-fiqhiyah_As-saady.mp3',
          totalParagraphs: 18,
        ),
      ],
    ),
    'bk_lamiyyat_al_afal': const MutunAudioEntry(
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
}
