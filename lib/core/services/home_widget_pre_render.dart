import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/widget_large.dart';
import '../../features/prayer/presentation/widgets/widget_ribbon.dart';

/// Daily cache-key tracking for native Android & iOS widgets.
///
/// Both Android (`RemoteViews` XML + `WidgetChronometerHelper.kt`) and iOS
/// (`TalibIlmWidgets.swift` + `TalibIlmWidgetViews.swift`) evaluate all 5
/// daily prayer transitions natively from the persisted schedule timestamps,
/// so offscreen bitmap pre-rendering is no longer needed.
class HomeWidgetPreRender {
  const HomeWidgetPreRender._();

  static String? _lastDailyRibbonRenderKey;
  static String? _lastDailyLargeRenderKey;

  /// Invalidates cached daily prayer state keys.
  static void invalidateDailyCache() {
    _lastDailyRibbonRenderKey = null;
    _lastDailyLargeRenderKey = null;
  }

  static Future<void> preRenderDailyRibbonSnapshots({
    required PrayerTimesDay day,
    required bool useDark,
    required String hijriDate,
    bool force = false,
    double? width,
    double? height,
  }) async {
    final effectiveW = width ?? kRibbonW;
    final effectiveH = height ?? kRibbonH;
    final dailyKey =
        '${day.city}_${day.date.year}-${day.date.month}-${day.date.day}_${useDark}_${effectiveW.toInt()}x${effectiveH.toInt()}';
    if (!force && dailyKey == _lastDailyRibbonRenderKey) return;
    _lastDailyRibbonRenderKey = dailyKey;
  }

  static Future<void> preRenderDailyLargeSnapshots({
    required PrayerTimesDay day,
    required bool useDark,
    required String hijriDate,
    bool force = false,
    double? width,
    double? height,
  }) async {
    final effectiveW = width ?? kLargeW;
    final effectiveH = height ?? kLargeH;
    final dailyKey =
        '${day.city}_${day.date.year}-${day.date.month}-${day.date.day}_${useDark}_${effectiveW.toInt()}x${effectiveH.toInt()}';
    if (!force && dailyKey == _lastDailyLargeRenderKey) return;
    _lastDailyLargeRenderKey = dailyKey;
  }
}
