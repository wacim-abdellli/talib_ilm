import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/data/models/last_activity.dart';

class PdfPageInfo {
  final int page;
  final int total;

  const PdfPageInfo({required this.page, required this.total});
}

class LastActivityService {
  static const _keyBookId = 'last_activity_book';
  static const _keyTab = 'last_activity_tab';
  static const _keySharhFile = 'last_activity_sharh_file';

  static const tabMutn = 'mutn';
  static const tabSharh = 'sharh';
  static const tabLessons = 'lessons';

  String pdfKeyForMutn(String bookId) => 'pdf_page:$bookId:mutn';

  String pdfKeyForSharh(String bookId, String sharhFile) =>
      'pdf_page:$bookId:sharh:$sharhFile';

  Future<void> setLastBook(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBookId, bookId);
  }

  Future<void> setLastTab(String bookId, String tab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBookId, bookId);
    await prefs.setString(_keyTab, tab);
    if (tab != tabSharh) {
      await prefs.remove(_keySharhFile);
    }
  }

  Future<void> setLastSharh(String bookId, String sharhFile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBookId, bookId);
    await prefs.setString(_keyTab, tabSharh);
    await prefs.setString(_keySharhFile, sharhFile);
  }

  Future<void> savePdfPage({
    required String key,
    required int page,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$key:page', page);
    await prefs.setInt('$key:total', total);
  }

  Future<PdfPageInfo?> getPdfPage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final page = prefs.getInt('$key:page');
    final total = prefs.getInt('$key:total');

    if (page == null && total == null) return null;

    return PdfPageInfo(
      page: page ?? 1,
      total: total ?? 0,
    );
  }

  Future<LastActivity?> getLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final bookId = prefs.getString(_keyBookId);
    final tab = prefs.getString(_keyTab);

    if (bookId == null || tab == null) return null;

    final sharhFile = prefs.getString(_keySharhFile);
    String? pdfKey;

    if (tab == tabMutn) {
      pdfKey = pdfKeyForMutn(bookId);
    } else if (tab == tabSharh && sharhFile != null) {
      pdfKey = pdfKeyForSharh(bookId, sharhFile);
    }

    int? page;
    int? total;
    if (pdfKey != null) {
      final info = await getPdfPage(pdfKey);
      page = info?.page;
      total = info?.total;
    }

    return LastActivity(
      bookId: bookId,
      tab: tab,
      sharhFile: sharhFile,
      page: page,
      total: total,
    );
  }
}
