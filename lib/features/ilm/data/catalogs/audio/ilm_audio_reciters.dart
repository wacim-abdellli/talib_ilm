import '../../models/book_audio_models.dart';

class MutunReciterDefaults {
  const MutunReciterDefaults._();

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
