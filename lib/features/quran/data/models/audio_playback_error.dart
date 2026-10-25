enum AudioPlaybackErrorType { network, sourceNotFound, unknown }

class AudioPlaybackError {
  final AudioPlaybackErrorType type;
  final String message;
  final dynamic originalError;

  const AudioPlaybackError({
    required this.type,
    required this.message,
    this.originalError,
  });

  static AudioPlaybackError classify(dynamic e) {
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

  @override
  String toString() => 'AudioPlaybackError($type: $message)';
}
