import '../../models/book_audio_models.dart';
import 'ilm_audio_reciters.dart';
import 'mutun_timestamps_data.dart';

class MutunSyllabusAudioEntries {
  const MutunSyllabusAudioEntries._();

  static const String archiveBaseUrl =
      'https://archive.org/download/Mottoon_Talib_Elm';
  static const String siniBaseUrl =
      'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini';

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
  };

  static const Map<String, MutunAudioEntry> canonicalEntries = {
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
          paragraphTimestamps: MutunTimestampsData.adhkarAdabSini,
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
          paragraphTimestamps: MutunTimestampsData.nawaqidIslamSini,
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
          paragraphTimestamps: MutunTimestampsData.qawaidArbaSini,
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
          paragraphTimestamps: MutunTimestampsData.usulThalathaSini,
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
          paragraphTimestamps: MutunTimestampsData.arbaeenNawawiSini,
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
          paragraphTimestamps: MutunTimestampsData.shurootSalahSini,
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
    'bk_ajrumiyyah': MutunAudioEntry(
      bookId: 'bk_ajrumiyyah',
      title: 'الآجرومية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.sini,
          audioUrl: '$siniBaseUrl/0403AlAajurrumiyyah_AbdulAzizAsSini.mp3',
          fallbackUrl: '$archiveBaseUrl/13.mp3',
          totalParagraphs: 30,
          paragraphTimestamps: MutunTimestampsData.ajrumiyyahSini,
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
          paragraphTimestamps: MutunTimestampsData.wasitiyyahSini,
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
}
