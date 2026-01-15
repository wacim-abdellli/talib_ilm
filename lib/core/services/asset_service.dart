import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/ilm/data/models/mutun_models.dart';
import '../../app/constants/app_assets.dart';

class AssetService {
  static Future<MutunProgram> loadMutunProgram() async {
    final raw = await rootBundle.loadString(
      AppAssets.mutunProgram,
    );

    final decoded = jsonDecode(raw);
    return MutunProgram.fromJson(decoded);
  }
}
