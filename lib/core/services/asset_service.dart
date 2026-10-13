import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../features/ilm/data/models/mutun_models.dart';
import '../../app/constants/app_assets.dart';

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
    final decoded = jsonDecode(raw);
    _cachedProgram = MutunProgram.fromJson(decoded);
    _loadingFuture = null;
    return _cachedProgram!;
  }

  @visibleForTesting
  static void clearCache() {
    _cachedProgram = null;
    _loadingFuture = null;
  }
}
