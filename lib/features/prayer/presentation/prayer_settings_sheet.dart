import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/adhan_service.dart';
import '../../../core/services/adhan_settings_service.dart';
import '../../../core/services/home_widget_service.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/icon_badge.dart';
import '../../../shared/widgets/section_header.dart';
import 'widgets/prayer_adhan_section.dart';
import 'widgets/prayer_adjustments_section.dart';
import 'widgets/prayer_calc_section.dart';
import 'widgets/prayer_muezzin_selector.dart';

class PrayerSettingsSheet extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const PrayerSettingsSheet({super.key, this.onSettingsChanged});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSettingsChanged,
  }) {
    AppSnackbar.dismiss();
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.92,
      builder: (_) => PrayerSettingsSheet(onSettingsChanged: onSettingsChanged),
    );
  }

  @override
  State<PrayerSettingsSheet> createState() => _PrayerSettingsSheetState();
}

class _PrayerSettingsSheetState extends State<PrayerSettingsSheet>
    with SingleTickerProviderStateMixin {
  final AdhanSettingsService _settingsService = AdhanSettingsService();
  final AdhanService _adhanService = AdhanService();

  late final TabController _tabController;
  AdhanSettings? _settings;
  WidgetThemeMode _widgetThemeMode = WidgetThemeMode.dark;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
    _adhanService.preload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adhanService.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _settingsService.getSettings();
    final mode = await HomeWidgetService.getThemeMode();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _widgetThemeMode = mode;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_settings == null || _saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    try {
      await _settingsService.saveSettings(_settings!);
      PrayerTimeService.clearCache();
      widget.onSettingsChanged?.call();

      // Refresh schedule in background without blocking sheet dismissal
      unawaited(
        PrayerScheduleService()
            .refreshSchedulesIfNeeded(force: true)
            .catchError((_) => const ScheduleBatchResult()),
      );
    } catch (_) {
      // Graceful fallback
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
        AppSnackbar.success(
          context,
          'تم حفظ إعدادات الصلاة والأذان بنجاح',
          duration: AppMotion.toastShort,
          hasNavBar: true,
        );
      }
    }
  }

  void _updateSettings(AdhanSettings newSettings) {
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (_loading || _settings == null) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        padding: const EdgeInsetsDirectional.all(AppSpace.xl),
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
              height: 140,
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
        borderRadius: AppRadius.sheetTopRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsetsDirectional.only(top: AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),

          // Header
          _buildHeader(context),
          Divider(height: 1, color: palette.border),

          // Segmented Tab Navigation (Solves the "too long & charged" issue)
          Container(
            margin: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              dividerHeight: 0.0,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              labelColor: palette.onPrimarySoft,
              unselectedLabelColor: palette.textMuted,
              labelStyle: textTheme.label.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: textTheme.label,
              padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.record_voice_over_rounded, size: AppIcon.sm),
                      SizedBox(width: AppSpace.xs),
                      Text('المؤذن والأصوات'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active_rounded, size: AppIcon.sm),
                      SizedBox(width: AppSpace.xs),
                      Text('التنبيهات والأذان'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: AppIcon.sm),
                      SizedBox(width: AppSpace.xs),
                      Text('الحساب والضبط'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.widgets_rounded, size: AppIcon.sm),
                      SizedBox(width: AppSpace.xs),
                      Text('أداة الشاشة'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Views per Tab
          Flexible(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                // Tab 0: Muezzin & Voices (Directly answers user request)
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                  child: PrayerMuezzinSelector(
                    settings: settings,
                    adhanService: _adhanService,
                    onSettingsChanged: _updateSettings,
                  ),
                ),

                // Tab 1: Notifications & Modes
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                  child: PrayerAdhanSection(
                    settings: settings,
                    isDark: isDark,
                    adhanService: _adhanService,
                    onSettingsChanged: _updateSettings,
                    onOpenVoicesTab: () => _tabController.animateTo(0),
                  ),
                ),

                // Tab 2: Calculation & Fine-tuning
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PrayerCalcSection(
                        settings: settings,
                        isDark: isDark,
                        onSettingsChanged: _updateSettings,
                      ),
                      const SizedBox(height: AppSpace.md),
                      PrayerAdjustmentsSection(
                        settings: settings,
                        isDark: isDark,
                        onSettingsChanged: _updateSettings,
                      ),
                    ],
                  ),
                ),

                // Tab 3: Home Screen Widget Theme
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                  child: _buildWidgetThemeSection(),
                ),
              ],
            ),
          ),

          // Sticky Save Button
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'أصوات المؤذنين، نمط التنبيهات، وضبط المواقيت',
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

  Widget _buildWidgetThemeSection() {
    final palette = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'مظهر أداة الشاشة الرئيسية',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'اختر مظهر بطاقة الصلاة على شاشة هاتفك (داكن موفر للبطارية أو ناصع البياض)',
            style: context.text.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          _buildWidgetThemeOption(
            title: 'داكن (أسود فاخر)',
            subtitle: 'بطاقة سوداء أنيقة وموفرة لاستهلاك شاشات AMOLED',
            icon: Icons.dark_mode_rounded,
            mode: WidgetThemeMode.dark,
          ),
          const SizedBox(height: AppSpace.sm),
          _buildWidgetThemeOption(
            title: 'فاتح (أبيض ناصع)',
            subtitle: 'بطاقة بيضاء ناصعة بتصميم عصري وأنيق',
            icon: Icons.light_mode_rounded,
            mode: WidgetThemeMode.light,
          ),
          const SizedBox(height: AppSpace.sm),
          _buildWidgetThemeOption(
            title: 'تلقائي (حسب النظام)',
            subtitle: 'يتغير المظهر تلقائياً وفق وضع الهاتف النهاري والليلي',
            icon: Icons.brightness_auto_rounded,
            mode: WidgetThemeMode.auto,
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required WidgetThemeMode mode,
  }) {
    final palette = context.palette;
    final isSelected = _widgetThemeMode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.selectionClick();
          setState(() => _widgetThemeMode = mode);
          await HomeWidgetService.setThemeMode(mode);
        },
        borderRadius: AppRadius.mdRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? palette.primarySoft : palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: isSelected ? palette.primary : palette.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? palette.primary : palette.textMuted,
                  size: AppIcon.md,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: context.text.bodyHeavy.copyWith(
                          color: isSelected ? palette.primary : palette.text,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: palette.primary,
                    size: AppIcon.sm,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border(
          top: BorderSide(color: palette.border),
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
