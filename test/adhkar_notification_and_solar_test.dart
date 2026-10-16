import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/adhkar_reminder_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_solar_stations_card.dart';

void main() {
  group('Adhkar Reminder Settings & Service Tests', () {
    test('Default settings initialize correctly with morning, evening, and sleep times', () {
      const settings = AdhkarReminderSettings();
      expect(settings.morningEnabled, isTrue);
      expect(settings.eveningEnabled, isTrue);
      expect(settings.sleepEnabled, isTrue);
      expect(settings.morningHour, equals(6));
      expect(settings.morningMinute, equals(30));
      expect(settings.eveningHour, equals(17));
      expect(settings.eveningMinute, equals(0));
      expect(settings.sleepHour, equals(22));
      expect(settings.sleepMinute, equals(0));
    });

    test('Loads settings properly from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'adhkar_rem_morning_enabled': false,
        'adhkar_rem_morning_hour': 7,
        'adhkar_rem_morning_min': 15,
        'adhkar_rem_evening_enabled': true,
        'adhkar_rem_evening_hour': 18,
        'adhkar_rem_evening_min': 45,
        'adhkar_rem_sleep_enabled': false,
        'adhkar_rem_sleep_hour': 23,
        'adhkar_rem_sleep_min': 30,
      });

      final service = AdhkarReminderService();
      final loaded = await service.getSettings();

      expect(loaded.morningEnabled, isFalse);
      expect(loaded.morningHour, equals(7));
      expect(loaded.morningMinute, equals(15));
      expect(loaded.eveningEnabled, isTrue);
      expect(loaded.eveningHour, equals(18));
      expect(loaded.eveningMinute, equals(45));
      expect(loaded.sleepEnabled, isFalse);
      expect(loaded.sleepHour, equals(23));
      expect(loaded.sleepMinute, equals(30));
    });

    test('copyWith updates specific fields cleanly', () {
      const initial = AdhkarReminderSettings();
      final updated = initial.copyWith(
        morningHour: 5,
        morningMinute: 45,
        sleepEnabled: false,
      );

      expect(updated.morningHour, equals(5));
      expect(updated.morningMinute, equals(45));
      expect(updated.morningEnabled, isTrue);
      expect(updated.sleepEnabled, isFalse);
      expect(updated.eveningEnabled, isTrue);
    });
  });

  group('Prayer Solar Stations (الشروق والغروب) Tests', () {
    test('PrayerTimesDay includes sunrise and sunset fields', () {
      final baseDate = DateTime(2026, 10, 16, 12, 0);
      final sunrise = DateTime(2026, 10, 16, 6, 32);
      final sunset = DateTime(2026, 10, 16, 17, 54);

      final day = PrayerTimesDay(
        city: 'الجزائر',
        date: baseDate,
        prayers: {'الفجر': DateTime(2026, 10, 16, 5, 12)},
        nextPrayer: 'الظهر',
        nextPrayerTime: DateTime(2026, 10, 16, 12, 30),
        sunrise: sunrise,
        sunset: sunset,
      );

      expect(day.sunrise, equals(sunrise));
      expect(day.sunset, equals(sunset));
    });

    testWidgets('PrayerSolarStationsCard renders both Shuruq and Ghurub stations', (tester) async {
      final sunrise = DateTime(2026, 10, 16, 6, 30);
      final sunset = DateTime(2026, 10, 16, 17, 45);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PrayerSolarStationsCard(
              sunrise: sunrise,
              sunset: sunset,
            ),
          ),
        ),
      );

      expect(find.text('الشروق'), findsOneWidget);
      expect(find.text('الغروب'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
      expect(find.byIcon(Icons.wb_twilight_rounded), findsOneWidget);
    });
  });
}
