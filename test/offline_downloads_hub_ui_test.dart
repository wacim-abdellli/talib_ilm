import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/offline_connectivity_service.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/offline_books_tab_view.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/offline_downloads_hub_sheet.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/offline_status_banner.dart';

Widget _wrapRtl(Widget child, {double textScale = 1.0, bool isDark = false}) {
  return MaterialApp(
    theme: isDark ? AppTheme.dark() : AppTheme.light(),
    builder: (context, inner) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: inner ?? const SizedBox.shrink(),
        ),
      );
    },
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    OfflineConnectivityService.setOverrideForTesting(null);
  });

  tearDown(() {
    OfflineConnectivityService.setOverrideForTesting(null);
  });

  group('Offline Connectivity & Banner Tests', () {
    test('OfflineConnectivityService updates and notifies listeners', () {
      final service = OfflineConnectivityService();
      expect(service.isOffline, isFalse);

      OfflineConnectivityService.setOverrideForTesting(true);
      expect(service.isOffline, isTrue);

      OfflineConnectivityService.setOverrideForTesting(false);
      expect(service.isOffline, isFalse);
    });

    testWidgets('OfflineStatusBanner hides when online and displays when offline', (tester) async {
      bool hubOpened = false;

      await tester.pumpWidget(
        _wrapRtl(
          OfflineStatusBanner(
            onOpenDownloadsHub: () => hubOpened = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Online: banner is hidden
      expect(find.text('وضع عدم الاتصال بالإنترنت'), findsNothing);

      // Trigger offline state
      OfflineConnectivityService.setOverrideForTesting(true);
      await tester.pumpAndSettle();

      // Offline: banner appears
      expect(find.text('وضع عدم الاتصال بالإنترنت'), findsOneWidget);
      expect(find.text('تصفح كتبك وسورك الصوتية المحمّلة'), findsOneWidget);

      // Tapping المحملات triggers callback
      await tester.tap(find.text('المحملات'));
      await tester.pumpAndSettle();
      expect(hubOpened, isTrue);

      // Tapping close dismisses banner
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('وضع عدم الاتصال بالإنترنت'), findsNothing);
    });
  });

  group('Offline Books & Hub Sheet Scaling Tests', () {
    final mockBook = ShamelaBook(
      id: 20854,
      title: 'معارج القبول بشرح سلم الوصول',
      author: 'حافظ الحكمي',
      category: 'العقيدة',
      categoryId: 1,
      totalPages: 1200,
    );

    final mockMutn = IlmBook(
      id: 'bk_usul_thalatha',
      title: 'الأصول الثلاثة وأدلتها',
      author: 'محمد بن عبد الوهاب',
      level: 'المستوى الأول',
      subject: 'العقيدة',
      description: 'أصل جامع في التوحيد',
      totalPages: 15,
      shuruh: const [],
    );

    testWidgets('OfflineBooksTabView renders books without overflow at 1.0x', (tester) async {
      await tester.pumpWidget(
        _wrapRtl(
          OfflineBooksTabView(
            downloadedBooks: [mockBook],
            bundledMutun: [mockMutn],
            progressById: const {},
            onOpenShamelaBook: (_) {},
            onOpenMutunBook: (_) {},
          ),
          textScale: 1.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('معارج القبول بشرح سلم الوصول'), findsOneWidget);
      expect(find.text('جاهز للقراءة بدون إنترنت'), findsOneWidget);
      expect(find.text('الأصول الثلاثة وأدلتها'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OfflineBooksTabView survives 1.5x scaling without overflow', (tester) async {
      await tester.pumpWidget(
        _wrapRtl(
          OfflineBooksTabView(
            downloadedBooks: [mockBook],
            bundledMutun: [mockMutn],
            progressById: const {},
            onOpenShamelaBook: (_) {},
            onOpenMutunBook: (_) {},
          ),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('OfflineBooksTabView survives 2.0x scaling without overflow', (tester) async {
      await tester.pumpWidget(
        _wrapRtl(
          OfflineBooksTabView(
            downloadedBooks: [mockBook],
            bundledMutun: [mockMutn],
            progressById: const {},
            onOpenShamelaBook: (_) {},
            onOpenMutunBook: (_) {},
          ),
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('OfflineDownloadsHubSheet shows title and tabs cleanly', (tester) async {
      await tester.pumpWidget(
        _wrapRtl(
          OfflineDownloadsHubSheet(
            onOpenShamelaBook: (_) {},
            onOpenMutunBook: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('حقيبة المحتوى بدون إنترنت'), findsOneWidget);
      expect(find.text('سور القرآن الصوتية'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
