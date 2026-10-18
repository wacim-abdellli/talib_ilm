import '../models/islamic_quiz_models.dart';
import 'quiz_hadith_catalog.dart';
import 'quiz_quran_catalog.dart';

/// Legacy proxy for Hadith and Quran catalogs for backwards compatibility.
class QuizHadithQuranCatalog {
  QuizHadithQuranCatalog._();

  static FanQuiz get hadithFan => QuizHadithCatalog.hadithFan;
  static FanQuiz get quranFan => QuizQuranCatalog.quranFan;
}
