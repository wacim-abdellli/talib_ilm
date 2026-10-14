import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../data/adhkar_models.dart';

/// Opens the scholarly Table of Contents (فهرس الأذكار) for an Adhkar section.
Future<int?> showAdhkarFahrasSheet({
  required BuildContext context,
  required String categoryTitle,
  required List<AthkarItem> items,
  required int currentIndex,
  required Map<String, int> counts,
  required String Function(AthkarItem) favoriteIdFor,
  required int Function(List<AthkarItem>, int) repeatFor,
}) {
  return AppSheet.show<int>(
    context: context,
    builder: (context) {
      return AdhkarFahrasSheet(
        categoryTitle: categoryTitle,
        items: items,
        currentIndex: currentIndex,
        counts: counts,
        favoriteIdFor: favoriteIdFor,
        repeatFor: repeatFor,
      );
    },
  );
}

/// Rich interactive table of contents (فهرس) for an Adhkar recitation session.
class AdhkarFahrasSheet extends StatefulWidget {
  final String categoryTitle;
  final List<AthkarItem> items;
  final int currentIndex;
  final Map<String, int> counts;
  final String Function(AthkarItem) favoriteIdFor;
  final int Function(List<AthkarItem>, int) repeatFor;

  const AdhkarFahrasSheet({
    super.key,
    required this.categoryTitle,
    required this.items,
    required this.currentIndex,
    required this.counts,
    required this.favoriteIdFor,
    required this.repeatFor,
  });

  @override
  State<AdhkarFahrasSheet> createState() => _AdhkarFahrasSheetState();
}

class _AdhkarFahrasSheetState extends State<AdhkarFahrasSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u0652\u0670\u0640]');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });

    // Auto-scroll to current item if beyond the top
    if (widget.currentIndex > 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final targetOffset = (widget.currentIndex * 90.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            targetOffset,
            duration: AppMotion.base,
            curve: AppMotion.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _normalizeArabic(String text) {
    var s = text.replaceAll(_tashkeelRegex, '');
    s = s.replaceAll(RegExp(r'[إأآا]'), 'ا');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ى', 'ي');
    return s.toLowerCase();
  }

  bool _isItemDone(int index) {
    final item = widget.items[index];
    final key = widget.favoriteIdFor(item);
    final count = widget.counts[key] ?? 0;
    final target = widget.repeatFor(widget.items, index);
    return target > 0 && count >= target;
  }

  int _countForItem(int index) {
    final item = widget.items[index];
    final key = widget.favoriteIdFor(item);
    return widget.counts[key] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final totalItems = widget.items.length;
    int completedCount = 0;
    for (int i = 0; i < totalItems; i++) {
      if (_isItemDone(i)) completedCount++;
    }
    final progressRatio = totalItems > 0 ? completedCount / totalItems : 0.0;

    final normalizedQuery = _normalizeArabic(_searchQuery);

    // List of pairs (originalIndex, item)
    final filteredEntries = <MapEntry<int, AthkarItem>>[];
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (normalizedQuery.isEmpty) {
        filteredEntries.add(MapEntry(i, item));
      } else {
        final normArabic = _normalizeArabic(item.arabic);
        final normFadl = _normalizeArabic(item.fadl);
        final normTitle = _normalizeArabic(item.countDescription);
        if (normArabic.contains(normalizedQuery) ||
            normFadl.contains(normalizedQuery) ||
            normTitle.contains(normalizedQuery)) {
          filteredEntries.add(MapEntry(i, item));
        }
      }
    }

    return AppSheet(
      titleText: 'فهرس الأذكار',
      icon: Icons.format_list_bulleted_rounded,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Summary: Section Title & Completion Stats ──────
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
              vertical: AppSpace.sm,
            ),
            child: Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.categoryTitle,
                          style: textTheme.label.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: completedCount == totalItems && totalItems > 0
                              ? palette.success.withValues(alpha: 0.15)
                              : palette.goldSoft,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'مكتمل $completedCount من $totalItems',
                          style: textTheme.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: completedCount == totalItems && totalItems > 0
                                ? palette.success
                                : palette.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 4,
                      backgroundColor: palette.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completedCount == totalItems && totalItems > 0
                            ? palette.success
                            : palette.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search & Filter Field ─────────────────────────────────
          if (totalItems >= 3)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.xs,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: palette.border),
                ),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  style: textTheme.body.copyWith(color: palette.text),
                  decoration: InputDecoration(
                    hintText: 'ابحث في أذكار هذا القسم...',
                    hintStyle: textTheme.caption.copyWith(color: palette.textMuted),
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: AppIcon.md,
                      color: palette.textMuted,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'مسح البحث',
                            icon: Icon(
                              Icons.clear_rounded,
                              size: AppIcon.sm,
                              color: palette.textMuted,
                            ),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpace.xs),

          // ── Scrollable Dhikr Items List ───────────────────────────
          Flexible(
            child: filteredEntries.isEmpty
                ? Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                    child: Center(
                      child: Text(
                        'لا توجد أذكار مطابقة للبحث',
                        style: textTheme.body.copyWith(color: palette.textMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xl,
                      vertical: AppSpace.sm,
                    ),
                    itemCount: filteredEntries.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: AppSpace.sm),
                    itemBuilder: (context, idx) {
                      final entry = filteredEntries[idx];
                      final origIndex = entry.key;
                      final item = entry.value;

                      final isDone = _isItemDone(origIndex);
                      final isCurrent = origIndex == widget.currentIndex;
                      final currentCount = _countForItem(origIndex);
                      final targetRepeat = widget.repeatFor(widget.items, origIndex);

                      return _FahrasDhikrTile(
                        origIndex: origIndex,
                        item: item,
                        isDone: isDone,
                        isCurrent: isCurrent,
                        currentCount: currentCount,
                        targetRepeat: targetRepeat,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context, origIndex);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FahrasDhikrTile extends StatelessWidget {
  final int origIndex;
  final AthkarItem item;
  final bool isDone;
  final bool isCurrent;
  final int currentCount;
  final int targetRepeat;
  final VoidCallback onTap;

  const _FahrasDhikrTile({
    required this.origIndex,
    required this.item,
    required this.isDone,
    required this.isCurrent,
    required this.currentCount,
    required this.targetRepeat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    // Determine subtitle or label
    final hasCustomTitle = item.countDescription.isNotEmpty &&
        !item.countDescription.contains('مرة') &&
        !item.countDescription.contains('مرات');

    return Semantics(
      button: true,
      label: 'الذكر رقم ${origIndex + 1}',
      hint: isDone ? 'مكتمل' : (isCurrent ? 'الذكر الحالي' : 'اضغط للانتقال'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdRadius,
          child: Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: isCurrent
                  ? palette.primarySoft
                  : (isDone
                      ? palette.surfaceMuted
                      : palette.surfaceRaised),
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: isCurrent
                    ? palette.primary
                    : (isDone
                        ? palette.success.withValues(alpha: 0.35)
                        : palette.border),
                width: isCurrent ? 1.5 : 1.0,
              ),
              boxShadow: isCurrent ? palette.shadow : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Number / Status Badge ──
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? palette.success.withValues(alpha: 0.15)
                        : (isCurrent
                            ? palette.goldSoft
                            : palette.surfaceMuted),
                    border: Border.all(
                      color: isDone
                          ? palette.success
                          : (isCurrent ? palette.gold : palette.border),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(
                            Icons.check_rounded,
                            size: AppIcon.xs,
                            color: palette.success,
                          )
                        : Text(
                            '${origIndex + 1}',
                            style: textTheme.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isCurrent ? palette.gold : palette.textMuted,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: AppSpace.md),

                // ── Dhikr Excerpt & Metadata ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom Title or Row Header
                      if (hasCustomTitle) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs + 2,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: palette.goldSoft,
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Text(
                                item.countDescription,
                                style: textTheme.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.gold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: AppSpace.xs),
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primary,
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Text(
                                  'الحالي',
                                  style: textTheme.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: palette.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                      ] else if (isCurrent) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: palette.primary,
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Text(
                                'الذكر الحالي',
                                style: textTheme.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: palette.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                      ],

                      // Sacred Dhikr Arabic text
                      Text(
                        item.arabic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: textTheme.sacred.copyWith(
                          color: palette.text,
                          height: 1.5,
                        ),
                      ),

                      // Virtue snippet (if present)
                      if (item.fadl.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: AppIcon.xs,
                              color: palette.gold,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Expanded(
                              child: Text(
                                item.fadl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: AppSpace.sm),

                // ── Repetition & Count Badge ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isDone
                            ? palette.success.withValues(alpha: 0.15)
                            : palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: isDone
                              ? palette.success.withValues(alpha: 0.3)
                              : palette.border,
                        ),
                      ),
                      child: Text(
                        '$currentCount / $targetRepeat',
                        style: textTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDone ? palette.success : palette.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
