import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_library_wrapper.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<int> _bookmarkedSurahs = [];
  bool _isLoading = true;
  static const String _kBookmarksKey = 'dashboard_fav_surahs';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kBookmarksKey) ?? [];
    setState(() {
      _bookmarkedSurahs = list.map((e) => int.parse(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(int surahNum) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarkedSurahs.remove(surahNum);
    });
    await prefs.setStringList(
      _kBookmarksKey,
      _bookmarkedSurahs.map((e) => e.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFDF8F0);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFE8DED0)
        : const Color(0xFF3D2B1F);
    final accentColor = const Color(0xFFD4A853);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'المحفوظات',
          style: TextStyle(
            fontFamily: 'Amiri',
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _bookmarkedSurahs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: accentColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد محفوظات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookmarkedSurahs.length,
              itemBuilder: (context, index) {
                final surahNum = _bookmarkedSurahs[index];
                final surahName = quran.getSurahNameArabic(surahNum);

                return Dismissible(
                  key: ValueKey(surahNum),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  onDismissed: (direction) {
                    _removeBookmark(surahNum);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم الحذف من القائمة')),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfessionalQuranScreen(initialSurah: surahNum),
                          ),
                        );
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                        child: Text(
                          '$surahNum',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        'سورة $surahName',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _removeBookmark(surahNum),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
