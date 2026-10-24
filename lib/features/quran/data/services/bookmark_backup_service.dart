import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'bookmark_service.dart';
export 'bookmark_service.dart' show MergeResult;

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

    if (decoded is! Map) {
      return BackupValidationResult.failure('بنية البيانات في الملف غير صالحة');
    }

    final app = decoded['app'];
    if (app is! String || app != appIdentifier) {
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
      if (item is Map) {
        try {
          final map = item.map((k, v) => MapEntry(k.toString(), v));
          parsedBookmarks.add(Bookmark.fromJson(map));
        } catch (_) {
          // Skip malformed individual entries
        }
      }
    }

    LastRead? parsedLastRead;
    final rawLastRead = decoded['lastRead'];
    if (rawLastRead is Map) {
      try {
        final map = rawLastRead.map((k, v) => MapEntry(k.toString(), v));
        parsedLastRead = LastRead.fromJson(map);
      } catch (_) {}
    }

    if (parsedBookmarks.isEmpty && parsedLastRead == null) {
      return BackupValidationResult.failure(
        'لا توجد أي بيانات صالحة للاستيراد في الملف',
      );
    }

    return BackupValidationResult.success(
      version: version,
      bookmarks: parsedBookmarks,
      lastRead: parsedLastRead,
    );
  }

  /// Merges imported bookmarks with current bookmarks without duplicates.
  ///
  /// Delegates directly to [BookmarkService.atomicMergeBookmarks], ensuring the entire
  /// read, deduplication, note-handling, and write cycle occurs as an atomic repository
  /// transaction under the service lock.
  static Future<MergeResult> mergeBookmarks({
    required List<Bookmark> importedBookmarks,
    required bool overwriteExistingNotes,
    LastRead? importedLastRead,
  }) {
    return BookmarkService.atomicMergeBookmarks(
      importedBookmarks: importedBookmarks,
      overwriteExistingNotes: overwriteExistingNotes,
      importedLastRead: importedLastRead,
    );
  }
}
