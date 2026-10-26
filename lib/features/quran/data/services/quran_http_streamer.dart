import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Dedicated HTTP streaming client enforcing byte limits, timeouts, and test seam injection.
class QuranHttpStreamer {
  QuranHttpStreamer._();

  static http.Client? _injectedClient;
  static http.Client? _defaultClient;

  static void setHttpClient(http.Client client) {
    _injectedClient = client;
  }

  static void resetHttpClient() {
    _injectedClient?.close();
    _injectedClient = null;
    _defaultClient?.close();
    _defaultClient = null;
  }

  static http.Client get client =>
      _injectedClient ?? (_defaultClient ??= http.Client());

  /// Streams an HTTP GET response body while enforcing a strict maximum byte ceiling.
  /// Aborts early via socket cancellation if the response length or cumulative chunks exceed [maxBytes].
  static Future<String> fetchStreamedStringWithLimit(
    Uri uri, {
    required int maxBytes,
    required Duration timeout,
  }) async {
    final request = http.Request('GET', uri);
    final streamedResponse = await client.send(request).timeout(timeout);

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
        throw TimeoutException('Request timed out', timeout);
      },
    );

    return utf8.decode(bytes, allowMalformed: true);
  }
}
