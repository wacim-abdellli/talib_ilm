import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/remote_geocoding_consent_tile.dart';

void main() {
  group('RemoteGeocodingConsentTile Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildTestWidget({ValueChanged<bool>? onChanged}) {
      return MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: RemoteGeocodingConsentTile(onChanged: onChanged),
          ),
        ),
      );
    }

    testWidgets('Renders title, subtitle, and defaults to unchecked (opt-in only)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('البحث عن اسم المدينة عبر الإنترنت'), findsOneWidget);
      expect(
        find.text(
          'يسمح بإرسال الإحداثيات إلى (BigDataCloud) لجلب اسم المدينة بالعربية فقط عند تعذر التعرف عليها محلياً. معطل افتراضياً لحماية الخصوصية.',
        ),
        findsOneWidget,
      );

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('Toggling switch persists preference and notifies listener', (tester) async {
      bool? lastNotified;
      await tester.pumpWidget(buildTestWidget(
        onChanged: (val) => lastNotified = val,
      ));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      // Tap to opt in
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      expect(lastNotified, isTrue);
      expect(await LocationService.isRemoteGeocodingAllowed(), isTrue);

      // Tap to opt out
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(lastNotified, isFalse);
      expect(await LocationService.isRemoteGeocodingAllowed(), isFalse);
    });
  });
}
