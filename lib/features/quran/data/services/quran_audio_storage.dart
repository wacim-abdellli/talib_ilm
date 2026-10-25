import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import 'quran_audio_service.dart';

/// Storage, directory layout, file validation, and disk calculation utilities
/// for Holy Quran audio recitations.
class QuranAudioStorage {
  const QuranAudioStorage._();

  /// Directory root override for unit testing
  static Directory? testBaseDir;

  static String formatNumber(int n) => n.toString().padLeft(3, '0');

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
    final sStr = formatNumber(surah);
    final aStr = formatNumber(ayah);
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
      final sStr = formatNumber(surah);
      final aStr = formatNumber(a);
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
        if (f is File &&
            f.path.endsWith('.mp3') &&
            !f.path.contains('full_surah') &&
            isAyahAudioFileValid(f)) {
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
        if (e is File &&
            e.path.endsWith('.mp3') &&
            !e.path.contains('full_surah')) {
          if (reciterId != null) {
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
      try {
        final entities = base.listSync();
        for (final entity in entities) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      } catch (_) {}
    }
  }
}
