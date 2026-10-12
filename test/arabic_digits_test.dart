import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/core/utils/arabic_digits.dart';

void main() {
  test('toArabicDigits formats western digits', () {
    expect(toArabicDigits(42), '42');
    expect(toArabicDigits(604), '604');
  });

  test('getArabicJuzName uses ordinal titles', () {
    expect(getArabicJuzName(3), 'الجُزْءُ الثالث');
  });
}
