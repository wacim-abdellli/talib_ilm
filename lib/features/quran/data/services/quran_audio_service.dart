import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Reciter info
class Reciter {
  final String id;
  final String nameAr;
  final String nameEn;

  const Reciter({required this.id, required this.nameAr, required this.nameEn});
}

/// Available reciters
class Reciters {
  static const alafasy = Reciter(
    id: 'ar.alafasy',
    nameAr: 'مشاري العفاسي',
    nameEn: 'Mishary Alafasy',
  );

  static const abdulbasit = Reciter(
    id: 'ar.abdulbasitmurattal',
    nameAr: 'عبد الباسط عبد الصمد',
    nameEn: 'Abdul Basit',
  );

  static const husary = Reciter(
    id: 'ar.husary',
    nameAr: 'محمود خليل الحصري',
    nameEn: 'Al-Husary',
  );

  static const minshawi = Reciter(
    id: 'ar.minshawi',
    nameAr: 'محمد صديق المنشاوي',
    nameEn: 'Al-Minshawi',
  );

  static const all = [alafasy, abdulbasit, husary, minshawi];

  static Reciter? byId(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Audio download status
enum AudioDownloadStatus { notDownloaded, downloading, downloaded, error }

/// Quran Audio Service - Offline-first audio management
class QuranAudioService {
  static final QuranAudioService instance = QuranAudioService._();
  QuranAudioService._();

  Database? _db;
  String? _audioDir;

  static const String _baseUrl = 'https://cdn.islamic.network/quran/audio/128';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<String> get audioDirectory async {
    if (_audioDir != null) return _audioDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _audioDir = join(appDir.path, 'quran_audio');
    await Directory(_audioDir!).create(recursive: true);
    return _audioDir!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quran_audio.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE audio_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah INTEGER NOT NULL,
            ayah INTEGER NOT NULL,
            reciter TEXT NOT NULL,
            file_path TEXT NOT NULL,
            file_size INTEGER,
            downloaded_at INTEGER NOT NULL,
            UNIQUE(surah, ayah, reciter)
          )
        ''');

        await db.execute('''
          CREATE TABLE download_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah INTEGER NOT NULL,
            reciter TEXT NOT NULL,
            status INTEGER NOT NULL,
            progress REAL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_audio_surah ON audio_cache(surah, reciter)',
        );
      },
    );
  }

  /// Check if online
  Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Get audio URL for an ayah
  String getAudioUrl(int surah, int ayah, String reciterId) {
    // Calculate global ayah number
    final globalAyah = _getGlobalAyahNumber(surah, ayah);
    return '$_baseUrl/$reciterId/$globalAyah.mp3';
  }

  /// Get local file path for an ayah
  Future<String> _getLocalPath(int surah, int ayah, String reciterId) async {
    final dir = await audioDirectory;
    return join(dir, reciterId, '${surah}_$ayah.mp3');
  }

  /// Get audio file - returns local path if cached, or URL if online
  Future<String?> getAudioSource(int surah, int ayah, String reciterId) async {
    // Check local cache first
    final localPath = await _getLocalPath(surah, ayah, reciterId);
    if (await File(localPath).exists()) {
      return localPath;
    }

    // Return URL if online
    if (await _isOnline()) {
      return getAudioUrl(surah, ayah, reciterId);
    }

    return null; // Not available offline
  }

  /// Check if ayah audio is downloaded
  Future<bool> isAyahDownloaded(int surah, int ayah, String reciterId) async {
    final localPath = await _getLocalPath(surah, ayah, reciterId);
    return File(localPath).exists();
  }

  /// Download single ayah audio
  Future<bool> downloadAyah(int surah, int ayah, String reciterId) async {
    if (!await _isOnline()) return false;

    try {
      final url = getAudioUrl(surah, ayah, reciterId);
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final localPath = await _getLocalPath(surah, ayah, reciterId);
        final file = File(localPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);

        // Record in database
        final db = await database;
        await db.insert('audio_cache', {
          'surah': surah,
          'ayah': ayah,
          'reciter': reciterId,
          'file_path': localPath,
          'file_size': response.bodyBytes.length,
          'downloaded_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        return true;
      }
    } catch (_) {
      // Download failed
    }
    return false;
  }

  /// Download entire surah
  Future<void> downloadSurah(
    int surah,
    String reciterId, {
    void Function(double progress)? onProgress,
  }) async {
    if (!await _isOnline()) return;

    final ayahCount = _getAyahCount(surah);
    int downloaded = 0;

    for (int ayah = 1; ayah <= ayahCount; ayah++) {
      if (!await isAyahDownloaded(surah, ayah, reciterId)) {
        await downloadAyah(surah, ayah, reciterId);
      }
      downloaded++;
      onProgress?.call(downloaded / ayahCount);
    }
  }

  /// Check surah download status
  Future<double> getSurahDownloadProgress(int surah, String reciterId) async {
    final ayahCount = _getAyahCount(surah);
    int downloaded = 0;

    for (int ayah = 1; ayah <= ayahCount; ayah++) {
      if (await isAyahDownloaded(surah, ayah, reciterId)) {
        downloaded++;
      }
    }

    return downloaded / ayahCount;
  }

  /// Delete surah audio
  Future<void> deleteSurahAudio(int surah, String reciterId) async {
    final db = await database;
    final results = await db.query(
      'audio_cache',
      where: 'surah = ? AND reciter = ?',
      whereArgs: [surah, reciterId],
    );

    for (final row in results) {
      final path = row['file_path'] as String;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await db.delete(
      'audio_cache',
      where: 'surah = ? AND reciter = ?',
      whereArgs: [surah, reciterId],
    );
  }

  /// Get total cache size
  Future<int> getCacheSize() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(file_size) as total FROM audio_cache',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Clear all audio cache
  Future<void> clearCache() async {
    final dir = await audioDirectory;
    final directory = Directory(dir);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      await directory.create();
    }

    final db = await database;
    await db.delete('audio_cache');
  }

  /// Get ayah count for a surah
  int _getAyahCount(int surah) {
    const ayahCounts = [
      0,
      7,
      286,
      200,
      176,
      120,
      165,
      206,
      75,
      129,
      109,
      123,
      111,
      43,
      52,
      99,
      128,
      111,
      110,
      98,
      135,
      112,
      78,
      118,
      64,
      77,
      227,
      93,
      88,
      69,
      60,
      34,
      30,
      73,
      54,
      45,
      83,
      182,
      88,
      75,
      85,
      54,
      53,
      89,
      59,
      37,
      35,
      38,
      29,
      18,
      45,
      60,
      49,
      62,
      55,
      78,
      96,
      29,
      22,
      24,
      13,
      14,
      11,
      11,
      18,
      12,
      12,
      30,
      52,
      52,
      44,
      28,
      28,
      20,
      56,
      40,
      31,
      50,
      40,
      46,
      42,
      29,
      19,
      36,
      25,
      22,
      17,
      19,
      26,
      30,
      20,
      15,
      21,
      11,
      8,
      8,
      19,
      5,
      8,
      8,
      11,
      11,
      8,
      3,
      9,
      5,
      4,
      7,
      3,
      6,
      3,
      5,
      4,
      5,
      6,
    ];
    return surah > 0 && surah <= 114 ? ayahCounts[surah] : 0;
  }

  /// Get global ayah number
  int _getGlobalAyahNumber(int surah, int ayah) {
    const cumulative = [
      0,
      0,
      7,
      293,
      493,
      669,
      789,
      954,
      1160,
      1235,
      1364,
      1473,
      1596,
      1707,
      1750,
      1802,
      1901,
      2029,
      2140,
      2250,
      2348,
      2483,
      2595,
      2673,
      2791,
      2855,
      2932,
      3159,
      3252,
      3340,
      3409,
      3469,
      3503,
      3533,
      3606,
      3660,
      3705,
      3788,
      3970,
      4058,
      4133,
      4218,
      4272,
      4325,
      4414,
      4473,
      4510,
      4545,
      4583,
      4612,
      4630,
      4675,
      4735,
      4784,
      4846,
      4901,
      4979,
      5075,
      5104,
      5126,
      5150,
      5163,
      5177,
      5188,
      5199,
      5217,
      5229,
      5241,
      5271,
      5323,
      5375,
      5419,
      5447,
      5475,
      5495,
      5551,
      5591,
      5622,
      5672,
      5712,
      5758,
      5800,
      5829,
      5848,
      5884,
      5909,
      5931,
      5948,
      5967,
      5993,
      6023,
      6043,
      6058,
      6079,
      6090,
      6098,
      6106,
      6125,
      6130,
      6138,
      6146,
      6157,
      6168,
      6176,
      6179,
      6188,
      6193,
      6197,
      6204,
      6207,
      6213,
      6216,
      6221,
      6225,
      6230,
    ];
    return cumulative[surah] + ayah;
  }
}
