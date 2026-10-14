import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/constants/verified_cities.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/icon_badge.dart';

class LocationSettingsSheet extends StatefulWidget {
  final VoidCallback? onSaved;

  const LocationSettingsSheet({super.key, this.onSaved});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSaved,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.85,
      builder: (_) => LocationSettingsSheet(onSaved: onSaved),
    );
  }

  @override
  State<LocationSettingsSheet> createState() => _LocationSettingsSheetState();
}

class _LocationSettingsSheetState extends State<LocationSettingsSheet> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  LocationResult? _currentLocation;
  bool _loading = true;
  bool _locatingGps = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loc = await _locationService.getLocation();
    if (!mounted) return;
    setState(() {
      _currentLocation = loc;
      _loading = false;
    });
  }

  Future<void> _refreshGps() async {
    HapticFeedback.mediumImpact();

    // 1. Native permission check — prompts the Android system dialog if not yet decided
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _showPermissionDeniedDialog();
      return;
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      AppSnackbar.info(context, 'لم يتم منح إذن الموقع');
      return;
    }

    // 2. Hardware GPS service check on phone
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (!mounted) return;
      _showGpsDisabledDialog();
      return;
    }

    // 3. Acquire location smoothly from satellites
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

      await Future<void>.delayed(AppMotion.base);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locatingGps = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackbar.error(context, msg);
    }
  }

  void _showGpsDisabledDialog() {
    AppDialog.show(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'تفعيل خدمة الموقع (GPS)',
        icon: Icons.location_off_rounded,
        iconColor: context.palette.gold,
        content: Text(
          'خدمة تحديد الموقع (GPS) مغلقة على هاتفك. يرجى تفعيلها من شريط الإشعارات السريعة لتحديد موقعك تلقائياً وبدقة.',
          style: context.text.body.copyWith(
            color: context.palette.text,
            height: 1.4,
          ),
        ),
        actions: [
          AppButton.text(
            label: 'إلغاء',
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          const SizedBox(width: AppSpace.sm),
          AppButton(
            label: 'فتح الإعدادات',
            icon: Icons.settings_rounded,
            onPressed: () {
              Navigator.pop(dialogCtx);
              Geolocator.openLocationSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    AppDialog.show(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'إذن الوصول إلى الموقع',
        icon: Icons.security_rounded,
        iconColor: context.palette.primary,
        content: Text(
          'يتطلب تحديد الموقع تلقائياً إذن الـ GPS. يمكنك تفعيل الإذن من إعدادات التطبيق على هاتفك.',
          style: context.text.body.copyWith(
            color: context.palette.text,
            height: 1.4,
          ),
        ),
        actions: [
          AppButton.text(
            label: 'إلغاء',
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          const SizedBox(width: AppSpace.sm),
          AppButton(
            label: 'إعدادات التطبيق',
            icon: Icons.settings_rounded,
            onPressed: () {
              Navigator.pop(dialogCtx);
              Geolocator.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectVerifiedCity(VerifiedCity city) async {
    HapticFeedback.selectionClick();
    await _locationService.setVerifiedCity(city);
    if (!mounted) return;

    final loc = LocationResult(
      latitude: city.latitude,
      longitude: city.longitude,
      city: city.name,
      province: city.province,
      country: city.country,
      countryCode: city.countryCode,
      source: LocationSource.manual,
      calculationMethod: city.calculationMethod,
    );

    setState(() {
      _currentLocation = loc;
    });

    AppSnackbar.success(
      context,
      'تم اعتماد ${city.name} لحساب مواقيت الصلاة بدقة',
    );
    widget.onSaved?.call();

    await Future<void>.delayed(AppMotion.base);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clearManual() async {
    await _locationService.clearManualLocation();
    await _load();
    widget.onSaved?.call();
    if (!mounted) return;
    AppSnackbar.info(context, 'تمت العودة للوضع التلقائي');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_loading) {
      return Container(
        height: 280,
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

    final searchResults = _searchQuery.trim().isEmpty
        ? const <VerifiedCity>[]
        : VerifiedCitiesCatalog.search(_searchQuery.trim());

    return Container(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSpace.md,
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
                        'تحديد دقيق لحساب أوقات الصلاة والأذان',
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

          // Body
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                // 1. Current Active Location Card
                _buildActiveLocationCard(palette),

                const SizedBox(height: AppSpace.lg),

                // 2. High-Accuracy Hardware GPS Button
                _buildGpsButton(palette),

                const SizedBox(height: AppSpace.xs),
                Center(
                  child: Text(
                    'يتم طلب إذن الموقع من النظام مباشرة لتحديد أوقات الأذان بدقة',
                    textAlign: TextAlign.center,
                    style: context.text.caption.copyWith(
                      color: palette.textSubtle,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpace.xl),

                // 3. Clean Search Header
                Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'أو ابحث عن مدينتك يدوياً',
                      style: context.text.caption.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),

                // 4. Search Bar
                _buildSearchBar(palette),

                // 5. Search Results (only displayed when actively searching)
                if (_searchQuery.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  _buildSearchResults(palette, searchResults),
                ],
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
                        'العودة للـ GPS',
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
        ],
      ),
    );
  }

  Widget _buildGpsButton(AppPalette palette) {
    return AppButton(
      label: _locatingGps
          ? 'جاري الاتصال بالأقمار الاصطناعية (GPS)...'
          : 'تحديد موقعي الدقيق عبر GPS',
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
        hintText: 'اكتب اسم مدينتك أو ولايتك...',
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

  Widget _buildSearchResults(AppPalette palette, List<VerifiedCity> cities) {
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
