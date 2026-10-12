/// Formats numbers using standard Western numerals (1, 2, 3) per app guidelines.
String toArabicDigits(int number) => number.toString();

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
  return 'الجزء $juzNumber';
}
