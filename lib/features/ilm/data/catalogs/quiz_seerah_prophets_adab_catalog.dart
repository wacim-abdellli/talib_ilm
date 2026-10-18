import '../models/islamic_quiz_models.dart';
import 'quiz_adab_catalog.dart';
import 'quiz_prophets_catalog.dart';
import 'quiz_seerah_catalog.dart';

/// Legacy proxy for Seerah, Prophets, and Adab catalogs for backwards compatibility.
class QuizSeerahProphetsAdabCatalog {
  QuizSeerahProphetsAdabCatalog._();

  static FanQuiz get seerahFan => QuizSeerahCatalog.seerahFan;
  static FanQuiz get prophetsNamesFan => QuizProphetsCatalog.prophetsNamesFan;
  static FanQuiz get adabFan => QuizAdabCatalog.adabFan;
}
