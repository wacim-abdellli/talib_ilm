import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/quran.dart' as quran;

import 'quran_audio_downloader.dart';

enum AudioRepeatMode {
  none,
  singleAyah,
  surah,
}

enum AudioPlaybackErrorType {
  network,
  sourceNotFound,
  unknown,
}

class AudioPlaybackError {
  final AudioPlaybackErrorType type;
  final String message;
  final dynamic originalError;

  const AudioPlaybackError({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'AudioPlaybackError($type: $message)';
}

class QuranReciter {
  final String id;
  final String name;
  final String subfolder;

  const QuranReciter({
    required this.id,
    required this.name,
    required this.subfolder,
  });
}

class QuranAudioService {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal() {
    _initAudioListener();
  }

  final AudioPlayer _player = AudioPlayer();

  static const List<QuranReciter> reciters = [
    QuranReciter(
      id: 'alafasy',
      name: 'مشاري راشد العفاسي',
      subfolder: 'Alafasy_128kbps',
    ),
    QuranReciter(
      id: 'qatami',
      name: 'ناصر القطامي',
      subfolder: 'Nasser_Alqatami_128kbps',
    ),
    QuranReciter(
      id: 'dossari',
      name: 'ياسر الدوسري',
      subfolder: 'Yasser_Ad-Dussary_128kbps',
    ),
    QuranReciter(
      id: 'muaiqly',
      name: 'ماهر المعيقلي',
      subfolder: 'MaherAlMuaiqly128kbps',
    ),
    QuranReciter(
      id: 'husary',
      name: 'محمود خليل الحصري',
      subfolder: 'Husary_128kbps',
    ),
    QuranReciter(
      id: 'minshawi',
      name: 'محمد صديق المنشاوي',
      subfolder: 'Minshawy_Murattal_128kbps',
    ),
    QuranReciter(
      id: 'abdulbasit',
      name: 'عبد الباسط عبد الصمد',
      subfolder: 'AbdulSamad_64kbps_QuranExplorer.Com',
    ),
    QuranReciter(
      id: 'ghamadi',
      name: 'سعد الغامدي',
      subfolder: 'Ghamadi_40kbps',
    ),
    QuranReciter(
      id: 'shatri',
      name: 'أبو بكر الشاطري',
      subfolder: 'Abu_Bakr_Ash-Shaatree_128kbps',
    ),
    QuranReciter(
      id: 'shuraym',
      name: 'سعود الشريم',
      subfolder: 'Saood_ash-Shuraym_128kbps',
    ),
  ];

  QuranReciter _selectedReciter = reciters[0];
  QuranReciter get selectedReciter => _selectedReciter;
  void setSelectedReciter(QuranReciter reciter) => _selectedReciter = reciter;

  // State Notifiers for selective, high-performance UI rebuilds
  final ValueNotifier<int?> activeSurahNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<int?> activeAyahNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> speedNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<AudioRepeatMode> repeatModeNotifier =
      ValueNotifier<AudioRepeatMode>(AudioRepeatMode.none);
  final ValueNotifier<AudioPlaybackError?> errorNotifier =
      ValueNotifier<AudioPlaybackError?>(null);

  Timer? _sleepTimer;
  final ValueNotifier<int?> sleepTimerMinutesNotifier = ValueNotifier<int?>(null);

  bool _isContinuous = false;
  int _endAyah = 0;
  int? _loadedSurah;
  QuranReciter? _loadedReciter;
  ConcatenatingAudioSource? _playlist;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;

  void clearError() {
    errorNotifier.value = null;
  }

  static AudioPlaybackError classifyError(dynamic e) {
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('network') ||
        str.contains('connection') ||
        str.contains('timed out') ||
        str.contains('timeout')) {
      return const AudioPlaybackError(
        type: AudioPlaybackErrorType.network,
        message: 'تعذر تشغيل التلاوة. يرجى التحقق من الاتصال بالإنترنت',
      );
    } else if (str.contains('404') ||
        str.contains('not found') ||
        str.contains('filenotfound')) {
      return const AudioPlaybackError(
        type: AudioPlaybackErrorType.sourceNotFound,
        message: 'ملف التلاوة غير متوفر لهذا القارئ حالياً',
      );
    } else {
      return AudioPlaybackError(
        type: AudioPlaybackErrorType.unknown,
        message: 'تعذر تشغيل التلاوة، يرجى المحاولة مرة أخرى',
        originalError: e,
      );
    }
  }

  Future<void> _handlePlaybackError(dynamic e) async {
    final err = classifyError(e);
    activeSurahNotifier.value = null;
    activeAyahNotifier.value = null;
    isPlayingNotifier.value = false;
    _isContinuous = false;
    errorNotifier.value = err;
    try {
      await _player.stop();
    } catch (_) {}
  }

  void _initAudioListener() {
    _player.playerStateStream.listen(
      (state) {
        isPlayingNotifier.value = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _handleTrackCompleted();
        }
      },
      onError: (Object e) {
        _handlePlaybackError(e);
      },
    );

    // Sync activeAyahNotifier with player's internal index changes (e.g. from notification controls)
    _player.currentIndexStream.listen((index) {
      if (index != null && _loadedSurah != null) {
        final newAyah = index + 1;
        if (activeAyahNotifier.value != newAyah) {
          activeSurahNotifier.value = _loadedSurah;
          activeAyahNotifier.value = newAyah;
        }
      }
    });
  }

  String _formatNumber(int n) => n.toString().padLeft(3, '0');

  String getAudioUrl(int surah, int ayah, {QuranReciter? reciter}) {
    final r = reciter ?? _selectedReciter;
    final sStr = _formatNumber(surah);
    final aStr = _formatNumber(ayah);
    return 'https://everyayah.com/data/${r.subfolder}/$sStr$aStr.mp3';
  }

  /// Play a single verse
  Future<void> playVerse(int surah, int ayah, {QuranReciter? reciter}) async {
    _isContinuous = false;
    await _startPlay(surah, ayah, reciter: reciter);
  }

  /// Play continuous verses (e.g. whole Surah or Page)
  Future<void> playContinuous({
    required int surah,
    required int startAyah,
    int? endAyah,
    QuranReciter? reciter,
  }) async {
    _isContinuous = true;
    _endAyah = endAyah ?? quran.getVerseCount(surah);
    await _startPlay(surah, startAyah, reciter: reciter);
  }

  /// Resolves the audio source: uses locally downloaded file if exists, otherwise streams from URL.
  Future<AudioSource> getAudioSource(int surah, int ayah, {QuranReciter? reciter}) async {
    final r = reciter ?? _selectedReciter;
    final surahName = quran.getSurahNameArabic(surah);
    final tag = MediaItem(
      id: '${surah}_$ayah',
      album: 'سورة $surahName',
      title: 'الآية $ayah - سورة $surahName',
      artist: r.name,
      artUri: Uri.parse('android.resource://com.example.talib_ilm/mipmap/ic_launcher'),
      displayTitle: 'سورة $surahName',
      displaySubtitle: 'الآية $ayah · ${r.name}',
      displayDescription: 'تلاوة القرآن الكريم - طالب العلم',
    );

    try {
      final localPath = await QuranAudioDownloader.getLocalAyahPath(surah, ayah, reciter: r);
      final localFile = File(localPath);
      if (localFile.existsSync() && localFile.lengthSync() > 0) {
        return AudioSource.file(localPath, tag: tag);
      }
    } catch (_) {}

    final url = getAudioUrl(surah, ayah, reciter: r);
    return AudioSource.uri(Uri.parse(url), tag: tag);
  }

  Future<ConcatenatingAudioSource> _buildSurahPlaylist(int surah, QuranReciter reciter) async {
    final totalVerses = quran.getVerseCount(surah);
    final surahName = quran.getSurahNameArabic(surah);
    final children = <AudioSource>[];

    Directory? surahDir;
    try {
      surahDir = await QuranAudioDownloader.getSurahDir(surah, reciter.id);
    } catch (_) {}

    final sStr = _formatNumber(surah);

    for (int a = 1; a <= totalVerses; a++) {
      final aStr = _formatNumber(a);
      final tag = MediaItem(
        id: '${surah}_$a',
        album: 'سورة $surahName',
        title: 'الآية $a - سورة $surahName',
        artist: reciter.name,
        artUri: Uri.parse('android.resource://com.example.talib_ilm/mipmap/ic_launcher'),
        displayTitle: 'سورة $surahName',
        displaySubtitle: 'الآية $a · ${reciter.name}',
        displayDescription: 'تلاوة القرآن الكريم - طالب العلم',
      );

      File? localFile;
      if (surahDir != null) {
        localFile = File('${surahDir.path}/$sStr$aStr.mp3');
      }

      if (localFile != null && localFile.existsSync() && localFile.lengthSync() > 0) {
        children.add(AudioSource.file(localFile.path, tag: tag));
      } else {
        final url = getAudioUrl(surah, a, reciter: reciter);
        children.add(AudioSource.uri(Uri.parse(url), tag: tag));
      }
    }

    return ConcatenatingAudioSource(children: children);
  }

  Future<void> _startPlay(int surah, int ayah, {QuranReciter? reciter}) async {
    clearError();
    final r = reciter ?? _selectedReciter;
    activeSurahNotifier.value = surah;
    activeAyahNotifier.value = ayah;

    try {
      final totalVerses = quran.getVerseCount(surah);
      final targetIndex = (ayah - 1).clamp(0, totalVerses - 1);

      if (_loadedSurah != surah || _loadedReciter?.id != r.id || _playlist == null) {
        _loadedSurah = surah;
        _loadedReciter = r;
        _playlist = await _buildSurahPlaylist(surah, r);
        await _player.setAudioSource(
          _playlist!,
          initialIndex: targetIndex,
          initialPosition: Duration.zero,
        );
      } else {
        if (_player.currentIndex != targetIndex) {
          await _player.seek(Duration.zero, index: targetIndex);
        }
      }

      // Configure repeat loop mode
      switch (repeatModeNotifier.value) {
        case AudioRepeatMode.singleAyah:
          await _player.setLoopMode(LoopMode.one);
          break;
        case AudioRepeatMode.surah:
          await _player.setLoopMode(LoopMode.all);
          break;
        case AudioRepeatMode.none:
          await _player.setLoopMode(LoopMode.off);
          break;
      }

      await _player.setSpeed(speedNotifier.value);
      await _player.play();
    } catch (e) {
      debugPrint('QuranAudioService play error: $e');
      await _handlePlaybackError(e);
    }
  }

  void _handleTrackCompleted() {
    final surah = activeSurahNotifier.value;
    final ayah = activeAyahNotifier.value;

    if (surah == null || ayah == null) return;

    // Single Ayah & Surah repeats are handled natively by LoopMode.one / LoopMode.all
    if (repeatModeNotifier.value == AudioRepeatMode.singleAyah ||
        repeatModeNotifier.value == AudioRepeatMode.surah) {
      return;
    }

    final totalVerses = quran.getVerseCount(surah);
    final limit = (_isContinuous && _endAyah > 0) ? _endAyah : totalVerses;

    // Continuous across Surahs
    if (_isContinuous && surah < 114 && ayah >= limit) {
      playContinuous(surah: surah + 1, startAyah: 1);
    } else if (ayah >= limit) {
      stop();
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  Future<void> setPlaybackSpeed(double speed) async {
    speedNotifier.value = speed;
    await _player.setSpeed(speed);
  }

  Future<void> setRepeatMode(AudioRepeatMode mode) async {
    repeatModeNotifier.value = mode;
    try {
      switch (mode) {
        case AudioRepeatMode.none:
          await _player.setLoopMode(LoopMode.off);
          break;
        case AudioRepeatMode.singleAyah:
          await _player.setLoopMode(LoopMode.one);
          break;
        case AudioRepeatMode.surah:
          await _player.setLoopMode(LoopMode.all);
          break;
      }
    } catch (_) {}
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    sleepTimerMinutesNotifier.value = minutes;

    if (minutes != null && minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        stop();
        sleepTimerMinutesNotifier.value = null;
      });
    }
  }

  Future<void> nextAyah() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_loadedSurah != null && _loadedSurah! < 114) {
      await _startPlay(_loadedSurah! + 1, 1);
    }
  }

  Future<void> previousAyah() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_loadedSurah != null && _loadedSurah! > 1) {
      final prevSurah = _loadedSurah! - 1;
      final prevTotal = quran.getVerseCount(prevSurah);
      await _startPlay(prevSurah, prevTotal);
    }
  }

  Future<void> stop() async {
    activeSurahNotifier.value = null;
    activeAyahNotifier.value = null;
    isPlayingNotifier.value = false;
    _isContinuous = false;
    _loadedSurah = null;
    _loadedReciter = null;
    _playlist = null;
    _sleepTimer?.cancel();
    sleepTimerMinutesNotifier.value = null;
    clearError();
    await _player.stop();
  }

  void dispose() {
    _sleepTimer?.cancel();
    errorNotifier.dispose();
    _player.dispose();
  }
}
