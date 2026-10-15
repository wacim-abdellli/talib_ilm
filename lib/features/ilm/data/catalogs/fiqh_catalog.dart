import '../models/shamela_models.dart';
import 'fiqh_hanbali_shafii_catalog.dart';
import 'fiqh_maliki_hanafi_catalog.dart';

export 'fiqh_hanbali_shafii_catalog.dart';
export 'fiqh_maliki_hanafi_catalog.dart';

/// المذاهب الفقهية الأربعة المعتمدة: الحنبلي (17)، الشافعي (16)، المالكي (15)، الحنفي (14)
class FiqhCatalog {
  /// الفقه الحنبلي (Category ID: 17)
  static List<ShamelaBook> get hanbaliBooks =>
      FiqhHanbaliShafiiCatalog.hanbaliBooks;

  /// الفقه الشافعي (Category ID: 16)
  static List<ShamelaBook> get shafiiBooks =>
      FiqhHanbaliShafiiCatalog.shafiiBooks;

  /// الفقه المالكي (Category ID: 15)
  static List<ShamelaBook> get malikiBooks =>
      FiqhMalikiHanafiCatalog.malikiBooks;

  /// الفقه الحنفي (Category ID: 14)
  static List<ShamelaBook> get hanafiBooks =>
      FiqhMalikiHanafiCatalog.hanafiBooks;

  static List<ShamelaBook> get allBooks => [
        ...hanbaliBooks,
        ...shafiiBooks,
        ...malikiBooks,
        ...hanafiBooks,
      ];
}
