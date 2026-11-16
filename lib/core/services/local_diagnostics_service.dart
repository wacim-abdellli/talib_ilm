import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_policy.dart';
import 'offline_connectivity_service.dart';

/// Structured diagnostic entry stored locally on the user's device.
class DiagnosticEvent {
  final DateTime timestamp;
  final String category;
  final String severity;
  final String message;
  final String? trace;

  const DiagnosticEvent({
    required this.timestamp,
    required this.category,
    required this.severity,
    required this.message,
    this.trace,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        't': timestamp.toIso8601String(),
        'c': category,
        's': severity,
        'm': message,
        if (trace != null && trace!.isNotEmpty) 'tr': trace,
      };

  factory DiagnosticEvent.fromJson(Map<String, dynamic> json) {
    final ts = DateTime.tryParse(json['t']?.toString() ?? '') ?? DateTime.now();
    return DiagnosticEvent(
      timestamp: ts,
      category: (json['c']?.toString() ?? 'app').trim(),
      severity: (json['s']?.toString() ?? 'info').trim(),
      message: (json['m']?.toString() ?? '').trim(),
      trace: json['tr']?.toString(),
    );
  }
}

/// Privacy-first, offline-only ring buffer capturing runtime errors, audio fallbacks,
/// and connectivity transitions without network telemetry or PII.
class LocalDiagnosticsService {
  LocalDiagnosticsService._internal();
  static final LocalDiagnosticsService _instance =
      LocalDiagnosticsService._internal();
  factory LocalDiagnosticsService() => _instance;

  static const String storageKey = 'local_diagnostics_ring_v1';
  static const int maxEntries = 80;
  static const Duration _persistThrottle = AppPolicy.diagnosticsThrottle;

  final ListQueue<DiagnosticEvent> _events = ListQueue<DiagnosticEvent>();
  final ValueNotifier<int> eventCountNotifier = ValueNotifier<int>(0);

  bool _loadedFromPrefs = false;
  Future<void>? _loadInFlight;
  DateTime _lastPersistAt = DateTime.fromMillisecondsSinceEpoch(0);

  List<DiagnosticEvent> get recentEvents =>
      List<DiagnosticEvent>.unmodifiable(_events.toList().reversed);

  /// Records a bounded diagnostic event in memory and persists offline when needed.
  void record({
    required String category,
    required String message,
    String severity = 'info',
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      final combined = error != null ? '$message ($error)' : message;
      final cleanMessage = _truncate(_scrubMessage(combined), 240);
      final cleanTrace = stackTrace != null
          ? _compactStackTrace(stackTrace)
          : null;

      final entry = DiagnosticEvent(
        timestamp: DateTime.now(),
        category: category.trim().isEmpty ? 'app' : category.trim(),
        severity: severity,
        message: cleanMessage,
        trace: cleanTrace,
      );

      while (_events.length >= maxEntries) {
        _events.removeFirst();
      }
      _events.addLast(entry);
      eventCountNotifier.value = _events.length;

      final now = DateTime.now();
      if (severity == 'error' ||
          now.difference(_lastPersistAt) >= _persistThrottle) {
        _lastPersistAt = now;
        unawaited(_persistQuietly());
      }
    } catch (_) {
      // Diagnostics recording must never disrupt app execution.
    }
  }

  /// Loads previously stored events from local [SharedPreferences] once per session.
  Future<List<DiagnosticEvent>> loadEvents() async {
    if (_loadedFromPrefs) return recentEvents;
    _loadInFlight ??= _doLoadFromPrefs();
    await _loadInFlight;
    return recentEvents;
  }

  Future<void> _doLoadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final loaded = decoded
              .whereType<Map>()
              .map(
                (m) => DiagnosticEvent.fromJson(
                  Map<String, dynamic>.from(m),
                ),
              )
              .toList();
          final existingKeys = _events
              .map((e) => '${e.timestamp.toIso8601String()}|${e.category}|${e.message}')
              .toSet();
          final merged = <DiagnosticEvent>[
            for (final item in loaded)
              if (!existingKeys.contains(
                '${item.timestamp.toIso8601String()}|${item.category}|${item.message}',
              ))
                item,
            ..._events,
          ];
          _events.clear();
          final start =
              merged.length > maxEntries ? merged.length - maxEntries : 0;
          for (int i = start; i < merged.length; i++) {
            _events.addLast(merged[i]);
          }
          eventCountNotifier.value = _events.length;
        }
      }
    } catch (_) {
    } finally {
      _loadedFromPrefs = true;
      _loadInFlight = null;
    }
  }

  /// Clears all locally recorded diagnostic entries.
  Future<void> clearEvents() async {
    _events.clear();
    eventCountNotifier.value = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (_) {}
  }

  /// Builds a concise, human-readable text diagnostic report without PII or location data.
  String buildShareableReport() {
    final buf = StringBuffer()
      ..writeln('=== تقرير تشخيص طالب العلم (محلي) ===')
      ..writeln('المنصة: ${_platformLabel()}')
      ..writeln(
        'حالة الاتصال الحالية: ${OfflineConnectivityService().isOfflineNotifier.value ? "غير متصل" : "متصل"}',
      )
      ..writeln('عدد السجلات: ${_events.length}')
      ..writeln('----------------------------------------');

    final items = recentEvents.take(30).toList();
    if (items.isEmpty) {
      buf.writeln('لا توجد أخطاء أو ملاحظات مسجلة.');
    } else {
      for (final e in items) {
        final ts = e.timestamp.toIso8601String().substring(0, 19);
        buf.writeln('[$ts] [${e.severity}/${e.category}] ${e.message}');
        if (e.trace != null && e.trace!.isNotEmpty) {
          buf.writeln('  > ${e.trace}');
        }
      }
    }
    return buf.toString();
  }

  @visibleForTesting
  void resetForTesting() {
    _events.clear();
    _loadedFromPrefs = false;
    _loadInFlight = null;
    _lastPersistAt = DateTime.fromMillisecondsSinceEpoch(0);
    eventCountNotifier.value = 0;
  }

  Future<void> _persistQuietly() async {
    try {
      if (!_loadedFromPrefs) {
        await loadEvents();
      }
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _events.map((e) => e.toJson()).toList(growable: false),
      );
      await prefs.setString(storageKey, encoded);
    } catch (_) {}
  }

  static String _scrubMessage(String input) {
    var out = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    out = out.replaceAllMapped(
      RegExp(
        r'(latitude|longitude|lat|lon)=[-+]?\d+(\.\d+)?',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}=[redacted]',
    );
    return out;
  }

  static String? _compactStackTrace(StackTrace stack) {
    final frames = stack
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(3)
        .join(' | ');
    if (frames.isEmpty) return null;
    return _truncate(frames, 360);
  }

  static String _truncate(String s, int maxLen) =>
      s.length <= maxLen ? s : '${s.substring(0, maxLen - 1)}…';

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    return Platform.operatingSystem;
  }
}
