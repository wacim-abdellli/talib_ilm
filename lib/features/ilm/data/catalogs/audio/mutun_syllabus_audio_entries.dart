import '../../models/book_audio_models.dart';
import 'haliba_audiobooks_catalog.dart';
import 'ilm_audio_reciters.dart';
import 'mutun_advanced_audio_entries.dart';
import 'mutun_timestamps_data.dart';

class MutunSyllabusAudioEntries {
  const MutunSyllabusAudioEntries._();

  static const String archiveBaseUrl =
      'https://archive.org/download/Mottoon_Talib_Elm';
  static const String siniBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini';
  static const String shaydzmiSawtiyaUrl =
      'https://archive.org/download/Mutun_Sawtiya';
  static const String shaydzmiAqidahUrl =
      'https://archive.org/download/motoun_al3aqeedah';

  /// Alias map preventing duplicate entry definitions across variant book IDs.
  static const Map<String, String> aliases = {
    'bk_shurut_salah': 'bk_shuroot_salah',
    'bk_manzooma_bayquniyya': 'bk_manzumah_baiquoni',
    'bk_manzumah_bayquniyyah': 'bk_manzumah_baiquoni',
    'bk_ilbiri': 'bk_manzumah_albiri',
    'bk_ajrumiyya': 'bk_ajrumiyyah',
    'bk_wasitiyya': 'bk_wasitiyyah',
    'bk_unwan_alhikam': 'bk_unwan_al_hukm',
    'bk_rahbiyya': 'bk_rahibiyyah',
    'bk_tahawiyya': 'bk_aqidah_tahawiyyah',
    'bk_muqaddimah_jazariyyah': 'bk_jazariyyah',
  };

  static const List<String> _tuhfah11Titles = [
    'المقدمة', 'مقدمة التحفة', 'أحكام النون الساكنة والتنوين',
    'أحكام النون والميم المشددتين', 'أحكام الميم الساكنة',
    'حكم لام أل ولام الفعل', 'في المثلين والمتقاربين والمتجانسين',
    'أقسام المد', 'أحكام المد', 'أقسام المد اللازم', 'الخاتمة',
  ];

  static final Map<String, MutunAudioEntry> canonicalEntries = {
    // ── المستوى التمهيدي ──────────────────────────────────────
    'bk_adhkar_adab': MutunAudioEntry(
      bookId: 'bk_adhkar_adab',
      title: 'الآداب والأذكار',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0101AlAthkaar_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/03.mp3',
          totalParagraphs: 24,
          paragraphTimestamps: MutunTimestampsData.adhkarAdabSini,
        ),
        HalibaAudiobooksCatalog.sourceFor('hisn_muslim', totalParagraphs: 24),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/066-Hisn-almoslem.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/065-Athkar-assabah-walmassae.mp3',
          totalParagraphs: 24,
        ),
      ],
    ),

    // ── المستوى الأول ─────────────────────────────────────────
    'bk_nawaqid_islam': const MutunAudioEntry(
      bookId: 'bk_nawaqid_islam',
      title: 'نواقض الإسلام',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0203NawaaqidAlIslaam_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/04.mp3',
          totalParagraphs: 10,
          paragraphTimestamps: MutunTimestampsData.nawaqidIslamSini,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiAqidahUrl/nawaqid_al-islam_al-10.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/010-Nawaqid_al-islam_al-10.mp3',
          totalParagraphs: 10,
        ),
      ],
    ),
    'bk_qawaid_arba': const MutunAudioEntry(
      bookId: 'bk_qawaid_arba',
      title: 'القواعد الأربع',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0202AlQawaidAlArba_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/05.mp3',
          totalParagraphs: 8,
          paragraphTimestamps: MutunTimestampsData.qawaidArbaSini,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiAqidahUrl/qawaid_4.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/003-Qawaid_4.mp3',
          totalParagraphs: 8,
        ),
      ],
    ),
    'bk_usul_thalatha': const MutunAudioEntry(
      bookId: 'bk_usul_thalatha',
      title: 'ثلاثة الأصول وأدلتها',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0201AlUsulAtThalaath_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/06.mp3',
          totalParagraphs: 28,
          paragraphTimestamps: MutunTimestampsData.usulThalathaSini,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiAqidahUrl/osoul_3.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/001-Osoul_3.mp3',
          totalParagraphs: 28,
        ),
      ],
    ),
    'bk_arbaeen_nawawi': MutunAudioEntry(
      bookId: 'bk_arbaeen_nawawi',
      title: 'الأربعون النووية',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0204AlArbaunAnNawawiyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/07.mp3',
          totalParagraphs: 42,
          paragraphTimestamps: MutunTimestampsData.arbaeenNawawiSini,
        ),
        HalibaAudiobooksCatalog.sourceFor(
          'arbaeen_nawawi',
          totalParagraphs: 42,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/068-Arbaoun-nawawiah.mp3',
          fallbackUrl: '$archiveBaseUrl/07.mp3',
          totalParagraphs: 42,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.wazzan,
          audioUrl: 'https://archive.org/download/NAWWE/nawawi01.mp3',
          totalParagraphs: 42,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/NAWWE',
            count: 42,
            titlePrefix: 'الحديث',
            filePrefix: 'nawawi',
            padWidth: 2,
          ),
        ),
      ],
    ),

    // ── المستوى الثاني ─────────────────────────────────────────
    'bk_tuhfat_atfal': MutunAudioEntry(
      bookId: 'bk_tuhfat_atfal',
      title: 'تحفة الأطفال في تجويد القرآن',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0301ThufatUlAtfaal_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/08.mp3',
          totalParagraphs: 61,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_Tajweed/tohfa.mp3',
          fallbackUrl: '$archiveBaseUrl/08.mp3',
          totalParagraphs: 61,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/091-Tohfat_al-atfaal.mp3',
          fallbackUrl: '$archiveBaseUrl/08.mp3',
          totalParagraphs: 61,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.ghamdi,
          audioUrl:
              'https://archive.org/download/Matn_Tohfat_Atfal_uP_bY_mUSLEm/001_uP_bY_mUSLEm.mp3',
          totalParagraphs: 61,
          chapters: BookAudioChapter.fromTitles(
            baseUrl:
                'https://archive.org/download/Matn_Tohfat_Atfal_uP_bY_mUSLEm',
            titles: _tuhfah11Titles,
            padWidth: 3,
            fileSuffix: '_uP_bY_mUSLEm.mp3',
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.sunaid,
          audioUrl:
              'https://archive.org/download/4.Matn_Tohfat_Atfal_uP_bY_mUSLEm/001_uP_bY_mUSLEm.mp3',
          totalParagraphs: 61,
          chapters: BookAudioChapter.fromTitles(
            baseUrl:
                'https://archive.org/download/4.Matn_Tohfat_Atfal_uP_bY_mUSLEm',
            titles: _tuhfah11Titles,
            padWidth: 3,
            fileSuffix: '_uP_bY_mUSLEm.mp3',
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.hashem,
          audioUrl:
              'https://archive.org/download/2.Matn_Tohfat_Atfal_uP_bY_mUSLEm/01_uP_bY_mUSLEm.mp3',
          totalParagraphs: 61,
          chapters: BookAudioChapter.fromTitles(
            baseUrl:
                'https://archive.org/download/2.Matn_Tohfat_Atfal_uP_bY_mUSLEm',
            titles: const [
              'المقدمة', 'أحكام النون الساكنة والتنوين',
              'أحكام النون والميم المشددتين', 'أحكام الميم الساكنة',
              'حكم لام أل ولام الفعل', 'في المثلين والمتقاربين والمتجانسين',
              'أقسام المد', 'أحكام المد', 'أقسام المد اللازم', 'الخاتمة',
            ],
            padWidth: 2,
            fileSuffix: '_uP_bY_mUSLEm.mp3',
          ),
        ),
      ],
    ),
    'bk_shuroot_salah': const MutunAudioEntry(
      bookId: 'bk_shuroot_salah',
      title: 'شروط الصلاة وأركانها وواجباتها',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0302ShurutAsSalaah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/09.mp3',
          totalParagraphs: 14,
          paragraphTimestamps: MutunTimestampsData.shurootSalahSini,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/002-Chorout-assalah.mp3',
          fallbackUrl: '$archiveBaseUrl/09.mp3',
          totalParagraphs: 14,
        ),
      ],
    ),
    'bk_kitab_tawheed': MutunAudioEntry(
      bookId: 'bk_kitab_tawheed',
      title: 'كتاب التوحيد',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0303KitaabAtTawheed_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/10.mp3',
          totalParagraphs: 67,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/007-Ketab_attawheed_lite.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/008-Ketab_tawheed_full.mp3',
          totalParagraphs: 67,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shuwaihi,
          audioUrl:
              'https://archive.org/download/Kitab_Tawheed_Shuwaihi/01.mp3',
          totalParagraphs: 67,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Kitab_Tawheed_Shuwaihi',
            count: 67,
            titlePrefix: 'باب',
            padWidth: 2,
          ),
        ),
      ],
    ),
    'bk_kashf_shubuhat': const MutunAudioEntry(
      bookId: 'bk_kashf_shubuhat',
      title: 'كشف الشبهات',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/009-Kashf-ash-shobohaat.mp3',
          totalParagraphs: 20,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.faqeeh,
          audioUrl:
              'https://files.a-alqasim.com/audio/Mutoon/AbdulGhaniSaadiqAlFaqeeh/0804Kashf_AbdulGhaniSaadiqAlFaqeeh.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/009-Kashf-ash-shobohaat.mp3',
          totalParagraphs: 20,
        ),
      ],
    ),

    // ── المستوى الثالث ─────────────────────────────────────────
    'bk_manzumah_baiquoni': const MutunAudioEntry(
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
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/072-Baykouniah.mp3',
          fallbackUrl: '$archiveBaseUrl/11.mp3',
          totalParagraphs: 34,
        ),
      ],
    ),
    'bk_manzumah_albiri': MutunAudioEntry(
      bookId: 'bk_manzumah_albiri',
      title: 'منظومة أبي إسحاق الإلبيري',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0402AlIlbiri_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/12.mp3',
          totalParagraphs: 25,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.nafees,
          audioUrl: Uri.encodeFull(
            'https://archive.org/download/20250702_20250702_1109/تائية الإلبيري منظومة أبي إسحاق الإلبيري  أحمد النفيس.mp3',
          ),
          fallbackUrl: '$archiveBaseUrl/12.mp3',
          totalParagraphs: 25,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.badr,
          audioUrl:
              'https://archive.org/download/fawaid_011_201510/01%20(1).mp3',
          edition: BookAudioEdition.sharhMajalis,
          totalParagraphs: 25,
          chapters: List<BookAudioChapter>.unmodifiable([
            for (int i = 1; i <= 9; i++)
              BookAudioChapter(
                index: i,
                title: 'الفائدة المختارة $i من شرح تائية الإلبيري',
                audioUrl:
                    'https://archive.org/download/fawaid_011_201510/01%20($i).mp3',
              ),
          ]),
        ),
      ],
    ),
    'bk_ajrumiyyah': MutunAudioEntry(
      bookId: 'bk_ajrumiyyah',
      title: 'الآجرومية',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0403AlAajurrumiyyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/13.mp3',
          totalParagraphs: 30,
          paragraphTimestamps: MutunTimestampsData.ajrumiyyahSini,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/085-Ajroumiah.mp3',
          fallbackUrl: '$archiveBaseUrl/13.mp3',
          totalParagraphs: 30,
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_al-Arabiya/ajromyah.mp3',
          fallbackUrl: 'https://archive.org/download/Mutun_al-Arabiya/abb.mp3',
          edition: BookAudioEdition.nadhm,
          totalParagraphs: 30,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.nashmi,
          audioUrl:
              'https://archive.org/download/Al_Ajromia_uP_bY_mUSLEm/01_uP_bY_mUSLEm.mp3',
          totalParagraphs: 30,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Al_Ajromia_uP_bY_mUSLEm',
            count: 33,
            titlePrefix: 'باب الآجرومية',
            padWidth: 2,
            fileSuffix: '_uP_bY_mUSLEm.mp3',
          ),
        ),
      ],
    ),
    'bk_wasitiyyah': const MutunAudioEntry(
      bookId: 'bk_wasitiyyah',
      title: 'العقيدة الواسطية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0404AlWaasitiyyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/14.mp3',
          totalParagraphs: 35,
          paragraphTimestamps: MutunTimestampsData.wasitiyyahSini,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiAqidahUrl/alwassitiah.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/041-Alwassitiah.mp3',
          totalParagraphs: 35,
        ),
      ],
    ),

    // ── المستوى الرابع ─────────────────────────────────────────
    'bk_waraqat': const MutunAudioEntry(
      bookId: 'bk_waraqat',
      title: 'الورقات في أصول الفقه',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0501AlWaraqat_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/15.mp3',
          totalParagraphs: 22,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/083-Matn-alwaraqaat.mp3',
          fallbackUrl: '$archiveBaseUrl/15.mp3',
          totalParagraphs: 22,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_osol_al-Fiqh/waraqat.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/082-Nadhm_alwaraqat_al-amrity.mp3',
          edition: BookAudioEdition.nadhm,
          totalParagraphs: 22,
        ),
      ],
    ),
    'bk_unwan_al_hukm': MutunAudioEntry(
      bookId: 'bk_unwan_al_hukm',
      title: 'عنوان الحكم',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0502UnwanAlHikm_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/16.mp3',
          totalParagraphs: 20,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.badr,
          audioUrl:
              'https://archive.org/download/Sharh_Kasidat_Ounwan_Hekam/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          totalParagraphs: 20,
          chapters: BookAudioChapter.fromTitles(
            baseUrl: 'https://archive.org/download/Sharh_Kasidat_Ounwan_Hekam',
            titles: const [
              'المجلس الأول: الأبيات ١ - ١٩',
              'المجلس الثاني: الأبيات ٢٠ - ٤١',
              'المجلس الثالث: الأبيات ٤٢ - ٦٣',
            ],
            padWidth: 2,
          ),
        ),
      ],
    ),
    'bk_rahibiyyah': const MutunAudioEntry(
      bookId: 'bk_rahibiyyah',
      title: 'الرحبية في علم الفرائض',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0503ArRahbiyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/17.mp3',
          totalParagraphs: 30,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl: 'https://archive.org/download/Mutun_al-Fiqh/rahbeya.mp3',
          fallbackUrl: '$archiveBaseUrl/17.mp3',
          totalParagraphs: 30,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiSawtiyaUrl/084-Arrahbiyah.mp3',
          fallbackUrl: '$archiveBaseUrl/17.mp3',
          totalParagraphs: 30,
        ),
      ],
    ),
    'bk_aqidah_tahawiyyah': const MutunAudioEntry(
      bookId: 'bk_aqidah_tahawiyyah',
      title: 'العقيدة الطحاوية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0504AtTahawiyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/18.mp3',
          totalParagraphs: 50,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$shaydzmiAqidahUrl/tahawiyah_40kb.mp3',
          fallbackUrl: '$shaydzmiSawtiyaUrl/042-Tahawiyah.mp3',
          totalParagraphs: 50,
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fahad,
          audioUrl:
              'https://archive.org/download/Mutun_al-Aqida/altahaweya.mp3',
          edition: BookAudioEdition.nadhm,
          totalParagraphs: 50,
        ),
      ],
    ),

    ...MutunAdvancedAudioEntries.entries,
  };
}
