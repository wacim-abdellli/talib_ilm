import 'package:shared_preferences/shared_preferences.dart';

class LastPdfPageService {
  static const _prefix = 'last_pdf_page_';
  static const _totalPrefix = 'last_pdf_total_';

  String _key(String bookId, String pdfPath) => '$_prefix$bookId|$pdfPath';
  String _totalKey(String bookId, String pdfPath) =>
      '$_totalPrefix$bookId|$pdfPath';

  Future<void> save(
    String bookId,
    String pdfPath,
    int page, {
    int? totalPages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(bookId, pdfPath), page);
    if (totalPages != null && totalPages > 0) {
      await prefs.setInt(_totalKey(bookId, pdfPath), totalPages);
    }
  }

  Future<int> get(String bookId, String pdfPath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(bookId, pdfPath)) ?? 1;
  }

  Future<int?> getTotal(String bookId, String pdfPath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalKey(bookId, pdfPath));
  }
}
