import 'package:flutter/material.dart';

@immutable
class EncyclopediaSection {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String groupKey;
  final List<String> keywords;
  final String? targetCategory;
  final String? targetAuthor;

  const EncyclopediaSection({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.groupKey,
    this.keywords = const [],
    this.targetCategory,
    this.targetAuthor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncyclopediaSection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class EncyclopediaGroup {
  final String id;
  final String title;
  final String? quranAyah;
  final String? quranSurah;
  final List<EncyclopediaSection> sections;

  const EncyclopediaGroup({
    required this.id,
    required this.title,
    this.quranAyah,
    this.quranSurah,
    required this.sections,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncyclopediaGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
