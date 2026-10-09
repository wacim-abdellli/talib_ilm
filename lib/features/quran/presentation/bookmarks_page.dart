import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_palette.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_app_bar.dart';
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
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: PrimaryAppBar(
        title: 'المحفوظات',
        showBack: true,
        bottom: (!_isLoading && _bookmarkedSurahs.isNotEmpty)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.xs),
                  child: Text(
                    '${_bookmarkedSurahs.length} سور محفوظة',
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: palette.gold))
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
                  padding: AppSpace.screenPadding.copyWith(
                    top: AppSpace.sm,
                    bottom: AppSpace.xxl,
                  ),
                  itemCount: _bookmarkedSurahs.length,
                  itemBuilder: (context, index) {
                    final surahNum = _bookmarkedSurahs[index];

                    return Dismissible(
                      key: ValueKey(surahNum),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: AppSpace.sm),
                        alignment: AlignmentDirectional.centerStart,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                        decoration: BoxDecoration(
                          color: palette.errorSoft,
                          borderRadius: AppRadius.lgRadius,
                          border: Border.all(
                            color: palette.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'إزالة',
                              style: textTheme.label.copyWith(
                                color: palette.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Icon(
                              Icons.delete_outline_rounded,
                              color: palette.error,
                              size: AppIcon.md,
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
                        trailing: AppIconButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'إزالة من المحفوظات',
                          color: palette.textMuted,
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
