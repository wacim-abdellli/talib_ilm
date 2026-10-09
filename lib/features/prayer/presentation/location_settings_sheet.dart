import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/app_button.dart';
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
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  bool _loading = true;
  bool _manualEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final manual = await _locationService.getManualLocation();
    if (!mounted) return;
    setState(() {
      _manualEnabled = manual != null;
      _cityController.text = manual?.city ?? '';
      _latController.text = manual != null
          ? manual.latitude.toStringAsFixed(6)
          : '';
      _lonController.text = manual != null
          ? manual.longitude.toStringAsFixed(6)
          : '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat == null || lon == null) {
      _showMessage(AppStrings.locationInvalidMessage);
      return;
    }
    final city = _cityController.text.trim().isEmpty
        ? AppStrings.locationManualDefault
        : _cityController.text.trim();
    await _locationService.setManualLocation(
      LocationResult(latitude: lat, longitude: lon, city: city),
    );
    widget.onSaved?.call();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clearManual() async {
    await _locationService.clearManualLocation();
    widget.onSaved?.call();
    if (mounted) Navigator.pop(context);
  }

  void _showMessage(String message) {
    AppSnackbar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_loading) {
      return Container(
        height: 240,
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
              height: 48,
              borderRadius: AppRadius.mdRadius,
            ),
            const SizedBox(height: AppSpace.md),
            AppSkeleton(
              width: double.infinity,
              height: 52,
              borderRadius: AppRadius.mdRadius,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xxl,
        top: AppSpace.md,
        start: AppSpace.xl,
        end: AppSpace.xl,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(
          color: palette.border,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                const IconBadge(icon: Icons.location_on_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    AppStrings.locationSettingsTitle,
                    style: context.text.titleSmall.copyWith(
                      color: palette.text,
                    ),
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
            const SizedBox(height: AppSpace.lg),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              constraints: const BoxConstraints(
                minHeight: AppSize.tap,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: palette.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.locationManualToggle,
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Switch(
                    value: _manualEnabled,
                    activeThumbColor: palette.primary,
                    activeTrackColor: palette.primarySoft,
                    onChanged: (value) {
                      setState(() => _manualEnabled = value);
                    },
                  ),
                ],
              ),
            ),
            if (_manualEnabled) ...[
              const SizedBox(height: AppSpace.lg),
              _buildField(
                controller: _cityController,
                label: AppStrings.locationManualCityLabel,
                icon: Icons.location_city_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpace.md),
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
              const SizedBox(height: AppSpace.md),
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
              const SizedBox(height: AppSpace.xl),
              AppButton(
                label: AppStrings.locationSave,
                width: double.infinity,
                onPressed: _save,
              ),
            ] else ...[
              const SizedBox(height: AppSpace.lg),
              AppButton.outline(
                label: AppStrings.locationBackToAuto,
                width: double.infinity,
                onPressed: _clearManual,
              ),
            ],
          ],
        ),
      ),
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
