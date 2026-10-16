import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import '../models/quran_radio_model.dart';

class QuranRadioService extends ChangeNotifier {
  static final QuranRadioService _instance = QuranRadioService._internal();
  factory QuranRadioService() => _instance;

  QuranRadioService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();

  QuranRadioStation? _currentStation;
  bool _isPlaying = false;
  bool _isConnecting = false;
  String? _errorMessage;
  double _volume = 1.0;
  List<QuranRadioStation> _stations = [];

  QuranRadioStation? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;
  double get volume => _volume;
  List<QuranRadioStation> get stations => _stations;

  void _init() {
    _player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      final wasConnecting = _isConnecting;

      _isPlaying = state.playing;
      _isConnecting = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (wasPlaying != _isPlaying || wasConnecting != _isConnecting) {
        notifyListeners();
      }
    });

    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        _errorMessage = 'تعذر الاتصال بالبث المباشر. يرجى التحقق من الشبكة.';
        _isConnecting = false;
        _isPlaying = false;
        notifyListeners();
      },
    );

    loadStations();
  }

  /// Loads bundled 24/7 stations instantly offline, then refreshes online in background
  Future<void> loadStations() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/quran_radios.json');
      final list = json.decode(jsonStr) as List;
      _stations = list
          .map((item) => QuranRadioStation.fromJson(item as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}

    // Background online refresh from MP3Quran API
    _refreshOnlineStations();
  }

  Future<void> _refreshOnlineStations() async {
    try {
      final url = Uri.parse('https://mp3quran.net/api/v3/radios?language=ar');
      final response = await http.get(url).timeout(const Duration(seconds: 8)); // ui-lint: allow network timeout
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawRadios = data['radios'] as List? ?? [];
        if (rawRadios.isNotEmpty) {
          final Set<String> existingUrls = _stations.map((s) => s.url).toSet();
          final List<QuranRadioStation> updated = List.from(_stations);

          for (final item in rawRadios) {
            final u = item['url'] as String? ?? '';
            if (u.isNotEmpty && !existingUrls.contains(u)) {
              updated.add(QuranRadioStation(
                id: (item['id'] as num?)?.toInt() ?? 0,
                name: item['name'] as String? ?? '',
                rawName: item['name'] as String? ?? '',
                url: u,
                category: 'قراء العالم الإسلامي',
              ));
              existingUrls.add(u);
            }
          }

          if (updated.length != _stations.length) {
            _stations = updated;
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }

  /// Plays a radio station
  Future<void> playStation(QuranRadioStation station) async {
    if (_currentStation?.id == station.id && _isPlaying) return;

    // Pause Quran recitation so audios don't collide
    try {
      QuranAudioService().pause();
    } catch (_) {}

    _currentStation = station;
    _errorMessage = null;
    _isConnecting = true;
    notifyListeners();

    try {
      final audioSource = AudioSource.uri(
        Uri.parse(station.url),
        tag: MediaItem(
          id: 'quran_radio_${station.id}',
          title: station.name,
          artist: 'إذاعة القرآن الكريم - بث مباشر',
          album: station.category,
          artUri: Uri.parse('android.resource://com.example.talib_ilm/mipmap/ic_launcher'),
          displayTitle: station.name,
          displaySubtitle: 'إذاعة القرآن الكريم - بث مباشر',
          displayDescription: station.category,
        ),
      );

      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      _errorMessage = 'تعذر تشغيل هذه الإذاعة حالياً.';
      _isConnecting = false;
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> togglePlay(QuranRadioStation station) async {
    if (_currentStation?.id == station.id) {
      if (_isPlaying) {
        await pause();
      } else {
        await resume();
      }
    } else {
      await playStation(station);
    }
  }

  /// Switch to next radio station in the list
  Future<void> nextStation() async {
    if (_stations.isEmpty || _currentStation == null) return;
    final currentIndex = _stations.indexWhere((s) => s.id == _currentStation!.id);
    if (currentIndex == -1) return;
    final nextIndex = (currentIndex + 1) % _stations.length;
    await playStation(_stations[nextIndex]);
  }

  /// Switch to previous radio station in the list
  Future<void> previousStation() async {
    if (_stations.isEmpty || _currentStation == null) return;
    final currentIndex = _stations.indexWhere((s) => s.id == _currentStation!.id);
    if (currentIndex == -1) return;
    final prevIndex = (currentIndex - 1 + _stations.length) % _stations.length;
    await playStation(_stations[prevIndex]);
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_currentStation != null) {
      try {
        QuranAudioService().pause();
      } catch (_) {}
      await _player.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStation = null;
    _isPlaying = false;
    _isConnecting = false;
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
