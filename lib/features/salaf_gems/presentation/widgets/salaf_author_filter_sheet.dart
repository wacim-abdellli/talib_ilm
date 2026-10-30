import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';

class SalafAuthorFilterSheet extends StatelessWidget {
  final List<String> authors;
  final String selectedAuthor;
  final ValueChanged<String> onSelectAuthor;

  const SalafAuthorFilterSheet({
    super.key,
    required this.authors,
    required this.selectedAuthor,
    required this.onSelectAuthor,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> authors,
    required String selectedAuthor,
    required ValueChanged<String> onSelectAuthor,
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
        authors: authors,
        selectedAuthor: selectedAuthor,
        onSelectAuthor: onSelectAuthor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.sm,
              AppSpace.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  color: palette.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    'تصفية حسب القائل من أئمة السلف',
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                    ),
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
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              itemCount: authors.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpace.xs),
              itemBuilder: (context, index) {
                final author = authors[index];
                final isSelected = author == selectedAuthor;
                final isAll = author == 'الكل';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppRadius.mdRadius,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onSelectAuthor(author);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
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
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAll
                                ? Icons.all_inclusive_rounded
                                : Icons.person_rounded,
                            color:
                                isSelected ? palette.primary : palette.textMuted,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              isAll ? 'الكل (جميع الأعلام والأئمة)' : author,
                              style: textTheme.body.copyWith(
                                color:
                                    isSelected ? palette.primary : palette.text,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: palette.primary,
                            ),
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
    );
  }
}
