import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/constants/verified_cities.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/icon_badge.dart';

class LocationSettingsSheet extends StatefulWidget {
  final VoidCallback? onSaved;

  const LocationSettingsSheet({super.key, this.onSaved});

  @override
  State<LocationSettingsSheet> createState() => _LocationSettingsSheetState();
}

class _LocationSettingsSheetState extends State<LocationSettingsSheet> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  LocationResult? _currentLocation;
  bool _loading = true;
  bool _locatingGps = false;
  bool _showCustomCoordinates = false;
  String _selectedCountryFilter = 'ALL';
  String _searchQuery = '';

  static const List<Map<String, String>> _countryFilters = [
    {'code': 'ALL', 'label': 'الكل'},
    {'code': 'DZ', 'label': 'الجزائر 🇩🇿'},
    {'code': 'TN', 'label': 'تونس 🇹🇳'},
    {'code': 'MA', 'label': 'المغرب 🇲🇦'},
    {'code': 'EG', 'label': 'مصر 🇪🇬'},
    {'code': 'SA', 'label': 'السعودية 🇸🇦'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loc = await _locationService.getLocation();
    final manual = await _locationService.getManualLocation();
    if (!mounted) return;
    setState(() {
      _currentLocation = loc;
      _cityController.text = manual?.city ?? '';
      _latController.text =
          manual != null ? manual.latitude.toStringAsFixed(4) : '';
      _lonController.text =
          manual != null ? manual.longitude.toStringAsFixed(4) : '';
      _showCustomCoordinates =
          manual != null && manual.source == LocationSource.manual;
      _loading = false;
    });
  }

  Future<void> _refreshGps() async {
    HapticFeedback.mediumImpact();
    setState(() => _locatingGps = true);

    try {
      final result = await _locationService.refreshGpsLocation();
      if (!mounted) return;

      setState(() {
        _currentLocation = result;
        _locatingGps = false;
      });

      AppSnackbar.success(
        context,
        'تم تحديد موقعك بدقة عالية عبر GPS: ${result.city}',
      );
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _locatingGps = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackbar.error(context, msg);
    }
  }

  Future<void> _selectVerifiedCity(VerifiedCity city) async {
    HapticFeedback.selectionClick();
    await _locationService.setVerifiedCity(city);
    if (!mounted) return;

    final loc = await _locationService.getLocation();
    if (!mounted) return;

    setState(() {
      _currentLocation = loc;
    });

    AppSnackbar.success(
      context,
      'تم اعتماد ${city.name} لحساب مواقيت الصلاة بدقة',
    );
    widget.onSaved?.call();

    // Auto-close sheet after selection for seamless UX
    await Future<void>.delayed(AppMotion.base);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveCustomCoordinates() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat == null || lon == null) {
      AppSnackbar.error(context, AppStrings.locationInvalidMessage);
      return;
    }
    final city = _cityController.text.trim().isEmpty
        ? AppStrings.locationManualDefault
        : _cityController.text.trim();

    await _locationService.setManualLocation(
      LocationResult(
        latitude: lat,
        longitude: lon,
        city: city,
        source: LocationSource.manual,
      ),
    );

    widget.onSaved?.call();
    if (mounted) {
      AppSnackbar.success(context, 'تم حفظ الإحداثيات المخصصة');
      Navigator.pop(context);
    }
  }

  Future<void> _clearManual() async {
    await _locationService.clearManualLocation();
    await _load();
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_loading) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            AppSkeleton(
              width: double.infinity,
              height: 72,
              borderRadius: AppRadius.lgRadius,
            ),
            const SizedBox(height: AppSpace.md),
            AppSkeleton(
              width: double.infinity,
              height: 48,
              borderRadius: AppRadius.mdRadius,
            ),
          ],
        ),
      );
    }

    final filteredCities = VerifiedCitiesCatalog.search(
      _searchQuery,
      countryCode: _selectedCountryFilter,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
        top: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // Header
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
            child: Row(
              children: [
                const IconBadge(icon: Icons.location_on_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'موقعك ومواقيت الصلاة',
                        style: context.text.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'مصدر دقيق ومؤكد للمدينة وأوقات الأذان',
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  color: palette.textMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),
          Divider(height: 1, color: palette.border),

          // Scrollable body
          Flexible(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                // 1. Current Active Location Status Card
                _buildActiveLocationCard(palette),

                const SizedBox(height: AppSpace.md),

                // 2. High-Accuracy Hardware GPS Trigger Button
                _buildGpsButton(palette),

                const SizedBox(height: AppSpace.xl),

                // 3. Section Header for Verified City Selection
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'اختر مدينتك أو ولايتك المعتمدة',
                      style: context.text.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'قائمة رسمية للمدن والولايات لضمان دقة مواقيت الصلاة والأذان 100%',
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),

                const SizedBox(height: AppSpace.md),

                // 4. Search Bar
                _buildSearchBar(palette),

                const SizedBox(height: AppSpace.sm),

                // 5. Country Filter Pills
                _buildCountryFilters(palette),

                const SizedBox(height: AppSpace.md),

                // 6. Verified Cities List
                _buildCitiesList(palette, filteredCities),

                const SizedBox(height: AppSpace.lg),

                // 7. Expandable Custom Coordinates Accordion
                _buildCustomCoordinatesAccordion(palette),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLocationCard(AppPalette palette) {
    final loc = _currentLocation;
    if (loc == null) return const SizedBox.shrink();

    final isAccurate = loc.isAccurate;
    final sourceColor = isAccurate ? palette.primary : palette.gold;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: sourceColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: sourceColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAccurate
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: AppIcon.sm,
                      color: sourceColor,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      loc.sourceLabel,
                      style: context.text.caption.copyWith(
                        color: sourceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (loc.source == LocationSource.manual)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _clearManual,
                    borderRadius: AppRadius.smRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xs / 2,
                      ),
                      child: Text(
                        'العودة للتلقائي',
                        style: context.text.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            loc.city,
            style: context.text.title.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.text,
            ),
          ),
          if (loc.province != null || loc.country != null) ...[
            const SizedBox(height: AppSpace.xs / 2),
            Text(
              [loc.province, loc.country].whereType<String>().join(' • '),
              style: context.text.caption.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xs),
          Text(
            'الإحداثيات: ${loc.latitude.toStringAsFixed(4)}° N, ${loc.longitude.toStringAsFixed(4)}° E',
            style: context.text.caption.copyWith(
              color: palette.textSubtle,
            ),
          ),
          if (!isAccurate) ...[
            const SizedBox(height: AppSpace.sm),
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.gold.withValues(alpha: 0.08),
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: AppIcon.sm,
                    color: palette.gold,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      'الموقع تقديري عبر الإنترنت. اضغط الزر أدناه لتحديد موقع GPS بدقة، أو اختر مدينتك من القائمة.',
                      style: context.text.caption.copyWith(
                        color: palette.text,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGpsButton(AppPalette palette) {
    return AppButton(
      label: _locatingGps ? 'جاري الاتصال بالأقمار الاصطناعية (GPS)...' : 'تحديد موقعي الدقيق عبر GPS',
      icon: _locatingGps ? null : Icons.my_location_rounded,
      width: double.infinity,
      onPressed: _locatingGps ? null : _refreshGps,
    );
  }

  Widget _buildSearchBar(AppPalette palette) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      style: context.text.body.copyWith(
        color: palette.text,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'ابحث عن مدينتك أو ولايتك...',
        hintStyle: context.text.body.copyWith(
          color: palette.textSubtle,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: AppIcon.md,
          color: palette.primary,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? AppIconButton(
                icon: Icons.clear_rounded,
                tooltip: 'مسح',
                color: palette.textMuted,
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: palette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildCountryFilters(AppPalette palette) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _countryFilters.map((c) {
          final isSelected = _selectedCountryFilter == c['code'];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
            child: ChoiceChip(
              label: Text(
                c['label']!,
                style: context.text.caption.copyWith(
                  color: isSelected ? palette.onPrimary : palette.text,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: palette.primary,
              backgroundColor: palette.surfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pillRadius,
                side: BorderSide(
                  color: isSelected ? palette.primary : palette.border,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCountryFilter = c['code']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCitiesList(AppPalette palette, List<VerifiedCity> cities) {
    if (cities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpace.xl),
        alignment: Alignment.center,
        child: Text(
          'لم يتم العثور على مدينة مطابقة. يمكنك كتابة إحداثيات مخصصة أدناه.',
          textAlign: TextAlign.center,
          style: context.text.caption.copyWith(
            color: palette.textMuted,
          ),
        ),
      );
    }

    // Limit visible list items to max 25 for ultra-fast smooth scrolling
    final displayList = cities.take(25).toList();

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
          final isCurrent = _currentLocation?.city == city.name;

          return Material(
            color: isCurrent
                ? palette.primarySoft.withValues(alpha: 0.3)
                : Colors.transparent,
            child: InkWell(
              onTap: () => _selectVerifiedCity(city),
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
                      Icons.chevron_left_rounded,
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

  Widget _buildCustomCoordinatesAccordion(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.mdRadius,
          child: InkWell(
            onTap: () {
              setState(() {
                _showCustomCoordinates = !_showCustomCoordinates;
              });
            },
            borderRadius: AppRadius.mdRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: AppIcon.sm,
                    color: palette.primary,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      'إدخال إحداثيات مخصصة (متقدم)',
                      style: context.text.body.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _showCustomCoordinates
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showCustomCoordinates) ...[
          const SizedBox(height: AppSpace.md),
          _buildField(
            controller: _cityController,
            label: AppStrings.locationManualCityLabel,
            icon: Icons.location_city_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpace.sm),
          _buildField(
            controller: _latController,
            label: AppStrings.locationLatitudeLabel,
            icon: Icons.north_rounded,
            textInputAction: TextInputAction.next,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          _buildField(
            controller: _lonController,
            label: AppStrings.locationLongitudeLabel,
            icon: Icons.east_rounded,
            textInputAction: TextInputAction.done,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: AppStrings.locationSave,
            width: double.infinity,
            onPressed: _saveCustomCoordinates,
          ),
        ],
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: context.text.body.copyWith(
        color: palette.text,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: context.text.caption.copyWith(
          color: palette.textMuted,
        ),
        prefixIcon: Icon(
          icon,
          size: AppIcon.md,
          color: palette.primary,
        ),
        filled: true,
        fillColor: palette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
      ),
    );
  }
}
