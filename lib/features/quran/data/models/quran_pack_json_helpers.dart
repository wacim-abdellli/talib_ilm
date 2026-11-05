part of 'quran_pack_manifest.dart';

void _requireOnlyKeys(
  Map<String, dynamic> json,
  Set<String> allowedKeys,
  String path,
) {
  for (final key in json.keys) {
    if (!allowedKeys.contains(key)) {
      throw FormatException('Unknown field $path.$key for schema version 1');
    }
  }
}

Map<String, dynamic> _readObject(
  Map<String, dynamic> json,
  String key,
  String parent,
) {
  final value = json[key];
  if (value is! Map) throw FormatException('$parent.$key must be an object');
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$parent.$key contains a non-string key');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<T> _readObjectList<T>(
  Map<String, dynamic> json,
  String key,
  String parent,
  T Function(Map<String, dynamic>) parse, {
  required int maxLength,
}) {
  final value = json[key];
  if (value is! List || value.isEmpty || value.length > maxLength) {
    throw FormatException('$parent.$key must contain 1-$maxLength entries');
  }
  return List.unmodifiable(
    value.map((entry) {
      if (entry is! Map) {
        throw FormatException('$parent.$key entries must be objects');
      }
      final result = <String, dynamic>{};
      for (final mapEntry in entry.entries) {
        if (mapEntry.key is! String) {
          throw FormatException('$parent.$key contains a non-string key');
        }
        result[mapEntry.key as String] = mapEntry.value;
      }
      return parse(result);
    }),
  );
}

Set<T> _readEnumSet<T>(
  Map<String, dynamic> json,
  String key,
  String parent,
  T Function(Object?) parse, {
  required int maxLength,
}) {
  final value = json[key];
  if (value is! List || value.isEmpty || value.length > maxLength) {
    throw FormatException('$parent.$key must contain 1-$maxLength entries');
  }
  final result = <T>{};
  for (final entry in value) {
    if (!result.add(parse(entry))) {
      throw FormatException('$parent.$key contains duplicate values');
    }
  }
  return Set.unmodifiable(result);
}

String _readString(
  Map<String, dynamic> json,
  String key,
  String parent, {
  required int maxLength,
}) {
  final value = json[key];
  if (value is! String) throw FormatException('$parent.$key must be a string');
  _requireText(value, '$parent.$key', maxLength: maxLength);
  return value;
}

String? _readOptionalString(
  Map<String, dynamic> json,
  String key,
  String parent, {
  required int maxLength,
}) {
  if (_readOptionalValue(json, key, parent) == null) return null;
  return _readString(json, key, parent, maxLength: maxLength);
}

int? _readOptionalInt(Map<String, dynamic> json, String key, String parent) {
  if (_readOptionalValue(json, key, parent) == null) return null;
  return _readInt(json, key, parent);
}

Object? _readOptionalValue(
  Map<String, dynamic> json,
  String key,
  String parent,
) {
  if (!json.containsKey(key)) return null;
  if (json[key] == null) {
    throw FormatException('$parent.$key must be omitted instead of null');
  }
  return json[key];
}

int _readInt(Map<String, dynamic> json, String key, String parent) {
  final value = json[key];
  if (value is! int) throw FormatException('$parent.$key must be an integer');
  return value;
}

Uri _readHttpsUri(Map<String, dynamic> json, String key, String parent) {
  final value = _readString(json, key, parent, maxLength: 2048);
  final uri = Uri.tryParse(value);
  if (uri == null) throw FormatException('$parent.$key must be a URI');
  _requireHttpsUri(uri, '$parent.$key');
  return uri;
}

DateTime _readDateTime(Object? value, String path) {
  if (value is! String ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$').hasMatch(value)) {
    throw FormatException(
      '$path must be a UTC ISO-8601 timestamp at second precision',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || _formatCanonicalUtcDateTime(parsed) != value) {
    throw FormatException('$path is not a canonical UTC date-time');
  }
  return parsed;
}

/// Stable timestamp encoding for the signed manifest. Requiring second
/// precision and `Z` avoids signature changes caused by timezone or fraction
/// normalization when a manifest is parsed and serialized again.
String _formatCanonicalUtcDateTime(DateTime value) {
  if (!value.isUtc ||
      value.millisecond != 0 ||
      value.microsecond != 0 ||
      value.year < 0 ||
      value.year > 9999) {
    throw const FormatException(
      'Signed manifest timestamps must be UTC at whole-second precision',
    );
  }
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$year-$month-${day}T$hour:$minute:${second}Z';
}

void _requireText(String value, String path, {required int maxLength}) {
  if (value.trim().isEmpty || value.length > maxLength) {
    throw FormatException('$path must contain 1-$maxLength characters');
  }
}

void _requireHttpsUri(Uri uri, String path) {
  if (!uri.isAbsolute ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw FormatException(
      '$path must be an absolute HTTPS URI without user info',
    );
  }
}

void _requireSha256(String value, String path) {
  if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value)) {
    throw FormatException(
      '$path must contain exactly 64 hexadecimal characters',
    );
  }
}

void _requireSafeRelativePath(String path) {
  if (path.isEmpty ||
      path.length > 240 ||
      path.startsWith('/') ||
      path.contains('\\') ||
      !RegExp(r'^[A-Za-z0-9._/-]+$').hasMatch(path) ||
      path
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw const FormatException(
      'asset.path must be a safe relative POSIX path without traversal',
    );
  }
}
