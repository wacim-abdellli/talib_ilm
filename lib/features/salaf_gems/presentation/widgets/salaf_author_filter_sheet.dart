import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/salaf_filter_models.dart';

class SalafAuthorFilterSheet extends StatefulWidget {
  final List<SalafScholarItem> scholars;
  final Map<String, int> counts;
  final SalafScholarItem selectedScholar;
  final ValueChanged<SalafScholarItem> onSelectScholar;

  const SalafAuthorFilterSheet({
    super.key,
    required this.scholars,
    required this.counts,
    required this.selectedScholar,
    required this.onSelectScholar,
  });

  static Future<void> show({
    required BuildContext context,
    required List<SalafScholarItem> scholars,
    required Map<String, int> counts,
    required SalafScholarItem selectedScholar,
    required ValueChanged<SalafScholarItem> onSelectScholar,
  }) {
    final palette = context.palette;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTopRadius,
      ),
      builder: (_) => SalafAuthorFilterSheet(
        scholars: scholars,
        counts: counts,
        selectedScholar: selectedScholar,
        onSelectScholar: onSelectScholar,
      ),
    );
  }

  @override
  State<SalafAuthorFilterSheet> createState() => _SalafAuthorFilterSheetState();
}

class _SalafAuthorFilterSheetState extends State<SalafAuthorFilterSheet> {
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

    final filtered = widget.scholars.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.displayName.toLowerCase().contains(_searchQuery) ||
          s.role.toLowerCase().contains(_searchQuery);
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
                      Icons.person_search_rounded,
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
                          'تصفية حسب القائل من الأئمة والصحابة',
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'عرض الآثار والدرر الموثقة لكل إمام وعلم',
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

            // Search in Scholars Input
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
                          hintText: 'ابحث باسم الإمام أو الصحابي...',
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

            // Scholar List
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpace.xs),
                itemBuilder: (context, index) {
                  final scholar = filtered[index];
                  final isSelected = scholar.id == widget.selectedScholar.id;
                  final count = widget.counts[scholar.id] ?? 0;
                  final isAll = scholar.id == 'all';

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadius.mdRadius,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSelectScholar(scholar);
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
                                isAll
                                    ? Icons.all_inclusive_rounded
                                    : Icons.person_rounded,
                                color: isSelected
                                    ? palette.primary
                                    : palette.textMuted,
                                size: AppIcon.sm,
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    scholar.displayName,
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
                                  if (!isAll && scholar.role.isNotEmpty)
                                    Text(
                                      scholar.role,
                                      style: textTheme.caption.copyWith(
                                        color: palette.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
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
