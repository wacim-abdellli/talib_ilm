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
    final provider = uri?.queryParameters['provider'];
    final w = int.tryParse(wStr ?? '');
    final h = int.tryParse(hStr ?? '');
    if (w != null && h != null) {
      if (provider == 'large') {
        await HomeWidget.saveWidgetData<int>('widget_large_width', w);
        await HomeWidget.saveWidgetData<int>('widget_large_height', h);
        HomeWidgetService.invalidateCache();
        await HomeWidgetService.updateLarge(force: true);
      } else if (provider == 'ribbon') {
        await HomeWidget.saveWidgetData<int>('widget_ribbon_width', w);
        await HomeWidget.saveWidgetData<int>('widget_ribbon_height', h);
        HomeWidgetService.invalidateCache();
        await HomeWidgetService.updateRibbon(force: true);
      } else {
        await HomeWidget.saveWidgetData<int>('widget_width', w);
        await HomeWidget.saveWidgetData<int>('widget_height', h);
        HomeWidgetService.invalidateCache();
        await HomeWidgetService.updatePrayerWidget(force: true);
      }
    }
  }
}
