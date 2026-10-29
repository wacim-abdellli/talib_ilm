import '../../models/book_audio_models.dart';
import 'ilm_audio_reciters.dart';

/// Audio catalog for Fiqh, Nahw, Aqidah, and Seerah Shamela books (< 580 lines).
class TurathFiqhNahwSeerahAudioEntries {
  const TurathFiqhNahwSeerahAudioEntries._();

  static const String _sawtiya =
      'https://archive.org/download/Mutun_Sawtiya';

  static final Map<String, MutunAudioEntry> entries = {
    // ── العقيدة والتوحيد (شروح) ───────────────────────────────

    /// أصول الإيمان لابن عبد الوهاب
    'shamela_30847': MutunAudioEntry(
      bookId: 'shamela_30847',
      title: 'أصول الإيمان لمحمد بن عبد الوهاب',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.salihAlShaykh,
          audioUrl:
              'https://archive.org/download/Saleh_Al-Sheikh_23/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Saleh_Al-Sheikh_23',
            count: 23,
            titlePrefix: 'شرح أصول الإيمان',
            padWidth: 2,
          ),
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/012-Ossoul_al-iman_mohamed_ibn_abd-alwahhab.mp3',
        ),
      ],
    ),

    /// فتح المجيد شرح كتاب التوحيد
    'shamela_2386': MutunAudioEntry(
      bookId: 'shamela_2386',
      title: 'فتح المجيد شرح كتاب التوحيد',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.salihAlShaykh,
          audioUrl:
              'https://archive.org/download/Saleh_Al-Sheikh_19/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Saleh_Al-Sheikh_19',
            count: 45,
            titlePrefix: 'شرح فتح المجيد',
            padWidth: 2,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fawzan,
          audioUrl:
              'https://archive.org/download/Sharh__Fath_Almajeed/001.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Sharh__Fath_Almajeed',
            count: 89,
            titlePrefix: 'درس فتح المجيد',
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// القول السديد شرح كتاب التوحيد
    'shamela_8529': MutunAudioEntry(
      bookId: 'shamela_8529',
      title: 'القول السديد في مقاصد التوحيد',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.badr,
          audioUrl: 'https://archive.org/download/Al-kawl_Sadeed/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Al-kawl_Sadeed',
            count: 45,
            titlePrefix: 'شرح القول السديد',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// شرح الطحاوية للبدر
    'shamela_8352': MutunAudioEntry(
      bookId: 'shamela_8352',
      title: 'شرح العقيدة الطحاوية لابن أبي العز',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.badr,
          audioUrl:
              'https://archive.org/download/Sharh_Tahawiya_al-Badr/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Sharh_Tahawiya_al-Badr',
            count: 22,
            titlePrefix: 'شرح الطحاوية',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// الفتوى الحموية الكبرى
    'shamela_18381': MutunAudioEntry(
      bookId: 'shamela_18381',
      title: 'الفتوى الحموية الكبرى لابن تيمية',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/236.mp3',
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.fawzan,
          audioUrl:
              'https://archive.org/download/Sharh__Fatwa_Hamawiya_Al-Fawzan/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl:
                'https://archive.org/download/Sharh__Fatwa_Hamawiya_Al-Fawzan',
            count: 43,
            titlePrefix: 'شرح الحموية',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// الرسالة التدمرية لابن تيمية
    'shamela_11100': MutunAudioEntry(
      bookId: 'shamela_11100',
      title: 'الرسالة التدمرية لابن تيمية',
      sources: [
        const MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/012.mp3',
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.uthaymin,
          audioUrl:
              'https://archive.org/download/altadmoriyah_othaimeen/altadmoriyah_01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl:
                'https://archive.org/download/altadmoriyah_othaimeen',
            count: 20,
            titlePrefix: 'شرح التدمرية',
            filePrefix: 'altadmoriyah_',
            padWidth: 2,
          ),
        ),
      ],
    ),

    // ── الفقه ─────────────────────────────────────────────────

    /// الفقه الميسر
    'shamela_22726': MutunAudioEntry(
      bookId: 'shamela_22726',
      title: 'الفقه الميسر في ضوء الكتاب والسنة',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/024.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 4,
            titlePrefix: 'جزء الفقه الميسر',
            startNumber: 24,
            padWidth: 3,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl:
              'https://archive.org/download/islami-345_202505/%D8%A7%D9%84%D9%81%D9%82%D9%87%20%D8%A7%D9%84%D9%85%D9%8A%D8%B3%D8%B1%202%20%20%D8%A7%D9%84%D8%B7%D9%87%D8%A7%D8%B1%D8%A9%20%D8%A3%D8%AD%D9%83%D8%A7%D9%85%20%D8%A7%D9%84%D8%B7%D9%87%D8%A7%D8%B1%D8%A9%20%D9%88%D8%A7%D9%84%D9%85%D9%8A%D8%A7%D9%87.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-345_202505',
            items: const [
              (file: 'الفقه الميسر 2  الطهارة أحكام الطهارة والمياه.mp3', title: 'الفقه الميسر 2  الطهارة أحكام الطهارة والمياه'),
              (file: 'الفقه الميسر 3  الطهارة الآنية.mp3', title: 'الفقه الميسر 3  الطهارة الآنية'),
              (file: 'الفقه الميسر ١ المقدمة.mp3', title: 'الفقه الميسر ١ المقدمة'),
              (file: 'الفقه الميسر ١٠  الطهارة النجاسات وكيفية تطهيرها.mp3', title: 'الفقه الميسر ١٠  الطهارة النجاسات وكيفية تطهيرها'),
              (file: 'الفقه الميسر ١٠٠ كتاب الأطعمة والذبائح والنذور ( أحكام الذبائح ).mp3', title: 'الفقه الميسر ١٠٠ كتاب الأطعمة والذبائح والنذور ( أحكام الذبائح )'),
              (file: 'الفقه الميسر ١٠١ كتاب الأطعمة والذبائح والنذور ( أحكام الصيد ).mp3', title: 'الفقه الميسر ١٠١ كتاب الأطعمة والذبائح والنذور ( أحكام الصيد )'),
              (file: 'الفقه الميسر ١٠٢ كتاب القضاء والشهادات ( القضاء ).mp3', title: 'الفقه الميسر ١٠٢ كتاب القضاء والشهادات ( القضاء )'),
              (file: 'الفقه الميسر ١٠٣ كتاب القضاء والشهادات ( الشهادات ).mp3', title: 'الفقه الميسر ١٠٣ كتاب القضاء والشهادات ( الشهادات )'),
              (file: 'الفقه الميسر ١١  الطهارة الحيض والنفاس.mp3', title: 'الفقه الميسر ١١  الطهارة الحيض والنفاس'),
              (file: 'الفقه الميسر ١٢  الصلاة تعريف الصلاة وفضلها ووجوب الصلوات الخمس.mp3', title: 'الفقه الميسر ١٢  الصلاة تعريف الصلاة وفضلها ووجوب الصلوات الخمس'),
              (file: 'الفقه الميسر ١٣  الصلاة  الأذان والإقامة.mp3', title: 'الفقه الميسر ١٣  الصلاة  الأذان والإقامة'),
              (file: 'الفقه الميسر ١٤  الصلاة  مواقيت الصلاة.mp3', title: 'الفقه الميسر ١٤  الصلاة  مواقيت الصلاة'),
              (file: 'الفقه الميسر ١٥  الصلاة  شروط الصلاة وأركانها وحكم تاركها.mp3', title: 'الفقه الميسر ١٥  الصلاة  شروط الصلاة وأركانها وحكم تاركها'),
              (file: 'الفقه الميسر ١٦  الصلاة   صلاة التطوع.mp3', title: 'الفقه الميسر ١٦  الصلاة   صلاة التطوع'),
              (file: 'الفقه الميسر ١٧  الصلاة سجود السهو والتلاوة والشكر.mp3', title: 'الفقه الميسر ١٧  الصلاة سجود السهو والتلاوة والشكر'),
              (file: 'الفقه الميسر ١٨  الصلاة صلاة الجماعة.mp3', title: 'الفقه الميسر ١٨  الصلاة صلاة الجماعة'),
              (file: 'الفقه الميسر ١٩  الصلاة الإمامة.mp3', title: 'الفقه الميسر ١٩  الصلاة الإمامة'),
              (file: 'الفقه الميسر ٢٠  الصلاة صلاة أهل الأعذار.mp3', title: 'الفقه الميسر ٢٠  الصلاة صلاة أهل الأعذار'),
              (file: 'الفقه الميسر ٢١  الصلاة صلاة الجمعة.mp3', title: 'الفقه الميسر ٢١  الصلاة صلاة الجمعة'),
              (file: 'الفقه الميسر ٢٢  الصلاة صلاة الخوف.mp3', title: 'الفقه الميسر ٢٢  الصلاة صلاة الخوف'),
              (file: 'الفقه الميسر ٢٣  الصلاة صلاة العيدين.mp3', title: 'الفقه الميسر ٢٣  الصلاة صلاة العيدين'),
              (file: 'الفقه الميسر ٢٤  الصلاة صلاة الاستسقاء.mp3', title: 'الفقه الميسر ٢٤  الصلاة صلاة الاستسقاء'),
              (file: 'الفقه الميسر ٢٥  الصلاة صلاة الكسوف.mp3', title: 'الفقه الميسر ٢٥  الصلاة صلاة الكسوف'),
              (file: 'الفقه الميسر ٢٦  الصلاة صلاة الجنازة وأحكام الجنائز.mp3', title: 'الفقه الميسر ٢٦  الصلاة صلاة الجنازة وأحكام الجنائز'),
              (file: 'الفقه الميسر ٢٧  الزكاة مقدمات الزكاة.mp3', title: 'الفقه الميسر ٢٧  الزكاة مقدمات الزكاة'),
              (file: 'الفقه الميسر ٢٨  الزكاة زكاة الذهب والفضة.mp3', title: 'الفقه الميسر ٢٨  الزكاة زكاة الذهب والفضة'),
              (file: 'الفقه الميسر ٢٩  الزكاة زكاة الخارج من الأرض.mp3', title: 'الفقه الميسر ٢٩  الزكاة زكاة الخارج من الأرض'),
              (file: 'الفقه الميسر ٣٠  الزكاة زكاة بهيمة الأنعام.mp3', title: 'الفقه الميسر ٣٠  الزكاة زكاة بهيمة الأنعام'),
              (file: 'الفقه الميسر ٣١  الزكاة زكاة الفطر.mp3', title: 'الفقه الميسر ٣١  الزكاة زكاة الفطر'),
              (file: 'الفقه الميسر ٣٢  الزكاة أهل الزكاة.mp3', title: 'الفقه الميسر ٣٢  الزكاة أهل الزكاة'),
            ],
          ),
        ),
      ],
    ),

    /// دليل الطالب لنيل المطالب
    'shamela_11196': MutunAudioEntry(
      bookId: 'shamela_11196',
      title: 'دليل الطالب لنيل المطالب',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.shuwayir,
          audioUrl:
              'https://archive.org/download/Sharh_Daleel_At-Talib/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Sharh_Daleel_At-Talib',
            count: 88,
            titlePrefix: 'شرح دليل الطالب',
            padWidth: 2,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.bajabir,
          audioUrl:
              'https://archive.org/download/Sharh_Dalil_Talib/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Sharh_Dalil_Talib',
            count: 53,
            titlePrefix: 'شرح دليل الطالب',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// أخصر المختصرات
    'shamela_6084': MutunAudioEntry(
      bookId: 'shamela_6084',
      title: 'أخصر المختصرات في الفقه الحنبلي',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.basati,
          audioUrl:
              'https://archive.org/download/islami_-315/%D8%A3%D8%AE%D8%B5%D8%B1%20%D8%A7%D9%84%D9%85%D8%AE%D8%AA%D8%B5%D8%B1%D8%A7%D8%AA%201%20%D9%83%D8%AA%D8%A7%D8%A8%20%D8%A7%D9%84%D8%B7%D9%87%D8%A7%D8%B1%D8%A9.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami_-315',
            items: const [
              (file: 'أخصر المختصرات 1 كتاب الطهارة.mp3', title: 'أخصر المختصرات 1 كتاب الطهارة'),
              (file: 'أخصر المختصرات 10 كتاب النكاح.mp3', title: 'أخصر المختصرات 10 كتاب النكاح'),
              (file: 'أخصر المختصرات 11 كتاب الطلاق.mp3', title: 'أخصر المختصرات 11 كتاب الطلاق'),
              (file: 'أخصر المختصرات 12 كتاب الجنايات.mp3', title: 'أخصر المختصرات 12 كتاب الجنايات'),
              (file: 'أخصر المختصرات 13 كتاب القضاء إلى آخر الكتاب.mp3', title: 'أخصر المختصرات 13 كتاب القضاء إلى آخر الكتاب'),
              (file: 'أخصر المختصرات 2 كتاب الصلاة حتى سجود السهو.mp3', title: 'أخصر المختصرات 2 كتاب الصلاة حتى سجود السهو'),
              (file: 'أخصر المختصرات 3 من سجود السهو حتى نهاية كتاب الصلاة.mp3', title: 'أخصر المختصرات 3 من سجود السهو حتى نهاية كتاب الصلاة'),
              (file: 'أخصر المختصرات 4 كتاب الجنائز   كتاب الزكاة.mp3', title: 'أخصر المختصرات 4 كتاب الجنائز   كتاب الزكاة'),
              (file: 'أخصر المختصرات 5 كتاب الصيام   كتاب الحج.mp3', title: 'أخصر المختصرات 5 كتاب الصيام   كتاب الحج'),
              (file: 'أخصر المختصرات 6 كتاب الجهاد   كتاب البيوع حتى الرهن.mp3', title: 'أخصر المختصرات 6 كتاب الجهاد   كتاب البيوع حتى الرهن'),
              (file: 'أخصر المختصرات 7 من الرهن حتى المساقاة.mp3', title: 'أخصر المختصرات 7 من الرهن حتى المساقاة'),
              (file: 'أخصر المختصرات 8  من الإجارة حتى آخر كتاب البيوع.mp3', title: 'أخصر المختصرات 8  من الإجارة حتى آخر كتاب البيوع'),
              (file: 'أخصر المختصرات 9 كتاب الوصايا   الفرائض   العتق.mp3', title: 'أخصر المختصرات 9 كتاب الوصايا   الفرائض   العتق'),
            ],
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.bajabir,
          audioUrl:
              'https://archive.org/download/Akhsar_almoukhtasarat/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Akhsar_almoukhtasarat',
            count: 55,
            titlePrefix: 'شرح أخصر المختصرات',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// بداية المجتهد لابن رشد
    'shamela_21739': MutunAudioEntry(
      bookId: 'shamela_21739',
      title: 'بداية المجتهد ونهاية المقتصد لابن رشد',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.bilalMansour,
          audioUrl:
              'https://archive.org/download/islami-198_202504/%D9%83%D8%AA%D8%A7%D8%A8%20%D8%B5%D9%88%D8%AA%D9%8A%20%20%D8%A8%D8%AF%D8%A7%D9%8A%D8%A9%20%D8%A7%D9%84%D9%85%D8%AC%D8%AA%D9%87%D8%AF%20%D9%88%20%D9%86%D9%87%D8%A7%D9%8A%D8%A9%20%D8%A7%D9%84%D9%85%D9%82%D8%AA%D8%B5%D8%AF%20%D9%84%D9%84%D8%A5%D9%85%D8%A7%D9%85%20%D8%A5%D8%A8%D9%86%20%D8%B1%D8%B4%D8%AF%20%20%7B%D9%A3%7D%D9%83%D8%AA%D8%A7%D8%A8%20%D8%A7%D9%84%D8%B7%D9%87%D8%A7%D8%B1%D8%A9%20%20%D8%A3%D8%A8%D9%88%D8%A7%D8%A8%20%D8%A7%D9%84%D9%88%D8%B6%D9%88%D8%A1.mp3',
          chapters: BookAudioChapter.fromFiles(
            baseUrl: 'https://archive.org/download/islami-198_202504',
            items: const [
              (file: 'كتاب صوتي  بداية المجتهد و نهاية المقتصد للإمام إبن رشد  {٣}كتاب الطهارة  أبواب الوضوء.mp3', title: 'بداية المجتهد و نهاية المقتصد للإمام إبن رشد  {٣}كتاب الطهارة  أبواب الوضوء'),
              (file: 'كتاب صوتي  بداية المجتهد و نهاية المقتصد للإمام إبن رشد  أبواب الوضوء {٤} كتاب الطهارة.mp3', title: 'بداية المجتهد و نهاية المقتصد للإمام إبن رشد  أبواب الوضوء {٤} كتاب الطهارة'),
              (file: 'كتاب صوتي  بداية المجتهد و نهاية المقتصد{١} صوتي مسموعالمقدمة.mp3', title: 'بداية المجتهد و نهاية المقتصد{١} صوتي مسموعالمقدمة'),
              (file: 'كتاب صوتي  بداية المجتهد و نهاية المقتصد{٢} للإمام إبن رشدأبواب الوضوء كتاب الطهارة {١}.mp3', title: 'بداية المجتهد و نهاية المقتصد{٢} للإمام إبن رشدأبواب الوضوء كتاب الطهارة {١}'),
            ],
          ),
        ),
      ],
    ),

    /// مجموع الفتاوى لابن تيمية
    'shamela_7289': MutunAudioEntry(
      bookId: 'shamela_7289',
      title: 'مجموع الفتاوى لشيخ الإسلام ابن تيمية',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/165.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 10,
            titlePrefix: 'جزء مجموع الفتاوى',
            startNumber: 165,
            padWidth: 3,
          ),
        ),
      ],
    ),

    // ── النحو والصرف ───────────────────────────────────────────

    /// شرح شذور الذهب لابن هشام
    'shamela_6969': MutunAudioEntry(
      bookId: 'shamela_6969',
      title: 'شرح شذور الذهب لابن هشام',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.bashir,
          audioUrl: 'https://archive.org/download/bashir-mar-shozor/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/bashir-mar-shozor',
            count: 22,
            titlePrefix: 'مجلس شذور الذهب',
            padWidth: 2,
          ),
        ),
      ],
    ),

    /// شرح قطر الندى وبل الصدى لابن هشام
    'shamela_6970': MutunAudioEntry(
      bookId: 'shamela_6970',
      title: 'شرح قطر الندى وبل الصدى لابن هشام',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.fawzan,
          audioUrl: 'https://archive.org/download/fouzan-kater/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/fouzan-kater',
            count: 29,
            titlePrefix: 'شرح قطر الندى',
            padWidth: 2,
          ),
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl:
              'https://archive.org/download/Mutun_Sawtiya/090-Qatr_annada_ibn_hisham.mp3',
          edition: BookAudioEdition.nadhm,
        ),
      ],
    ),

    /// شرح ابن عقيل على ألفية ابن مالك
    'shamela_9904': MutunAudioEntry(
      bookId: 'shamela_9904',
      title: 'شرح ابن عقيل على ألفية ابن مالك',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/199.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 2,
            titlePrefix: 'جزء شرح ابن عقيل',
            startNumber: 199,
            padWidth: 3,
          ),
        ),
      ],
    ),

    /// أوضح المسالك إلى ألفية ابن مالك
    'shamela_11825': MutunAudioEntry(
      bookId: 'shamela_11825',
      title: 'أوضح المسالك إلى ألفية ابن مالك',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/189.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 3,
            titlePrefix: 'جزء أوضح المسالك',
            startNumber: 189,
            padWidth: 3,
          ),
        ),
      ],
    ),

    // ── الأصول والمصطلح ────────────────────────────────────────

    /// الأصول من علم الأصول للعثيمين
    'shamela_9942': MutunAudioEntry(
      bookId: 'shamela_9942',
      title: 'الأصول من علم الأصول لابن عثيمين',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.uthaymin,
          audioUrl: 'https://archive.org/download/sharho-osool/01.mp3',
          edition: BookAudioEdition.sharhMajalis,
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/sharho-osool',
            count: 6,
            titlePrefix: 'درس الأصول من علم الأصول',
            padWidth: 2,
          ),
        ),
        const MatnAudioSource(
          reciter: MutunReciterDefaults.shaydzmi,
          audioUrl: '$_sawtiya/076-Rissala_oussoul_fiqh.mp3',
        ),
      ],
    ),

    // ── السيرة النبوية ─────────────────────────────────────────

    /// سيرة ابن هشام (تهذيب السيرة)
    'shamela_23833': MutunAudioEntry(
      bookId: 'shamela_23833',
      title: 'السيرة النبوية لابن هشام (المختصر)',
      sources: [
        MatnAudioSource(
          reciter: MutunReciterDefaults.koutoubMasmouah,
          audioUrl: 'https://archive.org/download/Koutoub_masmou3a/034.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/Koutoub_masmou3a',
            count: 4,
            titlePrefix: 'جزء سيرة ابن هشام',
            startNumber: 34,
            padWidth: 3,
          ),
        ),
        MatnAudioSource(
          reciter: MutunReciterDefaults.hamadHarun,
          audioUrl: 'https://archive.org/download/islami-226_202504/01.mp3',
          chapters: BookAudioChapter.numbered(
            baseUrl: 'https://archive.org/download/islami-226_202504',
            count: 40,
            titlePrefix: 'مجلس سيرة ابن هشام',
            padWidth: 2,
          ),
        ),
      ],
    ),
  };
}
