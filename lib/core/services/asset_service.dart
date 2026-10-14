import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../features/ilm/data/models/mutun_models.dart';
import '../../app/constants/app_assets.dart';

MutunProgram _parseMutunProgram(String raw) {
  final decoded = jsonDecode(raw);
  return MutunProgram.fromJson(decoded);
}

class AssetService {
  static MutunProgram? _cachedProgram;
  static Future<MutunProgram>? _loadingFuture;

  static Future<MutunProgram> loadMutunProgram() async {
    if (_cachedProgram != null) return _cachedProgram!;
    if (_loadingFuture != null) return _loadingFuture!;

    _loadingFuture = _loadInternal();
    return _loadingFuture!;
  }

  static Future<MutunProgram> _loadInternal() async {
    final raw = await rootBundle.loadString(AppAssets.mutunProgram);
    _cachedProgram = await compute(_parseMutunProgram, raw);
    _loadingFuture = null;
    return _cachedProgram!;
  }

  @visibleForTesting
  static void clearCache() {
    _cachedProgram = null;
    _loadingFuture = null;
  }
}
