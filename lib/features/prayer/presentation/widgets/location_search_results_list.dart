import 'package:flutter/material.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/constants/verified_cities.dart';
import '../../../../core/models/location_result.dart';

class LocationSearchResultsList extends StatelessWidget {
  final List<VerifiedCity> cities;
  final LocationResult? currentLocation;
  final ValueChanged<VerifiedCity> onSelectCity;

  const LocationSearchResultsList({
    super.key,
    required this.cities,
    required this.currentLocation,
    required this.onSelectCity,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (cities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpace.xl),
        alignment: Alignment.center,
        child: Text(
          'لم يتم العثور على مدينة مطابقة. تأكد من صحة الاسم أو استخدم زر GPS أعلاه.',
          textAlign: TextAlign.center,
          style: context.text.caption.copyWith(
            color: palette.textMuted,
          ),
        ),
      );
    }

    final displayList = cities.take(15).toList();

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: palette.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayList.length,
        separatorBuilder: (_, index) => Divider(
          height: 1,
          thickness: 1,
          color: palette.border.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final city = displayList[index];
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
                          : Icons.location_city_rounded,
                      size: AppIcon.md,
                      color: isCurrent ? palette.primary : palette.textMuted,
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city.name,
                            style: context.text.body.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isCurrent ? palette.primary : palette.text,
                            ),
                          ),
                          if (city.province != null)
                            Text(
                              '${city.province} • ${city.country}',
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
        },
      ),
    );
  }
}
