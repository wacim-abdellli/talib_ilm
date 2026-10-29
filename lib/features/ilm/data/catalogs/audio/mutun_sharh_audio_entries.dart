import '../../models/book_audio_models.dart';
import 'ilm_audio_reciters.dart';

/// Scholarly commentary (شروح صوتية علمية) audio sources mapped to syllabus mutun (< 420 lines).
/// Merged into canonical entries via [MutunAudioEntry.withExtraSources].
class MutunSharhAudioEntries {
  const MutunSharhAudioEntries._();

  static final Map<String, List<MatnAudioSource>> extraSharhSources = {
    // ── ثلاثة الأصول ──────────────────────────────────────────
    'bk_usul_thalatha': [
      MatnAudioSource(
        reciter: MutunReciterDefaults.fawzan,
        audioUrl:
            'https://archive.org/download/Thalathat-Usul-Fawzan/3Usul01.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.numbered(
          baseUrl: 'https://archive.org/download/Thalathat-Usul-Fawzan',
          count: 10,
          titlePrefix: 'درس ثلاثة الأصول',
          filePrefix: '3Usul',
          padWidth: 2,
        ),
      ),
      MatnAudioSource(
        reciter: MutunReciterDefaults.uthaymin,
        audioUrl:
            'https://archive.org/download/thalathah_alosool_othaimeen_C_03/thalathah_alosool_othaimeen_C_01.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.numbered(
          baseUrl:
              'https://archive.org/download/thalathah_alosool_othaimeen_C_03',
          count: 3,
          titlePrefix: 'شرح الأصول الثلاثة مجلس',
          filePrefix: 'thalathah_alosool_othaimeen_C_',
          padWidth: 2,
        ),
      ),
    ],

    // ── كتاب التوحيد ──────────────────────────────────────────
    'bk_kitab_tawheed': [
      MatnAudioSource(
        reciter: MutunReciterDefaults.uthaymin,
        audioUrl: 'https://archive.org/download/ibnOthaimeen-Kawl/01.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.numbered(
          baseUrl: 'https://archive.org/download/ibnOthaimeen-Kawl',
          count: 54,
          titlePrefix: 'القول المفيد مجلس',
          padWidth: 2,
        ),
      ),
      MatnAudioSource(
        reciter: MutunReciterDefaults.salihAlShaykh,
        audioUrl:
            'https://archive.org/download/Saleh_Al-Sheikh_19/01.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.numbered(
          baseUrl: 'https://archive.org/download/Saleh_Al-Sheikh_19',
          count: 45,
          titlePrefix: 'شرح فتح المجيد مجلس',
          padWidth: 2,
        ),
      ),
    ],

    // ── الأربعون النووية ──────────────────────────────────────
    'bk_arbaeen_nawawi': [
      MatnAudioSource(
        reciter: MutunReciterDefaults.badr,
        audioUrl:
            'https://archive.org/download/char7-arba3in-al-badr/01.hadith1.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.fromFiles(
          baseUrl: 'https://archive.org/download/char7-arba3in-al-badr',
          items: const [
            (file: '00.moukadima.mp3', title: 'المقدمة والمدخل لشرح الأربعين'),
            (file: '01.hadith1.mp3', title: 'الحديث الأول: إنما الأعمال بالنيات'),
            (file: '02a.mp3', title: 'الحديث الثاني (١): مراتب الدين والإسلام'),
            (file: '02b.mp3', title: 'الحديث الثاني (٢): أركان الإيمان'),
            (file: '02c.mp3', title: 'الحديث الثاني (٣): الإحسان وأشراط الساعة'),
            (file: '02d.mp3', title: 'الحديث الثاني (٤): فوائد حديث جبريل'),
            (file: '03.hadith3.mp3', title: 'الحديث الثالث: بني الإسلام على خمس'),
            (file: '04.hadith4.mp3', title: 'الحديث الرابع: إن أحدكم يجمع خلقه'),
            (file: '05.hadith5.mp3', title: 'الحديث الخامس: من أحدث في أمرنا هذا'),
            (file: '06.hadith6.mp3', title: 'الحديث السادس: الحلال بين والحرام بين'),
            (file: '07.hadith7.mp3', title: 'الحديث السابع: الدين النصيحة'),
            (file: '08.hadith8.mp3', title: 'الحديث الثامن: أمرت أن أقاتل الناس'),
            (file: '09.hadith9.mp3', title: 'الحديث التاسع: ما نهيتكم عنه فاجتنبوه'),
            (file: '10.hadith10.mp3', title: 'الحديث العاشر: إن الله طيب لا يقبل إلا طيبا'),
            (file: '11.hadith11.mp3', title: 'الحديث الحادي عشر: دع ما يريبك إلى ما لا يريبك'),
            (file: '12.hadith12.mp3', title: 'الحديث الثاني عشر: من حسن إسلام المرء'),
            (file: '13.hadith13.mp3', title: 'الحديث الثالث عشر: لا يؤمن أحدكم حتى يحب لأخيه'),
            (file: '14.hadith14.mp3', title: 'الحديث الرابع عشر: لا يحل دم امرئ مسلم'),
            (file: '15.hadith15.mp3', title: 'الحديث الخامس عشر: من كان يؤمن بالله واليوم الآخر'),
            (file: '16.hadith16.mp3', title: 'الحديث السادس عشر: لا تغضب'),
            (file: '17.hadith17.mp3', title: 'الحديث السابع عشر: إن الله كتب الإحسان'),
            (file: '18.hadith18.mp3', title: 'الحديث الثامن عشر: اتق الله حيثما كنت'),
            (file: '19.hadith19.mp3', title: 'الحديث التاسع عشر: احفظ الله يحفظك'),
            (file: '20.hadith20.mp3', title: 'الحديث العشرون: إذا لم تستح فاصنع ما شئت'),
            (file: '21.hadith21.mp3', title: 'الحديث الحادي والعشرون: قل آمنت بالله ثم استقم'),
            (file: '22.hadith22.mp3', title: 'الحديث الثاني والعشرون: أرأيت إذا صليت المكتوبات'),
            (file: '23.hadith23.mp3', title: 'الحديث الثالث والعشرون: الطهور شطر الإيمان'),
            (file: '24.hadith24.mp3', title: 'الحديث الرابع والعشرون: يا عبادي إني حرمت الظلم'),
            (file: '25.hadith25.mp3', title: 'الحديث الخامس والعشرون: ذهب أهل الدثور بالأجور'),
            (file: '26.hadith26.mp3', title: 'الحديث السادس والعشرون: كل سلامى من الناس عليه صدقة'),
            (file: '27.hadith27.mp3', title: 'الحديث السابع والعشرون: البر حسن الخلق'),
            (file: '28.hadith28.mp3', title: 'الحديث الثامن والعشرون: أوصيكم بتقوى الله'),
            (file: '29.hadith29.mp3', title: 'الحديث التاسع والعشرون: دلني على عمل يدخلني الجنة'),
            (file: '30.hadith30.mp3', title: 'الحديث الثلاثون: إن الله فرض فرائض فلا تضيعوها'),
            (file: '31.hadith31.mp3', title: 'الحديث الحادي والثلاثون: ازهد في الدنيا يحبك الله'),
            (file: '32.hadith32.mp3', title: 'الحديث الثاني والثلاثون: لا ضرر ولا ضرار'),
            (file: '33.hadith33.mp3', title: 'الحديث الثالث والثلاثون: لو يعطى الناس بدعواهم'),
            (file: '34.hadith34.mp3', title: 'الحديث الرابع والثلاثون: من رأى منكم منكرا'),
            (file: '35.hadith35.mp3', title: 'الحديث الخامس والثلاثون: لا تحاسدوا ولا تباغضوا'),
            (file: '36.hadith36.mp3', title: 'الحديث السادس والثلاثون: من نفس عن مؤمن كربة'),
            (file: '37.hadith37.mp3', title: 'الحديث السابع والثلاثون: إن الله كتب الحسنات والسيئات'),
            (file: '38.hadith38.mp3', title: 'الحديث الثامن والثلاثون: من عادى لي وليا'),
            (file: '39.hadith39.mp3', title: 'الحديث التاسع والثلاثون: إن الله تجاوز لي عن أمتي'),
            (file: '40.hadith40.mp3', title: 'الحديث الأربعون: كن في الدنيا كأنك غريب'),
            (file: '41.hadith41.mp3', title: 'الحديث الحادي والأربعون: لا يؤمن أحدكم حتى يكون هواه تبعا'),
            (file: '42.hadith42.mp3', title: 'الحديث الثاني والأربعون: يا ابن آدم إنك ما دعوتني ورجوتني'),
          ],
        ),
      ),
    ],


    // ── المنظومة البيقونية ────────────────────────────────────
    'bk_manzumah_baiquoni': [
      MatnAudioSource(
        reciter: MutunReciterDefaults.uthaymin,
        audioUrl: Uri.encodeFull(
            'https://archive.org/download/05AlMandhomahAlBayqoneyahBinOthaimeen/01  Al-Mandhomah Al-Bayqoneyah - Bin Othaimeen.mp3'),
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.fromFiles(
          baseUrl:
              'https://archive.org/download/05AlMandhomahAlBayqoneyahBinOthaimeen',
          items: const [
            (
              file: '01  Al-Mandhomah Al-Bayqoneyah - Bin Othaimeen.mp3',
              title: 'الدرس الأول: تعريف الحديث الصحيح والحسن'
            ),
            (
              file: '02  Al-Mandhomah Al-Bayqoneyah - Bin Othaimeen.mp3',
              title: 'الدرس الثاني: الضعيف والمرفوع والموقوف'
            ),
            (
              file: '03  Al-Mandhomah Al-Bayqoneyah - Bin Othaimeen.mp3',
              title: 'الدرس الثالث: المسند والمتصل والمسلسل'
            ),
            (
              file: '04  Al-Mandhomah Al-Bayqoneyah - Bin Othaimeen.mp3',
              title: 'الدرس الرابع: العزيز والمشهور والمعنعن'
            ),
            (
              file: '05  Al-Mandhomah Al-Bayqoneyah - Bin Othaimeen.mp3',
              title: 'الدرس الخامس: المبهم والغريب والمنقطع'
            ),
            (
              file: '06  Al-Mandhomah Al-Bayqoneyah - Bin Othaimeen.mp3',
              title: 'الدرس السادس: المعضل والمنكر والمتروك'
            ),
            (
              file: '07  Al-Mandhomah Al-Bayqoneyah - Bin Othaimeen.mp3',
              title: 'الدرس السابع: الموضوع والخاتمة'
            ),
          ],
        ),
      ),
    ],

    // ── الآجرومية ─────────────────────────────────────────────
    'bk_ajrumiyyah': [
      MatnAudioSource(
        reciter: MutunReciterDefaults.uthaymin,
        audioUrl:
            'https://archive.org/download/Alajromiyah_2_Othaimeen/01.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.numbered(
          baseUrl: 'https://archive.org/download/Alajromiyah_2_Othaimeen',
          count: 16,
          titlePrefix: 'شرح الآجرومية درس',
          padWidth: 2,
        ),
      ),
    ],

    // ── الورقات في أصول الفقه ─────────────────────────────────
    'bk_waraqat': [
      MatnAudioSource(
        reciter: MutunReciterDefaults.khamis,
        audioUrl:
            'https://archive.org/download/Fikh_12_uP_bY_mUSLEm/01.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.numbered(
          baseUrl: 'https://archive.org/download/Fikh_12_uP_bY_mUSLEm',
          count: 5,
          titlePrefix: 'شرح الورقات مجلس',
          padWidth: 2,
        ),
      ),
    ],

    // ── العقيدة الواسطية ──────────────────────────────────────
    'bk_wasitiyyah': [
      MatnAudioSource(
        reciter: MutunReciterDefaults.uthaymin,
        audioUrl: 'https://archive.org/download/wasiteyyah/01a.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.numbered(
          baseUrl: 'https://archive.org/download/wasiteyyah',
          count: 33,
          titlePrefix: 'شرح الواسطية مجلس',
          padWidth: 2,
          fileSuffix: 'a.mp3',
        ),
      ),
    ],

    // ── العقيدة الطحاوية ──────────────────────────────────────
    'bk_aqidah_tahawiyyah': [
      MatnAudioSource(
        reciter: MutunReciterDefaults.badr,
        audioUrl:
            'https://archive.org/download/Sharh_Tahawiya_al-Badr/01.mp3',
        edition: BookAudioEdition.sharh,
        chapters: BookAudioChapter.numbered(
          baseUrl: 'https://archive.org/download/Sharh_Tahawiya_al-Badr',
          count: 22,
          titlePrefix: 'شرح الطحاوية مجلس',
          padWidth: 2,
        ),
      ),
    ],
  };
}
