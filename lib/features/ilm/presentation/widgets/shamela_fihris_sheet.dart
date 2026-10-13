import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/shamela_models.dart';

class ShamelaFihrisSheet extends StatefulWidget {
  final List<ShamelaChapter> chapters;
  final bool isLoading;
  final int currentPage;
  final ValueChanged<int> onPageSelected;

  const ShamelaFihrisSheet({
    super.key,
    required this.chapters,
    required this.isLoading,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<ShamelaFihrisSheet> createState() => _ShamelaFihrisSheetState();
}

class _ShamelaFihrisSheetState extends State<ShamelaFihrisSheet> {
  String _search = '';

  List<ShamelaChapter> get _filtered {
    if (_search.trim().isEmpty) return widget.chapters;
    final q = _search.trim().toLowerCase();
    return widget.chapters.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final list = _filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsetsDirectional.only(
                  top: AppSpace.md,
                  bottom: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: palette.gold, size: AppIcon.lg),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'فهرس موضوعات الكتاب',
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.chapters.length} أبواب',
                    style: textTheme.caption.copyWith(color: palette.textMuted),
                  ),
                ],
              ),
            ),
            // Search filter
            if (widget.chapters.length > 5) ...[
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.xs,
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: textTheme.bodySmall.copyWith(color: palette.text),
                  decoration: InputDecoration(
                    hintText: 'ابحث في أبواب الفهرس...',
                    hintStyle: textTheme.caption.copyWith(color: palette.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, size: AppIcon.sm, color: palette.textMuted),
                    filled: true,
                    fillColor: palette.surface,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.smRadius,
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.smRadius,
                      borderSide: BorderSide(color: palette.border),
                    ),
                  ),
                ),
              ),
            ],
            Divider(color: palette.border, height: 1),
            Expanded(
              child: widget.isLoading
                  ? Center(child: CircularProgressIndicator(color: palette.gold))
                  : list.isEmpty
                      ? const EmptyState(
                          icon: Icons.menu_book_rounded,
                          title: 'لا يتوفر موضوع مطابق',
                          subtitle: 'جرب البحث بكلمة أخرى أو تصفح الصفحات مباشرة.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsetsDirectional.all(AppSpace.md),
                          itemCount: list.length,
                          separatorBuilder: (_, index) => Divider(color: palette.border, height: 1),
                          itemBuilder: (context, i) {
                            final ch = list[i];
                            final isCurrent = ch.pageNumber == widget.currentPage;

                            return ListTile(
                              onTap: () {
                                Navigator.pop(context);
                                widget.onPageSelected(ch.pageNumber);
                              },
                              contentPadding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xxs,
                              ),
                              title: Text(
                                ch.title,
                                style: textTheme.bodySmall.copyWith(
                                  color: isCurrent ? palette.gold : palette.text,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrent ? palette.goldSoft : palette.surfaceMuted,
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Text(
                                  'ص ${ch.pageNumber}',
                                  style: textTheme.caption.copyWith(
                                    color: isCurrent ? palette.gold : palette.textMuted,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
