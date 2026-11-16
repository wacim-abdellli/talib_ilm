part of 'quran_audio_downloader.dart';

extension _QuranAudioDownloaderWorkerHandlers on QuranAudioDownloader {
  Future<void> _downloadSurahTrackImpl({
    required int surah,
    required QuranReciter reciter,
    required Directory surahDir,
    required String key,
    required int gen,
    required http.Client httpClient,
    required int totalVerses,
  }) async {
    final targetFile = File('${surahDir.path}/full_surah.mp3');
    if (targetFile.existsSync() && targetFile.lengthSync() > 1000) {
      _setProg(
        key,
        surah,
        reciter.id,
        totalVerses,
        totalVerses,
        targetFile.lengthSync(),
        SurahDownloadStatus.completed,
      );
      return;
    }

    if (!reciter.hasSurah(surah)) {
      _setProg(
        key,
        surah,
        reciter.id,
        0,
        totalVerses,
        0,
        SurahDownloadStatus.failed,
        'هذه السورة غير متوفرة بصوت القارئ',
      );
      return;
    }

    _setProg(
      key,
      surah,
      reciter.id,
      0,
      totalVerses,
      0,
      SurahDownloadStatus.downloading,
    );

    final sStr = QuranAudioDownloader._formatNumber(surah);
    final remoteUrl = '${reciter.surahBaseUrl}$sStr.mp3';
    final tempFile = File('${surahDir.path}/full_surah_g$gen.tmp');

    IOSink? sink;
    try {
      final request = http.Request('GET', Uri.parse(remoteUrl));
      final http.StreamedResponse response = await httpClient
          .send(request)
          .timeout(AppPolicy.networkTimeout);

      if (response.statusCode != 200) {
        throw HttpException('Server returned ${response.statusCode}');
      }

      final contentType =
          response.headers['content-type']?.toLowerCase() ?? '';
      if (contentType.contains('text/html') ||
          contentType.contains('text/plain') ||
          contentType.contains('application/json')) {
        throw const HttpException('Server returned invalid content type');
      }

      final totalBytesExpected =
          response.contentLength ?? (totalVerses * 85 * 1024);
      sink = tempFile.openWrite();
      int receivedBytes = 0;
      int lastReportedVerses = 0;

      await for (final chunk in response.stream) {
        if (_operationGenerations[key] != gen) {
          await sink.close();
          try {
            if (tempFile.existsSync()) tempFile.deleteSync();
          } catch (_) {}
          return;
        }

        if (_pauseFlags[key] == true) {
          await sink.close();
          _setProg(
            key,
            surah,
            reciter.id,
            lastReportedVerses,
            totalVerses,
            receivedBytes,
            SurahDownloadStatus.paused,
          );
          return;
        }

        if (_cancelFlags[key] == true) {
          await sink.close();
          try {
            if (tempFile.existsSync()) tempFile.deleteSync();
          } catch (_) {}
          _removeProgress(key);
          return;
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        final double ratio =
            (receivedBytes / totalBytesExpected).clamp(0.0, 1.0);
        final currentVerses =
            (ratio * totalVerses).toInt().clamp(0, totalVerses);
        lastReportedVerses = currentVerses;

        _setProg(
          key,
          surah,
          reciter.id,
          currentVerses,
          totalVerses,
          receivedBytes,
          SurahDownloadStatus.downloading,
        );
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (_operationGenerations[key] != gen || _cancelFlags[key] == true) {
        try {
          if (tempFile.existsSync()) tempFile.deleteSync();
        } catch (_) {}
        return;
      }

      if (tempFile.existsSync() && tempFile.lengthSync() > 1000) {
        if (targetFile.existsSync()) {
          try {
            targetFile.deleteSync();
          } catch (_) {}
        }
        await tempFile.rename(targetFile.path);
        _setProg(
          key,
          surah,
          reciter.id,
          totalVerses,
          totalVerses,
          targetFile.lengthSync(),
          SurahDownloadStatus.completed,
        );
      } else {
        throw const HttpException('الملف الصوتي المستلم تالف أو غير صالح');
      }
    } catch (e) {
      try {
        await sink?.close();
      } catch (_) {}
      try {
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}

      if (_operationGenerations[key] != gen) return;
      if (_cancelFlags[key] == true) {
        _removeProgress(key);
        return;
      }
      if (_pauseFlags[key] == true) return;

      final isDiskError = e is FileSystemException;
      final String errorMsg;
      if (isDiskError) {
        errorMsg = 'المساحة التخزينية غير كافية لإكمال التنزيل';
      } else if (e is TimeoutException) {
        errorMsg = 'انتهت مهلة الاتصال بالخادم، يرجى المحاولة لاحقاً';
      } else if (e is HttpException) {
        errorMsg = e.message;
      } else {
        errorMsg = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت';
      }

      _setProg(
        key,
        surah,
        reciter.id,
        0,
        totalVerses,
        0,
        SurahDownloadStatus.failed,
        errorMsg,
      );
    }
  }

  void _pauseDownloadImpl(int surah, {QuranReciter? reciter}) {
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

  void _cancelDownloadImpl(int surah, {QuranReciter? reciter}) {
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

  void _resetStateForTestingImpl() {
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

  void _setProgImpl(
    String key,
    int surah,
    String reciterId,
    int downloadedAyahs,
    int totalAyahs,
    int downloadedBytes,
    SurahDownloadStatus status, [
    String? errorMessage,
  ]) {
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

  void _updateProgressImpl(String key, SurahDownloadProgress progress) {
    downloadProgressNotifier.value = Map<String, SurahDownloadProgress>.from(
      downloadProgressNotifier.value,
    )..[key] = progress;
  }

  void _removeProgressImpl(String key) {
    downloadProgressNotifier.value = Map<String, SurahDownloadProgress>.from(
      downloadProgressNotifier.value,
    )..remove(key);
  }
}
