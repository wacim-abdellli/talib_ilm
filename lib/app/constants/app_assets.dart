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
  static const String adhanAqsa = 'assets/audio/adhan_aqsa.mp3';
  static const String adhanTakbeer = 'assets/audio/adhan_takbeer.mp3';

  static const String adhanAnnouncementFajr =
      'assets/audio/adhan_announcement_fajr.mp3';
  static const String adhanAnnouncementDhuhr =
      'assets/audio/adhan_announcement_dhuhr.mp3';
  static const String adhanAnnouncementAsr =
      'assets/audio/adhan_announcement_asr.mp3';
  static const String adhanAnnouncementMaghrib =
      'assets/audio/adhan_announcement_maghrib.mp3';
  static const String adhanAnnouncementIsha =
      'assets/audio/adhan_announcement_isha.mp3';
  static const String adhanAnnouncementGeneral =
      'assets/audio/adhan_announcement_general.mp3';

  static String adhanAnnouncementFor(String? prayerName) {
    if (prayerName == null) return adhanAnnouncementGeneral;
    if (prayerName.contains('فجر')) return adhanAnnouncementFajr;
    if (prayerName.contains('ظهر')) return adhanAnnouncementDhuhr;
    if (prayerName.contains('عصر')) return adhanAnnouncementAsr;
    if (prayerName.contains('مغرب')) return adhanAnnouncementMaghrib;
    if (prayerName.contains('عشاء')) return adhanAnnouncementIsha;
    return adhanAnnouncementGeneral;
  }

  static String adhanTakbeerFor(String? prayerName) {
    return adhanTakbeer;
  }

  static String mutunPdf(String bookId) {
    return 'assets/pdfs/mutun/$bookId.pdf';
  }

  static String sharhPdf(String bookId, String file) {
    return 'assets/pdfs/shuruh/$bookId/$file.pdf';
  }
}
