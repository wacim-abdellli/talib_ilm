import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/location_service.dart';

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
    if (_loading) {
      return const SizedBox(height: AppUi.sheetPlaceholderHeight);
    }

    return Padding(
      padding: AppUi.screenPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.locationSettingsTitle, style: AppText.heading),
          const SizedBox(height: AppUi.gapSM),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.locationManualToggle, style: AppText.body),
            value: _manualEnabled,
            onChanged: (value) {
              setState(() => _manualEnabled = value);
            },
          ),
          if (_manualEnabled) ...[
            const SizedBox(height: AppUi.gapSM),
            TextField(
              controller: _cityController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.locationManualCityLabel,
              ),
            ),
            const SizedBox(height: AppUi.gapMD),
            TextField(
              controller: _latController,
              textInputAction: TextInputAction.next,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: AppStrings.locationLatitudeLabel,
              ),
            ),
            const SizedBox(height: AppUi.gapMD),
            TextField(
              controller: _lonController,
              textInputAction: TextInputAction.done,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: AppStrings.locationLongitudeLabel,
              ),
            ),
            const SizedBox(height: AppUi.gapLG),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: _save,
                child: const Text(AppStrings.locationSave),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppUi.gapMD),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _clearManual,
                child: const Text(AppStrings.locationBackToAuto),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
