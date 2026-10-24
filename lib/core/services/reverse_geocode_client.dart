import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import '../constants/app_policy.dart';

/// Bounded, secure HTTP reverse geocoding client for location resolution.
class ReverseGeocodeClient {
  final HttpClient Function()? clientFactory;

  const ReverseGeocodeClient({this.clientFactory});

  /// Reverse geocodes coordinates via BigDataCloud API with strict resource, timeout, and payload bounds.
  Future<Map<String, String>?> reverseGeocode(
    double latitude,
    double longitude, {
    HttpClient? clientOverride,
    Duration? timeoutOverride,
  }) async {
    // 1. Sanity bounds on coordinates
    if (latitude < -90.0 || latitude > 90.0 || longitude < -180.0 || longitude > 180.0) {
      return null;
    }

    final deadline = timeoutOverride ?? AppPolicy.networkFast;
    final client = clientOverride ?? (clientFactory != null ? clientFactory!() : HttpClient());
    client.connectionTimeout = deadline;

    HttpClientRequest? activeRequest;
    StreamSubscription<List<int>>? responseSub;

    try {
      // Single overall operation deadline encompassing connection, request, response, and raw body streaming
      return await Future<Map<String, String>?>.sync(() async {
        final uri = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=ar',
        );
        if (uri.scheme != 'https') {
          return null;
        }

        activeRequest = await client.getUrl(uri);
        final response = await activeRequest!.close();

        if (response.statusCode != HttpStatus.ok) {
          return null;
        }

        // Count raw bytes before decoding to prevent memory exhaustion and handle multibyte UTF-8 correctly (C32)
        final rawBytes = <int>[];
        final completer = Completer<void>();

        responseSub = response.listen(
          (chunk) {
            rawBytes.addAll(chunk);
            if (rawBytes.length > AppPolicy.maxGeocodeBytes) {
              responseSub?.cancel();
              if (!completer.isCompleted) {
                completer.completeError(
                  const FormatException('Reverse geocode payload exceeded raw byte limit'),
                );
              }
            }
          },
          onError: (e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );

        await completer.future;

        // Strict UTF-8 decoding (rejects malformed bytes)
        final payload = utf8.decode(rawBytes, allowMalformed: false);
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) {
          final res = <String, String>{};
          final subdivision = data['principalSubdivision'];
          final locality = data['city'] ?? data['locality'];

          // Prefer clean province or major subdivision over obscure cadastral hamlets
          if (subdivision is String && subdivision.trim().isNotEmpty) {
            res['province'] = cleanAdministrativeName(subdivision.trim());
          }
          if (locality is String && locality.trim().isNotEmpty) {
            res['city'] = cleanAdministrativeName(locality.trim());
          }
          if (data['countryName'] is String && (data['countryName'] as String).trim().isNotEmpty) {
            res['country'] = (data['countryName'] as String).trim();
          }
          if (data['countryCode'] is String && (data['countryCode'] as String).trim().isNotEmpty) {
            res['countryCode'] = (data['countryCode'] as String).trim().toUpperCase();
          }
          return res;
        }
        return null;
      }).timeout(deadline);
    } catch (_) {
      try {
        activeRequest?.abort();
      } catch (_) {}
      return null;
    } finally {
      await responseSub?.cancel();
      if (clientOverride == null && clientFactory == null) {
        client.close(force: true);
      }
    }
  }

  String? pickCleanCity(List<Placemark> placemarks) {
    for (final place in placemarks) {
      final admin = place.administrativeArea?.trim();
      final locality = place.locality?.trim();
      final sub = place.subAdministrativeArea?.trim();

      if (locality != null && locality.isNotEmpty) {
        final cleanLocality = cleanAdministrativeName(locality);
        if (admin != null && admin.isNotEmpty) {
          final cleanAdmin = cleanAdministrativeName(admin);
          if (cleanAdmin != cleanLocality) {
            return cleanAdmin;
          }
        }
        return cleanLocality;
      }

      if (sub != null && sub.isNotEmpty) return cleanAdministrativeName(sub);
      if (admin != null && admin.isNotEmpty) return cleanAdministrativeName(admin);
    }
    return null;
  }

  static String cleanAdministrativeName(String raw) {
    var s = raw.trim();
    // Remove French / English prefixes
    s = s.replaceAll(
      RegExp(r'^(Commune de|Gouvernorat de|Province de|Wilaya de|State of|Province of)\s+', caseSensitive: false),
      '',
    );
    // Clean Arabic prefixes if redundant
    if (s.startsWith('ولاية ')) s = s.substring(6).trim();
    if (s.startsWith('محافظة ')) s = s.substring(7).trim();
    return s.trim();
  }
}
