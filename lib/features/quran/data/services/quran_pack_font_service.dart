import 'dart:io';

import 'package:flutter/services.dart';

import '../models/quran_models.dart';
import 'quran_pack_install_service.dart';

/// Loads a verified installed riwayah font only when its edition is opened.
class QuranPackFontService {
  QuranPackFontService._();

  static final Set<QuranRiwayahId> _loadedEditions = {};

  static String familyFor(QuranRiwayahId edition) =>
      'TalibIlmQuran_${edition.wireValue}';

  static Future<String> load(QuranRiwayahId edition) async {
    final family = familyFor(edition);
    if (_loadedEditions.contains(edition)) return family;

    final path = await QuranPackInstallService.fontPath(edition);
    if (path == null) throw StateError('خط الرواية غير مثبت على الجهاز');
    final bytes = await File(path).readAsBytes();
    if (bytes.isEmpty) throw const FormatException('ملف خط الرواية فارغ');

    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
    _loadedEditions.add(edition);
    return family;
  }
}
