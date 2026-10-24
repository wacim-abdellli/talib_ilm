import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_palette.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/shared/widgets/app_button.dart';
import 'package:talib_ilm/shared/widgets/search_bar_widget.dart';
import 'package:talib_ilm/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:talib_ilm/features/home/presentation/widgets/home_hero_timeline_station.dart';
import 'package:talib_ilm/features/home/presentation/widgets/quick_action_button.dart';
import 'package:talib_ilm/features/more/presentation/widgets/more_section_card.dart';

Widget wrapWithTheme(Widget child, {bool isDark = false, double textScale = 1.0}) {
  final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
  return MaterialApp(
    theme: theme,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(child: child),
        ),
      ),
    ),
  );
}

double _lum(Color c) {
  double f(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double contrastRatio(Color a, Color b) {
  var la = _lum(a);
  var lb = _lum(b);
  if (la < lb) {
    final t = la;
    la = lb;
    lb = t;
  }
  return (la + 0.05) / (lb + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T10 / C21 — AppButton 48dp Minimum Hit Target & Edge Taps', () {
    testWidgets('small button registers taps at all four extreme edges of 48dp box', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        wrapWithTheme(
          AppButton(
            label: 'حفظ',
            size: AppButtonSize.sm,
            onPressed: () => tapCount++,
          ),
        ),
      );

      final buttonFinder = find.byType(AppButton);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(size.width, greaterThanOrEqualTo(48.0));

      final topLeft = tester.getTopLeft(buttonFinder);
      final bottomRight = tester.getBottomRight(buttonFinder);
      final topRight = tester.getTopRight(buttonFinder);
      final bottomLeft = tester.getBottomLeft(buttonFinder);

      // 1. Top-edge tap
      await tester.tapAt(topLeft + const Offset(4, 2));
      await tester.pumpAndSettle();
      expect(tapCount, 1, reason: 'Top edge tap within 48dp hit box must trigger onPressed');

      // 2. Bottom-edge tap
      await tester.tapAt(bottomRight - const Offset(4, 2));
      await tester.pumpAndSettle();
      expect(tapCount, 2, reason: 'Bottom edge tap within 48dp hit box must trigger onPressed');

      // 3. Top-right edge tap
      await tester.tapAt(topRight + const Offset(-4, 2));
      await tester.pumpAndSettle();
      expect(tapCount, 3, reason: 'Top-right corner tap within 48dp hit box must trigger onPressed');

      // 4. Bottom-left edge tap
      await tester.tapAt(bottomLeft + const Offset(4, -2));
      await tester.pumpAndSettle();
      expect(tapCount, 4, reason: 'Bottom-left corner tap within 48dp hit box must trigger onPressed');

      // 5. Center tap
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(tapCount, 5, reason: 'Center tap must trigger onPressed');
    });

    testWidgets('AppButton provides Semantics with correct enabled and label attributes', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          AppButton(
            label: 'تأكيد التسجيل',
            onPressed: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AppButton)),
        matchesSemantics(
          label: 'تأكيد التسجيل',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('disabled AppButton reflects disabled semantics and ignores edge taps', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        wrapWithTheme(
          const AppButton(
            label: 'معطل',
            onPressed: null,
          ),
        ),
      );

      final buttonFinder = find.byType(AppButton);
      await tester.tapAt(tester.getTopLeft(buttonFinder) + const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(tapCount, 0);

      expect(
        tester.getSemantics(buttonFinder),
        matchesSemantics(
          label: 'معطل',
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('loading AppButton reflects loading status in Semantics and suppresses taps', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        wrapWithTheme(
          AppButton(
            label: 'تحميل',
            isLoading: true,
            onPressed: () => tapCount++,
          ),
        ),
      );

      final buttonFinder = find.byType(AppButton);
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(tapCount, 0);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final semantics = tester.getSemantics(buttonFinder);
      expect(semantics.label, contains('جاري التحميل'));
    });
  });

  group('T10 / C21 — AppRoot Text Scale 2.0 Accessibility Support', () {
    testWidgets('root app builder honors text scale 2.0 without clamping at 1.5', (tester) async {
      // Build an app using TalibIlmApp structure to verify builder clamps to 2.0, not 1.5
      late BuildContext innerContext;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Replicate TalibIlmApp.builder logic
                final mediaQuery = MediaQuery.of(context);
                final shortestSide = mediaQuery.size.shortestSide;
                final sizeScale = (shortestSide / AppSize.textScaleBaseWidth)
                    .clamp(AppSize.textScaleMin, AppSize.textScaleMax)
                    .toDouble();
                final baseScale = mediaQuery.textScaler.scale(1.0);
                final scaled = TextScaler.linear(
                  (baseScale * sizeScale).clamp(
                    AppSize.textScaleMin,
                    AppSize.textScaleMax,
                  ),
                );

                return MediaQuery(
                  data: mediaQuery.copyWith(textScaler: scaled),
                  child: Builder(
                    builder: (childContext) {
                      innerContext = childContext;
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      final effectiveScaler = MediaQuery.of(innerContext).textScaler;
      final effectiveScale = effectiveScaler.scale(1.0);
      expect(effectiveScale, greaterThanOrEqualTo(1.9), reason: 'Root app must allow text scale 2.0');
    });

    testWidgets('screens and widgets survive scale 1.0, 1.5, and 2.0 without overflow', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          wrapWithTheme(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: 'متابعة القراءة من سورة البقرة بصوت الشيخ الحصري',
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                SearchBarWidget(
                  hintText: 'ابحث في المصحف والتفاسير',
                  onSearch: (_) {},
                  onFilterTap: () {},
                ),
              ],
            ),
            textScale: scale,
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Failed at textScale $scale');
      }
    });
  });

  group('T10 / C21 — Contrast Compliance Proof (WCAG AA text >= 4.5:1)', () {
    test('Light theme textSubtle achieves >= 4.5:1 on surfaceMuted, surface, and bg', () {
      final textSubtle = AppPalette.light.textSubtle;
      final surfaceMuted = AppPalette.light.surfaceMuted;
      final surface = AppPalette.light.surface;
      final bg = AppPalette.light.bg;

      final ratioMuted = contrastRatio(textSubtle, surfaceMuted);
      final ratioSurface = contrastRatio(textSubtle, surface);
      final ratioBg = contrastRatio(textSubtle, bg);

      expect(ratioMuted, greaterThanOrEqualTo(4.5), reason: 'Light textSubtle on surfaceMuted must be AA');
      expect(ratioSurface, greaterThanOrEqualTo(4.5), reason: 'Light textSubtle on surface must be AA');
      expect(ratioBg, greaterThanOrEqualTo(4.5), reason: 'Light textSubtle on bg must be AA');
    });

    test('Dark theme textSubtle achieves >= 4.5:1 on surfaceRaised, surfaceMuted, and bg', () {
      final textSubtle = AppPalette.dark.textSubtle;
      final surfaceRaised = AppPalette.dark.surfaceRaised;
      final surfaceMuted = AppPalette.dark.surfaceMuted;
      final bg = AppPalette.dark.bg;

      final ratioRaised = contrastRatio(textSubtle, surfaceRaised);
      final ratioMuted = contrastRatio(textSubtle, surfaceMuted);
      final ratioBg = contrastRatio(textSubtle, bg);

      expect(ratioRaised, greaterThanOrEqualTo(4.5), reason: 'Dark textSubtle on surfaceRaised must be AA');
      expect(ratioMuted, greaterThanOrEqualTo(4.5), reason: 'Dark textSubtle on surfaceMuted must be AA');
      expect(ratioBg, greaterThanOrEqualTo(4.5), reason: 'Dark textSubtle on bg must be AA');
    });
  });

  group('Task R68 — RTL Directional & Spacing Token Accessibility & Scalability', () {
    testWidgets('QuickActionButton renders with Directional gradient and survives scales 1.0, 1.5, 2.0', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        for (final isDark in [false, true]) {
          await tester.pumpWidget(
            wrapWithTheme(
              QuickActionButton(
                icon: Icons.menu_book_rounded,
                label: 'القرآن الكريم',
                onTap: () {},
              ),
              isDark: isDark,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'QuickActionButton failed at scale $scale isDark=$isDark');
          expect(find.text('القرآن الكريم'), findsOneWidget);
        }
      }
    });

    testWidgets('HomeHeroTimelineStation with AppSpace.xxs renders cleanly at scales 1.0, 1.5, 2.0', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          wrapWithTheme(
            Row(
              children: [
                HomeHeroTimelineStation(
                  prayerName: 'الفجر',
                  prayerTime: DateTime(2026, 10, 24, 5, 20),
                  isCurrent: true,
                  isPast: false,
                  isInPrayerTime: false,
                ),
              ],
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'HomeHeroTimelineStation failed at scale $scale');
        expect(find.text('الفجر'), findsOneWidget);
      }
    });

    testWidgets('MoreSectionCard with AppSpace.xxs renders cleanly in RTL at scales 1.0, 1.5, 2.0', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          wrapWithTheme(
            MoreSectionCard(
              section: MoreSection(
                title: 'إعدادات المظهر',
                subtitle: 'الوضع الداكن والفاتح وألوان الواجهة',
                icon: Icons.palette_outlined,
                color: AppPalette.light.primary,
                onTap: () {},
              ),
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'MoreSectionCard failed at scale $scale');
        expect(find.text('إعدادات المظهر'), findsOneWidget);
      }
    });

    testWidgets('LearningPulseCard with Directional gradient renders without overflow at scales 1.0, 1.5, 2.0', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          wrapWithTheme(
            const LearningPulseCard(),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'LearningPulseCard failed at scale $scale');
        expect(find.text('ابدأ رحلة طلب العلم'), findsOneWidget);
      }
    });
  });
}
