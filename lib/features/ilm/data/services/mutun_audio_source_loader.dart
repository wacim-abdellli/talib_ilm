import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_policy.dart';
import '../../../../core/services/local_diagnostics_service.dart';
import '../../../../core/services/offline_connectivity_service.dart';
import '../catalogs/mutun_audio_catalog.dart';

class MutunLoadedAudioResult {
  final bool loaded;
  final bool isMultiChapter;
  final int startChapter;
  final Duration? duration;
  final String effectiveUrl;
  final bool usedFallback;

  const MutunLoadedAudioResult({
    required this.loaded,
    required this.isMultiChapter,
    required this.startChapter,
    required this.duration,
    required this.effectiveUrl,
    required this.usedFallback,
  });
}

/// Persistence & resilient streaming loader for [MutunAudioService].
class MutunAudioSourceLoader {
  final Map<String, DateTime> _untrustedTlsHosts = <String, DateTime>{};

  /// Clears any cached host bypasses (e.g. when network connectivity is restored
  /// or when the user explicitly retries audio playback).
  void resetTransientFailures() {
    _untrustedTlsHosts.clear();
  }

  bool _isHostTemporarilyBypassed(String host) {
    final recordedAt = _untrustedTlsHosts[host];
    if (recordedAt == null) return false;
    // Never bypass permanently: expire after 1 minute so transient outages heal automatically.
    if (DateTime.now().difference(recordedAt) > AppPolicy.pollingStandard * 2) {
      _untrustedTlsHosts.remove(host);
      return false;
    }
    return true;
  }

  bool _isTlsCertificateError(Object err) {
    final msg = err.toString().toLowerCase();
    return msg.contains('handshake') ||
        msg.contains('certificate') ||
        msg.contains('tls') ||
        msg.contains('ssl');
  }

  Future<void> persistReciterChoice(String bookId, String reciterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ilm_audio_reciter_$bookId', reciterId);
    } catch (_) {}
  }

  Future<String?> loadSavedReciterId(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('ilm_audio_reciter_$bookId');
    } catch (_) {
      return null;
    }
  }

  Future<void> persistBookChapter(
    String bookId,
    String reciterId,
    int idx,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ilm_audio_chapter_${bookId}_$reciterId', idx);
    } catch (_) {}
  }

  Future<int> loadSavedChapter(String bookId, String reciterId, int max) async {
    if (max <= 1) return 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('ilm_audio_chapter_${bookId}_$reciterId') ?? 0;
      return saved.clamp(0, max - 1);
    } catch (_) {
      return 0;
    }
  }

  int? computeActiveParagraph({
    required String? bookId,
    required String reciterId,
    required Duration pos,
    required Duration duration,
    required int totalParagraphs,
  }) {
    final timestamps = bookId != null
        ? MutunAudioCatalog.getParagraphTimestamps(bookId, reciterId: reciterId)
        : null;
    if (timestamps != null && timestamps.isNotEmpty) {
      final posMs = pos.inMilliseconds;
      int idx = 1;
      for (int i = 0; i < timestamps.length; i++) {
        if (posMs >= timestamps[i]) {
          idx = i + 1;
        } else {
          break;
        }
      }
      final maxP = totalParagraphs > 1 ? totalParagraphs : timestamps.length;
      return idx.clamp(1, maxP);
    }
    if (duration > Duration.zero && totalParagraphs > 1) {
      final ratio = pos.inMilliseconds / duration.inMilliseconds;
      return ((ratio * totalParagraphs).floor() + 1).clamp(1, totalParagraphs);
    }
    return null;
  }

  int resolveParagraphTargetMs({
    required String? bookId,
    required String reciterId,
    required int index,
    required Duration duration,
    required int totalParagraphs,
  }) {
    final timestamps = bookId != null
        ? MutunAudioCatalog.getParagraphTimestamps(bookId, reciterId: reciterId)
        : null;
    if (timestamps != null && index >= 1 && index <= timestamps.length) {
      return timestamps[index - 1];
    }
    if (duration > Duration.zero && totalParagraphs > 1) {
      return ((index - 1) / totalParagraphs * duration.inMilliseconds).round();
    }
    return 0;
  }

  Future<MutunLoadedAudioResult> loadIntoPlayer({
    required AudioPlayer player,
    required String bookId,
    required String requestedUrl,
    required MutunReciter reciter,
    int? initialChapterIndex,
    Duration? initialPosition,
    bool isFallbackAttempt = false,
  }) async {
    final sourceMeta =
        MutunAudioCatalog.getSource(bookId, reciterId: reciter.id);
    final fallbackCandidate = sourceMeta?.fallbackUrl;
    var effectiveUrl = requestedUrl;
    var effectiveIsFallback = isFallbackAttempt;

    final host = Uri.tryParse(effectiveUrl)?.host;
    if (!effectiveIsFallback &&
        host != null &&
        _isHostTemporarilyBypassed(host) &&
        fallbackCandidate != null &&
        fallbackCandidate.isNotEmpty) {
      effectiveUrl = fallbackCandidate;
      effectiveIsFallback = true;
    }

    final mediaTitle =
        MutunAudioCatalog.getEntry(bookId)?.title ?? 'مكتبة طالب العلم الصوتية';
    final chapters = (!effectiveIsFallback &&
            sourceMeta != null &&
            sourceMeta.isMultiChapter)
        ? sourceMeta.chapters!
        : null;
    var startChapter = 0;

    if (chapters != null && chapters.length > 1) {
      startChapter = initialChapterIndex ??
          await loadSavedChapter(bookId, reciter.id, chapters.length);
      try {
        // ignore: deprecated_member_use
        final playlist = ConcatenatingAudioSource(
          useLazyPreparation: true,
          children: [
            for (final ch in chapters)
              AudioSource.uri(
                Uri.parse(ch.audioUrl),
                tag: MediaItem(
                  id: '${reciter.id}_${bookId}_ch_${ch.index}',
                  title: ch.title,
                  artist: reciter.name,
                  album: mediaTitle,
                  displayTitle: ch.title,
                  displaySubtitle: '$mediaTitle · ${reciter.name}',
                ),
              ),
          ],
        );
        final dur = await player
            .setAudioSource(
              playlist,
              initialIndex: startChapter,
              initialPosition: initialPosition,
            )
            .timeout(AppPolicy.networkTimeout);
        OfflineConnectivityService().reportOnline();
        return MutunLoadedAudioResult(
          loaded: true,
          isMultiChapter: true,
          startChapter: startChapter,
          duration: dur,
          effectiveUrl: effectiveUrl,
          usedFallback: effectiveIsFallback,
        );
      } catch (playlistErr) {
        debugPrint('Multi-chapter playlist failed: $playlistErr');
        if (startChapter >= 0 && startChapter < chapters.length) {
          effectiveUrl = chapters[startChapter].audioUrl;
        }
      }
    }

    final effectiveHost = Uri.tryParse(effectiveUrl)?.host;
    final chapterFallback =
        (chapters != null &&
            startChapter >= 0 &&
            startChapter < chapters.length)
        ? chapters[startChapter].fallbackUrl
        : null;
    final resolvedFallback = chapterFallback ?? fallbackCandidate;
    final attemptTimeout = AppPolicy.networkTimeout;

    try {
      final tag = MediaItem(
        id: '${reciter.id}_$bookId',
        title: mediaTitle,
        artist: reciter.name,
        album: 'مكتبة طالب العلم الصوتية',
        displayTitle: mediaTitle,
        displaySubtitle: reciter.name,
      );
      final dur = await player
          .setAudioSource(
            AudioSource.uri(Uri.parse(effectiveUrl), tag: tag),
            initialPosition: initialPosition,
          )
          .timeout(attemptTimeout);
      OfflineConnectivityService().reportOnline();
      return MutunLoadedAudioResult(
        loaded: true,
        isMultiChapter: false,
        startChapter: startChapter,
        duration: dur,
        effectiveUrl: effectiveUrl,
        usedFallback: effectiveIsFallback,
      );
    } catch (sourceErr) {
      debugPrint('AudioSource.uri failed ($effectiveUrl): $sourceErr');
      if (effectiveHost != null &&
          !effectiveIsFallback &&
          resolvedFallback != null &&
          _isTlsCertificateError(sourceErr)) {
        _untrustedTlsHosts[effectiveHost] = DateTime.now();
        LocalDiagnosticsService().record(
          category: 'audio',
          severity: 'warn',
          message:
              'Book audio TLS error for $effectiveHost (switching to fallback)',
          error: sourceErr,
        );
        return MutunLoadedAudioResult(
          loaded: false,
          isMultiChapter: false,
          startChapter: startChapter,
          duration: null,
          effectiveUrl: effectiveUrl,
          usedFallback: effectiveIsFallback,
        );
      }
      try {
        await player.stop();
        final dur = await player
            .setUrl(effectiveUrl, initialPosition: initialPosition)
            .timeout(attemptTimeout);
        OfflineConnectivityService().reportOnline();
        return MutunLoadedAudioResult(
          loaded: true,
          isMultiChapter: false,
          startChapter: startChapter,
          duration: dur,
          effectiveUrl: effectiveUrl,
          usedFallback: effectiveIsFallback,
        );
      } catch (urlErr) {
        debugPrint('Direct setUrl failed ($effectiveUrl): $urlErr');
        LocalDiagnosticsService().record(
          category: 'audio',
          severity: 'warn',
          message: 'Book audio load failed for ${effectiveHost ?? effectiveUrl}',
          error: urlErr,
        );
        if (effectiveHost != null &&
            resolvedFallback != null &&
            (_isTlsCertificateError(sourceErr) ||
                _isTlsCertificateError(urlErr))) {
          _untrustedTlsHosts[effectiveHost] = DateTime.now();
        }
      }
    }

    return MutunLoadedAudioResult(
      loaded: false,
      isMultiChapter: false,
      startChapter: startChapter,
      duration: null,
      effectiveUrl: effectiveUrl,
      usedFallback: effectiveIsFallback,
    );
  }

  /// Resolves effective reciter for [bookId] falling back to the book's first reciter.
  MutunReciter effectiveReciterForBook(String? bookId, MutunReciter current) {
    if (bookId == null) return current;
    final available = MutunAudioCatalog.getRecitersForBook(bookId);
    if (available.isEmpty || available.any((r) => r.id == current.id)) {
      return current;
    }
    return available.first;
  }

  /// Resolves the primary streaming URL for [bookId] with fallback to default Sini reciter.
  String urlForBook(String bookId, String reciterId) =>
      MutunAudioCatalog.getAudioUrl(bookId, reciterId: reciterId) ??
      MutunAudioCatalog.getAudioUrl(bookId, reciterId: 'sini') ??
      '';

  /// Loads [requestedUrl] into [player], automatically recreating & trying fallback URL on failure.
  Future<MutunLoadedAudioResult> loadWithFallback({
    required AudioPlayer Function() getPlayer,
    required Future<void> Function() recreatePlayer,
    required String bookId,
    required String requestedUrl,
    required MutunReciter reciter,
    int? initialChapterIndex,
    Duration? initialPosition,
    bool isFallbackAttempt = false,
  }) async {
    final first = await loadIntoPlayer(
      player: getPlayer(),
      bookId: bookId,
      requestedUrl: requestedUrl,
      reciter: reciter,
      initialChapterIndex: initialChapterIndex,
      initialPosition: initialPosition,
      isFallbackAttempt: isFallbackAttempt,
    );
    if (first.loaded || first.usedFallback || isFallbackAttempt) return first;
    final fallbackUrl = resolveFallbackUrl(
      bookId,
      reciter.id,
      first.effectiveUrl,
      chapterIndex: first.startChapter,
    );
    if (fallbackUrl == null) return first;
    await recreatePlayer();
    return loadIntoPlayer(
      player: getPlayer(),
      bookId: bookId,
      requestedUrl: fallbackUrl,
      reciter: reciter,
      initialChapterIndex: first.startChapter,
      initialPosition: initialPosition,
      isFallbackAttempt: true,
    );
  }

  /// Resolves the preferred reciter for [bookId] from saved preferences or defaults.
  Future<MutunReciter?> pickReciterForBook(
    String bookId,
    MutunReciter current,
  ) async {
    final available = MutunAudioCatalog.getRecitersForBook(bookId);
    if (available.isEmpty) return null;
    var chosen = available.any((r) => r.id == current.id)
        ? current
        : available.first;
    final savedId = await loadSavedReciterId(bookId);
    if (savedId != null) {
      final match = available.where((r) => r.id == savedId);
      if (match.isNotEmpty) chosen = match.first;
    }
    return chosen;
  }

  /// Resolves the next alternative URL if primary source fails.
  String? resolveFallbackUrl(
    String bookId,
    String reciterId,
    String failedUrl, {
    int? chapterIndex,
  }) {
    final chapters =
        MutunAudioCatalog.getSource(bookId, reciterId: reciterId)?.chapters;
    String? candidate;
    if (chapters != null &&
        chapterIndex != null &&
        chapterIndex >= 0 &&
        chapterIndex < chapters.length) {
      candidate = chapters[chapterIndex].fallbackUrl;
    }
    candidate ??=
        MutunAudioCatalog.getFallbackAudioUrl(bookId, reciterId: reciterId) ??
        MutunAudioCatalog.getAudioUrl(bookId, reciterId: 'sini');
    if (candidate == null || candidate.isEmpty || candidate == failedUrl) {
      return null;
    }
    return candidate;
  }

  /// Returns an accurate localized error message after checking connectivity.
  Future<String> resolveErrorMessage() async {
    final isOffline = await OfflineConnectivityService().checkConnectivity();
    return isOffline
        ? 'لا يوجد اتصال بالإنترنت. اضغط تشغيل عند عودة الشبكة'
        : 'تعذر تشغيل الصوت. يرجى التحقق من الاتصال بالإنترنت';
  }
}
