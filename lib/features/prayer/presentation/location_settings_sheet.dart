import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/app_snackbar.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: context.goldColor.withValues(alpha: isDark ? 0.25 : 0.12),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.outlineVariantColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.goldColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(Icons.location_on_rounded, color: context.goldColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.locationSettingsTitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                ),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppStrings.locationManualToggle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                value: _manualEnabled,
                activeTrackColor: context.goldColor.withValues(alpha: 0.5),
                activeThumbColor: context.goldColor,
                onChanged: (value) {
                  setState(() => _manualEnabled = value);
                },
              ),
            ),
            if (_manualEnabled) ...[
              const SizedBox(height: 16),
              _buildField(
                controller: _cityController,
                label: AppStrings.locationManualCityLabel,
                icon: Icons.location_city_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _latController,
                label: AppStrings.locationLatitudeLabel,
                icon: Icons.north_rounded,
                textInputAction: TextInputAction.next,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _lonController,
                label: AppStrings.locationLongitudeLabel,
                icon: Icons.east_rounded,
                textInputAction: TextInputAction.done,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.goldColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    AppStrings.locationSave,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _clearManual,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: context.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    AppStrings.locationBackToAuto,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontFamily: 'Cairo',
        color: context.textPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          color: context.textSecondaryColor,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, size: 18, color: context.goldColor),
        filled: true,
        fillColor: context.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.goldColor, width: 1.5),
        ),
      ),
    );
  }
}
