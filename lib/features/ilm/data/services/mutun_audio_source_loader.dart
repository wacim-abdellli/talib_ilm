import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_policy.dart';
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
  final Set<String> _untrustedTlsHosts = <String>{};

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
        _untrustedTlsHosts.contains(host) &&
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
      }
    }

    final attemptTimeout = (!effectiveIsFallback &&
            host == 'files.a-alqasim.com' &&
            fallbackCandidate != null)
        ? AppPolicy.networkFast
        : AppPolicy.networkRetry;

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
      return MutunLoadedAudioResult(
        loaded: true,
        isMultiChapter: false,
        startChapter: 0,
        duration: dur,
        effectiveUrl: effectiveUrl,
        usedFallback: effectiveIsFallback,
      );
    } catch (sourceErr) {
      debugPrint('AudioSource.uri failed ($effectiveUrl): $sourceErr');
      if (host == 'files.a-alqasim.com' && fallbackCandidate != null) {
        _untrustedTlsHosts.add('files.a-alqasim.com');
      } else {
        try {
          await player.stop();
          final dur = await player
              .setUrl(effectiveUrl, initialPosition: initialPosition)
              .timeout(attemptTimeout);
          return MutunLoadedAudioResult(
            loaded: true,
            isMultiChapter: false,
            startChapter: 0,
            duration: dur,
            effectiveUrl: effectiveUrl,
            usedFallback: effectiveIsFallback,
          );
        } catch (urlErr) {
          debugPrint('Direct setUrl failed ($effectiveUrl): $urlErr');
          if (host != null && fallbackCandidate != null) {
            _untrustedTlsHosts.add(host);
          }
        }
      }
    }

    return MutunLoadedAudioResult(
      loaded: false,
      isMultiChapter: false,
      startChapter: 0,
      duration: null,
      effectiveUrl: effectiveUrl,
      usedFallback: effectiveIsFallback,
    );
  }
}
