import 'package:home_widget/home_widget.dart';
import 'home_widget_service.dart';

/// Top-level background callback invoked when the home widget is resized or interacted with.
@pragma('vm:entry-point')
Future<void> prayerWidgetBackgroundCallback(Uri? uri) async {
  if (uri?.host == 'refresh' || uri?.host == 'rollover') {
    HomeWidgetService.invalidateCache();
    await HomeWidgetService.updateAllWidgets(force: true);
    return;
  }
  if (uri?.host == 'resize') {
    final wStr = uri?.queryParameters['minWidth'];
    final hStr = uri?.queryParameters['minHeight'];
    final provider = uri?.queryParameters['provider']?.toLowerCase() ?? '';
    final w = int.tryParse(wStr ?? '');
    final h = int.tryParse(hStr ?? '');
    if (w != null && h != null && w > 0 && h > 0) {
      await HomeWidget.saveWidgetData<int>('widget_width', w);
      await HomeWidget.saveWidgetData<int>('widget_height', h);

      if (provider.contains('large')) {
        await HomeWidget.saveWidgetData<int>('large_widget_width', w);
        await HomeWidget.saveWidgetData<int>('large_widget_height', h);
        await HomeWidget.saveWidgetData<int>('widget_large_width', w);
        await HomeWidget.saveWidgetData<int>('widget_large_height', h);
        HomeWidgetService.invalidateCache();
        await HomeWidgetService.updateLarge(force: true);
      } else if (provider.contains('ribbon')) {
        await HomeWidget.saveWidgetData<int>('ribbon_widget_width', w);
        await HomeWidget.saveWidgetData<int>('ribbon_widget_height', h);
        await HomeWidget.saveWidgetData<int>('widget_ribbon_width', w);
        await HomeWidget.saveWidgetData<int>('widget_ribbon_height', h);
        HomeWidgetService.invalidateCache();
        await HomeWidgetService.updateRibbon(force: true);
      } else if (provider.contains('standard')) {
        await HomeWidget.saveWidgetData<int>('standard_widget_width', w);
        await HomeWidget.saveWidgetData<int>('standard_widget_height', h);
        await HomeWidget.saveWidgetData<int>('widget_standard_width', w);
        await HomeWidget.saveWidgetData<int>('widget_standard_height', h);
        HomeWidgetService.invalidateCache();
        await HomeWidgetService.updateStandard(force: true);
      } else if (provider.contains('compact')) {
        await HomeWidget.saveWidgetData<int>('compact_widget_width', w);
        await HomeWidget.saveWidgetData<int>('compact_widget_height', h);
        await HomeWidget.saveWidgetData<int>('widget_compact_width', w);
        await HomeWidget.saveWidgetData<int>('widget_compact_height', h);
        HomeWidgetService.invalidateCache();
        await HomeWidgetService.updateCompact(force: true);
      } else {
        HomeWidgetService.invalidateCache();
        await HomeWidgetService.updateAllWidgets(force: true);
      }
    }
  }
}
