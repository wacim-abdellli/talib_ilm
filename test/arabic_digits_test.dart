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

  test('toWesternDigits converts eastern Arabic numerals to western numerals', () {
    expect(toWesternDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(toWesternDigits('السنن الرواتب (١٢ ركعة)'), 'السنن الرواتب (12 ركعة)');
    expect(toWesternDigits('سورة طه: ١١٤'), 'سورة طه: 114');
  });
}
