import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_policy.dart';
import '../models/quran_models.dart';

/// Edition Service - Manages downloadable Quran editions (Riwayat)
/// Handles: Check status, Download, Save, Load from local storage.
/// Hardened with streaming byte limits, atomic disk writes, path sanitization, and test seams.
class EditionService {
  static const String _downloadedEditionsKey = 'downloaded_editions';
  static const String _currentEditionKey = 'current_edition';

  // API endpoints for different editions
  static const Map<String, String> _editionApiUrls = {
    'hafs': 'https://api.alquran.cloud/v1/quran/quran-uthmani',
    'warsh': 'https://api.alquran.cloud/v1/quran/quran-simple',
    'tajweed': 'https://api.alquran.cloud/v1/quran/quran-tajweed',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HTTP TEST SEAM & TEST DIRECTORY OVERRIDE
  // ═══════════════════════════════════════════════════════════════════════════

  static http.Client? _injectedClient;
  static http.Client? _defaultClient;

  @visibleForTesting
  static Directory? testBaseDir;

  @visibleForTesting
  static Future<void> Function(File source, File destination)? testFileInstaller;

  static final Set<String> _activeDownloads = {};

  @visibleForTesting
  static void setHttpClient(http.Client client) {
    _injectedClient = client;
  }

  @visibleForTesting
  static void resetHttpClient() {
    _injectedClient?.close();
    _injectedClient = null;
    _defaultClient?.close();
    _defaultClient = null;
  }

  static http.Client get _client =>
      _injectedClient ?? (_defaultClient ??= http.Client());

  @visibleForTesting
  static void resetForTesting() {
    resetHttpClient();
    testBaseDir = null;
    testFileInstaller = null;
    _activeDownloads.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT VALIDATION & PATH SANITIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static bool isValidEditionId(String editionId) {
    if (editionId.trim().isEmpty) return false;
    // Disallow path traversal characters
    if (editionId.contains('/') ||
        editionId.contains('\\') ||
        editionId.contains('..')) {
      return false;
    }
    return _editionApiUrls.containsKey(editionId);
  }

  static bool isValidSurahNumber(int number) => number >= 1 && number <= 114;

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK IF EDITION IS DOWNLOADED
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> isEditionDownloaded(String editionId) async {
    // Hafs is always "downloaded" (bundled)
    if (editionId == 'hafs') return true;
    if (!isValidEditionId(editionId)) return false;

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
    if (!isValidEditionId(editionId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentEditionKey, editionId);
  }

  static Future<String> getCurrentEdition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentEditionKey) ?? 'hafs';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD EDITION (STREAMED, BYTE-CAPPED, ATOMIC WRITE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Downloads an edition and atomically saves it to local storage.
  /// Enforces AppPolicy.maxQuranEditionBytes streaming limit.
  static Stream<DownloadProgress> downloadEdition(String editionId) async* {
    yield DownloadProgress(0.05, 'جاري الاتصال...');

    if (!isValidEditionId(editionId)) {
      yield DownloadProgress(0.0, 'خطأ: رواية غير معروفة', isError: true);
      return;
    }

    if (_activeDownloads.contains(editionId)) {
      yield DownloadProgress(
        0.0,
        'التحميل قيد التنفيذ بالفعل',
        isError: true,
      );
      return;
    }

    final apiUrl = _editionApiUrls[editionId]!;
    _activeDownloads.add(editionId);

    File? tmpFile;
    IOSink? sink;
    try {
      yield DownloadProgress(0.1, 'جاري التحميل من السيرفر...');

      final request = http.Request('GET', Uri.parse(apiUrl));
      final streamedResponse = await _client.send(request).timeout(
            AppPolicy.networkLong,
          );

      if (streamedResponse.statusCode != 200) {
        yield DownloadProgress(
          0.0,
          'فشل التحميل: ${streamedResponse.statusCode}',
          isError: true,
        );
        return;
      }

      final contentLength = streamedResponse.contentLength;
      final maxBytes = AppPolicy.maxQuranEditionBytes;
      if (contentLength != null && contentLength > maxBytes) {
        yield DownloadProgress(
          0.0,
          'حجم الرواية يتجاوز الحد المسموح',
          isError: true,
        );
        return;
      }

      final directory = await _getEditionsDirectory();
      tmpFile = File('${directory.path}/$editionId.json.tmp');
      sink = tmpFile.openWrite();

      int receivedBytes = 0;
      final completer = Completer<void>();
      late final StreamSubscription<List<int>> subscription;

      subscription = streamedResponse.stream.listen(
        (chunk) {
          receivedBytes += chunk.length;
          if (receivedBytes > maxBytes) {
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                Exception(
                  'Payload exceeded maximum edition size ($maxBytes bytes)',
                ),
              );
            }
            return;
          }
          sink?.add(chunk);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) completer.completeError(error, stackTrace);
        },
        onDone: () async {
          if (sink != null) {
            await sink.flush();
            await sink.close();
          }
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future.timeout(
        AppPolicy.networkLong,
        onTimeout: () {
          subscription.cancel();
          throw TimeoutException('انتهت مهلة تحميل الرواية');
        },
      );

      yield DownloadProgress(0.6, 'جاري معالجة البيانات...');

      // Validate JSON data integrity
      final rawString = await tmpFile.readAsString();
      final jsonData = jsonDecode(rawString);
      if (jsonData is! Map<String, dynamic> || jsonData['data'] == null) {
        throw const FormatException('بيانات الرواية غير صالحة');
      }

      yield DownloadProgress(0.8, 'جاري الحفظ في الجهاز...');

      // AUD-101: Failure-safe atomic replacement preserving existing offline edition.
      // 1. If an existing edition file is present, move it to a temporary backup (.bak).
      // 2. Install the new validated file into place.
      // 3. If installation fails, roll back the backup file to restore the previous edition.
      // 4. On successful installation, delete the backup file.
      final finalFile = File('${directory.path}/$editionId.json');
      final backupFile = File('${directory.path}/$editionId.json.bak');
      final hadExisting = await finalFile.exists();

      if (hadExisting) {
        if (await backupFile.exists()) {
          try {
            await backupFile.delete();
          } catch (_) {}
        }
        await finalFile.rename(backupFile.path);
      }

      try {
        final installer = testFileInstaller ?? (File src, File dst) => src.rename(dst.path);
        await installer(tmpFile, finalFile);

        // Installation succeeded: safely delete backup
        if (hadExisting && await backupFile.exists()) {
          try {
            await backupFile.delete();
          } catch (_) {}
        }
      } catch (installError) {
        // Rollback: restore backupFile back to finalFile if it existed
        if (hadExisting && await backupFile.exists()) {
          try {
            if (await finalFile.exists()) {
              await finalFile.delete();
            }
            await backupFile.rename(finalFile.path);
          } catch (_) {}
        }
        rethrow;
      }

      yield DownloadProgress(0.95, 'جاري التحديث...');

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
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (tmpFile != null && await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {}
      }
      final msg = e.toString();
      yield DownloadProgress(
        0.0,
        'حدث خطأ: ${msg.length > 50 ? msg.substring(0, 50) : msg}',
        isError: true,
      );
    } finally {
      _activeDownloads.remove(editionId);
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
    if (editionId == 'hafs') return null;
    if (!isValidEditionId(editionId) || !isValidSurahNumber(surahNumber)) {
      return null;
    }

    try {
      final directory = await _getEditionsDirectory();
      final file = File('${directory.path}/$editionId.json');
      final backupFile = File('${directory.path}/$editionId.json.bak');

      // Crash-recovery: if primary file was midway through replacement when crash occurred
      if (!await file.exists() && await backupFile.exists()) {
        try {
          await backupFile.rename(file.path);
        } catch (_) {}
      }

      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      final data = jsonData['data'];
      if (data == null) return null;

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
    if (editionId == 'hafs' || !isValidEditionId(editionId)) return false;

    try {
      final directory = await _getEditionsDirectory();
      final file = File('${directory.path}/$editionId.json');
      final backupFile = File('${directory.path}/$editionId.json.bak');
      final tmpFile = File('${directory.path}/$editionId.json.tmp');

      if (await file.exists()) {
        await file.delete();
      }
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      final downloadedList = prefs.getStringList(_downloadedEditionsKey) ?? [];
      downloadedList.remove(editionId);
      await prefs.setStringList(_downloadedEditionsKey, downloadedList);

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
    if (!isValidEditionId(editionId)) return 0;
    try {
      final directory = await _getEditionsDirectory();
      final file = File('${directory.path}/$editionId.json');

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getTotalEditionsSize() async {
    try {
      final directory = await _getEditionsDirectory();
      if (!await directory.exists()) return 0;

      int total = 0;
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Directory> _getEditionsDirectory() async {
    if (testBaseDir != null) {
      if (!await testBaseDir!.exists()) {
        await testBaseDir!.create(recursive: true);
      }
      return testBaseDir!;
    }

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
