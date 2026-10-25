import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;

import '../../../../core/constants/app_policy.dart';
import 'quran_audio_frame_merger.dart';
import 'quran_audio_service.dart';
import 'quran_audio_storage.dart';

export '../models/surah_download_progress.dart';
import '../models/surah_download_progress.dart';
export 'quran_audio_storage.dart';

/// Service managing offline downloading, storage tracking, and local cache
/// resolution for Holy Quran audio recitations by Surah.
class QuranAudioDownloader {
  static final QuranAudioDownloader _instance =
      QuranAudioDownloader._internal();
  factory QuranAudioDownloader() => _instance;
  QuranAudioDownloader._internal();

  /// Directory root override for unit testing, delegated to [QuranAudioStorage].
  static Directory? get testBaseDir => QuranAudioStorage.testBaseDir;
  static set testBaseDir(Directory? dir) => QuranAudioStorage.testBaseDir = dir;

  /// Optional test HTTP client seam for deterministic unit testing.
  @visibleForTesting
  static http.Client? testClient;

  @visibleForTesting
  static void setHttpClient(http.Client client) => testClient = client;

  @visibleForTesting
  static void resetHttpClient() => testClient = null;

  /// Storage and file helper delegations for backward compatibility
  static Future<Directory> getAudioBaseDir() =>
      QuranAudioStorage.getAudioBaseDir();

  static Future<Directory> getSurahDir(int surah, String reciterId) =>
      QuranAudioStorage.getSurahDir(surah, reciterId);

  static Future<String> getLocalAyahPath(
    int surah,
    int ayah, {
    QuranReciter? reciter,
  }) =>
      QuranAudioStorage.getLocalAyahPath(surah, ayah, reciter: reciter);

  static bool isAyahAudioFileValid(File file) =>
      QuranAudioStorage.isAyahAudioFileValid(file);

  static Future<bool> isSurahDownloaded(
    int surah, {
    QuranReciter? reciter,
  }) =>
      QuranAudioStorage.isSurahDownloaded(surah, reciter: reciter);

  static Future<int> getSurahDownloadedBytes(
    int surah, {
    QuranReciter? reciter,
  }) =>
      QuranAudioStorage.getSurahDownloadedBytes(surah, reciter: reciter);

  static Future<int> getTotalStorageUsed({String? reciterId}) =>
      QuranAudioStorage.getTotalStorageUsed(reciterId: reciterId);

  static double estimateSurahSizeMb(int surah, {QuranReciter? reciter}) =>
      QuranAudioStorage.estimateSurahSizeMb(surah, reciter: reciter);

  static String formatBytes(int bytes) => QuranAudioStorage.formatBytes(bytes);

  static Future<void> deleteSurahAudio(
    int surah, {
    QuranReciter? reciter,
  }) =>
      QuranAudioStorage.deleteSurahAudio(surah, reciter: reciter);

  static Future<void> deleteAllDownloadedAudio() =>
      QuranAudioStorage.deleteAllDownloadedAudio();

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

  static String _formatNumber(int n) => QuranAudioStorage.formatNumber(n);

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

    // Input bounds validation
    if (surah < 1 || surah > 114) {
      _setProg(
        key,
        surah,
        reciter.id,
        0,
        0,
        0,
        SurahDownloadStatus.failed,
        'رقم السورة غير صالح ($surah)',
      );
      return;
    }

    final gen = (_operationGenerations[key] ?? 0) + 1;
    _operationGenerations[key] = gen;

    final totalVerses = quran.getVerseCount(surah);
    final surahDir = await QuranAudioStorage.getSurahDir(surah, reciter.id);

    _pauseFlags[key] = false;
    _cancelFlags[key] = false;

    final effectiveClient = client ?? testClient;
    final bool ownsClient = client == null && testClient == null;
    final httpClient = effectiveClient ?? http.Client();
    _activeHttpClients[key] = httpClient;

    try {
      // Check already downloaded and verified verses for resume
      int existingCount = 0;
      int existingBytes = 0;
      for (int a = 1; a <= totalVerses; a++) {
        final sStr = _formatNumber(surah);
        final aStr = _formatNumber(a);
        final file = File('${surahDir.path}/$sStr$aStr.mp3');
        if (QuranAudioStorage.isAyahAudioFileValid(file)) {
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
        if (QuranAudioStorage.isAyahAudioFileValid(targetFile)) {
          continue;
        }

        final remoteUrl =
            'https://everyayah.com/data/${reciter.subfolder}/$sStr$aStr.mp3';
        final tempFile = File('${surahDir.path}/$sStr${aStr}_g$gen.tmp');

        try {
          final request = http.Request('GET', Uri.parse(remoteUrl));
          // Connection deadline
          final http.StreamedResponse response = await httpClient
              .send(request)
              .timeout(AppPolicy.networkTimeout);

          if (response.statusCode != 200) {
            throw HttpException('Server returned ${response.statusCode}');
          }

          // Content-Type check (reject 200 HTML or text error body)
          final contentType =
              response.headers['content-type']?.toLowerCase() ?? '';
          if (contentType.contains('text/html') ||
              contentType.contains('text/plain') ||
              contentType.contains('application/json')) {
            throw const HttpException('استجابة الخادم غير صالحة (HTML/Text)');
          }

          final expectedLength = response.contentLength;
          if (expectedLength != null &&
              expectedLength > AppPolicy.maxAyahAudioBytes) {
            throw const HttpException('حجم الآية يتجاوز الحد المسموح به');
          }

          final sink = tempFile.openWrite();
          int downloadedAyahBytes = 0;
          final completer = Completer<void>();
          late final StreamSubscription<List<int>> sub;

          sub = response.stream.timeout(AppPolicy.networkMedium).listen(
            (chunk) {
              if (_cancelFlags[key] == true ||
                  _pauseFlags[key] == true ||
                  _operationGenerations[key] != gen) {
                sub.cancel();
                if (!completer.isCompleted) completer.complete();
                return;
              }
              downloadedAyahBytes += chunk.length;
              if (downloadedAyahBytes > AppPolicy.maxAyahAudioBytes) {
                sub.cancel();
                if (!completer.isCompleted) {
                  completer.completeError(
                    const HttpException('حجم الآية يتجاوز الحد المسموح به'),
                  );
                }
                return;
              }
              sink.add(chunk);
            },
            onError: (Object error) {
              if (!completer.isCompleted) completer.completeError(error);
            },
            onDone: () {
              if (!completer.isCompleted) completer.complete();
            },
            cancelOnError: true,
          );

          try {
            await completer.future;
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

          // Integrity validation before atomic promotion
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
          if (!QuranAudioStorage.isAyahAudioFileValid(tempFile)) {
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
        if (testBaseDir == null) {
          unawaited(QuranAudioFrameMerger.assembleFullSurahAudio(surah, reciter: reciter));
        }
      }
    } finally {
      // Release resources and in-flight tracking on every exit
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
    QuranAudioStorage.getSurahDir(surah, r.id).then((dir) {
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

  void _setProg(String key, int surah, String reciterId, int downloadedAyahs,
      int totalAyahs, int downloadedBytes, SurahDownloadStatus status, [String? errorMessage]) {
    _updateProgress(key, SurahDownloadProgress(
      surah: surah, reciterId: reciterId, downloadedAyahs: downloadedAyahs,
      totalAyahs: totalAyahs, downloadedBytes: downloadedBytes, status: status, errorMessage: errorMessage,
    ));
  }

  void _updateProgress(String key, SurahDownloadProgress progress) {
    downloadProgressNotifier.value = Map<String, SurahDownloadProgress>.from(downloadProgressNotifier.value)..[key] = progress;
  }

  void _removeProgress(String key) {
    downloadProgressNotifier.value = Map<String, SurahDownloadProgress>.from(downloadProgressNotifier.value)..remove(key);
  }
}
