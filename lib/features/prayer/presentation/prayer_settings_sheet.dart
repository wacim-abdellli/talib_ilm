import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/theme_colors.dart';
import '../../../core/services/adhan_service.dart';
import '../../../core/services/adhan_settings_service.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_states.dart';

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
                  _buildCalcMethodSection(settings, isDark),
                  const SizedBox(height: 18),
                  _buildAdhanSection(settings, isDark),
                  const SizedBox(height: 18),
                  _buildNotificationsSection(settings, isDark),
                  const SizedBox(height: 18),
                  _buildAdjustmentsSection(settings, isDark),
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

  Widget _buildCalcMethodSection(AdhanSettings settings, bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('طريقة الحساب', Icons.calculate_outlined, isDark),
          const SizedBox(height: 16),
          ...AdhanSettingsService.calculationMethods.entries.map((entry) {
            final isSelected = settings.calculationMethod == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _updateSettings(
                      settings.copyWith(calculationMethod: entry.key),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                context.primaryColor,
                                context.primaryColor.withValues(alpha: 0.85),
                              ],
                            )
                          : null,
                      color: isSelected ? null : context.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? context.primaryColor
                            : context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? Colors.white
                              : context.textSecondaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : context.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdhanSection(AdhanSettings settings, bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'الأذان والصوت',
            Icons.volume_up_outlined,
            isDark,
          ),
          const SizedBox(height: 16),

          // Enable toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  'تشغيل صوت الأذان',
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
                  value: settings.enabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    _updateSettings(settings.copyWith(enabled: val));
                  },
                  activeThumbColor: context.primaryColor,
                  activeTrackColor: context.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          if (settings.enabled) ...[
            const SizedBox(height: 16),

            // Muezzin selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                ),
              ),
              child: DropdownButtonFormField<AdhanSound>(
                initialValue: settings.sound,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: context.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'صوت المؤذن',
                  labelStyle: TextStyle(
                    fontFamily: 'Cairo',
                    color: context.textSecondaryColor,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: const [
                  DropdownMenuItem(
                    value: AdhanSound.makkah,
                    child: Text('مكة المكرمة'),
                  ),
                  DropdownMenuItem(
                    value: AdhanSound.madinah,
                    child: Text('المدينة المنورة'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _updateSettings(settings.copyWith(sound: val));
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // Volume slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مستوى الصوت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    Text(
                      '${settings.volume.toInt()}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.volume_mute_rounded,
                      size: 20,
                      color: context.textSecondaryColor,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: context.primaryColor,
                          inactiveTrackColor: context.primaryColor.withValues(alpha: 0.2),
                          thumbColor: context.primaryColor,
                          overlayColor: context.primaryColor.withValues(alpha: 0.15),
                        ),
                        child: Slider(
                          value: settings.volume,
                          min: 0,
                          max: 100,
                          onChanged: (val) {
                            _updateSettings(settings.copyWith(volume: val));
                          },
                        ),
                      ),
                    ),
                    Icon(
                      Icons.volume_up_rounded,
                      size: 20,
                      color: context.primaryColor,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Test button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await _adhanService.test(
                    settings.sound,
                    volume: settings.volume,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline_rounded,
                        color: context.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تجربة صوت الأذان',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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

  Widget _buildAdjustmentsSection(AdhanSettings settings, bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('تعديل التوقيت', Icons.tune_outlined, isDark),
          const SizedBox(height: 4),
          Text(
            'تعديل التوقيت بالدقيقة (+ أو -)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...AdhanSettingsService.prayerNames.map((name) {
            final adj = settings.adjustments[name] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAdjustButton(
                          icon: Icons.remove_rounded,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            final updated = Map<String, int>.from(
                              settings.adjustments,
                            );
                            updated[name] = adj - 1;
                            _updateSettings(
                              settings.copyWith(adjustments: updated),
                            );
                          },
                        ),
                        Container(
                          width: 50,
                          alignment: Alignment.center,
                          child: Text(
                            adj > 0 ? '+$adj' : '$adj',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: adj == 0
                                  ? context.textSecondaryColor
                                  : context.primaryColor,
                            ),
                          ),
                        ),
                        _buildAdjustButton(
                          icon: Icons.add_rounded,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            final updated = Map<String, int>.from(
                              settings.adjustments,
                            );
                            updated[name] = adj + 1;
                            _updateSettings(
                              settings.copyWith(adjustments: updated),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: context.primaryColor),
        ),
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
