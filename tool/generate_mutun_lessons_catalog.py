import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("assets/data/mutun_shuruh_videos.json", "r", encoding="utf-8") as f:
    data = json.load(f)

lines = []
lines.append("import '../models/lesson_model.dart';")
lines.append("")
lines.append("/// Comprehensive Islamic Scholarly Video & Audio Lessons Catalog")
lines.append("/// Curated by top contemporary scholars of Ahl as-Sunnah:")
lines.append("/// (عبد الرزاق البدر، صالح العصيمي، عثمان الخميس، عبد السلام الشويعر، صالح آل الشيخ، سليمان الرحيلي، هيثم سرحان، صالح سندي، وليد السعيدان).")
lines.append("class MutunLessonsCatalog {")
lines.append("  static final Map<String, List<Lesson>> _lessonsByBook = {")

for book in data["books"]:
    book_id = book["book_id"]
    title_ar = book["title_ar"]
    lines.append(f"    // ── {title_ar} ({book_id}) ──")
    lines.append(f"    '{book_id}': const [")
    
    idx = 0
    for scholar in book["shuyookh"]:
        s_name = scholar["name"]
        p_id = scholar["playlist_id"]
        p_url = scholar["playlist_url"]
        scholar_display = f"الشيخ {s_name}" if not s_name.startswith("الشيخ") and not s_name.startswith("د.") else s_name
        
        for vid in scholar["videos"]:
            v_id = vid["video_id"]
            v_title = vid["title"].replace("'", "\\'")
            v_dur = vid["duration_minutes"]
            lines.append("      Lesson(")
            lines.append(f"        index: {idx},")
            lines.append(f"        title: '{v_title}',")
            lines.append(f"        videoId: '{v_id}',")
            lines.append(f"        durationMinutes: {v_dur},")
            lines.append(f"        scholar: '{scholar_display}',")
            lines.append(f"        playlistId: '{p_id}',")
            lines.append(f"        url: 'https://www.youtube.com/watch?v={v_id}',")
            lines.append("      ),")
            idx += 1
            
    lines.append("    ],")

lines.append("  };")
lines.append("")
lines.append("  /// Mapping of (bookId, scholar) to playlist ID")
lines.append("  static final Map<String, String> _playlistsByScholar = {")
for book in data["books"]:
    book_id = book["book_id"]
    for scholar in book["shuyookh"]:
        s_name = scholar["name"]
        scholar_display = f"الشيخ {s_name}" if not s_name.startswith("الشيخ") and not s_name.startswith("د.") else s_name
        p_id = scholar["playlist_id"]
        lines.append(f"    '{book_id}::{scholar_display}': '{p_id}',")
lines.append("  };")
lines.append("")
lines.append("  /// Get verified lesson playlist for any book in the mutun curriculum")
lines.append("  static List<Lesson> getLessonsForBook(String bookId, {String? scholar, String? fallbackPlaylist}) {")
lines.append("    final list = _lessonsByBook[bookId];")
lines.append("    if (list != null && list.isNotEmpty) {")
lines.append("      if (scholar != null && scholar.isNotEmpty) {")
lines.append("        final filtered = list.where((l) => l.scholar == scholar).toList();")
lines.append("        if (filtered.isNotEmpty) return filtered;")
lines.append("      }")
lines.append("      return list;")
lines.append("    }")
lines.append("    // Fallback if dynamic custom book")
lines.append("    return Lesson.generateFromPlaylist(")
lines.append("      fallbackPlaylist ?? 'PLClZ7RmnwNVPdQHQ1NhNFgpiEeVSY7PYq',")
lines.append("      count: 5,")
lines.append("    );")
lines.append("  }")
lines.append("")
lines.append("  /// Get all distinct scholars explaining this book")
lines.append("  static List<String> getScholarsForBook(String bookId) {")
lines.append("    final list = _lessonsByBook[bookId];")
lines.append("    if (list == null || list.isEmpty) return const [];")
lines.append("    final seen = <String>{};")
lines.append("    final scholars = <String>[];")
lines.append("    for (final l in list) {")
lines.append("      final s = l.scholar;")
lines.append("      if (s != null && s.isNotEmpty && seen.add(s)) {")
lines.append("        scholars.add(s);")
lines.append("      }")
lines.append("    }")
lines.append("    return scholars;")
lines.append("  }")
lines.append("")
lines.append("  /// Get playlist ID for specific scholar and book")
lines.append("  static String? getPlaylistForScholar(String bookId, String scholar) {")
lines.append("    return _playlistsByScholar['$bookId::$scholar'];")
lines.append("  }")
lines.append("")
lines.append("  /// Check if a book has a curated lecture series")
lines.append("  static bool hasLessons(String bookId) {")
lines.append("    return _lessonsByBook.containsKey(bookId);")
lines.append("  }")
lines.append("}")
lines.append("")

output_file = "lib/features/ilm/data/catalogs/mutun_lessons_catalog.dart"
with open(output_file, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Generated {output_file} successfully")
