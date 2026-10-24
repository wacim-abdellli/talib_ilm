import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/more/presentation/credits_and_licenses_page.dart';
import 'package:talib_ilm/shared/widgets/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task R65: Privacy Policy & Play Disclosures Verification', () {
    testWidgets('credits_and_licenses_page renders truthful privacy policy copy',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreditsAndLicensesPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to privacy section
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('شفافية الخصوصية واستخدام البيانات'), findsOneWidget);

      // 2. Personal info & ad-free
      expect(find.textContaining('لا جمع للبيانات الشخصية'), findsOneWidget);
      expect(find.textContaining('خلو تام من الإعلانات'), findsOneWidget);

      // 3. Local storage & backup
      expect(find.textContaining('التخزين المحلي والنسخ الاحتياطي'), findsOneWidget);

      // 4. Location coordinates
      expect(find.textContaining('إحداثيات الموقع ومواقيت الصلاة'), findsOneWidget);
      expect(find.textContaining('BigDataCloud'), findsOneWidget);

      // 5. External media hosts
      expect(find.textContaining('الاتصال بالإنترنت ومحتوى الوسائط'), findsOneWidget);
      expect(find.textContaining('EveryAyah.com'), findsOneWidget);
      expect(find.textContaining('Quran.com'), findsOneWidget);
      expect(find.textContaining('mp3quran.net'), findsOneWidget);
      expect(find.textContaining('Shamela.ws'), findsOneWidget);
      expect(find.textContaining('YouTube'), findsOneWidget);

      // 6. Detailed policy dialog button
      final buttonFinder = find.byType(AppButton).last;
      expect(buttonFinder, findsOneWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      await tester.tap(buttonFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('بيان الخصوصية واستخدام البيانات'), findsOneWidget);
      expect(find.textContaining('صفر بيانات مجمعة'), findsOneWidget);
      expect(find.textContaining('docs/PRIVACY_POLICY.md'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();

      expect(find.text('بيان الخصوصية واستخدام البيانات'), findsNothing);
    });

    test('privacy documents exist and cover all traced network hosts', () {
      final privacyPolicyFile = File('docs/PRIVACY_POLICY.md');
      final dataSafetyFile = File('docs/GOOGLE_PLAY_DATA_SAFETY_FACT_SHEET.md');

      expect(privacyPolicyFile.existsSync(), isTrue,
          reason: 'docs/PRIVACY_POLICY.md must exist');
      expect(dataSafetyFile.existsSync(), isTrue,
          reason: 'docs/GOOGLE_PLAY_DATA_SAFETY_FACT_SHEET.md must exist');

      final policyContent = privacyPolicyFile.readAsStringSync();
      final dataSafetyContent = dataSafetyFile.readAsStringSync();

      const requiredHosts = [
        'everyayah.com',
        'api.quran.com',
        'mp3quran.net',
        'shamela.ws',
        'youtube.com',
        'api.bigdatacloud.net',
      ];

      for (final host in requiredHosts) {
        expect(policyContent.contains(host), isTrue,
            reason: 'PRIVACY_POLICY.md must explicitly disclose host: $host');
        expect(dataSafetyContent.contains(host), isTrue,
            reason: 'GOOGLE_PLAY_DATA_SAFETY_FACT_SHEET.md must disclose host: $host');
      }

      // Assert radical honesty: neither document falsely claims "no data leaves device"
      expect(policyContent.contains('no data leaves the device'), isFalse);
      expect(dataSafetyContent.contains('no data leaves the device'), isFalse);

      // Assert location is documented as optional / opt-in
      expect(policyContent.contains('Opt-In Only'), isTrue);
      expect(dataSafetyContent.contains('Optional'), isTrue);
    });
  });
}
