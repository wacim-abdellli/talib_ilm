class AppAssets {
  AppAssets._();

  static const String hadithData = 'assets/data/hadith.json';
  static const String adhkarData = 'assets/data/adhkar.json';
  static const String mutunProgram = 'assets/data/mutun_program.json';
  static const String dailyMotivation = 'assets/data/daily_motivation.json';

  static const String adhanMakkah = 'assets/audio/adhan_makkah.mp3';
  static const String adhanMadinah = 'assets/audio/adhan_madinah.mp3';

  static String mutunPdf(String bookId) {
    return 'assets/pdfs/mutun/$bookId.pdf';
  }

  static String sharhPdf(String bookId, String file) {
    return 'assets/pdfs/shuruh/$bookId/$file.pdf';
  }
}
