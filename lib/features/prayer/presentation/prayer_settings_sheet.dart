import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/theme_colors.dart';
import '../../../core/services/adhan_service.dart';
import '../../../core/services/adhan_settings_service.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_states.dart';
import 'widgets/prayer_adhan_section.dart';
import 'widgets/prayer_adjustments_section.dart';
import 'widgets/prayer_calc_section.dart';

class PrayerSettingsSheet extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const PrayerSettingsSheet({super.key, this.onSettingsChanged});

  @override
  State<PrayerSettingsSheet> createState() => _PrayerSettingsSheetState();
}

class _PrayerSettingsSheetState extends State<PrayerSettingsSheet> {
  final AdhanSettingsService _settingsService = AdhanSettingsService();
  final AdhanService _adhanService = AdhanService();

  AdhanSettings? _settings;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
    _adhanService.preload(); // Preload audio
  }

  @override
  void dispose() {
    _adhanService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _settingsService.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_settings == null || _saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    await _settingsService.saveSettings(_settings!);
    widget.onSettingsChanged?.call();

    if (!mounted) return;

    AppSnackbar.success(context, 'تم حفظ إعدادات الصلاة');

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.pop(context);
  }

  void _updateSettings(AdhanSettings newSettings) {
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _settings == null) {
      return const SizedBox(height: 300, child: AppLoadingIndicator());
    }

    final settings = _settings!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: context.goldColor.withValues(alpha: isDark ? 0.25 : 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          Divider(height: 1, color: context.outlineVariantColor),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PrayerCalcSection(
                    settings: settings,
                    isDark: isDark,
                    onSettingsChanged: _updateSettings,
                  ),
                  const SizedBox(height: 18),
                  PrayerAdhanSection(
                    settings: settings,
                    isDark: isDark,
                    adhanService: _adhanService,
                    onSettingsChanged: _updateSettings,
                  ),
                  const SizedBox(height: 18),
                  _buildNotificationsSection(settings, isDark),
                  const SizedBox(height: 18),
                  PrayerAdjustmentsSection(
                    settings: settings,
                    isDark: isDark,
                    onSettingsChanged: _updateSettings,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Save button
          _buildSaveButton(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.goldColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.mosque_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات الصلاة والأذان',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                Text(
                  'تخصيص الحساب والمؤذن والتنبيهات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: context.textSecondaryColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: context.primaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }



  Widget _buildNotificationsSection(AdhanSettings settings, bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'التنبيهات',
            Icons.notifications_outlined,
            isDark,
          ),
          const SizedBox(height: 16),

          // Notify before slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'التنبيه قبل دخول الوقت',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${settings.notifyBeforeMinutes.toInt()} دقيقة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.goldColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: context.goldColor,
                  inactiveTrackColor: context.goldColor.withValues(alpha: 0.2),
                  thumbColor: context.goldColor,
                  overlayColor: context.goldColor.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: settings.notifyBeforeMinutes,
                  min: 5,
                  max: 30,
                  divisions: 5,
                  onChanged: (val) {
                    _updateSettings(
                      settings.copyWith(notifyBeforeMinutes: val),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Iqama toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  'تذكير الإقامة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: settings.iqamaReminders,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    _updateSettings(settings.copyWith(iqamaReminders: val));
                  },
                  activeThumbColor: context.goldColor,
                  activeTrackColor: context.goldColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildSaveButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(
            color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _saving ? null : _save,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: _saving
                    ? null
                    : LinearGradient(
                        colors: [
                          context.primaryColor,
                          context.primaryColor.withValues(alpha: 0.85),
                        ],
                      ),
                color: _saving ? Colors.grey : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _saving
                    ? null
                    : [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'حفظ الإعدادات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
