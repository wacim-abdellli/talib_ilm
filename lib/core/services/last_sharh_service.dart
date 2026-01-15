import 'package:shared_preferences/shared_preferences.dart';

class LastSharhService {
  static const _prefix = 'last_sharh_file_';

  Future<void> save(String bookId, String sharhFile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$bookId', sharhFile);
  }

  Future<String?> get(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$bookId');
  }
}
