import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import 'quran_audio_service.dart';

export '../models/surah_download_progress.dart';
import '../models/surah_download_progress.dart';

/// Service managing offline downloading, storage tracking, and local cache
/// resolution for Holy Quran audio recitations by Surah.
class QuranAudioDownloader {
  static final QuranAudioDownloader _instance =
      QuranAudioDownloader._internal();
  factory QuranAudioDownloader() => _instance;
  QuranAudioDownloader._internal();

  /// Directory root override for unit testing
  static Directory? testBaseDir;

  /// Notifier mapping key `${reciterId}_${surah}` to active download progress.
  final ValueNotifier<Map<String, SurahDownloadProgress>>
      downloadProgressNotifier =
      ValueNotifier<Map<String, SurahDownloadProgress>>({});

  /// Control flags to support pause and cancel
  final Map<String, bool> _pauseFlags = {};
  final Map<String, bool> _cancelFlags = {};
  final Map<String, http.Client> _activeHttpClients = {};

  /// In-flight active download futures (C14: join/no-op duplicate requests)
  final Map<String, Future<void>> _inFlightDownloads = {};

  /// Operation generations to prevent stale operations from mutating state (C14)
  final Map<String, int> _operationGenerations = {};

  static String _formatNumber(int n) => n.toString().padLeft(3, '0');

  /// Base directory for storing audio files: `<app_doc>/quran_audio/`
  static Future<Directory> getAudioBaseDir() async {
    if (testBaseDir != null) return testBaseDir!;
    final appDoc = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDoc.path}/quran_audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory for a specific reciter and surah
  static Future<Directory> getSurahDir(int surah, String reciterId) async {
    final base = await getAudioBaseDir();
    final dir = Directory('${base.path}/$reciterId/$surah');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Local path for a specific verse file
  static Future<String> getLocalAyahPath(
    int surah,
    int ayah, {
    QuranReciter? reciter,
  }) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final dir = await getSurahDir(surah, r.id);
    final sStr = _formatNumber(surah);
    final aStr = _formatNumber(ayah);
    return '${dir.path}/$sStr$aStr.mp3';
  }

  /// Check whether an ayah audio file exists, has plausible size (>= 32 bytes),
  /// and does not start with ASCII text markup (<html, {"error", etc.).
  static bool isAyahAudioFileValid(File file) {
    if (!file.existsSync()) return false;
    final length = file.lengthSync();
    if (length < 32) return false;
    try {
      final raf = file.openSync(mode: FileMode.read);
      try {
        final sampleSize = length < 64 ? length : 64;
        final header = raf.readSync(sampleSize);
        if (header.isEmpty) return false;
        final first = header[0];
        // '<' (0x3C), '{' (0x7B), '[' (0x5B), '!' (0x21)
        if (first == 0x3C || first == 0x7B || first == 0x5B || first == 0x21) {
          return false;
        }
        return true;
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return false;
    }
  }

  /// Check whether an entire surah has all verses downloaded and verified
  static Future<bool> isSurahDownloaded(
    int surah, {
    QuranReciter? reciter,
  }) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final dir = await getSurahDir(surah, r.id);
    if (!await dir.exists()) return false;

    final totalVerses = quran.getVerseCount(surah);
    for (int a = 1; a <= totalVerses; a++) {
      final sStr = _formatNumber(surah);
      final aStr = _formatNumber(a);
      final file = File('${dir.path}/$sStr$aStr.mp3');
      if (!isAyahAudioFileValid(file)) {
        return false;
      }
    }
    return true;
  }

  /// Calculate total size of downloaded files for a surah in bytes
  static Future<int> getSurahDownloadedBytes(
    int surah, {
    QuranReciter? reciter,
  }) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final dir = await getSurahDir(surah, r.id);
    if (!await dir.exists()) return 0;

    int total = 0;
    try {
      final files = dir.listSync();
      for (final f in files) {
        if (f is File && f.path.endsWith('.mp3') && isAyahAudioFileValid(f)) {
          total += f.lengthSync();
        }
      }
    } catch (_) {}
    return total;
  }

  /// Total storage used across all reciters or a specific reciter
  static Future<int> getTotalStorageUsed({String? reciterId}) async {
    final base = await getAudioBaseDir();
    if (!await base.exists()) return 0;

    int totalBytes = 0;
    try {
      final entities = base.listSync(recursive: true);
      for (final e in entities) {
        if (e is File && e.path.endsWith('.mp3')) {
          if (reciterId != null) {
            // Check if within reciter's directory
            final normalized = e.path.replaceAll('\\', '/');
            if (!normalized.contains('/$reciterId/')) continue;
          }
          totalBytes += e.lengthSync();
        }
      }
    } catch (_) {}
    return totalBytes;
  }

  /// Estimates the total download size of a surah in megabytes
  static double estimateSurahSizeMb(int surah, {QuranReciter? reciter}) {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final totalVerses = quran.getVerseCount(surah);

    // Approximate size in KB per verse based on bitrate
    int kbPerVerse = 85;
    if (r.subfolder.contains('64kbps')) {
      kbPerVerse = 45;
    } else if (r.subfolder.contains('40kbps')) {
      kbPerVerse = 28;
    }

    final totalKb = totalVerses * kbPerVerse;
    return totalKb / 1024.0;
  }

  /// Human-friendly format for bytes
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 ب';
    const suffixes = ['ب', 'ك.ب', 'م.ب', 'ج.ب'];
    int i = 0;
    double dBytes = bytes.toDouble();
    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }
    return '${dBytes.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Downloads all verses for a Surah sequentially.
  /// Automatically joins any in-flight download for the same reciter/surah.
  /// Automatically resumes by skipping any verses already stored on disk and verified.
  Future<void> downloadSurah({
    required int surah,
    QuranReciter? reciter,
    http.Client? client,
  }) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final key = '${r.id}_$surah';

    // C14: Join in-flight download if one is already active (join / no-op)
    final existingFuture = _inFlightDownloads[key];
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = _executeDownloadSurah(
      surah: surah,
      reciter: r,
      client: client,
    );
    _inFlightDownloads[key] = future;
    return future;
  }

  Future<void> _executeDownloadSurah({
    required int surah,
    required QuranReciter reciter,
    http.Client? client,
  }) async {
    final key = '${reciter.id}_$surah';
    final gen = (_operationGenerations[key] ?? 0) + 1;
    _operationGenerations[key] = gen;

    final totalVerses = quran.getVerseCount(surah);
    final surahDir = await getSurahDir(surah, reciter.id);

    _pauseFlags[key] = false;
    _cancelFlags[key] = false;

    final bool ownsClient = client == null;
    final httpClient = client ?? http.Client();
    _activeHttpClients[key] = httpClient;

    try {
      // Check already downloaded and verified verses for resume
      int existingCount = 0;
      int existingBytes = 0;
      for (int a = 1; a <= totalVerses; a++) {
        final sStr = _formatNumber(surah);
        final aStr = _formatNumber(a);
        final file = File('${surahDir.path}/$sStr$aStr.mp3');
        if (isAyahAudioFileValid(file)) {
          existingCount++;
          existingBytes += file.lengthSync();
        } else if (file.existsSync()) {
          // Stale / corrupted / empty file from older runs: delete so it re-downloads
          try {
            file.deleteSync();
          } catch (_) {}
        }
      }

      if (_operationGenerations[key] != gen) return;

      if (existingCount == totalVerses) {
        _setProg(key, surah, reciter.id, totalVerses, totalVerses, existingBytes, SurahDownloadStatus.completed);
        return;
      }

      _setProg(key, surah, reciter.id, existingCount, totalVerses, existingBytes, SurahDownloadStatus.downloading);

      int currentCount = existingCount;
      int currentBytes = existingBytes;

      // Clean up any stale temp files from prior aborted attempts
      try {
        if (await surahDir.exists()) {
          for (final file in surahDir.listSync()) {
            if (file is File && file.path.endsWith('.tmp')) {
              file.deleteSync();
            }
          }
        }
      } catch (_) {}

      for (int a = 1; a <= totalVerses; a++) {
        if (_operationGenerations[key] != gen) return;

        // Check for pause
        if (_pauseFlags[key] == true) {
          _setProg(key, surah, reciter.id, currentCount, totalVerses, currentBytes, SurahDownloadStatus.paused);
          return;
        }

        // Check for cancel
        if (_cancelFlags[key] == true) {
          _removeProgress(key);
          return;
        }

        final sStr = _formatNumber(surah);
        final aStr = _formatNumber(a);
        final targetFile = File('${surahDir.path}/$sStr$aStr.mp3');

        // If already downloaded and valid, skip
        if (isAyahAudioFileValid(targetFile)) {
          continue;
        }

        final remoteUrl =
            'https://everyayah.com/data/${reciter.subfolder}/$sStr$aStr.mp3';
        final tempFile = File('${surahDir.path}/$sStr${aStr}_g$gen.tmp');

        try {
          final request = http.Request('GET', Uri.parse(remoteUrl));
          // C15: Connection deadline
          final http.StreamedResponse response = await httpClient
              .send(request)
              .timeout(AppMotion.networkTimeout);

          if (response.statusCode != 200) {
            throw HttpException('Server returned ${response.statusCode}');
          }

          // C15: Content-Type check (reject 200 HTML or text error body)
          final contentType =
              response.headers['content-type']?.toLowerCase() ?? '';
          if (contentType.contains('text/html') ||
              contentType.contains('text/plain') ||
              contentType.contains('application/json')) {
            throw const HttpException('استجابة الخادم غير صالحة (HTML/Text)');
          }

          final expectedLength = response.contentLength;
          final sink = tempFile.openWrite();
          int downloadedAyahBytes = 0;
          const int maxAyahBytes = 25 * 1024 * 1024; // 25 MB max bound

          try {
            // C15: Body chunk idle timeout
            await for (final chunk
                in response.stream.timeout(AppMotion.networkMedium)) {
              if (_cancelFlags[key] == true ||
                  _pauseFlags[key] == true ||
                  _operationGenerations[key] != gen) {
                break;
              }
              downloadedAyahBytes += chunk.length;
              if (downloadedAyahBytes > maxAyahBytes) {
                throw const HttpException('حجم الآية يتجاوز الحد المسموح به');
              }
              sink.add(chunk);
            }
          } finally {
            await sink.flush();
            await sink.close();
          }

          // Check if superseded during download
          if (_operationGenerations[key] != gen) {
            try {
              if (tempFile.existsSync()) await tempFile.delete();
            } catch (_) {}
            return;
          }

          // Check if canceled during write
          if (_cancelFlags[key] == true) {
            try {
              if (tempFile.existsSync()) await tempFile.delete();
            } catch (_) {}
            _removeProgress(key);
            return;
          }

          // Check if paused during write
          if (_pauseFlags[key] == true) {
            try {
              if (tempFile.existsSync()) await tempFile.delete();
            } catch (_) {}
            _setProg(key, surah, reciter.id, currentCount, totalVerses, currentBytes, SurahDownloadStatus.paused);
            return;
          }

          // C15: Integrity validation before atomic promotion
          // 1. Nonempty check
          if (!tempFile.existsSync() || tempFile.lengthSync() == 0) {
            try {
              if (tempFile.existsSync()) await tempFile.delete();
            } catch (_) {}
            throw const HttpException('الملف الصوتي المستلم فارغ');
          }

          // 2. Declared Content-Length check
          if (expectedLength != null && expectedLength > 0) {
            if (downloadedAyahBytes != expectedLength) {
              try {
                if (tempFile.existsSync()) await tempFile.delete();
              } catch (_) {}
              throw HttpException(
                'تم استلام ملف مبتور ($downloadedAyahBytes من $expectedLength بايت)',
              );
            }
          }

          // 3. Plausible audio validation
          if (!isAyahAudioFileValid(tempFile)) {
            try {
              if (tempFile.existsSync()) await tempFile.delete();
            } catch (_) {}
            throw const HttpException('الملف الصوتي المستلم تالف أو غير صالح');
          }

          // Atomic promotion: rename temp to target
          if (targetFile.existsSync()) await targetFile.delete();
          await tempFile.rename(targetFile.path);

          currentCount++;
          currentBytes += targetFile.lengthSync();

          _setProg(
            key,
            surah,
            reciter.id,
            currentCount,
            totalVerses,
            currentBytes,
            currentCount == totalVerses ? SurahDownloadStatus.completed : SurahDownloadStatus.downloading,
          );
        } catch (e) {
          // Safely cleanup temp file
          try {
            if (tempFile.existsSync()) await tempFile.delete();
          } catch (_) {}

          if (_operationGenerations[key] != gen) return;

          // User intentionally canceled
          if (_cancelFlags[key] == true) {
            _removeProgress(key);
            return;
          }

          // User intentionally paused
          if (_pauseFlags[key] == true) {
            _setProg(key, surah, reciter.id, currentCount, totalVerses, currentBytes, SurahDownloadStatus.paused);
            return;
          }

          // True network or disk failure
          final isDiskError = e is FileSystemException;
          final String errorMsg;
          if (isDiskError) {
            errorMsg = 'المساحة التخزينية غير كافية لإكمال التنزيل';
          } else if (e is TimeoutException) {
            errorMsg = 'انتهت مهلة الاتصال بالخادم، يرجى المحاولة لاحقاً';
          } else if (e is HttpException) {
            errorMsg = e.message;
          } else if (e.toString().contains('Connection closed') ||
              e.toString().contains('SocketException') ||
              e.toString().contains('TimeoutException') ||
              e.toString().contains('Failed host lookup') ||
              e.toString().contains('ClientException')) {
            errorMsg = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت';
          } else {
            errorMsg = 'تعذر تحميل الآية $a، يرجى إعادة المحاولة';
          }

          _setProg(
            key,
            surah,
            reciter.id,
            currentCount,
            totalVerses,
            currentBytes,
            SurahDownloadStatus.failed,
            errorMsg,
          );
          return;
        }
      }

      if (_operationGenerations[key] == gen) {
        _setProg(key, surah, reciter.id, totalVerses, totalVerses, currentBytes, SurahDownloadStatus.completed);
      }
    } finally {
      // C16: Release resources and in-flight tracking on every exit
      _inFlightDownloads.remove(key);
      _activeHttpClients.remove(key);
      if (ownsClient) {
        httpClient.close();
      }
    }
  }

  void pauseDownload(int surah, {QuranReciter? reciter}) {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final key = '${r.id}_$surah';
    _pauseFlags[key] = true;
    _cancelFlags[key] = false;
    _activeHttpClients[key]?.close();
    _activeHttpClients.remove(key);

    final prev = downloadProgressNotifier.value[key];
    if (prev != null) {
      _setProg(
        key,
        surah,
        r.id,
        prev.downloadedAyahs,
        prev.totalAyahs,
        prev.downloadedBytes,
        SurahDownloadStatus.paused,
      );
    }
  }

  void cancelDownload(int surah, {QuranReciter? reciter}) {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final key = '${r.id}_$surah';
    _cancelFlags[key] = true;
    _pauseFlags[key] = false;
    // Advance generation so in-flight writes cannot promote or alter state
    _operationGenerations[key] = (_operationGenerations[key] ?? 0) + 1;
    _activeHttpClients[key]?.close();
    _activeHttpClients.remove(key);

    // Clean up any temp files for this surah
    getSurahDir(surah, r.id).then((dir) {
      try {
        if (dir.existsSync()) {
          for (final file in dir.listSync()) {
            if (file is File && file.path.endsWith('.tmp')) {
              file.deleteSync();
            }
          }
        }
      } catch (_) {}
    });

    _removeProgress(key);
  }

  /// Reset internal state and notifiers for test isolation
  void resetStateForTesting() {
    _inFlightDownloads.clear();
    _operationGenerations.clear();
    _pauseFlags.clear();
    _cancelFlags.clear();
    for (final client in _activeHttpClients.values) {
      client.close();
    }
    _activeHttpClients.clear();
    downloadProgressNotifier.value = {};
  }

  /// Delete all downloaded audio files for a specific Surah
  static Future<void> deleteSurahAudio(
    int surah, {
    QuranReciter? reciter,
  }) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final dir = await getSurahDir(surah, r.id);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Delete all downloaded audio files across all reciters
  static Future<void> deleteAllDownloadedAudio() async {
    final base = await getAudioBaseDir();
    if (await base.exists()) {
      await base.delete(recursive: true);
      await base.create(recursive: true);
    }
  }

  void _setProg(String key, int surah, String reciterId, int downloadedAyahs,
      int totalAyahs, int downloadedBytes, SurahDownloadStatus status, [String? errorMessage]) {
    _updateProgress(
      key,
      SurahDownloadProgress(
        surah: surah,
        reciterId: reciterId,
        downloadedAyahs: downloadedAyahs,
        totalAyahs: totalAyahs,
        downloadedBytes: downloadedBytes,
        status: status,
        errorMessage: errorMessage,
      ),
    );
  }

  void _updateProgress(String key, SurahDownloadProgress progress) {
    final current = Map<String, SurahDownloadProgress>.from(downloadProgressNotifier.value);
    current[key] = progress;
    downloadProgressNotifier.value = current;
  }

  void _removeProgress(String key) {
    final current = Map<String, SurahDownloadProgress>.from(downloadProgressNotifier.value);
    current.remove(key);
    downloadProgressNotifier.value = current;
  }
}
