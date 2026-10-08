import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
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
    final isDark = context.isDark;
    final bgColor = context.backgroundColor;
    final cardColor = context.surfaceContainer;
    final textColor = context.textPrimaryColor;
    final accentColor = context.goldColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'المحفوظات',
          style: TextStyle(
            fontFamily: 'Amiri',
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
                    color: accentColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد سور محفوظة بعد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                  onDismissed: (direction) {
                    _removeBookmark(surahNum);
                    AppSnackbar.info(context, 'تم الحذف من المحفوظات');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.04,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfessionalQuranScreen(initialSurah: surahNum),
                          ),
                        );
                      },
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          '$surahNum',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: accentColor,
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
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _removeBookmark(surahNum);
                          AppSnackbar.info(context, 'تم الحذف من المحفوظات');
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
