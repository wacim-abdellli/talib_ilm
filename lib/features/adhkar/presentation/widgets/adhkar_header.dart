import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/icon_badge.dart';

class AdhkarHeader extends StatefulWidget {
  final int streak;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onNotifications;
  final bool showBack;
  final VoidCallback? onBack;

  const AdhkarHeader({
    super.key,
    required this.streak,
    required this.selectedCategory,
    required this.onSelectCategory,
    this.onSearch,
    this.onNotifications,
    this.showBack = false,
    this.onBack,
  });

  @override
  State<AdhkarHeader> createState() => _AdhkarHeaderState();
}

class _AdhkarHeaderState extends State<AdhkarHeader> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    widget.onSearch?.call(query);
  }

  void _stopSearching() {
    _searchController.clear();
    widget.onSearch?.call('');
    setState(() => _isSearching = false);
  }

  Widget _buildCategoryTab(
    BuildContext context,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    final palette = context.palette;
    final activeBg = palette.primary;
    final activeText = palette.onPrimary;

    final inactiveBg = palette.surface;
    final inactiveBorder = palette.border;
    final inactiveText = palette.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: isActive ? activeBg : inactiveBg,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: isActive ? palette.primary : inactiveBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppIcon.sm,
                color: isActive ? activeText : inactiveText,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                label,
                style: (isActive ? context.text.labelBold : context.text.labelMedium).copyWith(
                  color: isActive ? activeText : inactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSearching) ...[
              // Active Search Header Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: AppSize.inputH,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: AppIcon.md,
                            color: palette.primary,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: _onSearchChanged,
                              style: context.text.body.copyWith(
                                color: palette.text,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ابحث في نصوص الأذكار والأدعية...',
                                hintStyle: context.text.bodySmall.copyWith(
                                  color: palette.textSubtle,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: AppIcon.sm,
                                color: palette.textMuted,
                              ),
                              tooltip: 'مسح البحث',
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: AppIcon.md,
                      color: palette.textMuted,
                    ),
                    tooltip: 'إلغاء البحث',
                    onPressed: _stopSearching,
                  ),
                ],
              ),
            ] else ...[
              // Standard Dashboard Header
              Row(
                children: [
                  if (widget.showBack || Navigator.canPop(context)) ...[
                    AppBackButton(onTap: widget.onBack),
                    const SizedBox(width: AppSpace.xs),
                  ],
                  const IconBadge(
                    icon: Icons.auto_awesome_rounded,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الأذكار والأدعية',
                          style: context.text.title.copyWith(
                            color: palette.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'احفظ أذكار اليوم والليلة من السنة',
                          style: context.text.bodySmall.copyWith(
                            color: palette.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Notifications / Reminders Icon Button
                  if (widget.onNotifications != null)
                    IconButton(
                      icon: Icon(
                        Icons.notifications_active_outlined,
                        size: AppIcon.md,
                        color: palette.gold,
                      ),
                      tooltip: 'تنبيهات الأذكار',
                      onPressed: widget.onNotifications,
                    ),
                  // Search Dhikr Icon Button
                  IconButton(
                    icon: Icon(
                      Icons.search_rounded,
                      size: AppIcon.md,
                      color: palette.textMuted,
                    ),
                    tooltip: 'بحث في الأذكار',
                    onPressed: () => setState(() => _isSearching = true),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  // Streak Badge
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.smRadius,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: AppIcon.sm,
                          color: palette.gold,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          '${widget.streak}',
                          style: context.text.labelBold.copyWith(
                            color: palette.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            // Category tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildCategoryTab(
                    context,
                    'الكل',
                    Icons.grid_view_rounded,
                    widget.selectedCategory == 'all',
                    () => widget.onSelectCategory('all'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'الصباح',
                    Icons.wb_sunny_rounded,
                    widget.selectedCategory == 'morning',
                    () => widget.onSelectCategory('morning'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'المساء',
                    Icons.nights_stay_rounded,
                    widget.selectedCategory == 'evening',
                    () => widget.onSelectCategory('evening'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'بعد الصلاة',
                    Icons.mosque_outlined,
                    widget.selectedCategory == 'after_prayer',
                    () => widget.onSelectCategory('after_prayer'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'سنن الصلاة',
                    Icons.access_time_filled_rounded,
                    widget.selectedCategory == 'prayer_sunan',
                    () => widget.onSelectCategory('prayer_sunan'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'أحوال اليوم',
                    Icons.wb_twilight_rounded,
                    widget.selectedCategory == 'daily',
                    () => widget.onSelectCategory('daily'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'الكرب والهم',
                    Icons.shield_outlined,
                    widget.selectedCategory == 'distress',
                    () => widget.onSelectCategory('distress'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'تسبيح واستغفار',
                    Icons.circle_outlined,
                    widget.selectedCategory == 'tasbeeh',
                    () => widget.onSelectCategory('tasbeeh'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'أدعية جامعة',
                    Icons.menu_book_rounded,
                    widget.selectedCategory == 'duas',
                    () => widget.onSelectCategory('duas'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
