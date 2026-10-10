import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/adhan_service.dart';
import '../../../core/services/adhan_settings_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/icon_badge.dart';
import '../../../shared/widgets/section_header.dart';
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
    final palette = context.palette;

    if (_loading || _settings == null) {
      return Container(
        height: 300,
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
              height: 120,
              borderRadius: AppRadius.lgRadius,
            ),
          ],
        ),
      );
    }

    final settings = _settings!;
    final isDark = palette.isDark;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(
          color: palette.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),

          // Header
          _buildHeader(context),
          Divider(height: 1, color: palette.border),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PrayerCalcSection(
                    settings: settings,
                    isDark: isDark,
                    onSettingsChanged: _updateSettings,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  PrayerAdhanSection(
                    settings: settings,
                    isDark: isDark,
                    adhanService: _adhanService,
                    onSettingsChanged: _updateSettings,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _buildNotificationsSection(settings),
                  const SizedBox(height: AppSpace.lg),
                  PrayerAdjustmentsSection(
                    settings: settings,
                    isDark: isDark,
                    onSettingsChanged: _updateSettings,
                  ),
                ],
              ),
            ),
          ),

          // Save button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.xl,
        AppSpace.md,
        AppSpace.xl,
        AppSpace.md,
      ),
      child: Row(
        children: [
          const IconBadge(icon: Icons.mosque_rounded),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات الصلاة والأذان',
                  style: context.text.titleSmall.copyWith(
                    color: palette.text,
                  ),
                ),
                Text(
                  'تخصيص الحساب والمؤذن والتنبيهات',
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
    );
  }

  Widget _buildNotificationsSection(AdhanSettings settings) {
    final palette = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'التنبيهات',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpace.md),

          // Notify before slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'التنبيه قبل دخول الوقت',
                    style: context.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  Text(
                    '${settings.notifyBeforeMinutes.toInt()} دقيقة',
                    style: context.text.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: palette.primary,
                  inactiveTrackColor: palette.border,
                  thumbColor: palette.primary,
                  overlayColor: palette.primarySoft,
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

          const SizedBox(height: AppSpace.md),

          // Iqama toggle
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'تذكير الإقامة',
                    style: context.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
                Switch(
                  value: settings.iqamaReminders,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    _updateSettings(settings.copyWith(iqamaReminders: val));
                  },
                  activeThumbColor: palette.primary,
                  activeTrackColor: palette.primarySoft,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: palette.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: 'حفظ الإعدادات',
          width: double.infinity,
          isLoading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}
