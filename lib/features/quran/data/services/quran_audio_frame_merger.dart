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

  /// Strips ID3v2 metadata header at the beginning (starts with 'ID3'),
  /// ID3v1 metadata tag at the end (128 bytes starting with 'TAG'), and
  /// any encoder Xing/Info VBR/CBR header frame in the first MPEG frame.
  ///
  /// Everyayah.com MP3s include an 'Info' frame specifying the single-ayah
  /// frame count (e.g. 137 frames = 3 seconds). If preserved in a concatenated
  /// file, ExoPlayer reads this first header and terminates playback after
  /// just 3 seconds. Stripping the Info frame ensures pure, continuous MPEG
  /// frames that play seamlessly from start to finish.
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

    // Strip Xing / Info header frame
    final searchLimit = (start + 128 < end) ? start + 128 : end;
    int infoIdx = -1;
    for (int i = start; i < searchLimit - 4; i++) {
      if ((data[i] == 0x58 && data[i + 1] == 0x69 && data[i + 2] == 0x6E && data[i + 3] == 0x67) || // 'Xing'
          (data[i] == 0x49 && data[i + 1] == 0x6E && data[i + 2] == 0x66 && data[i + 3] == 0x6F)) {  // 'Info'
        infoIdx = i;
        break;
      }
    }

    if (infoIdx != -1) {
      // Find the next MPEG frame sync word (0xFF, 0xEx or 0xFF, 0xFx) after the Info frame
      final syncLimit = (infoIdx + 1500 < end) ? infoIdx + 1500 : end;
      for (int i = infoIdx + 4; i < syncLimit - 1; i++) {
        if (data[i] == 0xFF && (data[i + 1] & 0xE0) == 0xE0) {
          start = i;
          break;
        }
      }
    }

    if (start == 0 && end == data.length) return data;
    if (start >= end) return Uint8List(0);
    return Uint8List.sublistView(data, start, end);
  }

  /// Path to the full-surah merged MP3 audio file
  static Future<File> getFullSurahFile(int surah, {QuranReciter? reciter}) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final dir = await QuranAudioDownloader.getSurahDir(surah, r.id);
    return File('${dir.path}/full_surah.mp3');
  }

  /// Checks whether an existing full_surah.mp3 is valid and complete, or if
  /// it suffers from legacy truncation or Info-header poisoning.
  static bool isFullSurahFileHealthy(File file, int surah, {QuranReciter? reciter}) {
    if (!file.existsSync()) return false;
    final length = file.lengthSync();
    if (length < 1024) return false;

    // Surah-based direct downloads (e.g. Luhaidan) are standalone full MP3s
    if (reciter?.isSurahBased == true) {
      return true;
    }

    final totalVerses = quran.getVerseCount(surah);
    // 1. Check if the file still has the legacy 'Info' or 'Xing' header in the first 250 bytes
    try {
      final raf = file.openSync(mode: FileMode.read);
      try {
        final sampleSize = length < 250 ? length : 250;
        final sample = raf.readSync(sampleSize);
        for (int i = 0; i < sample.length - 4; i++) {
          if ((sample[i] == 0x58 && sample[i + 1] == 0x69 && sample[i + 2] == 0x6E && sample[i + 3] == 0x67) ||
              (sample[i] == 0x49 && sample[i + 1] == 0x6E && sample[i + 2] == 0x66 && sample[i + 3] == 0x6F)) {
            return false; // Legacy poisoned file! Needs rebuild!
          }
        }
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return false;
    }

    // 2. Check if the file size is plausibly large enough for all verses in the Surah
    if (totalVerses > 1) {
      final minExpected = totalVerses * 128;
      if (length < minExpected) {
        return false; // Truncated file!
      }
    }

    return true;
  }

  /// Checks if a valid, assembled full-surah MP3 recording exists on disk
  static Future<bool> isFullSurahAssembled(int surah, {QuranReciter? reciter}) async {
    final file = await getFullSurahFile(surah, reciter: reciter);
    return isFullSurahFileHealthy(file, surah, reciter: reciter);
  }

  /// Returns the full-surah audio file if available or all verses exist.
  /// If all individual verses exist but full_surah.mp3 is not yet created
  /// or is corrupted/truncated, assembles it on-the-fly and returns the resulting File.
  static Future<File?> getFullSurahAudioFile(int surah, {QuranReciter? reciter}) async {
    final file = await getFullSurahFile(surah, reciter: reciter);
    if (file.existsSync()) {
      if (isFullSurahFileHealthy(file, surah, reciter: reciter)) {
        return file;
      }
      try {
        file.deleteSync();
      } catch (_) {}
    }

    if (reciter?.isSurahBased == true) {
      return null;
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
    bool forceRebuild = false,
  }) async {
    final r = reciter ?? QuranAudioService().selectedReciter;
    final dir = await QuranAudioDownloader.getSurahDir(surah, r.id);
    final targetFile = File('${dir.path}/full_surah.mp3');

    if (!forceRebuild && targetFile.existsSync()) {
      if (isFullSurahFileHealthy(targetFile, surah, reciter: r)) {
        return targetFile;
      }
      try {
        targetFile.deleteSync();
      } catch (_) {}
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
