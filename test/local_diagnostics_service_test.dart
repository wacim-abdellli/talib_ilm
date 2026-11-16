import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/local_diagnostics_service.dart';
import 'package:talib_ilm/core/services/offline_connectivity_service.dart';
import 'package:talib_ilm/features/more/presentation/widgets/diagnostics_report_sheet.dart';
import 'package:talib_ilm/shared/widgets/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalDiagnosticsService().resetForTesting();
    OfflineConnectivityService.setOverrideForTesting(false);
  });

  tearDown(() {
    OfflineConnectivityService.setOverrideForTesting(null);
  });

  group('LocalDiagnosticsService & DiagnosticsReportSheet', () {
    test('Maintains bounded ring buffer of maxEntries and scrubs GPS coordinates', () async {
      final diag = LocalDiagnosticsService();

      for (int i = 0; i < LocalDiagnosticsService.maxEntries + 15; i++) {
        diag.record(
          category: 'test_cat',
          severity: 'info',
          message: 'Event #$i at latitude=34.7406 longitude=10.7603',
        );
      }

      expect(diag.recentEvents.length, LocalDiagnosticsService.maxEntries);
      expect(diag.recentEvents.first.message, contains('Event #94'));
      expect(diag.recentEvents.first.message, isNot(contains('34.7406')));
      expect(diag.recentEvents.first.message, contains('latitude=[redacted]'));

      diag.record(
        category: 'flutter_error',
        severity: 'error',
        message: 'Sample UI error',
        stackTrace: StackTrace.current,
      );
      await Future<void>.delayed(Duration.zero);

      final report = diag.buildShareableReport();
      expect(report, contains('Sample UI error'));
      expect(report, contains('[error/flutter_error]'));
    });

    testWidgets('DiagnosticsReportSheet renders events, copies report, clears, and survives 2.0x text scale', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      LocalDiagnosticsService().record(
        category: 'audio',
        severity: 'warn',
        message: 'Simulated fallback test event',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: const Scaffold(
              body: DiagnosticsReportSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('التشخيص والدعم الفني'), findsOneWidget);
      expect(find.textContaining('Simulated fallback test event'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'نسخ التقرير'));
      await tester.pumpAndSettle();
      expect(copiedText, contains('Simulated fallback test event'));

      await tester.tap(find.widgetWithText(AppButton, 'مسح السجل'));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد أعطال مسجلة'), findsOneWidget);
    });
  });
}
