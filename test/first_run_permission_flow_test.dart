import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/features/onboarding/presentation/onboarding_page.dart';
import 'package:talib_ilm/features/prayer/presentation/qibla_page.dart';
import 'package:talib_ilm/shared/widgets/app_button.dart';
import 'package:talib_ilm/shared/widgets/location_pre_permission_sheet.dart';
import 'package:talib_ilm/shared/widgets/notification_pre_permission_sheet.dart';

Widget _wrapWithApp(Widget child, {bool isDark = false}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: isDark ? AppTheme.dark() : AppTheme.light(),
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('R6b — First-Run & Pre-Permission Boundary Suite', () {
    test('1. Cold start: getLocation(autoPrompt: false) returns default Makkah without prompting', () async {
      final service = LocationService();
      LocationService.clearCache();

      final result = await service.getLocation(autoPrompt: false);

      expect(result.source, LocationSource.defaultCity);
      expect(result.city, 'مكة المكرمة');
      expect(result.latitude, 21.3891);
      expect(result.longitude, 39.8579);
    });

    test('2. Cold start: PrayerTimeService computes prayer times without GPS permissions', () async {
      final service = PrayerTimeService(
        now: () => DateTime(2026, 10, 26, 12, 0),
      );

      final day = await service.getPrayerTimesDay();

      expect(day.city, 'مكة المكرمة');
      expect(day.prayers.length, 5);
      expect(day.prayers.containsKey('الظهر'), isTrue);
    });

    test('3. Saved GPS / Manual priority: returns saved location immediately with zero latency', () async {
      SharedPreferences.setMockInitialValues({
        'last_city': 'الجزائر العاصمة',
        'last_lat': 36.7538,
        'last_lon': 3.0588,
        'last_is_verified_gps': true,
      });

      final service = LocationService();
      LocationService.clearCache();

      final result = await service.getLocation(autoPrompt: false);

      expect(result.source, LocationSource.savedGps);
      expect(result.city, 'الجزائر العاصمة');
      expect(result.latitude, 36.7538);
      expect(result.longitude, 3.0588);
    });

    testWidgets('4. LocationPrePermissionSheet: renders explanations and triggers callbacks', (tester) async {
      bool allowed = false;
      bool declined = false;
      bool manual = false;

      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: LocationPrePermissionSheet(
              onAllow: () => allowed = true,
              onDecline: () => declined = true,
              onManualSelect: () => manual = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تحديد الموقع لمواقيت الصلاة والقبلة'), findsOneWidget);
      expect(find.text('حساب مواقيت الصلاة بدقة'), findsOneWidget);
      expect(find.text('توجيه بوصلة القبلة'), findsOneWidget);
      expect(find.text('خصوصية تامة وأمان'), findsOneWidget);

      // Verify "Not Now" / decline action
      final declineBtn = find.text('لاحقاً (الاعتماد على مكة المكرمة)');
      expect(declineBtn, findsOneWidget);
      await tester.tap(declineBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(declined, isTrue);

      // Verify "Allow" action
      final allowBtn = find.text('السماح بالوصول للموقع');
      expect(allowBtn, findsOneWidget);
      await tester.tap(allowBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(allowed, isTrue);

      // Verify "Manual" action
      final manualBtn = find.text('اختيار المدينة يدوياً من القائمة');
      expect(manualBtn, findsOneWidget);
      await tester.tap(manualBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(manual, isTrue);
    });

    testWidgets('5. NotificationPrePermissionSheet: explains features and tracks deferral in prefs', (tester) async {
      bool declined = false;

      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: NotificationPrePermissionSheet(
              onDecline: () => declined = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تفعيل تنبيهات الأذان والأذكار'), findsOneWidget);
      expect(find.text('صوت الأذان عند دخول الوقت'), findsOneWidget);
      expect(find.text('التذكير المسبق والإقامة'), findsOneWidget);
      expect(find.text('سورة الكهف والأذكار اليومية'), findsOneWidget);

      final notNowBtn = find.text('لاحقاً');
      expect(notNowBtn, findsOneWidget);
      await tester.tap(notNowBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(declined, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(NotificationPrePermissionSheet.prefKey), isTrue);
      expect(prefs.getBool('adhan_enabled'), isFalse);
    });

    testWidgets('6. QiblaPage: shows permission explanation view with manual city fallback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrapWithApp(
          const QiblaPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('تحديد اتجاه القبلة'), findsOneWidget);
      expect(find.text('منح إذن الموقع'), findsOneWidget);
      expect(find.text('استخدام المدينة المحددة في التطبيق'), findsOneWidget);

      // Tapping manual city allows using Qibla without GPS permission
      final fallbackBtn = find.text('استخدام المدينة المحددة في التطبيق');
      await tester.tap(fallbackBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      // Qibla calculation successfully initialized without throwing
      expect(find.text('تحديد اتجاه القبلة'), findsNothing);
    });

    testWidgets('7. OnboardingPage: completes 3-page flow and records completion in prefs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool completed = false;

      await tester.pumpWidget(
        _wrapWithApp(
          OnboardingPage(
            onCompleted: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page 1
      expect(find.text('القرآن الكريم والمتون العلمية'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      // Advance to Page 2
      await tester.tap(find.widgetWithText(AppButton, 'التالي'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('مواقيت الصلاة والأذان الشريف'), findsOneWidget);

      // Advance to Page 3
      await tester.tap(find.widgetWithText(AppButton, 'التالي'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('حصن المسلم والورد اليومي'), findsOneWidget);
      expect(find.text('ابدأ الاستخدام'), findsOneWidget);

      // Finish Onboarding
      await tester.tap(find.widgetWithText(AppButton, 'ابدأ الاستخدام'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(OnboardingPage.prefKey), isTrue);
    });

    testWidgets('8. OnboardingPage: skip button immediately completes and persists state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool completed = false;

      await tester.pumpWidget(
        _wrapWithApp(
          OnboardingPage(
            onCompleted: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final skipBtn = find.widgetWithText(AppButton, 'تخطي');
      expect(skipBtn, findsOneWidget);
      await tester.tap(skipBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(OnboardingPage.prefKey), isTrue);
    });

    testWidgets('9. OnboardingPage: survives text scales 1.0, 1.5, and 2.0 across all 3 pages without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final scale in [1.0, 1.5, 2.0]) {
        for (final isDark in [false, true]) {
          await tester.pumpWidget(
            _wrapWithApp(
              Builder(
                builder: (ctx) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: OnboardingPage(
                    key: ValueKey('onboarding_${scale}_$isDark'),
                    onCompleted: () {},
                  ),
                ),
              ),
              isDark: isDark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Advance to Page 2
          await tester.tap(
            find.widgetWithText(AppButton, 'التالي'),
            warnIfMissed: false,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Advance to Page 3
          await tester.tap(
            find.widgetWithText(AppButton, 'التالي'),
            warnIfMissed: false,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}
