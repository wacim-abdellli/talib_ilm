import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/core/utils/safe_url_launcher.dart';

void main() {
  group('SafeUrlLauncher — External Content & URL Boundary Enforcement', () {
    test('accepts legitimate HTTPS web URLs', () {
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ')), isTrue);
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('https://github.com/wacim-abdellli/talib_ilm')), isTrue);
    });

    test('accepts native YouTube application scheme', () {
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('vnd.youtube:dQw4w9WgXcQ')), isTrue);
    });

    test('rejects cleartext HTTP URLs', () {
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('http://insecure-site.com')), isFalse);
    });

    test('rejects dangerous script schemes (javascript:, data:)', () {
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('javascript:alert(1)')), isFalse);
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('data:text/html;base64,PHNjcmlwdD4=')), isFalse);
    });

    test('rejects local file and content access schemes', () {
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('file:///etc/passwd')), isFalse);
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('content://contacts/people')), isFalse);
    });

    test('rejects parameter script injection payloads', () {
      expect(SafeUrlLauncher.isSafeUri(Uri.parse('https://example.com/?next=javascript:evil()')), isFalse);
    });
  });
}
