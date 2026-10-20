import 'package:talib_ilm/features/home/domain/models/hadith.dart';

class GradedHadith {
  final String id;
  final int number;
  final String title;
  final String collection;
  final String category;
  final String grade;
  final String source;
  final String narrator;
  final String matn;
  final String benefits;

  final String? searchIndex;

  static final RegExp _dotsRegex = RegExp(r'\.{2,}');
  static final RegExp _trailingDotsRegex = RegExp(r'\.+$');

  const GradedHadith({
    required this.id,
    required this.number,
    required this.title,
    required this.collection,
    required this.category,
    required this.grade,
    required this.source,
    required this.narrator,
    required this.matn,
    required this.benefits,
    this.searchIndex,
  });

  GradedHadith copyWith({
    String? id,
    int? number,
    String? title,
    String? collection,
    String? category,
    String? grade,
    String? source,
    String? narrator,
    String? matn,
    String? benefits,
    String? searchIndex,
  }) {
    return GradedHadith(
      id: id ?? this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      collection: collection ?? this.collection,
      category: category ?? this.category,
      grade: grade ?? this.grade,
      source: source ?? this.source,
      narrator: narrator ?? this.narrator,
      matn: matn ?? this.matn,
      benefits: benefits ?? this.benefits,
      searchIndex: searchIndex ?? this.searchIndex,
    );
  }

  static String cleanText(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?(?:p|div|span|b|i|u|strong|em)[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  factory GradedHadith.fromJson(Map<String, dynamic> json, {String? searchIndex}) {
    return GradedHadith(
      id: json['id'] as String? ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      title: cleanText(json['title'] as String? ?? ''),
      collection: json['collection'] as String? ?? 'الأربعون النووية',
      category: json['category'] as String? ?? 'عام',
      grade: json['grade'] as String? ?? 'صحيح',
      source: cleanText(json['source'] as String? ?? ''),
      narrator: cleanText(json['narrator'] as String? ?? ''),
      matn: cleanText(json['matn'] as String? ?? ''),
      benefits: cleanText(json['benefits'] as String? ?? ''),
      searchIndex: searchIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'collection': collection,
    'category': category,
    'grade': grade,
    'source': source,
    'narrator': narrator,
    'matn': matn,
    'benefits': benefits,
  };

  /// Generates clean, perfectly formatted share/copy text for this Hadith
  String toShareText() {
    final cMatn = cleanText(matn);
    final cNarrator = cleanText(narrator);
    final cSource = cleanText(source);
    final cGrade = cleanText(grade);
    final cBenefits = cleanText(benefits);

    final buffer = StringBuffer('«$cMatn»\n\n');
    if (cNarrator.isNotEmpty) {
      buffer.writeln('• الراوي: $cNarrator');
    }
    if (cSource.isNotEmpty) {
      buffer.writeln('• التخريج: $cSource');
    }
    if (cGrade.isNotEmpty) {
      buffer.writeln('• الدرجة: $cGrade');
    }
    if (cBenefits.isNotEmpty) {
      buffer.writeln('• الفوائد: $cBenefits');
    }
    buffer.write('\nمن تطبيق طالب العلم');
    return buffer.toString();
  }

  /// Compatibility bridge with existing HadithFavoritesService
  Hadith toLegacyHadith() {
    return Hadith(
      text: matn,
      source: '$source - $grade',
    );
  }

  /// Whether this Hadith is Muttafaq 'alayh or Sahih
  bool get isSahih => grade.contains('صحيح');

  /// Clean title guaranteed to have no trailing dots, ellipses, or generic headers
  String get cleanTitle {
    var t = title.replaceAll(_dotsRegex, '').replaceAll(_trailingDotsRegex, '').trim();
    if (t.startsWith('حديث من ') || t.startsWith('الحديث القدسي ')) {
      if (category.isNotEmpty && !category.contains('القدسي')) {
        return category;
      }
    }
    return t.isNotEmpty ? t : 'حديث نبوي شريف';
  }

  /// Clean matn snippet for compact cards
  String get shortMatn {
    if (matn.length <= 140) return matn;
    return '${matn.substring(0, 137)}...';
  }
}
