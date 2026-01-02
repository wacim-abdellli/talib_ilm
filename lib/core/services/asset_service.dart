import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/ilm/data/models/mutun_models.dart';

class AssetService {
  static Future<MutunProgram> loadMutunProgram() async {
    final raw = await rootBundle.loadString(
      'assets/data/mutun_program.json',
    );

    final decoded = jsonDecode(raw);
    return MutunProgram.fromJson(decoded);
  }
}
