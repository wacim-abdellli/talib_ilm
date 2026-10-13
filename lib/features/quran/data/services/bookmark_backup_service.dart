import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'bookmark_service.dart';

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? version;
  final List<Bookmark> bookmarks;
  final LastRead? lastRead;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.version,
    this.bookmarks = const [],
    this.lastRead,
  });

  factory BackupValidationResult.failure(String message) {
    return BackupValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }

  factory BackupValidationResult.success({
    required int version,
    required List<Bookmark> bookmarks,
    LastRead? lastRead,
  }) {
    return BackupValidationResult(
      isValid: true,
      version: version,
      bookmarks: bookmarks,
      lastRead: lastRead,
    );
  }
}

class MergeResult {
  final int addedCount;
  final int updatedCount;
  final int skippedCount;

  const MergeResult({
    required this.addedCount,
    required this.updatedCount,
    required this.skippedCount,
  });
}

class BookmarkBackupService {
  static const int currentVersion = 1;
  static const String appIdentifier = 'talib_ilm';

  /// Generates a standardized JSON backup string of current bookmarks and last read.
  static Future<String> createBackupJson() async {
    final bookmarks = await BookmarkService.getBookmarks();
    final lastRead = await BookmarkService.getLastRead();

    final Map<String, dynamic> payload = {
      'app': appIdentifier,
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'lastRead': lastRead.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Exports bookmarks to a temporary JSON file and opens the system Share sheet.
  static Future<void> exportAndShare(BuildContext context) async {
    final jsonStr = await createBackupJson();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/talib_ilm_bookmarks_backup.json');
    await file.writeAsString(jsonStr, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'نسخة احتياطية لمحفوظات طالب علم',
      text: 'نسخة احتياطية للآيات المحفوظة والملاحظات الإيمانية من تطبيق طالب علم.',
    );
  }

  /// Validates the JSON string structure, application signature, and version.
  static BackupValidationResult validateAndParse(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return BackupValidationResult.failure('الملف المحدد فارغ تماماً');
    }

    dynamic decoded;
    try {
      decoded = json.decode(jsonString);
    } catch (_) {
      return BackupValidationResult.failure('الملف المحدد تالف أو ليس بصيغة JSON صالحة');
    }

    if (decoded is! Map<String, dynamic>) {
      return BackupValidationResult.failure('بنية البيانات في الملف غير صالحة');
    }

    final app = decoded['app'] as String?;
    if (app != appIdentifier) {
      return BackupValidationResult.failure(
        'الملف لا ينتمي لتطبيق طالب علم (توقيع غير مطابق)',
      );
    }

    final version = decoded['version'];
    if (version == null || version is! int) {
      return BackupValidationResult.failure('رقم إصدار النسخة الاحتياطية مفقود');
    }

    if (version > currentVersion || version < 1) {
      return BackupValidationResult.failure(
        'إصدار النسخة الاحتياطية غير مدعوم (الإصدار: $version)',
      );
    }

    final rawBookmarks = decoded['bookmarks'];
    if (rawBookmarks is! List) {
      return BackupValidationResult.failure('قائمة المحفوظات داخل الملف تالفة');
    }

    final List<Bookmark> parsedBookmarks = [];
    for (final item in rawBookmarks) {
      if (item is Map<String, dynamic>) {
        try {
          parsedBookmarks.add(Bookmark.fromJson(item));
        } catch (_) {
          // Skip malformed individual entries
        }
      }
    }

    LastRead? parsedLastRead;
    final rawLastRead = decoded['lastRead'];
    if (rawLastRead is Map<String, dynamic>) {
      try {
        parsedLastRead = LastRead.fromJson(rawLastRead);
      } catch (_) {}
    }

    return BackupValidationResult.success(
      version: version,
      bookmarks: parsedBookmarks,
      lastRead: parsedLastRead,
    );
  }

  /// Merges imported bookmarks with current bookmarks without duplicates.
  static Future<MergeResult> mergeBookmarks({
    required List<Bookmark> importedBookmarks,
    required bool overwriteExistingNotes,
    LastRead? importedLastRead,
  }) async {
    final current = await BookmarkService.getBookmarks();
    int added = 0;
    int updated = 0;
    int skipped = 0;

    for (final imported in importedBookmarks) {
      final existingIndex = current.indexWhere(
        (b) => b.surah == imported.surah && b.ayah == imported.ayah,
      );

      if (existingIndex == -1) {
        // Brand new bookmark
        current.add(imported);
        added++;
      } else {
        // Exists already
        final existing = current[existingIndex];
        if (overwriteExistingNotes) {
          current[existingIndex] = Bookmark(
            surah: imported.surah,
            ayah: imported.ayah,
            page: imported.page,
            note: imported.note ?? existing.note,
            timestamp: imported.timestamp,
          );
          updated++;
        } else {
          skipped++;
        }
      }
    }

    // Save back to BookmarkService
    await BookmarkService.saveAllBookmarks(current);

    if (importedLastRead != null) {
      final currentLastRead = await BookmarkService.getLastRead();
      if (importedLastRead.timestamp.isAfter(currentLastRead.timestamp)) {
        await BookmarkService.saveLastRead(
          surah: importedLastRead.surah,
          ayah: importedLastRead.ayah,
          page: importedLastRead.page,
        );
      }
    }

    return MergeResult(
      addedCount: added,
      updatedCount: updated,
      skippedCount: skipped,
    );
  }
}
