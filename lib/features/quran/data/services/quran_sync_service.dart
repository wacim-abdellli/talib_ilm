import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/quran_database.dart';
import 'quran_page_service.dart';

class QuranSyncService {
  static const String _chunkKeyPrefix = 'quran_chunk_synced_';
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  // Singleton
  static final QuranSyncService _instance = QuranSyncService._();
  QuranSyncService._();
  static QuranSyncService get instance => _instance;

  final StreamController<double> _progressController =
      StreamController.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // Track active downloads to prevent duplicates
  final Set<int> _activeDownloads = {};

  /// Check if a specific chunk (20 pages) is downloaded
  Future<bool> isChunkDownloaded(int chunkIndex) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_chunkKeyPrefix$chunkIndex') ?? false;
  }

  /// Download Initial content (Al-Fatiha + Pages 1-3)
  /// Blocking, fast, essential for First Launch.
  Future<void> downloadInitialContent() async {
    if (await isChunkDownloaded(1)) return; // Already have first chunk

    // Just download first 3 pages quickly
    // But for simplicity, we can trigger Chunk 1 download and wait for it.
    // Chunk 1 is pages 1-20.
    await downloadChunk(1);
  }

  /// Download a logical chunk of pages (Index 1..31)
  /// Each chunk is 20 pages (Juz-like size).
  Future<void> downloadChunk(int chunkIndex) async {
    if (_activeDownloads.contains(chunkIndex)) return; // Already downloading
    if (await isChunkDownloaded(chunkIndex)) return; // Already done

    _activeDownloads.add(chunkIndex);
    _progressController.add(0.0);

    try {
      final startPage = (chunkIndex - 1) * 20 + 1;
      final endPage = (chunkIndex * 20).clamp(1, 604);
      final totalPages = endPage - startPage + 1;

      print(
        'Starting download for Chunk $chunkIndex (Pages $startPage-$endPage)',
      );

      for (int i = 0; i < totalPages; i++) {
        final pageNum = startPage + i;

        // Check DB first (Checkpointing)
        final existing = await QuranDatabase.instance.getPage(pageNum);
        if (existing == null) {
          await _fetchAndSavePage(pageNum);
        }

        // Progress for this chunk operation
        _progressController.add((i + 1) / totalPages);

        // Gentle throttle
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Mark as done
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_chunkKeyPrefix$chunkIndex', true);
      print('Chunk $chunkIndex Completed.');
    } catch (e) {
      print('Chunk $chunkIndex Failed: $e');
      _progressController.addError(e);
      rethrow;
    } finally {
      _activeDownloads.remove(chunkIndex);
    }
  }

  /// Single Page Fetcher (Internal)
  Future<void> _fetchAndSavePage(int pageNumber) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        final uri = Uri.parse(
          '$_baseUrl/verses/by_page/$pageNumber?fields=text_uthmani',
        );
        final response = await http
            .get(
              uri,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final data = QuranPageData.fromApiResponse(pageNumber, json);
          await QuranDatabase.instance.savePage(pageNumber, data);
          return;
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        attempts++;
        if (attempts >= 3) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
