import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import 'quran_audio_service.dart';

enum SurahDownloadStatus {
  idle,
  downloading,
  paused,
  completed,
  failed,
}

class SurahDownloadProgress {
  final int surah;
  final String reciterId;
  final int downloadedAyahs;
  final int totalAyahs;
  final int downloadedBytes;
  final SurahDownloadStatus status;
  final String? errorMessage;

  const SurahDownloadProgress({
    required this.surah,
    required this.reciterId,
    required this.downloadedAyahs,
    required this.totalAyahs,
    required this.downloadedBytes,
    required this.status,
    this.errorMessage,
  });

  double get progressFraction =>
      totalAyahs > 0 ? (downloadedAyahs / totalAyahs).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == SurahDownloadStatus.completed;
  bool get isDownloading => status == SurahDownloadStatus.downloading;
  bool get isPaused => status == SurahDownloadStatus.paused;
}

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
      if (!file.existsSync() || file.lengthSync() == 0) {
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
        if (f is File && f.path.endsWith('.mp3')) {
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
  /// Automatically resumes by skipping any verses already stored on disk.
  Future<void> downloadSurah({
    required int surah,
    QuranReciter? reciter,
    http.Client? client,
  }) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final key = '${r.id}_$surah';
    final totalVerses = quran.getVerseCount(surah);
    final surahDir = await getSurahDir(surah, r.id);

    _pauseFlags[key] = false;
    _cancelFlags[key] = false;

    final httpClient = client ?? http.Client();
    _activeHttpClients[key] = httpClient;

    // Check already downloaded verses for resume
    int existingCount = 0;
    int existingBytes = 0;
    for (int a = 1; a <= totalVerses; a++) {
      final sStr = _formatNumber(surah);
      final aStr = _formatNumber(a);
      final file = File('${surahDir.path}/$sStr$aStr.mp3');
      if (file.existsSync() && file.lengthSync() > 0) {
        existingCount++;
        existingBytes += file.lengthSync();
      }
    }

    if (existingCount == totalVerses) {
      _updateProgress(
        key,
        SurahDownloadProgress(
          surah: surah,
          reciterId: r.id,
          downloadedAyahs: totalVerses,
          totalAyahs: totalVerses,
          downloadedBytes: existingBytes,
          status: SurahDownloadStatus.completed,
        ),
      );
      return;
    }

    _updateProgress(
      key,
      SurahDownloadProgress(
        surah: surah,
        reciterId: r.id,
        downloadedAyahs: existingCount,
        totalAyahs: totalVerses,
        downloadedBytes: existingBytes,
        status: SurahDownloadStatus.downloading,
      ),
    );

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
      // Check for pause
      if (_pauseFlags[key] == true) {
        _updateProgress(
          key,
          SurahDownloadProgress(
            surah: surah,
            reciterId: r.id,
            downloadedAyahs: currentCount,
            totalAyahs: totalVerses,
            downloadedBytes: currentBytes,
            status: SurahDownloadStatus.paused,
          ),
        );
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
      if (targetFile.existsSync() && targetFile.lengthSync() > 0) {
        continue;
      }

      final remoteUrl =
          'https://everyayah.com/data/${r.subfolder}/$sStr$aStr.mp3';

      try {
        final request = http.Request('GET', Uri.parse(remoteUrl));
        final response = await httpClient.send(request);

        if (response.statusCode != 200) {
          throw HttpException('Server returned ${response.statusCode}');
        }

        final tempFile = File('${surahDir.path}/$sStr$aStr.tmp');
        final sink = tempFile.openWrite();

        try {
          await response.stream.listen(
            (chunk) {
              sink.add(chunk);
            },
            cancelOnError: true,
          ).asFuture<void>();
        } finally {
          await sink.flush();
          await sink.close();
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
          _updateProgress(
            key,
            SurahDownloadProgress(
              surah: surah,
              reciterId: r.id,
              downloadedAyahs: currentCount,
              totalAyahs: totalVerses,
              downloadedBytes: currentBytes,
              status: SurahDownloadStatus.paused,
            ),
          );
          return;
        }

        // Rename temp to target
        if (targetFile.existsSync()) await targetFile.delete();
        await tempFile.rename(targetFile.path);

        currentCount++;
        currentBytes += targetFile.lengthSync();

        _updateProgress(
          key,
          SurahDownloadProgress(
            surah: surah,
            reciterId: r.id,
            downloadedAyahs: currentCount,
            totalAyahs: totalVerses,
            downloadedBytes: currentBytes,
            status: currentCount == totalVerses
                ? SurahDownloadStatus.completed
                : SurahDownloadStatus.downloading,
          ),
        );
      } catch (e) {
        // Safely cleanup temp file
        try {
          final tempFile = File('${surahDir.path}/$sStr$aStr.tmp');
          if (tempFile.existsSync()) await tempFile.delete();
        } catch (_) {}

        // User intentionally canceled
        if (_cancelFlags[key] == true) {
          _removeProgress(key);
          return;
        }

        // User intentionally paused
        if (_pauseFlags[key] == true) {
          _updateProgress(
            key,
            SurahDownloadProgress(
              surah: surah,
              reciterId: r.id,
              downloadedAyahs: currentCount,
              totalAyahs: totalVerses,
              downloadedBytes: currentBytes,
              status: SurahDownloadStatus.paused,
            ),
          );
          return;
        }

        // True network or disk failure
        final isDiskError = e is FileSystemException;
        final String errorMsg;
        if (isDiskError) {
          errorMsg = 'المساحة التخزينية غير كافية لإكمال التنزيل';
        } else if (e.toString().contains('Connection closed') ||
            e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('ClientException')) {
          errorMsg = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت';
        } else {
          errorMsg = 'تعذر تحميل الآية $a، يرجى إعادة المحاولة';
        }

        _updateProgress(
          key,
          SurahDownloadProgress(
            surah: surah,
            reciterId: r.id,
            downloadedAyahs: currentCount,
            totalAyahs: totalVerses,
            downloadedBytes: currentBytes,
            status: SurahDownloadStatus.failed,
            errorMessage: errorMsg,
          ),
        );
        return;
      }
    }

    _updateProgress(
      key,
      SurahDownloadProgress(
        surah: surah,
        reciterId: r.id,
        downloadedAyahs: totalVerses,
        totalAyahs: totalVerses,
        downloadedBytes: currentBytes,
        status: SurahDownloadStatus.completed,
      ),
    );
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
      _updateProgress(
        key,
        SurahDownloadProgress(
          surah: surah,
          reciterId: r.id,
          downloadedAyahs: prev.downloadedAyahs,
          totalAyahs: prev.totalAyahs,
          downloadedBytes: prev.downloadedBytes,
          status: SurahDownloadStatus.paused,
        ),
      );
    }
  }

  void cancelDownload(int surah, {QuranReciter? reciter}) {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final key = '${r.id}_$surah';
    _cancelFlags[key] = true;
    _pauseFlags[key] = false;
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

  void _updateProgress(String key, SurahDownloadProgress progress) {
    final current =
        Map<String, SurahDownloadProgress>.from(downloadProgressNotifier.value);
    current[key] = progress;
    downloadProgressNotifier.value = current;
  }

  void _removeProgress(String key) {
    final current =
        Map<String, SurahDownloadProgress>.from(downloadProgressNotifier.value);
    current.remove(key);
    downloadProgressNotifier.value = current;
  }
}
