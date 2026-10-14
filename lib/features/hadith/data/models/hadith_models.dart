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
  });

  factory GradedHadith.fromJson(Map<String, dynamic> json) {
    return GradedHadith(
      id: json['id'] as String? ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      collection: json['collection'] as String? ?? 'الأربعون النووية',
      category: json['category'] as String? ?? 'عام',
      grade: json['grade'] as String? ?? 'صحيح',
      source: json['source'] as String? ?? '',
      narrator: json['narrator'] as String? ?? '',
      matn: json['matn'] as String? ?? '',
      benefits: json['benefits'] as String? ?? '',
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
    var t = title.replaceAll(RegExp(r'\.{2,}'), '').replaceAll(RegExp(r'\.+$'), '').trim();
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
