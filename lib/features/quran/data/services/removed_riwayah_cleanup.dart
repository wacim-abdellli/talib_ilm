import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Removes data installed by the discontinued Warsh and Qalun app feature.
class RemovedRiwayahCleanup {
  RemovedRiwayahCleanup._();

  static const _migrationKey = 'migration_removed_warsh_qalun_v1';
  static const _removedEditions = {'warsh', 'qalun'};

  static Future<void> run() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(_migrationKey) == true) return;

      final currentEdition = preferences.getString('current_edition');
      if (_removedEditions.contains(currentEdition)) {
        await preferences.remove('current_edition');
      }

      final downloadedEditions = preferences.getStringList(
        'downloaded_editions',
      );
      if (downloadedEditions != null) {
        final retained = downloadedEditions
            .where((edition) => !_removedEditions.contains(edition))
            .toList(growable: false);
        await preferences.setStringList('downloaded_editions', retained);
      }

      final supportDirectory = await getApplicationSupportDirectory();
      final packsDirectory = Directory(
        p.join(supportDirectory.path, 'quran_packs'),
      );
      if (await packsDirectory.exists()) {
        await for (final entity in packsDirectory.list(followLinks: false)) {
          final name = p.basename(entity.path);
          final isRemovedPack = _removedEditions.any(
            (edition) => name == edition || name.startsWith('.$edition.'),
          );
          if (isRemovedPack) await entity.delete(recursive: true);
        }
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final legacyEditionsDirectory = Directory(
        p.join(documentsDirectory.path, 'quran_editions'),
      );
      for (final edition in _removedEditions) {
        for (final suffix in ['.json', '.json.bak', '.json.tmp']) {
          final file = File(
            p.join(legacyEditionsDirectory.path, '$edition$suffix'),
          );
          if (await file.exists()) await file.delete();
        }
      }

      await preferences.setBool(_migrationKey, true);
    } catch (_) {
      // Retry the migration on the next launch if any cleanup step fails.
    }
  }
}
