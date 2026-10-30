import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/app_share.dart';

import '../../../../core/constants/app_policy.dart';
import 'bookmark_service.dart';
export 'bookmark_service.dart' show MergeResult;

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? version;
  final List<Bookmark> bookmarks;
  final LastRead? lastRead;
  final int acceptedCount;
  final int rejectedCount;
  final List<String> rejectionReasons;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.version,
    this.bookmarks = const [],
    this.lastRead,
    this.acceptedCount = 0,
    this.rejectedCount = 0,
    this.rejectionReasons = const [],
  });

  factory BackupValidationResult.failure(
    String message, {
    int rejectedCount = 0,
    List<String> rejectionReasons = const [],
  }) {
    return BackupValidationResult(
      isValid: false,
      errorMessage: message,
      rejectedCount: rejectedCount,
      rejectionReasons: rejectionReasons,
    );
  }

  factory BackupValidationResult.success({
    required int version,
    required List<Bookmark> bookmarks,
    LastRead? lastRead,
    int? acceptedCount,
    int rejectedCount = 0,
    List<String> rejectionReasons = const [],
  }) {
    return BackupValidationResult(
      isValid: true,
      version: version,
      bookmarks: bookmarks,
      lastRead: lastRead,
      acceptedCount: acceptedCount ?? (bookmarks.length + (lastRead != null ? 1 : 0)),
      rejectedCount: rejectedCount,
      rejectionReasons: rejectionReasons,
    );
  }
}

class BookmarkBackupService {
  static const int currentVersion = 1;
  static const String appIdentifier = 'talib_ilm';

  /// Safely reads the backup file content with explicit byte limits and strict UTF-8 decoding.
  static Future<String> readBackupFile(PlatformFile file) async {
    // 1. Check metadata length first
    if (file.size > AppPolicy.maxBackupFileBytes) {
      throw const FormatException('حجم الملف يتجاوز الحد الأقصى المسموح به (512 كيلوبايت)');
    }

    // 2. If bytes are already in memory
    if (file.bytes != null) {
      if (file.bytes!.length > AppPolicy.maxBackupFileBytes) {
        throw const FormatException('حجم الملف يتجاوز الحد الأقصى المسموح به (512 كيلوبايت)');
      }
      return utf8.decode(file.bytes!, allowMalformed: false);
    }

    // 3. For path-based files
    if (file.path != null) {
      final ioFile = File(file.path!);
      if (!await ioFile.exists()) {
        throw const FileSystemException('الملف المحدد غير موجود');
      }

      final fileLength = await ioFile.length();
      if (fileLength > AppPolicy.maxBackupFileBytes) {
        throw const FormatException('حجم الملف يتجاوز الحد الأقصى المسموح به (512 كيلوبايت)');
      }

      // Stream read bounded bytes in case file changed between stat and read
      final stream = ioFile.openRead();
      final bytes = <int>[];
      await for (final chunk in stream) {
        bytes.addAll(chunk);
        if (bytes.length > AppPolicy.maxBackupFileBytes) {
          throw const FormatException('حجم الملف يتجاوز الحد الأقصى المسموح به أثناء القراءة');
        }
      }
      return utf8.decode(bytes, allowMalformed: false);
    }

    throw const FormatException('تعذر الوصول إلى محتوى الملف المحدد');
  }

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

    if (!context.mounted) return;
    await AppShare.shareXFiles(
      context,
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'نسخة احتياطية لمحفوظات طالب علم',
      text: 'نسخة احتياطية للآيات المحفوظة والملاحظات الإيمانية من تطبيق طالب علم.',
    );
  }

  /// Validates the JSON string structure, application signature, version, bounds, and coordinates.
  static BackupValidationResult validateAndParse(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return BackupValidationResult.failure('الملف المحدد فارغ تماماً');
    }

    if (utf8.encode(jsonString).length > AppPolicy.maxBackupFileBytes) {
      return BackupValidationResult.failure(
        'حجم الملف يتجاوز الحد الأقصى المسموح به (512 كيلوبايت)',
      );
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

    if (rawBookmarks.length > AppPolicy.maxBackupBookmarks) {
      return BackupValidationResult.failure(
        'عدد المحفوظات يتجاوز الحد الأقصى المسموح به (${AppPolicy.maxBackupBookmarks} عنصر)',
      );
    }

    final List<Bookmark> parsedBookmarks = [];
    final Set<String> seenCoordinates = {};
    int rejectedCount = 0;
    final List<String> rejectionReasons = [];

    for (int i = 0; i < rawBookmarks.length; i++) {
      final item = rawBookmarks[i];
      if (item is! Map) {
        rejectedCount++;
        rejectionReasons.add('العنصر رقم $i ليس كائناً صالحاً');
        continue;
      }

      try {
        final map = item.map((k, v) => MapEntry(k.toString(), v));
        final bookmark = Bookmark.fromJson(map, strict: true);

        // Coordinate duplicate policy: keep first, reject duplicate
        final coordKey = '${bookmark.surah}:${bookmark.ayah}:${bookmark.isSurah}';
        if (seenCoordinates.contains(coordKey)) {
          rejectedCount++;
          rejectionReasons.add('تكرار في الآية المحفوظة (${bookmark.surah}:${bookmark.ayah})');
          continue;
        }

        seenCoordinates.add(coordKey);
        parsedBookmarks.add(bookmark);
      } on FormatException catch (e) {
        rejectedCount++;
        rejectionReasons.add('العنصر رقم $i: ${e.message}');
      } catch (_) {
        rejectedCount++;
        rejectionReasons.add('العنصر رقم $i غير صالح');
      }
    }

    LastRead? parsedLastRead;
    final rawLastRead = decoded['lastRead'];
    if (rawLastRead != null) {
      if (rawLastRead is! Map) {
        rejectedCount++;
        rejectionReasons.add('بيانات آخر قراءة ليست كائناً صالحاً');
      } else {
        try {
          final map = rawLastRead.map((k, v) => MapEntry(k.toString(), v));
          parsedLastRead = LastRead.fromJson(map, strict: true);
        } catch (e) {
          rejectedCount++;
          rejectionReasons.add('بيانات آخر قراءة غير صالحة: $e');
        }
      }
    }

    if (parsedBookmarks.isEmpty && parsedLastRead == null) {
      return BackupValidationResult.failure(
        'لا توجد أي بيانات صالحة للاستيراد في الملف',
        rejectedCount: rejectedCount,
        rejectionReasons: rejectionReasons,
      );
    }

    return BackupValidationResult.success(
      version: version,
      bookmarks: parsedBookmarks,
      lastRead: parsedLastRead,
      acceptedCount: parsedBookmarks.length + (parsedLastRead != null ? 1 : 0),
      rejectedCount: rejectedCount,
      rejectionReasons: rejectionReasons,
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
