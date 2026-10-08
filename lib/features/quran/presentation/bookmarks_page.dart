import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/empty_state.dart';
import 'quran_library_wrapper.dart';
import 'widgets/surah_card.dart';

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
    if (mounted) {
      setState(() {
        _bookmarkedSurahs = list.map((e) => int.parse(e)).toList();
        _isLoading = false;
      });
    }
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
    final textColor = context.textPrimaryColor;
    final accentColor = context.goldColor;
    final mutedColor = context.textSecondaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'المحفوظات',
              style: TextStyle(
                fontFamily: 'Amiri',
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            if (!_isLoading && _bookmarkedSurahs.isNotEmpty)
              Text(
                '${_bookmarkedSurahs.length} سور محفوظة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _bookmarkedSurahs.isEmpty
              ? EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'لا توجد سور محفوظة بعد',
                  subtitle:
                      'قم بحفظ السور المفضلة لديك بالضغط على أيقونة الحفظ في شاشة القرآن لتصل إليها سريعاً هنا.',
                  actionLabel: 'تصفح القرآن الكريم',
                  onAction: () => Navigator.pop(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: _bookmarkedSurahs.length,
                  itemBuilder: (context, index) {
                    final surahNum = _bookmarkedSurahs[index];

                    return Dismissible(
                      key: ValueKey(surahNum),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'إزالة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent.shade100,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (direction) {
                        _removeBookmark(surahNum);
                        AppSnackbar.info(context, 'تمت إزالة السورة من المحفوظات');
                      },
                      child: SurahCard(
                        surahNumber: surahNum,
                        isBookmarked: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfessionalQuranScreen(
                                initialSurah: surahNum,
                              ),
                            ),
                          ).then((_) => _loadBookmarks());
                        },
                        onBookmarkTap: () {
                          _removeBookmark(surahNum);
                          AppSnackbar.info(context, 'تمت إزالة السورة من المحفوظات');
                        },
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: mutedColor,
                            size: 22,
                          ),
                          tooltip: 'إزالة من المحفوظات',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _removeBookmark(surahNum);
                            AppSnackbar.info(
                              context,
                              'تمت إزالة السورة من المحفوظات',
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
