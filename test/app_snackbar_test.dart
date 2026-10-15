import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';

void main() {
  group('AppSnackbar HUD Tests', () {
    Widget buildTestHarness({required Widget child}) {
      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('displays snackbar message and updates in-place without duplicate entries',
        (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        buildTestHarness(
          child: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Trigger first toast (e.g. from athan option)
      AppSnackbar.success(testContext, 'الظهر: تم ضبط التنبيه إلى (أذان كامل)');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('الظهر: تم ضبط التنبيه إلى (أذان كامل)'), findsOneWidget);

      // Trigger second toast immediately (e.g. switching to nidaa)
      AppSnackbar.success(testContext, 'الظهر: تم ضبط التنبيه إلى (نداء وقت الصلاة)');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Should seamlessly update in-place without stacking or duplicating
      expect(find.text('الظهر: تم ضبط التنبيه إلى (نداء وقت الصلاة)'), findsOneWidget);
      expect(find.text('الظهر: تم ضبط التنبيه إلى (أذان كامل)'), findsNothing);

      // Dismiss programmatically
      AppSnackbar.dismiss();
      await tester.pump();

      expect(find.text('الظهر: تم ضبط التنبيه إلى (نداء وقت الصلاة)'), findsNothing);
    });

    testWidgets('dismiss removes toast and handles subsequent shows safely',
        (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        buildTestHarness(
          child: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      AppSnackbar.info(testContext, 'رسالة تجريبية');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('رسالة تجريبية'), findsOneWidget);

      AppSnackbar.dismiss();
      await tester.pump();
      expect(find.text('رسالة تجريبية'), findsNothing);

      // Can show again without errors
      AppSnackbar.error(testContext, 'خطأ تجريبي');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('خطأ تجريبي'), findsOneWidget);

      AppSnackbar.dismiss();
      await tester.pump();
    });
  });
}
