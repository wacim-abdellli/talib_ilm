class AppAssets {
  AppAssets._();

  static const String hadithData = 'assets/data/hadith.json';
  static const String adhkarData = 'assets/data/adhkar.json';
  static const String mutunProgram = 'assets/data/mutun_program.json';
  static const String dailyMotivation = 'assets/data/daily_motivation.json';

  static const String adhanMakkah = 'assets/audio/adhan_makkah.mp3';
  static const String adhanMadinah = 'assets/audio/adhan_madinah.mp3';
  static const String adhanAlafasy = 'assets/audio/adhan_alafasy.mp3';
  static const String adhanAbdulbasit = 'assets/audio/adhan_abdulbasit.mp3';
  static const String adhanQatami = 'assets/audio/adhan_qatami.mp3';
  static const String adhanTakbeer = 'assets/audio/adhan_takbeer.mp3';
  static const String adhanTakbeerFajr = 'assets/audio/adhan_takbeer_fajr.mp3';
  static const String adhanTakbeerDhuhr = 'assets/audio/adhan_takbeer_dhuhr.mp3';
  static const String adhanTakbeerAsr = 'assets/audio/adhan_takbeer_asr.mp3';
  static const String adhanTakbeerMaghrib = 'assets/audio/adhan_takbeer_maghrib.mp3';
  static const String adhanTakbeerIsha = 'assets/audio/adhan_takbeer_isha.mp3';

  static String adhanTakbeerFor(String? prayerName) {
    if (prayerName == null) return adhanTakbeer;
    if (prayerName.contains('فجر')) return adhanTakbeerFajr;
    if (prayerName.contains('ظهر')) return adhanTakbeerDhuhr;
    if (prayerName.contains('عصر')) return adhanTakbeerAsr;
    if (prayerName.contains('مغرب')) return adhanTakbeerMaghrib;
    if (prayerName.contains('عشاء')) return adhanTakbeerIsha;
    return adhanTakbeer;
  }

  static String mutunPdf(String bookId) {
    return 'assets/pdfs/mutun/$bookId.pdf';
  }

  static String sharhPdf(String bookId, String file) {
    return 'assets/pdfs/shuruh/$bookId/$file.pdf';
  }
}
