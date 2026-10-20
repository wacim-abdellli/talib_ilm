import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_book_preview_row.dart';

void main() {
  Widget buildTestableWidget(Widget child, {double textScale = 1.0}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    );
  }

  group('IlmBookPreviewRow Tests', () {
    testWidgets('renders title, subtitle, and fires onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          IlmBookPreviewRow(
            title: 'كتاب التوحيد الذي هو حق الله على العبيد',
            subtitle: 'الشيخ محمد بن عبد الوهاب • 192 ص',
            accentColor: const Color(0xFF0D9488),
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('كتاب التوحيد الذي هو حق الله على العبيد'), findsOneWidget);
      expect(find.text('الشيخ محمد بن عبد الوهاب • 192 ص'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      await tester.tap(find.byType(IlmBookPreviewRow));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders checkmark when isCompleted is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          IlmBookPreviewRow(
            title: 'الأصول الثلاثة وأدلتها',
            subtitle: 'الشيخ محمد بن عبد الوهاب • مكتمل',
            accentColor: const Color(0xFF0D9488),
            isCompleted: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets('survives text scales 1.0, 1.5, 2.0 without overflow', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          buildTestableWidget(
            IlmBookPreviewRow(
              title: 'كتاب الأربعين النووية في الأحاديث الصحيحة النبوية مع زيادات ابن رجب الحنبلي',
              subtitle: 'الإمام يحيى بن شرف النووي الدمشقي • 120 ص',
              accentColor: const Color(0xFF0D9488),
              onTap: () {},
            ),
            textScale: scale,
          ),
        );

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('renders author and distinct progressBadge pill', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          IlmBookPreviewRow(
            title: 'نواقض الإسلام',
            subtitle: 'محمد بن عبد الوهاب • صفحة 2 من 2',
            author: 'محمد بن عبد الوهاب',
            progressBadge: 'صفحة 2 من 2',
            accentColor: const Color(0xFF0D9488),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('نواقض الإسلام'), findsOneWidget);
      expect(find.text('محمد بن عبد الوهاب'), findsOneWidget);
      expect(find.text('صفحة 2 من 2'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
    });

    testWidgets('renders completed badge with checkmark inside badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          IlmBookPreviewRow(
            title: 'نواقض الإسلام',
            subtitle: 'محمد بن عبد الوهاب • مكتمل',
            author: 'محمد بن عبد الوهاب',
            progressBadge: 'مكتمل',
            accentColor: const Color(0xFF0D9488),
            isCompleted: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('نواقض الإسلام'), findsOneWidget);
      expect(find.text('محمد بن عبد الوهاب'), findsOneWidget);
      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2)); // in badge and trailing
    });
  });

  group('IlmViewAllRow Tests', () {
    testWidgets('renders label and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          IlmViewAllRow(
            label: 'عرض جميع الكتب (18)',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('عرض جميع الكتب (18)'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      await tester.tap(find.byType(IlmViewAllRow));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
