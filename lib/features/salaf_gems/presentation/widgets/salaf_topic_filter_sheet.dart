import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/salaf_filter_models.dart';

class SalafTopicFilterSheet extends StatefulWidget {
  final List<SalafTopicItem> topics;
  final Map<String, int> counts;
  final SalafTopicItem selectedTopic;
  final ValueChanged<SalafTopicItem> onSelectTopic;

  const SalafTopicFilterSheet({
    super.key,
    required this.topics,
    required this.counts,
    required this.selectedTopic,
    required this.onSelectTopic,
  });

  static Future<void> show({
    required BuildContext context,
    required List<SalafTopicItem> topics,
    required Map<String, int> counts,
    required SalafTopicItem selectedTopic,
    required ValueChanged<SalafTopicItem> onSelectTopic,
  }) {
    final palette = context.palette;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTopRadius,
      ),
      builder: (_) => SalafTopicFilterSheet(
        topics: topics,
        counts: counts,
        selectedTopic: selectedTopic,
        onSelectTopic: onSelectTopic,
      ),
    );
  }

  @override
  State<SalafTopicFilterSheet> createState() => _SalafTopicFilterSheetState();
}

class _SalafTopicFilterSheetState extends State<SalafTopicFilterSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final filtered = widget.topics.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.title.toLowerCase().contains(_searchQuery);
    }).toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsetsDirectional.only(top: AppSpace.sm),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.sm,
                AppSpace.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.bookmarks_rounded,
                      color: palette.gold,
                      size: AppIcon.sm,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تصفية حسب الباب والموضوع',
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'تصفح الآثار والدرر بحسب الأبواب الإيمانية والعلمية',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: palette.textMuted,
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search in Topics Input
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: palette.border),
                ),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: palette.textMuted,
                      size: AppIcon.sm,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.trim().toLowerCase()),
                        style: textTheme.body.copyWith(color: palette.text),
                        decoration: InputDecoration(
                          hintText: 'ابحث في أسماء الأبواب...',
                          hintStyle: textTheme.body.copyWith(
                            color: palette.textSubtle,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsetsDirectional.symmetric(
                            vertical: AppSpace.sm,
                          ),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        color: palette.textMuted,
                        tooltip: 'مسح',
                        iconSize: AppIcon.sm,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Topics List
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpace.xs),
                itemBuilder: (context, index) {
                  final topic = filtered[index];
                  final isSelected = topic.id == widget.selectedTopic.id;
                  final count = widget.counts[topic.id] ?? 0;
                  final isAll = topic.id == 'all';

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadius.mdRadius,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSelectTopic(topic);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.primarySoft
                              : palette.surfaceRaised,
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(
                            color: isSelected ? palette.primary : palette.border,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? palette.primary.withValues(alpha: 0.15)
                                    : palette.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                topic.icon,
                                color: isSelected
                                    ? palette.primary
                                    : palette.textMuted,
                                size: AppIcon.sm,
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Text(
                                topic.title,
                                style: textTheme.body.copyWith(
                                  color: isSelected
                                      ? palette.primary
                                      : palette.text,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            // Verified count pill
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xs / 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? palette.primary.withValues(alpha: 0.18)
                                    : palette.surfaceMuted,
                                borderRadius: AppRadius.pillRadius,
                              ),
                              child: Text(
                                isAll ? '$count أثر' : '$count دُرّة',
                                style: textTheme.caption.copyWith(
                                  color: isSelected
                                      ? palette.primary
                                      : palette.textMuted,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: AppSpace.xs),
                              Icon(
                                Icons.check_circle_rounded,
                                color: palette.primary,
                                size: AppIcon.sm,
                              ),
                            ],
                          ],
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

