import 'package:flutter/foundation.dart';

@immutable
class SalafGem {
  final String id;
  final String author;
  final String role;
  final String category;
  final String topic;
  final String text;
  final String sourceRef;

  const SalafGem({
    required this.id,
    required this.author,
    required this.role,
    required this.category,
    required this.topic,
    required this.text,
    required this.sourceRef,
  });

  factory SalafGem.fromJson(Map<String, dynamic> json) {
    return SalafGem(
      id: json['id'] as String? ?? '',
      author: (json['author'] as String? ?? 'من درر السلف').trim(),
      role: (json['role'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? 'درر السلف').trim(),
      topic: (json['topic'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
      sourceRef: (json['sourceRef'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'role': role,
      'category': category,
      'topic': topic,
      'text': text,
      'sourceRef': sourceRef,
    };
  }

  /// Clean quote body stripping redundant leading "قال فلان... :"
  String get cleanText {
    var result = text.trim();
    final prefixRegex = RegExp(r'^(?:قال|كتب|سمع|روي عَن)\s+[^:：\n]{2,60}[:：]\s*');
    result = result.replaceFirst(prefixRegex, '').trim();
    if (result.startsWith('(') && result.endsWith(')')) {
      result = result.substring(1, result.length - 1).trim();
    }
    return result.isEmpty ? text : result;
  }

  String get shareableText {
    final buffer = StringBuffer();
    if (topic.isNotEmpty && topic != category) {
      buffer.writeln('[$topic]');
    }
    buffer.writeln('«$cleanText»');
    buffer.writeln('— $author');
    if (sourceRef.isNotEmpty) {
      buffer.writeln('المصدر والتخريج: $sourceRef');
    }
    buffer.write('\nمن تطبيق طالب العلم');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalafGem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
