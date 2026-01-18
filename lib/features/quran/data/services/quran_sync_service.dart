import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/quran_database.dart';
import 'quran_page_service.dart';

class QuranSyncService {
  static const String _syncKey = 'quran_full_synced';
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  // Singleton
  static final QuranSyncService _instance = QuranSyncService._();
  QuranSyncService._();
  static QuranSyncService get instance => _instance;

  final StreamController<double> _progressController =
      StreamController.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Check if Quran is fully downloaded
  Future<bool> isQuranDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncKey) ?? false;
  }

  /// Start full download (Option B)
  Future<void> startFullSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _progressController.add(0.0);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Strategy: Download all 604 pages
      for (int i = 1; i <= 604; i++) {
        // Check if page exists in DB (resume capability)
        final existing = await QuranDatabase.instance.getPage(i);
        if (existing == null) {
          await _fetchAndSavePage(i);
        }

        // Update progress
        double progress = i / 604;
        _progressController.add(progress);

        // Tiny throttle to prevent aggressive rate limiting
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Mark as done
      await prefs.setBool(_syncKey, true);
      _progressController.add(1.0);
      print('Quran Sync Completed Successfully.');
    } catch (e) {
      print('Sync Failed: $e');
      _progressController.addError(e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _fetchAndSavePage(int pageNumber) async {
    // Retry logic
    int attempts = 0;
    while (attempts < 3) {
      try {
        final uri = Uri.parse(
          '$_baseUrl/verses/by_page/$pageNumber?fields=text_uthmani',
        );
        final response = await http
            .get(
              uri,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final data = QuranPageData.fromApiResponse(pageNumber, json);
          await QuranDatabase.instance.savePage(pageNumber, data);
          return; // Success
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        attempts++;
        if (attempts >= 3) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
