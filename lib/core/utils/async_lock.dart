import 'dart:async';

/// A FIFO asynchronous lock to serialize concurrent asynchronous operations within an isolate.
class AsyncLock {
  Future<void>? _last;

  /// Executes [operation] exclusively once all previously queued operations have completed.
  Future<T> synchronized<T>(Future<T> Function() operation) async {
    final prev = _last;
    final completer = Completer<void>();
    _last = completer.future;

    if (prev != null) {
      try {
        await prev;
      } catch (_) {
        // Preceding task failure does not block subsequent tasks.
      }
    }

    try {
      return await operation();
    } finally {
      if (identical(_last, completer.future)) {
        _last = null;
      }
      completer.complete();
    }
  }
}
