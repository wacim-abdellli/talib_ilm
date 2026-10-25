import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;

import 'quran_audio_downloader.dart';
import 'quran_audio_service.dart';

/// Helper service for assembling gapless, single-file Holy Quran Surah MP3 recordings
/// by stripping ID3 container headers and concatenating pure MPEG audio frames.
class QuranAudioFrameMerger {
  const QuranAudioFrameMerger._();

  static String _formatNumber(int n) => n.toString().padLeft(3, '0');

  /// Strips ID3v2 metadata header at the beginning (starts with 'ID3') and
  /// ID3v1 metadata tag at the end (128 bytes starting with 'TAG') to extract
  /// pure MPEG audio frames for seamless, gapless audio concatenation.
  static Uint8List stripId3Tags(Uint8List data) {
    int start = 0;
    // Strip ID3v2 header: 'ID3' (0x49, 0x44, 0x33) followed by version and 4-byte synchsafe size
    if (data.length >= 10 &&
        data[0] == 0x49 &&
        data[1] == 0x44 &&
        data[2] == 0x33) {
      final size = ((data[6] & 0x7F) << 21) |
          ((data[7] & 0x7F) << 14) |
          ((data[8] & 0x7F) << 7) |
          (data[9] & 0x7F);
      start = 10 + size;
      if (start > data.length) start = 0;
    }

    int end = data.length;
    // Strip ID3v1 tag: 128 bytes at end starting with 'TAG' (0x54, 0x41, 0x47)
    if (data.length - start >= 128) {
      final tagIdx = data.length - 128;
      if (data[tagIdx] == 0x54 &&
          data[tagIdx + 1] == 0x41 &&
          data[tagIdx + 2] == 0x47) {
        end = tagIdx;
      }
    }

    if (start == 0 && end == data.length) return data;
    return Uint8List.sublistView(data, start, end);
  }

  /// Path to the full-surah merged MP3 audio file
  static Future<File> getFullSurahFile(int surah, {QuranReciter? reciter}) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final dir = await QuranAudioDownloader.getSurahDir(surah, r.id);
    return File('${dir.path}/full_surah.mp3');
  }

  /// Checks if a valid, assembled full-surah MP3 recording exists on disk
  static Future<bool> isFullSurahAssembled(int surah, {QuranReciter? reciter}) async {
    final file = await getFullSurahFile(surah, reciter: reciter);
    return file.existsSync() && file.lengthSync() > 1024;
  }

  /// Returns the full-surah audio file if available or all verses exist.
  /// If all individual verses exist but full_surah.mp3 is not yet created,
  /// assembles it on-the-fly and returns the resulting File.
  static Future<File?> getFullSurahAudioFile(int surah, {QuranReciter? reciter}) async {
    final file = await getFullSurahFile(surah, reciter: reciter);
    if (file.existsSync() && file.lengthSync() > 1024) {
      return file;
    }

    final isDownloaded = await QuranAudioDownloader.isSurahDownloaded(
      surah,
      reciter: reciter,
    );
    if (isDownloaded) {
      return assembleFullSurahAudio(surah, reciter: reciter);
    }
    return null;
  }

  /// Assembles all individual downloaded ayah audio files of a Surah into
  /// a single, seamless, studio-grade full Surah audio MP3 file.
  static Future<File?> assembleFullSurahAudio(
    int surah, {
    QuranReciter? reciter,
  }) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final dir = await QuranAudioDownloader.getSurahDir(surah, r.id);
    final targetFile = File('${dir.path}/full_surah.mp3');

    if (targetFile.existsSync() && targetFile.lengthSync() > 1024) {
      return targetFile;
    }

    final totalVerses = quran.getVerseCount(surah);
    final tempFile = File('${dir.path}/.full_surah.tmp');
    if (tempFile.existsSync()) {
      try {
        tempFile.deleteSync();
      } catch (_) {}
    }

    IOSink? sink;
    try {
      final activeSink = tempFile.openWrite();
      sink = activeSink;
      for (int a = 1; a <= totalVerses; a++) {
        final sStr = _formatNumber(surah);
        final aStr = _formatNumber(a);
        final ayahFile = File('${dir.path}/$sStr$aStr.mp3');
        if (!ayahFile.existsSync()) {
          await activeSink.close();
          sink = null;
          try {
            if (tempFile.existsSync()) tempFile.deleteSync();
          } catch (_) {}
          return null;
        }

        final bytes = await ayahFile.readAsBytes();
        final pureFrames = stripId3Tags(bytes);
        activeSink.add(pureFrames);
      }

      await activeSink.flush();
      await activeSink.close();
      sink = null;

      if (tempFile.existsSync() && tempFile.lengthSync() > 1024) {
        if (targetFile.existsSync()) {
          targetFile.deleteSync();
        }
        tempFile.renameSync(targetFile.path);
        return targetFile;
      }
    } catch (e) {
      debugPrint('QuranAudioFrameMerger error assembling Surah $surah: $e');
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      try {
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}
    }
    return null;
  }
}
