import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_list_tile.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../data/services/shamela_service.dart';

/// Modal bottom sheet displaying bookmarked pages for a Shamela book.
class ShamelaBookmarksSheet extends StatefulWidget {
  final int bookId;
  final ValueChanged<int> onNavigate;
  final List<int>? initialPages;

  const ShamelaBookmarksSheet({
    super.key,
    required this.bookId,
    required this.onNavigate,
    this.initialPages,
  });

  /// Static helper to display the sheet modal
  static Future<void> show({
    required BuildContext context,
    required int bookId,
    required ValueChanged<int> onNavigate,
    List<int>? initialPages,
  }) {
    return AppSheet.show<void>(
      context: context,
      builder: (ctx) => ShamelaBookmarksSheet(
        bookId: bookId,
        onNavigate: onNavigate,
        initialPages: initialPages,
      ),
    );
  }

  @override
  State<ShamelaBookmarksSheet> createState() => _ShamelaBookmarksSheetState();
}

class _ShamelaBookmarksSheetState extends State<ShamelaBookmarksSheet> {
  List<int> _pages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPages != null) {
      _pages = List<int>.from(widget.initialPages!)..sort();
      _isLoading = false;
    } else {
      _loadBookmarks();
    }
  }

  Future<void> _loadBookmarks() async {
    final pages = await ShamelaService.getBookmarkedPages(widget.bookId);
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(int page) async {
    HapticFeedback.mediumImpact();
    await ShamelaService.toggleBookmark(widget.bookId, page);
    if (!mounted) return;
    setState(() {
      _pages.remove(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppSheet(
      titleText: 'الصفحات المحفوظة',
      icon: Icons.bookmark_rounded,
      padding: EdgeInsetsDirectional.zero,
      child: _isLoading
          ? const Padding(
              padding: EdgeInsetsDirectional.all(AppSpace.xxl),
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          : _pages.isEmpty
              ? const Padding(
                  padding: EdgeInsetsDirectional.all(AppSpace.xxl),
                  child: AppEmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'لا توجد صفحات محفوظة',
                    subtitle: 'اضغط على رمز الإشارة المرجعية لحفظ الصفحة الحالية',
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: AppSpace.sm,
                  ),
                  itemCount: _pages.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    thickness: 1,
                    color: palette.border,
                  ),
                  itemBuilder: (context, index) {
                    final page = _pages[index];

                    return Dismissible(
                      key: ValueKey('shamela_bookmark_${widget.bookId}_$page'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: palette.errorSoft,
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSpace.xl,
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: palette.error,
                          size: AppIcon.lg,
                        ),
                      ),
                      onDismissed: (_) => _removeBookmark(page),
                      child: Semantics(
                        label: 'صفحة $page',
                        button: true,
                        child: AppListTile(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onNavigate(page);
                          },
                          leading: Container(
                            width: AppSize.buttonH,
                            height: AppSize.buttonH,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.primarySoft,
                              borderRadius: AppRadius.mdRadius,
                            ),
                            child: Text(
                              '$page',
                              style: context.text.titleSmall.copyWith(
                                color: palette.onPrimarySoft,
                              ),
                            ),
                          ),
                          title: 'صفحة $page',
                          subtitle: 'انقر للانتقال مباشرة إلى الصفحة',
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: AppIcon.sm,
                            color: palette.textSubtle,
                          ),
                          showChevron: false,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
