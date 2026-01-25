import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';

/// Edition Service - Manages downloadable Quran editions (Riwayat)
/// Handles: Check status, Download, Save, Load from local storage
class EditionService {
  static const String _downloadedEditionsKey = 'downloaded_editions';
  static const String _currentEditionKey = 'current_edition';

  // API endpoints for different editions
  static const Map<String, String> _editionApiUrls = {
    'hafs': 'https://api.alquran.cloud/v1/quran/quran-uthmani',
    'warsh':
        'https://api.alquran.cloud/v1/quran/quran-simple', // Placeholder - real Warsh endpoint needed
    'tajweed': 'https://api.alquran.cloud/v1/quran/quran-tajweed',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK IF EDITION IS DOWNLOADED
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> isEditionDownloaded(String editionId) async {
    // Hafs is always "downloaded" (bundled)
    if (editionId == 'hafs') return true;

    final prefs = await SharedPreferences.getInstance();
    final downloadedList = prefs.getStringList(_downloadedEditionsKey) ?? [];
    return downloadedList.contains(editionId);
  }

  static Future<List<String>> getDownloadedEditions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedEditionsKey) ?? [];
    // Always include hafs
    if (!list.contains('hafs')) {
      list.insert(0, 'hafs');
    }
    return list;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SET/GET CURRENT EDITION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> setCurrentEdition(String editionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentEditionKey, editionId);
  }

  static Future<String> getCurrentEdition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentEditionKey) ?? 'hafs';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD EDITION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Downloads an edition and saves it to local storage
  /// Returns a stream of progress (0.0 to 1.0) and status messages
  static Stream<DownloadProgress> downloadEdition(String editionId) async* {
    yield DownloadProgress(0.05, 'جاري الاتصال...');

    final apiUrl = _editionApiUrls[editionId];
    if (apiUrl == null) {
      yield DownloadProgress(0.0, 'خطأ: رواية غير معروفة', isError: true);
      return;
    }

    try {
      // Stage 1: Fetch from API
      yield DownloadProgress(0.1, 'جاري التحميل من السيرفر...');

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        yield DownloadProgress(
          0.0,
          'فشل التحميل: ${response.statusCode}',
          isError: true,
        );
        return;
      }

      yield DownloadProgress(0.5, 'جاري معالجة البيانات...');

      // Stage 2: Parse and save
      final jsonData = jsonDecode(response.body);

      // Get storage directory
      final directory = await _getEditionsDirectory();
      final file = File('${directory.path}/$editionId.json');

      yield DownloadProgress(0.7, 'جاري الحفظ في الجهاز...');

      // Save the JSON data
      await file.writeAsString(jsonEncode(jsonData));

      yield DownloadProgress(0.9, 'جاري التحقق...');

      // Mark as downloaded in preferences
      final prefs = await SharedPreferences.getInstance();
      final downloadedList = prefs.getStringList(_downloadedEditionsKey) ?? [];
      if (!downloadedList.contains(editionId)) {
        downloadedList.add(editionId);
        await prefs.setStringList(_downloadedEditionsKey, downloadedList);
      }

      yield DownloadProgress(1.0, 'تم بنجاح!');
    } catch (e) {
      debugPrint('Edition download error: $e');
      yield DownloadProgress(
        0.0,
        'حدث خطأ: ${e.toString().substring(0, 50)}',
        isError: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD EDITION DATA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load a surah from a specific edition
  static Future<Surah?> loadSurahFromEdition(
    String editionId,
    int surahNumber,
  ) async {
    // For hafs, use the normal API/cache flow
    if (editionId == 'hafs') {
      return null; // Signal to use default loader
    }

    try {
      final directory = await _getEditionsDirectory();
      final file = File('${directory.path}/$editionId.json');

      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      // Parse the full Quran data and extract the surah
      final data = jsonData['data'];
      if (data == null) return null;

      // The API returns all surahs in 'surahs' array
      final List<dynamic> surahs = data['surahs'] ?? [];
      final surahJson = surahs.firstWhere(
        (s) => s['number'] == surahNumber,
        orElse: () => null,
      );

      if (surahJson == null) return null;

      return Surah.fromJson(surahJson);
    } catch (e) {
      debugPrint('Error loading surah from edition: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE EDITION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> deleteEdition(String editionId) async {
    // Cannot delete hafs
    if (editionId == 'hafs') return false;

    try {
      final directory = await _getEditionsDirectory();
      final file = File('${directory.path}/$editionId.json');

      if (await file.exists()) {
        await file.delete();
      }

      // Remove from downloaded list
      final prefs = await SharedPreferences.getInstance();
      final downloadedList = prefs.getStringList(_downloadedEditionsKey) ?? [];
      downloadedList.remove(editionId);
      await prefs.setStringList(_downloadedEditionsKey, downloadedList);

      // If this was the current edition, switch back to hafs
      final current = await getCurrentEdition();
      if (current == editionId) {
        await setCurrentEdition('hafs');
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting edition: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORAGE SIZE
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<int> getEditionStorageSize(String editionId) async {
    try {
      final directory = await _getEditionsDirectory();
      final file = File('${directory.path}/$editionId.json');

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> getTotalEditionsSize() async {
    try {
      final directory = await _getEditionsDirectory();
      if (!await directory.exists()) return 0;

      int total = 0;
      await for (var entity in directory.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Directory> _getEditionsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final editionsDir = Directory('${appDir.path}/quran_editions');

    if (!await editionsDir.exists()) {
      await editionsDir.create(recursive: true);
    }

    return editionsDir;
  }
}

/// Progress model for download stream
class DownloadProgress {
  final double progress; // 0.0 to 1.0
  final String status;
  final bool isError;

  DownloadProgress(this.progress, this.status, {this.isError = false});
}
