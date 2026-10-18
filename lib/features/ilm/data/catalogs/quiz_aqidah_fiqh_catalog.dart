import '../models/islamic_quiz_models.dart';
import 'quiz_aqidah_catalog.dart';
import 'quiz_fiqh_catalog.dart';

/// Legacy proxy for Aqidah and Fiqh catalogs for backwards compatibility.
class QuizAqidahFiqhCatalog {
  QuizAqidahFiqhCatalog._();

  static FanQuiz get aqidahFan => QuizAqidahCatalog.aqidahFan;
  static FanQuiz get fiqhFan => QuizFiqhCatalog.fiqhFan;
}
