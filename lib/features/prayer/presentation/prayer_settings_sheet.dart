import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
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
    setState(() => _saving = true);

    await _settingsService.saveSettings(_settings!);
    widget.onSettingsChanged?.call();

    if (!mounted) return;

    // Success feedback
    // Success feedback
    AppSnackbar.success(context, 'تم حفظ الإعدادات');

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
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          const Divider(height: 1),

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
                  const SizedBox(height: 20),
                  _buildAdhanSection(settings, isDark),
                  const SizedBox(height: 20),
                  _buildNotificationsSection(settings, isDark),
                  const SizedBox(height: 20),
                  _buildAdjustmentsSection(settings, isDark),
                  const SizedBox(height: 24),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF6A9A9A), const Color(0xFF8ACACA)]
                    : [const Color(0xFF6A9A9A), const Color(0xFF7AB5A8)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mosque_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'إعدادات الصلاة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF5F3F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE8E6E3),
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
            color: const Color(0xFF6A9A9A).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6A9A9A)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
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
                    _updateSettings(
                      settings.copyWith(calculationMethod: entry.key),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF6A9A9A), Color(0xFF7AB5A8)],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? const Color(0xFF0A0A0A) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                  ? const Color(0xFF1F1F1F)
                                  : const Color(0xFFE8E6E3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black54),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: settings.enabled,
                  onChanged: (val) {
                    _updateSettings(settings.copyWith(enabled: val));
                  },
                  activeThumbColor: const Color(0xFF6A9A9A),
                  activeTrackColor: const Color(
                    0xFF6A9A9A,
                  ).withValues(alpha: 0.5),
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
                color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1F1F1F)
                      : const Color(0xFFE8E6E3),
                ),
              ),
              child: DropdownButtonFormField<AdhanSound>(
                initialValue: settings.sound,
                decoration: const InputDecoration(
                  labelText: 'المؤذن',
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
                        fontSize: 14,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${settings.volume.toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A9A9A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.volume_mute,
                      size: 18,
                      color: Color(0xFF6A9A9A),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF6A9A9A),
                          inactiveTrackColor: const Color(
                            0xFF6A9A9A,
                          ).withValues(alpha: 0.2),
                          thumbColor: const Color(0xFF6A9A9A),
                          overlayColor: const Color(
                            0xFF6A9A9A,
                          ).withValues(alpha: 0.2),
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
                    const Icon(
                      Icons.volume_up,
                      size: 18,
                      color: Color(0xFF6A9A9A),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Test button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await _adhanService.test(
                    settings.sound,
                    volume: settings.volume,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A9A9A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6A9A9A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: Color(0xFF6A9A9A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تجربة الصوت',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6A9A9A),
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
                    'التنبيه قبل الصلاة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${settings.notifyBeforeMinutes.toInt()} دقيقة',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFCAAF7C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFCAAF7C),
                  inactiveTrackColor: const Color(
                    0xFFCAAF7C,
                  ).withValues(alpha: 0.2),
                  thumbColor: const Color(0xFFCAAF7C),
                  overlayColor: const Color(0xFFCAAF7C).withValues(alpha: 0.2),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: settings.iqamaReminders,
                  onChanged: (val) {
                    _updateSettings(settings.copyWith(iqamaReminders: val));
                  },
                  activeThumbColor: const Color(0xFFCAAF7C),
                  activeTrackColor: const Color(
                    0xFFCAAF7C,
                  ).withValues(alpha: 0.5),
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
            'تعديل بالدقيقة (+ أو -)',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1F1F1F)
                            : const Color(0xFFE8E6E3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAdjustButton(
                          icon: Icons.remove,
                          onPressed: () {
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: adj == 0
                                  ? (isDark ? Colors.white54 : Colors.black54)
                                  : const Color(0xFF6A9A9A),
                            ),
                          ),
                        ),
                        _buildAdjustButton(
                          icon: Icons.add,
                          onPressed: () {
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
          child: Icon(icon, size: 18, color: const Color(0xFF6A9A9A)),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE8E6E3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _saving ? null : _save,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: _saving
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF6A9A9A), Color(0xFF7AB5A8)],
                      ),
                color: _saving ? Colors.grey : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _saving
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF6A9A9A).withValues(alpha: 0.3),
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
