import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/models/quran_models.dart';
import 'package:talib_ilm/features/quran/data/services/quran_pack_install_service.dart';
import 'package:talib_ilm/features/quran/presentation/quran_riwayah_downloads_page.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/quran_riwayah_card.dart';

Widget _buildTestApp({
  required Widget child,
  double textScaleFactor = 1.0,
  Size size = const Size(390, 2000),
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScaleFactor),
          size: size,
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'quran_current_edition': 'hafs',
      'quran_installed_packs_v1': ['hafs'],
    });
    tempDirectory = await Directory.systemTemp.createTemp(
      'quran_riwayah_page_test_',
    );
    QuranPackInstallService.resetForTesting();
    QuranPackInstallService.testBaseDir = tempDirectory;
  });

  tearDown(() async {
    QuranPackInstallService.resetForTesting();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('QuranRiwayahDownloadsPage and QuranRiwayahCard UI/UX', () {
    testWidgets('renders elevated scholarly header, riwayat list and authenticity footnote', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(_buildTestApp(child: const QuranRiwayahDownloadsPage()));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      // AppBar title
      expect(find.text('روايات المصحف الشريف'), findsOneWidget);

      // Scholarly Header
      expect(find.text('الروايات القرآنية المتواترة'), findsOneWidget);
      expect(find.textContaining('القراءات العشر المتواترة'), findsOneWidget);
      expect(find.textContaining('الرواية النشطة'), findsWidgets);
      expect(find.textContaining('المثبتة'), findsOneWidget);
      expect(find.textContaining('المساحة المستخدمة'), findsOneWidget);

      // Three canonical editions
      expect(find.text('حفص عن عاصم'), findsWidgets);
      expect(find.text('ورش عن نافع'), findsOneWidget);
      expect(find.text('قالون عن نافع'), findsOneWidget);

      // Sacred emblem letters
      expect(find.text('ح'), findsOneWidget);
      expect(find.text('و'), findsOneWidget);
      expect(find.text('ق'), findsOneWidget);

      // Scholarly transmission metadata
      expect(find.text('طريق الشاطبية'), findsOneWidget);
      expect(find.text('طريق أبي يعقوب الأزرق'), findsOneWidget);
      expect(find.text('طريق أبي نشيط المروزي'), findsOneWidget);

      // Verse count conventions
      expect(find.text('العد الكوفي (6236 آية)'), findsOneWidget);
      expect(find.text('العد المدني الأخير (6214 آية)'), findsOneWidget);
      expect(find.text('العد المدني الأول (6214 آية)'), findsOneWidget);

      // Authenticity footnote
      expect(find.text('التوثيق الرقمي والرسم العثماني'), findsOneWidget);
      expect(find.textContaining('مجمع الملك فهد لطباعة المصحف الشريف'), findsOneWidget);
    });

    testWidgets('QuranRiwayahCard adapts gracefully to large text scaling (1.5x and 2.0x) without overflow', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          _buildTestApp(
            textScaleFactor: scale,
            child: Scaffold(
              body: SingleChildScrollView(
                child: QuranRiwayahCard(
                  edition: QuranRiwayahId.warsh,
                  isCurrent: false,
                  isInstalled: false,
                  storageBytes: 0,
                  progress: null,
                  isDownloading: false,
                  onUse: () {},
                  onDownload: () {},
                  onCancel: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ورش عن نافع'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('QuranRiwayahCard displays downloading progress bar and cancel button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: QuranRiwayahCard(
              edition: QuranRiwayahId.warsh,
              isCurrent: false,
              isInstalled: false,
              storageBytes: 0,
              progress: const QuranPackInstallProgress(
                QuranRiwayahId.warsh,
                0.65,
                'جارٍ تنزيل ملف الخط',
              ),
              isDownloading: true,
              onUse: () {},
              onDownload: () {},
              onCancel: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('جارٍ التنزيل'), findsWidgets);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('جارٍ تنزيل ملف الخط'), findsOneWidget);
      expect(find.text('إلغاء التنزيل'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog when deleting installed edition', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: QuranRiwayahCard(
              edition: QuranRiwayahId.warsh,
              isCurrent: false,
              isInstalled: true,
              storageBytes: 3000000,
              progress: null,
              isDownloading: false,
              onUse: () {},
              onDownload: () {},
              onCancel: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('جاهزة للقراءة'), findsOneWidget);
      expect(find.text('تفعيل وقراءة الرواية'), findsOneWidget);
      expect(find.byTooltip('حذف الرواية من الجهاز'), findsOneWidget);
    });
  });
}

