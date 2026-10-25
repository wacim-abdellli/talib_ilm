import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../core/constants/verified_cities.dart';
import '../../../../core/models/location_result.dart';
import '../../../../shared/widgets/app_button.dart';

class LocationSearchResultsList extends StatelessWidget {
  final List<VerifiedCity> cities;
  final List<VerifiedCity> onlineCities;
  final bool isSearchingOnline;
  final String searchQuery;
  final VoidCallback? onTriggerOnlineSearch;
  final LocationResult? currentLocation;
  final ValueChanged<VerifiedCity> onSelectCity;

  const LocationSearchResultsList({
    super.key,
    required this.cities,
    this.onlineCities = const [],
    this.isSearchingOnline = false,
    this.searchQuery = '',
    this.onTriggerOnlineSearch,
    required this.currentLocation,
    required this.onSelectCity,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasLocal = cities.isNotEmpty;
    final hasOnline = onlineCities.isNotEmpty;

    if (!hasLocal && !hasOnline && !isSearchingOnline) {
      return Container(
        padding: const EdgeInsetsDirectional.all(AppSpace.xl),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: palette.border),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'لم يتم العثور على مدينة مطابقة محلياً في القائمة.',
              textAlign: TextAlign.center,
              style: context.text.caption.copyWith(
                color: palette.textMuted,
              ),
            ),
            if (onTriggerOnlineSearch != null && searchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              AppButton(
                label: 'البحث عبر الإنترنت عن "$searchQuery"',
                icon: Icons.travel_explore_rounded,
                onPressed: onTriggerOnlineSearch,
              ),
            ],
          ],
        ),
      );
    }

    final localDisplay = cities.take(15).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasLocal) ...[
          Container(
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: palette.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: localDisplay.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: palette.border.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                return _buildCityTile(
                  context,
                  palette,
                  localDisplay[index],
                  isOnline: false,
                );
              },
            ),
          ),
        ],

        if (isSearchingOnline) ...[
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: AppIcon.sm,
                  height: AppIcon.sm,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  'جاري البحث عبر الإنترنت عن "$searchQuery"...',
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ] else if (hasOnline) ...[
          const SizedBox(height: AppSpace.md),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
            child: Row(
              children: [
                Icon(
                  Icons.travel_explore_rounded,
                  size: AppIcon.sm,
                  color: palette.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  'نتائج البحث عبر الإنترنت',
                  style: context.text.caption.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Container(
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: palette.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: onlineCities.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: palette.border.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                return _buildCityTile(
                  context,
                  palette,
                  onlineCities[index],
                  isOnline: true,
                );
              },
            ),
          ),
        ] else if (hasLocal && onTriggerOnlineSearch != null && searchQuery.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          AppButton.text(
            label: 'البحث أيضاً عبر الإنترنت عن "$searchQuery"',
            icon: Icons.travel_explore_rounded,
            onPressed: onTriggerOnlineSearch,
          ),
        ],
      ],
    );
  }

  Widget _buildCityTile(
    BuildContext context,
    AppPalette palette,
    VerifiedCity city, {
    required bool isOnline,
  }) {
    final isCurrent = currentLocation?.city == city.name;

    return Material(
      color: isCurrent
          ? palette.primarySoft.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onSelectCity(city),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSize.tap),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              Icon(
                isCurrent
                    ? Icons.check_circle_rounded
                    : (isOnline
                        ? Icons.travel_explore_rounded
                        : Icons.location_city_rounded),
                size: AppIcon.md,
                color: isCurrent ? palette.primary : palette.textMuted,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            city.name,
                            style: context.text.body.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isCurrent ? palette.primary : palette.text,
                            ),
                          ),
                        ),
                        if (isOnline) ...[
                          const SizedBox(width: AppSpace.xs),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: palette.primarySoft,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              'عبر الإنترنت',
                              style: context.text.caption.copyWith(
                                color: palette.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (city.province != null || city.country.isNotEmpty)
                      Text(
                        [city.province, city.country]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(' • '),
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppIcon.md,
                color: palette.textSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
