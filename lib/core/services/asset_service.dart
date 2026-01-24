import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/ilm/data/models/mutun_models.dart';

class AssetService {
  static Future<MutunProgram> loadMutunProgram() async {
    final String jsonString = await rootBundle.loadString('assets/data/mutun_program.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return MutunProgram.fromJson(jsonMap['program']);
  }
}
