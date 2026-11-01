import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import 'quran_audio_service.dart';

class DownloadedSurahItem {
  final int surah;
  final String surahName;
  final int verseCount;
  final int bytes;
  final QuranReciter reciter;

  const DownloadedSurahItem({
    required this.surah,
    required this.surahName,
    required this.verseCount,
    required this.bytes,
    required this.reciter,
  });
}

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

  /// Directory for a specific reciter and surah.
  /// If [create] is true (default), creates the directory on disk if it does not exist.
  static Future<Directory> getSurahDir(
    int surah,
    String reciterId, {
    bool create = true,
  }) async {
    final base = await getAudioBaseDir();
    final dir = Directory('${base.path}/$reciterId/$surah');
    if (create && !await dir.exists()) {
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
    final dir = await getSurahDir(surah, r.id, create: false);
    if (!await dir.exists()) return false;

    if (r.isSurahBased) {
      final file = File('${dir.path}/full_surah.mp3');
      return file.existsSync() && file.lengthSync() > 1000;
    }

    final totalVerses = quran.getVerseCount(surah);
    final List<FileSystemEntity> files;
    try {
      files = dir.listSync();
    } catch (_) {
      return false;
    }
    // Fast path: if directory contains fewer files than total verses, it cannot be complete
    if (files.length < totalVerses) return false;

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
    final dir = await getSurahDir(surah, r.id, create: false);
    if (!await dir.exists()) return 0;

    if (r.isSurahBased) {
      final file = File('${dir.path}/full_surah.mp3');
      return file.existsSync() ? file.lengthSync() : 0;
    }

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

  /// Returns a map of reciterId -> total bytes stored on disk.
  /// Scans only existing directories on disk in one fast pass.
  static Future<Map<String, int>> getStorageByReciter() async {
    final result = <String, int>{};
    final base = await getAudioBaseDir();
    if (!await base.exists()) return result;

    try {
      final reciterEntities = base.listSync();
      for (final entity in reciterEntities) {
        if (entity is! Directory) continue;
        final reciterId = entity.uri.pathSegments.reversed.where((s) => s.isNotEmpty).firstOrNull ??
            entity.path.split(RegExp(r'[\\/]')).last;

        int totalBytes = 0;
        try {
          final files = entity.listSync(recursive: true);
          for (final f in files) {
            if (f is File && f.path.endsWith('.mp3')) {
              totalBytes += f.lengthSync();
            }
          }
        } catch (_) {}

        if (totalBytes > 0) {
          result[reciterId] = totalBytes;
        }
      }
    } catch (_) {}

    return result;
  }

  /// Total storage used across all reciters or a specific reciter
  static Future<int> getTotalStorageUsed({String? reciterId}) async {
    final base = await getAudioBaseDir();
    if (!await base.exists()) return 0;

    int totalBytes = 0;
    try {
      if (reciterId != null) {
        final reciterDir = Directory('${base.path}/$reciterId');
        if (!await reciterDir.exists()) return 0;
        final files = reciterDir.listSync(recursive: true);
        for (final f in files) {
          if (f is File && f.path.endsWith('.mp3')) {
            totalBytes += f.lengthSync();
          }
        }
        return totalBytes;
      }

      final files = base.listSync(recursive: true);
      for (final f in files) {
        if (f is File && f.path.endsWith('.mp3')) {
          totalBytes += f.lengthSync();
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
    } else if (r.subfolder.contains('40kbps') || r.subfolder.contains('32kbps')) {
      kbPerVerse = 28;
    } else if (r.subfolder.contains('192kbps')) {
      kbPerVerse = 130;
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
    final dir = await getSurahDir(surah, r.id, create: false);
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

  /// Delete all downloaded audio files for a specific reciter
  static Future<void> deleteReciterAudio(QuranReciter reciter) async {
    final base = await getAudioBaseDir();
    final reciterDir = Directory('${base.path}/${reciter.id}');
    if (await reciterDir.exists()) {
      await reciterDir.delete(recursive: true);
    }
  }

  /// Scans and returns all downloaded surahs grouped by reciter.
  /// High-performance implementation: Scans ONLY directories that actually exist on disk!
  static Future<Map<QuranReciter, List<DownloadedSurahItem>>> getDownloadedSurahsByReciter() async {
    final results = <QuranReciter, List<DownloadedSurahItem>>{};
    final base = await getAudioBaseDir();
    if (!await base.exists()) return results;

    final recitersById = {for (final r in QuranAudioService.reciters) r.id: r};

    final List<FileSystemEntity> reciterEntities;
    try {
      reciterEntities = base.listSync();
    } catch (_) {
      return results;
    }

    for (final entity in reciterEntities) {
      if (entity is! Directory) continue;
      final reciterId = entity.uri.pathSegments.reversed.where((s) => s.isNotEmpty).firstOrNull ??
          entity.path.split(RegExp(r'[\\/]')).last;
      final reciter = recitersById[reciterId];
      if (reciter == null) continue;

      final List<FileSystemEntity> surahEntities;
      try {
        surahEntities = entity.listSync();
      } catch (_) {
        continue;
      }

      final downloadedSurahs = <DownloadedSurahItem>[];
      for (final surahEntity in surahEntities) {
        if (surahEntity is! Directory) continue;
        final dirName = surahEntity.uri.pathSegments.reversed.where((s) => s.isNotEmpty).firstOrNull ??
            surahEntity.path.split(RegExp(r'[\\/]')).last;
        final surahNumber = int.tryParse(dirName);
        if (surahNumber == null || surahNumber < 1 || surahNumber > 114) continue;

        final isDownloaded = await isSurahDownloaded(surahNumber, reciter: reciter);
        if (isDownloaded) {
          final bytes = await getSurahDownloadedBytes(surahNumber, reciter: reciter);
          downloadedSurahs.add(
            DownloadedSurahItem(
              surah: surahNumber,
              surahName: quran.getSurahNameArabic(surahNumber),
              verseCount: quran.getVerseCount(surahNumber),
              bytes: bytes,
              reciter: reciter,
            ),
          );
        }
      }

      if (downloadedSurahs.isNotEmpty) {
        downloadedSurahs.sort((a, b) => a.surah.compareTo(b.surah));
        results[reciter] = downloadedSurahs;
      }
    }

    return results;
  }
}
