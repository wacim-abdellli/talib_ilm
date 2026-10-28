import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../../app/theme/app_policy.dart';
import '../../../../core/services/audio_coordinator.dart';
import '../models/quran_radio_model.dart';

class QuranRadioService extends ChangeNotifier {
  static final QuranRadioService _instance = QuranRadioService._internal();
  factory QuranRadioService() => _instance;

  QuranRadioService._internal() {
    _init();
  }

  static http.Client? _testClient;
  static http.Client? _sharedClient;

  @visibleForTesting
  static void setHttpClient(http.Client client) => _testClient = client;

  @visibleForTesting
  static void resetHttpClient() => _testClient = null;

  static http.Client get httpClient =>
      _testClient ?? (_sharedClient ??= http.Client());

  Future<void>? _inFlightRefresh;

  @visibleForTesting
  Future<void>? get inFlightRefreshForTesting => _inFlightRefresh;

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;

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

  // ignore: deprecated_member_use
  ConcatenatingAudioSource? _playlist;

  // ignore: deprecated_member_use
  ConcatenatingAudioSource _buildPlaylist(List<QuranRadioStation> list) {
    // ignore: deprecated_member_use
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: list.map((s) => _createAudioSource(s)).toList(),
    );
  }

  AudioSource _createAudioSource(QuranRadioStation station) {
    return AudioSource.uri(
      Uri.parse(station.url),
      tag: MediaItem(
        id: 'quran_radio_${station.id}',
        title: station.name,
        artist: 'إذاعة القرآن الكريم - بث مباشر',
        album: station.category,
        duration: Duration(hours: 24, seconds: station.id),
        artUri: Uri.parse('android.resource://com.talibilm.app/mipmap/ic_launcher'),
        displayTitle: station.name,
        displaySubtitle: 'إذاعة القرآن الكريم - بث مباشر',
        displayDescription: station.category,
      ),
    );
  }

  void _init() {
    AudioCoordinator.onPauseRadio = pause;

    _playerStateSub?.cancel();
    _playerStateSub = _player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      final wasConnecting = _isConnecting;

      _isPlaying = state.playing;
      _isConnecting = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (wasPlaying != _isPlaying || wasConnecting != _isConnecting) {
        notifyListeners();
      }
    });

    _currentIndexSub?.cancel();
    _currentIndexSub = _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _stations.length) {
        final station = _stations[index];
        if (_currentStation?.id != station.id) {
          _currentStation = station;
          notifyListeners();
        }
      }
    });

    _playbackEventSub?.cancel();
    _playbackEventSub = _player.playbackEventStream.listen(
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
      _playlist = _buildPlaylist(_stations);
      notifyListeners();
    } catch (_) {}

    // Background online refresh from MP3Quran API with deduplication
    unawaited(refreshOnlineStations());
  }

  /// Refreshes online stations with deduplication, byte limits, and HTTPS validation.
  Future<void> refreshOnlineStations() async {
    if (_inFlightRefresh != null) {
      return _inFlightRefresh;
    }
    final future = _performOnlineRefresh();
    _inFlightRefresh = future;
    try {
      await future;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<void> _performOnlineRefresh() async {
    try {
      final url = Uri.parse('https://mp3quran.net/api/v3/radios?language=ar');
      final body = await _fetchStreamedStringWithLimit(
        url,
        maxBytes: AppPolicy.maxRadioCatalogBytes,
        timeout: const Duration(seconds: 8), // ui-lint: allow network timeout
      );

      final data = json.decode(body);
      if (data is! Map<String, dynamic>) return;
      final rawRadios = data['radios'] as List? ?? [];
      if (rawRadios.isEmpty) return;

      final Set<String> existingUrls = _stations.map((s) => s.url).toSet();
      final List<QuranRadioStation> updated = List.from(_stations);

      for (final item in rawRadios) {
        if (updated.length >= AppPolicy.maxRadioStations) break;
        if (item is! Map<String, dynamic>) continue;

        final rawUrl = item['url'] as String? ?? '';
        final parsedUri = Uri.tryParse(rawUrl);

        // Security requirement: station streams must strictly use secure HTTPS
        if (parsedUri == null ||
            !parsedUri.isScheme('https') ||
            parsedUri.host.isEmpty) {
          continue;
        }

        final cleanUrl = parsedUri.toString();
        if (existingUrls.contains(cleanUrl)) continue;

        final rawName = (item['name'] as String? ?? '').trim();
        if (rawName.isEmpty) continue;
        final sanitizedName =
            rawName.length > 120 ? rawName.substring(0, 120) : rawName;

        updated.add(QuranRadioStation(
          id: (item['id'] as num?)?.toInt() ?? (1000 + updated.length),
          name: sanitizedName,
          rawName: rawName,
          url: cleanUrl,
          category: 'قراء العالم الإسلامي',
        ));
        existingUrls.add(cleanUrl);
      }

      if (updated.length != _stations.length) {
        _stations = updated;
        _playlist = _buildPlaylist(_stations);
        notifyListeners();
      }
    } catch (_) {
      // Offline safety invariant: network timeout, stream cancellation,
      // or server errors leave existing bundled stations intact.
    }
  }

  static Future<String> _fetchStreamedStringWithLimit(
    Uri url, {
    required int maxBytes,
    Duration timeout = const Duration(seconds: 8), // ui-lint: allow network timeout
  }) async {
    final request = http.Request('GET', url);
    request.headers['Accept'] = 'application/json';

    final streamedResponse = await httpClient.send(request).timeout(timeout);

    if (streamedResponse.statusCode != 200) {
      throw Exception('HTTP error ${streamedResponse.statusCode}');
    }

    final contentLength = streamedResponse.contentLength;
    if (contentLength != null && contentLength > maxBytes) {
      throw Exception('Response exceeded maximum byte limit ($maxBytes)');
    }

    final bytesBuilder = BytesBuilder(copy: false);
    int totalBytes = 0;
    final completer = Completer<List<int>>();
    late final StreamSubscription<List<int>> subscription;

    subscription = streamedResponse.stream.listen(
      (chunk) {
        totalBytes += chunk.length;
        if (totalBytes > maxBytes) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('Response stream cancelled: exceeded $maxBytes bytes'),
            );
          }
          return;
        }
        bytesBuilder.add(chunk);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(bytesBuilder.takeBytes());
      },
      cancelOnError: true,
    );

    final bytes = await completer.future.timeout(
      timeout,
      onTimeout: () {
        subscription.cancel();
        throw TimeoutException('Radio catalog request timed out', timeout);
      },
    );

    return utf8.decode(bytes, allowMalformed: true);
  }

  @visibleForTesting
  void resetForTesting({List<QuranRadioStation>? stations}) {
    _stations = stations ?? [];
    _currentStation = null;
    _isPlaying = false;
    _isConnecting = false;
    _errorMessage = null;
    _inFlightRefresh = null;
  }

  /// Plays a radio station
  Future<void> playStation(QuranRadioStation station) async {
    if (_currentStation?.id == station.id && _isPlaying) return;

    // Acquire audio focus: automatically pauses Quran recitation and Mutun audio
    await AudioCoordinator.acquireFocus(AudioStreamType.radio);

    final stationIndex = _stations.indexWhere((s) => s.id == station.id);
    if (stationIndex == -1) return;

    _currentStation = station;
    _errorMessage = null;
    _isConnecting = true;
    notifyListeners();

    try {
      if (_playlist == null || _playlist!.length != _stations.length) {
        _playlist = _buildPlaylist(_stations);
        await _player.setAudioSource(_playlist!, initialIndex: stationIndex);
      } else if (_player.audioSource != _playlist) {
        await _player.setAudioSource(_playlist!, initialIndex: stationIndex);
      } else {
        await _player.seek(Duration.zero, index: stationIndex);
      }
      await _player.play();
    } catch (e) {
      _errorMessage = 'تعذر تشغيل هذه الإذاعة حالياً.';
      _isConnecting = false;
      _isPlaying = false;
      AudioCoordinator.releaseFocus(AudioStreamType.radio);
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
    if (_player.hasNext) {
      await _player.seekToNext();
      await _player.play();
    } else if (_stations.isNotEmpty) {
      await playStation(_stations.first);
    }
  }

  /// Switch to previous radio station in the list
  Future<void> previousStation() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _player.play();
    } else if (_stations.isNotEmpty) {
      await playStation(_stations.last);
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    AudioCoordinator.releaseFocus(AudioStreamType.radio);
    notifyListeners();
  }

  Future<void> resume() async {
    if (_currentStation != null) {
      await AudioCoordinator.acquireFocus(AudioStreamType.radio);
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
    AudioCoordinator.releaseFocus(AudioStreamType.radio);
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _currentIndexSub?.cancel();
    _playbackEventSub?.cancel();
    if (AudioCoordinator.onPauseRadio == pause) {
      AudioCoordinator.onPauseRadio = null;
    }
    _player.dispose();
    super.dispose();
  }
}
