import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_text.dart';
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
      _latController.text =
          manual != null ? manual.latitude.toStringAsFixed(6) : '';
      _lonController.text =
          manual != null ? manual.longitude.toStringAsFixed(6) : '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat == null || lon == null) {
      _showMessage('أدخل خط العرض وخط الطول بشكل صحيح.');
      return;
    }
    final city = _cityController.text.trim().isEmpty
        ? 'الموقع اليدوي'
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.body),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 240);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إعدادات الموقع', style: AppText.heading),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('استخدام موقع يدوي', style: AppText.body),
            value: _manualEnabled,
            onChanged: (value) {
              setState(() => _manualEnabled = value);
            },
          ),
          if (_manualEnabled) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'المدينة (اختياري)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _latController,
              textInputAction: TextInputAction.next,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'خط العرض (Latitude)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lonController,
              textInputAction: TextInputAction.done,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'خط الطول (Longitude)',
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: _save,
                child: const Text('حفظ الموقع'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _clearManual,
                child: const Text('العودة للموقع التلقائي'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
