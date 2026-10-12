/// Western digits → Arabic-Indic (٠–٩), as used in Medina Mushaf page numbers.
String toArabicDigits(int number) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final str = number.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final code = str.codeUnitAt(i) - 48;
    if (code >= 0 && code <= 9) {
      buffer.write(digits[code]);
    } else {
      buffer.write(str[i]);
    }
  }
  return buffer.toString();
}

/// Formal Arabic juz ordinal titles (Medina Mushaf style).
String getArabicJuzName(int juzNumber) {
  const juzNames = [
    'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
    'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
    'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر',
    'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
    'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون', 'الرابع والعشرون', 'الخامس والعشرون',
    'السادس والعشرون', 'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
  ];
  if (juzNumber >= 1 && juzNumber <= 30) {
    return 'الجُزْءُ ${juzNames[juzNumber - 1]}';
  }
  return 'الجزء ${toArabicDigits(juzNumber)}';
}
