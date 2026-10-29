import '../../models/book_audio_models.dart';
import 'ilm_audio_reciters.dart';

/// Complete verified studio audiobook catalog of Dr. Rashid ibn Fahd Al-Haliba
/// (مشروع بوح للكتب الصوتية — 36 recordings on CloudFront HTTPS CDN with
/// official Anchor/Spotify enclosure redirects as fallback).
class HalibaAudiobookItem {
  final String id;
  final String title;
  final String durationLabel;
  final String cloudFrontUrl;
  final String anchorFallbackUrl;
  final BookAudioEdition edition;

  const HalibaAudiobookItem({
    required this.id,
    required this.title,
    required this.durationLabel,
    required this.cloudFrontUrl,
    required this.anchorFallbackUrl,
    this.edition = BookAudioEdition.fullText,
  });

  MatnAudioSource toSource({int totalParagraphs = 1}) {
    return MatnAudioSource(
      reciter: MutunReciterDefaults.haliba,
      audioUrl: cloudFrontUrl,
      fallbackUrl: anchorFallbackUrl,
      totalParagraphs: totalParagraphs,
      edition: edition,
    );
  }
}

class HalibaAudiobooksCatalog {
  const HalibaAudiobooksCatalog._();

  static const String _cf24 =
      'https://d3ctxlq1ktw2nl.cloudfront.net/staging/2026-7-24';
  static const String _cf23 =
      'https://d3ctxlq1ktw2nl.cloudfront.net/staging/2026-7-23';
  static const String _cf17 =
      'https://d3ctxlq1ktw2nl.cloudfront.net/staging/2026-1-17';
  static const String _anc = 'https://anchor.fm/s/10f31c8c8/podcast/play';

  static String _wrap(String playId, String folder, String file) {
    final encoded = Uri.encodeComponent(
      'https://d3ctxlq1ktw2nl.cloudfront.net/staging/$folder/$file',
    );
    return '$_anc/$playId/$encoded';
  }

  static final Map<String, HalibaAudiobookItem> items = {
    'arbaeen_nawawi': HalibaAudiobookItem(
      id: 'arbaeen_nawawi',
      title: 'الأربعون النووية للحافظ النووي',
      durationLabel: '00:40:44',
      cloudFrontUrl: '$_cf24/c3e47adc-2ad0-405f-9ffe-8e4807f6b925.mp3',
      anchorFallbackUrl: _wrap(
        '124659103',
        '2026-7-24',
        'c3e47adc-2ad0-405f-9ffe-8e4807f6b925.mp3',
      ),
    ),
    'hisn_muslim': HalibaAudiobookItem(
      id: 'hisn_muslim',
      title: 'حصن المسلم من أذكار الكتاب والسنة',
      durationLabel: '01:28:42',
      cloudFrontUrl: '$_cf24/8963095c-cec2-f697-184f-c61dff033008.mp3',
      anchorFallbackUrl: _wrap(
        '124658008',
        '2026-7-24',
        '8963095c-cec2-f697-184f-c61dff033008.mp3',
      ),
    ),
    'umdat_ahkam': HalibaAudiobookItem(
      id: 'umdat_ahkam',
      title: 'عمدة الأحكام من كلام سيد الأنام',
      durationLabel: '03:23:29',
      cloudFrontUrl: '$_cf24/ffd35f9e-c8b1-cd29-32bb-3993376e3703.mp3',
      anchorFallbackUrl: _wrap(
        '124657088',
        '2026-7-24',
        'ffd35f9e-c8b1-cd29-32bb-3993376e3703.mp3',
      ),
    ),
    'mukhtasar_fawaid': HalibaAudiobookItem(
      id: 'mukhtasar_fawaid',
      title: 'مختصر كتاب الفوائد لابن القيم',
      durationLabel: '02:50:11',
      cloudFrontUrl: '$_cf24/c448fd7a-6105-330a-98c9-2b4b56afc0e9.mp3',
      anchorFallbackUrl: _wrap(
        '124658191',
        '2026-7-24',
        'c448fd7a-6105-330a-98c9-2b4b56afc0e9.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'mukhtasar_daa_dawaa': HalibaAudiobookItem(
      id: 'mukhtasar_daa_dawaa',
      title: 'مختصر كتاب الداء والدواء لابن القيم',
      durationLabel: '02:35:52',
      cloudFrontUrl: '$_cf24/86261d28-8892-f387-7867-196fd8cea5d6.mp3',
      anchorFallbackUrl: _wrap(
        '124654778',
        '2026-7-24',
        '86261d28-8892-f387-7867-196fd8cea5d6.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'mukhtasar_tariq_hijratayn': HalibaAudiobookItem(
      id: 'mukhtasar_tariq_hijratayn',
      title: 'مختصر كتاب طريق الهجرتين لابن القيم',
      durationLabel: '03:01:52',
      cloudFrontUrl: '$_cf24/c5592a57-38ea-ddc8-32e1-99c4989fe9be.mp3',
      anchorFallbackUrl: _wrap(
        '124656638',
        '2026-7-24',
        'c5592a57-38ea-ddc8-32e1-99c4989fe9be.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'mukhtasar_uddat_sabirin': HalibaAudiobookItem(
      id: 'mukhtasar_uddat_sabirin',
      title: 'مختصر كتاب عدة الصابرين وذخيرة الشاكرين',
      durationLabel: '02:45:39',
      cloudFrontUrl: '$_cf24/b3d14ae4-21cd-1026-1a3a-28ed1f051a62.mp3',
      anchorFallbackUrl: _wrap(
        '124656288',
        '2026-7-24',
        'b3d14ae4-21cd-1026-1a3a-28ed1f051a62.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'mukhtasar_hadi_arwah': HalibaAudiobookItem(
      id: 'mukhtasar_hadi_arwah',
      title: 'مختصر كتاب حادي الأرواح إلى بلاد الأفراح',
      durationLabel: '02:19:04',
      cloudFrontUrl: '$_cf24/6565b184-6cf2-f836-7234-f20a0cc9fb95.mp3',
      anchorFallbackUrl: _wrap(
        '124656903',
        '2026-7-24',
        '6565b184-6cf2-f836-7234-f20a0cc9fb95.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'lataif_ramadan': HalibaAudiobookItem(
      id: 'lataif_ramadan',
      title: 'وظائف رمضان من لطائف المعارف لابن رجب',
      durationLabel: '02:06:15',
      cloudFrontUrl: '$_cf24/16169683-68e8-a930-55e4-3cf568d07b4c.mp3',
      anchorFallbackUrl: _wrap(
        '124655818',
        '2026-7-24',
        '16169683-68e8-a930-55e4-3cf568d07b4c.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'fath_karim_mannan': HalibaAudiobookItem(
      id: 'fath_karim_mannan',
      title: 'فتح الكريم المنان في آداب حملة القرآن',
      durationLabel: '00:36:03',
      cloudFrontUrl: '$_cf24/948a418b-7394-882b-3673-dba62a1c37d5.mp3',
      anchorFallbackUrl: _wrap(
        '124658466',
        '2026-7-24',
        '948a418b-7394-882b-3673-dba62a1c37d5.mp3',
      ),
    ),
    'akhlaq_hamalat_quran': HalibaAudiobookItem(
      id: 'akhlaq_hamalat_quran',
      title: 'مختصر كتاب أخلاق حملة القرآن للآجري',
      durationLabel: '00:59:45',
      cloudFrontUrl: '$_cf17/33a2158c-7aec-ed23-8610-e1d778c0c0b9.mp3',
      anchorFallbackUrl: _wrap(
        '115652142',
        '2026-1-17',
        '33a2158c-7aec-ed23-8610-e1d778c0c0b9.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'fadail_quran_ibn_abdulwahhab': HalibaAudiobookItem(
      id: 'fadail_quran_ibn_abdulwahhab',
      title: 'كتاب فضائل القرآن للإمام محمد بن عبد الوهاب',
      durationLabel: '00:32:28',
      cloudFrontUrl: '$_cf24/19d215a0-9942-ac1e-f9ce-0bce5b6a1885.mp3',
      anchorFallbackUrl: _wrap(
        '124658399',
        '2026-7-24',
        '19d215a0-9942-ac1e-f9ce-0bce5b6a1885.mp3',
      ),
    ),
    'fadail_quran_sahihayn': HalibaAudiobookItem(
      id: 'fadail_quran_sahihayn',
      title: 'كتاب فضائل القرآن من الجامع بين الصحيحين',
      durationLabel: '00:32:28',
      cloudFrontUrl: '$_cf24/f3c5bcd2-6613-7d65-df84-5a03e1d21319.mp3',
      anchorFallbackUrl: _wrap(
        '124656204',
        '2026-7-24',
        'f3c5bcd2-6613-7d65-df84-5a03e1d21319.mp3',
      ),
    ),
    'istighna_bil_quran': HalibaAudiobookItem(
      id: 'istighna_bil_quran',
      title: 'الاستغناء بالقرآن لابن رجب الحنبلي',
      durationLabel: '00:39:44',
      cloudFrontUrl: '$_cf24/effbcea5-7e8d-be5e-5e96-3522618fba3d.mp3',
      anchorFallbackUrl: _wrap(
        '124658753',
        '2026-7-24',
        'effbcea5-7e8d-be5e-5e96-3522618fba3d.mp3',
      ),
    ),
    'warathat_anbiya': HalibaAudiobookItem(
      id: 'warathat_anbiya',
      title: 'ورثة الأنبياء لابن رجب الحنبلي',
      durationLabel: '01:52:25',
      cloudFrontUrl: '$_cf24/4c57a95c-6746-ed20-cb20-7edacb5eb0ad.mp3',
      anchorFallbackUrl: _wrap(
        '124658581',
        '2026-7-24',
        '4c57a95c-6746-ed20-cb20-7edacb5eb0ad.mp3',
      ),
    ),
    'sharh_ma_dhiban': HalibaAudiobookItem(
      id: 'sharh_ma_dhiban',
      title: 'شرح حديث ما ذئبان جائعان لابن رجب',
      durationLabel: '01:07:42',
      cloudFrontUrl: '$_cf24/a5c434fc-26f4-40fa-ea05-4bb78f3897d5.mp3',
      anchorFallbackUrl: _wrap(
        '124655663',
        '2026-7-24',
        'a5c434fc-26f4-40fa-ea05-4bb78f3897d5.mp3',
      ),
    ),
    'dhull_inkisar': HalibaAudiobookItem(
      id: 'dhull_inkisar',
      title: 'الذل والانكسار للعزيز الجبار لابن رجب',
      durationLabel: '00:51:07',
      cloudFrontUrl: '$_cf24/f51a1972-8e63-db2f-c878-7ac502374750.mp3',
      anchorFallbackUrl: _wrap(
        '124655251',
        '2026-7-24',
        'f51a1972-8e63-db2f-c878-7ac502374750.mp3',
      ),
    ),
    'mahajjah_sayr_duljah': HalibaAudiobookItem(
      id: 'mahajjah_sayr_duljah',
      title: 'متن المحجة في سير الدلجة لابن رجب',
      durationLabel: '00:49:11',
      cloudFrontUrl: '$_cf23/2e2c46d2-b652-100c-ef0d-e532ebc804c9.mp3',
      anchorFallbackUrl: _wrap(
        '124630063',
        '2026-7-23',
        '2e2c46d2-b652-100c-ef0d-e532ebc804c9.mp3',
      ),
    ),
    'arbaeen_ihtisabiyyah': HalibaAudiobookItem(
      id: 'arbaeen_ihtisabiyyah',
      title: 'الأربعون الاحتسابية',
      durationLabel: '00:35:12',
      cloudFrontUrl: '$_cf24/c638e2a2-33b2-def0-a1ab-d46613c21ab4.mp3',
      anchorFallbackUrl: _wrap(
        '124659637',
        '2026-7-24',
        'c638e2a2-33b2-def0-a1ab-d46613c21ab4.mp3',
      ),
    ),
    'ahadith_kulliyyah': HalibaAudiobookItem(
      id: 'ahadith_kulliyyah',
      title: 'الأحاديث الكلية في أبواب الدين',
      durationLabel: '01:27:09',
      cloudFrontUrl: '$_cf24/123bc5ef-a199-5b87-34c4-ececa60c6a19.mp3',
      anchorFallbackUrl: _wrap(
        '124659251',
        '2026-7-24',
        '123bc5ef-a199-5b87-34c4-ececa60c6a19.mp3',
      ),
    ),
    'ahadith_qudsiyyah': HalibaAudiobookItem(
      id: 'ahadith_qudsiyyah',
      title: 'الأحاديث القدسية الأربعينية لملا علي القاري',
      durationLabel: '00:28:14',
      cloudFrontUrl: '$_cf23/dee7e1d1-3396-bfe7-708c-732139ed7063.mp3',
      anchorFallbackUrl: _wrap(
        '124630697',
        '2026-7-23',
        'dee7e1d1-3396-bfe7-708c-732139ed7063.mp3',
      ),
    ),
    'fitan_ashrat_saah': HalibaAudiobookItem(
      id: 'fitan_ashrat_saah',
      title: 'الفتن وأشراط الساعة',
      durationLabel: '00:55:43',
      cloudFrontUrl: '$_cf24/d9137b68-c386-d480-5f30-e26e7bd5cad8.mp3',
      anchorFallbackUrl: _wrap(
        '124658844',
        '2026-7-24',
        'd9137b68-c386-d480-5f30-e26e7bd5cad8.mp3',
      ),
    ),
    'ishrun_seerah': HalibaAudiobookItem(
      id: 'ishrun_seerah',
      title: 'العشرون في السيرة النبوية',
      durationLabel: '00:16:37',
      cloudFrontUrl: '$_cf24/7eca476f-6418-050c-51bf-8e8ba264789e.mp3',
      anchorFallbackUrl: _wrap(
        '124658350',
        '2026-7-24',
        '7eca476f-6418-050c-51bf-8e8ba264789e.mp3',
      ),
    ),
    'wafat_nabi': HalibaAudiobookItem(
      id: 'wafat_nabi',
      title: 'الجامع لأحاديث وفاة النبي ﷺ',
      durationLabel: '00:34:04',
      cloudFrontUrl: '$_cf24/dc9d8ff2-9deb-8bf0-9b7d-629f2476122f.mp3',
      anchorFallbackUrl: _wrap(
        '124656554',
        '2026-7-24',
        'dc9d8ff2-9deb-8bf0-9b7d-629f2476122f.mp3',
      ),
    ),
    'araj_fil_faraj': HalibaAudiobookItem(
      id: 'araj_fil_faraj',
      title: 'الأرج في الفرج تلخيص الفرج بعد الشدة',
      durationLabel: '01:32:35',
      cloudFrontUrl: '$_cf24/47620eec-78ed-a0f0-9eab-3372d06a983f.mp3',
      anchorFallbackUrl: _wrap(
        '124656044',
        '2026-7-24',
        '47620eec-78ed-a0f0-9eab-3372d06a983f.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'nasihah_ibn_habbal': HalibaAudiobookItem(
      id: 'nasihah_ibn_habbal',
      title: 'النصيحة المختصة لابن الحبال البعلي',
      durationLabel: '00:28:23',
      cloudFrontUrl: '$_cf24/664946fa-807e-64ff-a97c-9c8c31ee14f4.mp3',
      anchorFallbackUrl: _wrap(
        '124655571',
        '2026-7-24',
        '664946fa-807e-64ff-a97c-9c8c31ee14f4.mp3',
      ),
    ),
    'dhawq_salah': HalibaAudiobookItem(
      id: 'dhawq_salah',
      title: 'ذوق الصلاة لابن القيم',
      durationLabel: '01:11:25',
      cloudFrontUrl: '$_cf24/9d4af41e-2bc3-c3dc-6e3f-9ba543c493ac.mp3',
      anchorFallbackUrl: _wrap(
        '124655388',
        '2026-7-24',
        '9d4af41e-2bc3-c3dc-6e3f-9ba543c493ac.mp3',
      ),
    ),
    'ahwal_qiyamah_targheeb': HalibaAudiobookItem(
      id: 'ahwal_qiyamah_targheeb',
      title: 'أهوال يوم القيامة من صحيح الترغيب والترهيب',
      durationLabel: '00:45:15',
      cloudFrontUrl: '$_cf24/ec09e8b2-8f4b-f4d3-fda0-be2505548bbb.mp3',
      anchorFallbackUrl: _wrap(
        '124655125',
        '2026-7-24',
        'ec09e8b2-8f4b-f4d3-fda0-be2505548bbb.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'sifat_jannah_targheeb': HalibaAudiobookItem(
      id: 'sifat_jannah_targheeb',
      title: 'صفة الجنة من صحيح الترغيب والترهيب',
      durationLabel: '00:24:23',
      cloudFrontUrl: '$_cf24/45f498d6-d652-fe4d-dc44-a75c37a81be7.mp3',
      anchorFallbackUrl: _wrap(
        '124654701',
        '2026-7-24',
        '45f498d6-d652-fe4d-dc44-a75c37a81be7.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'wasiyyat_ibn_qudamah': HalibaAudiobookItem(
      id: 'wasiyyat_ibn_qudamah',
      title: 'وصية الموفق ابن قدامة المقدسي',
      durationLabel: '01:03:29',
      cloudFrontUrl: '$_cf24/fed4a645-eaeb-f71f-02ec-15092be9fdaf.mp3',
      anchorFallbackUrl: _wrap(
        '124631562',
        '2026-7-24',
        'fed4a645-eaeb-f71f-02ec-15092be9fdaf.mp3',
      ),
    ),
    'shifa_part1': HalibaAudiobookItem(
      id: 'shifa_part1',
      title: 'مختصر كتاب الشفا للقاضي عياض - القسم الأول',
      durationLabel: '02:53:35',
      cloudFrontUrl: '$_cf23/5d74486a-833d-e5c5-34d0-822ff4aa93c4.mp3',
      anchorFallbackUrl: _wrap(
        '124631231',
        '2026-7-23',
        '5d74486a-833d-e5c5-34d0-822ff4aa93c4.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'shifa_part2': HalibaAudiobookItem(
      id: 'shifa_part2',
      title: 'مختصر كتاب الشفا للقاضي عياض - القسم الثاني',
      durationLabel: '00:53:44',
      cloudFrontUrl: '$_cf23/56618db4-6fee-29bc-655b-7364e73f2aac.mp3',
      anchorFallbackUrl: _wrap(
        '124631479',
        '2026-7-23',
        '56618db4-6fee-29bc-655b-7364e73f2aac.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'shifa_part3': HalibaAudiobookItem(
      id: 'shifa_part3',
      title: 'مختصر كتاب الشفا للقاضي عياض - القسم الثالث',
      durationLabel: '02:53:35',
      cloudFrontUrl: '$_cf23/fcfd793c-7dac-b0f9-92a6-2ba42a280b23.mp3',
      anchorFallbackUrl: _wrap(
        '124631592',
        '2026-7-23',
        'fcfd793c-7dac-b0f9-92a6-2ba42a280b23.mp3',
      ),
      edition: BookAudioEdition.mukhtasar,
    ),
    'laftat_kabid': HalibaAudiobookItem(
      id: 'laftat_kabid',
      title: 'لفتة الكبد إلى نصيحة الولد لابن الجوزي',
      durationLabel: '00:34:05',
      cloudFrontUrl: '$_cf23/decffb43-4375-35c4-2c76-70fe63ce8609.mp3',
      anchorFallbackUrl: _wrap(
        '124630953',
        '2026-7-23',
        'decffb43-4375-35c4-2c76-70fe63ce8609.mp3',
      ),
    ),
    'wasaya_salaf_shabab': HalibaAudiobookItem(
      id: 'wasaya_salaf_shabab',
      title: 'من وصايا السلف للشباب للشيخ عبد الرزاق البدر',
      durationLabel: '00:25:08',
      cloudFrontUrl: '$_cf23/3a56a27a-4bc7-218c-fda6-cb5bfdc6da46.mp3',
      anchorFallbackUrl: _wrap(
        '124630672',
        '2026-7-23',
        '3a56a27a-4bc7-218c-fda6-cb5bfdc6da46.mp3',
      ),
    ),
    'risalat_ibn_qayyim': HalibaAudiobookItem(
      id: 'risalat_ibn_qayyim',
      title: 'رسالة ابن القيم إلى أحد إخوانه',
      durationLabel: '00:49:02',
      cloudFrontUrl: '$_cf23/a68f7731-ea8c-8297-ba29-54690bf6b5cf.mp3',
      anchorFallbackUrl: _wrap(
        '124630472',
        '2026-7-23',
        'a68f7731-ea8c-8297-ba29-54690bf6b5cf.mp3',
      ),
    ),
  };

  static MatnAudioSource sourceFor(String id, {int totalParagraphs = 1}) =>
      items[id]!.toSource(totalParagraphs: totalParagraphs);

  static MatnAudioSource get sahihTargheebSelectionsSource {
    final p1 = items['ahwal_qiyamah_targheeb']!;
    final p2 = items['sifat_jannah_targheeb']!;
    return MatnAudioSource(
      reciter: MutunReciterDefaults.haliba,
      audioUrl: p1.cloudFrontUrl,
      fallbackUrl: p1.anchorFallbackUrl,
      edition: BookAudioEdition.mukhtasar,
      chapters: [
        BookAudioChapter(
          index: 1,
          title: p1.title,
          audioUrl: p1.cloudFrontUrl,
          fallbackUrl: p1.anchorFallbackUrl,
        ),
        BookAudioChapter(
          index: 2,
          title: p2.title,
          audioUrl: p2.cloudFrontUrl,
          fallbackUrl: p2.anchorFallbackUrl,
        ),
      ],
    );
  }
}
