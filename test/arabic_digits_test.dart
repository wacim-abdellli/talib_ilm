import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/core/utils/arabic_digits.dart';

void main() {
  test('toArabicDigits converts western digits', () {
    expect(toArabicDigits(42), '٤٢');
    expect(toArabicDigits(604), '٦٠٤');
  });

  test('getArabicJuzName uses ordinal titles', () {
    expect(getArabicJuzName(3), 'الجُزْءُ الثالث');
  });
}
