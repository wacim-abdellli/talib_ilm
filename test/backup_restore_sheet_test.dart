import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/more/presentation/widgets/backup_restore_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createSheetWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: BackupRestoreSheet(),
      ),
    );
  }

  group('BackupRestoreSheet Lifecycle and Interaction Tests (C29)', () {
    testWidgets('renders export and import action cards', (tester) async {
      await tester.pumpWidget(createSheetWidget());
      await tester.pumpAndSettle();

      expect(find.text('النسخ الاحتياطي والاستعادة'), findsOneWidget);
      expect(find.text('تصدير نسخة احتياطية (JSON)'), findsOneWidget);
      expect(find.text('استيراد من ملف خارجي'), findsOneWidget);
      expect(find.byTooltip('إغلاق'), findsOneWidget);
    });

    testWidgets('dismisses sheet when close button is tapped', (tester) async {
      bool sheetDismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const BackupRestoreSheet(),
                  );
                  sheetDismissed = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(BackupRestoreSheet), findsOneWidget);

      await tester.tap(find.byTooltip('إغلاق'));
      await tester.pumpAndSettle();

      expect(find.byType(BackupRestoreSheet), findsNothing);
      expect(sheetDismissed, isTrue);
    });

    testWidgets('widget survives rapid disposal during sheet dismissal', (tester) async {
      await tester.pumpWidget(createSheetWidget());
      await tester.pumpAndSettle();

      // Dispose the widget tree while state might be active
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(find.byType(BackupRestoreSheet), findsNothing);
    });
  });
}
