import 'package:flutter/material.dart';

/// Single multiple-choice question with rich educational lesson, evidence, and reference.
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String lesson;
  final String evidence;
  final String reference;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.lesson,
    required this.evidence,
    required this.reference,
  });

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;
}

/// A level containing a curated set of questions within an Islamic science.
class QuizLevel {
  final String id;
  final int levelNumber;
  final String title;
  final String description;
  final List<QuizQuestion> questions;
  final int passingPercentage;

  const QuizLevel({
    required this.id,
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.questions,
    this.passingPercentage = 70,
  });

  int get totalQuestions => questions.length;
}

/// An Islamic discipline (فن من فنون العلم الشرعي) containing progressive levels.
class FanQuiz {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<QuizLevel> levels;

  const FanQuiz({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.levels,
  });

  int get totalQuestions =>
      levels.fold(0, (sum, level) => sum + level.totalQuestions);
}

/// Progress data for a specific level.
class QuizLevelProgress {
  final String levelId;
  final bool isUnlocked;
  final int highScore;
  final int totalQuestions;
  final int stars; // 0..3
  final bool isCompleted;

  const QuizLevelProgress({
    required this.levelId,
    required this.isUnlocked,
    required this.highScore,
    required this.totalQuestions,
    required this.stars,
    required this.isCompleted,
  });

  double get scorePercentage =>
      totalQuestions > 0 ? (highScore / totalQuestions) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'isUnlocked': isUnlocked,
        'highScore': highScore,
        'totalQuestions': totalQuestions,
        'stars': stars,
        'isCompleted': isCompleted,
      };

  factory QuizLevelProgress.fromJson(Map<String, dynamic> json) =>
      QuizLevelProgress(
        levelId: json['levelId'] as String? ?? '',
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        highScore: json['highScore'] as int? ?? 0,
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        stars: json['stars'] as int? ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

/// Aggregated user quiz stats and scholarly ranking.
class UserQuizStats {
  final int totalXp;
  final int totalQuizzesTaken;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final Map<String, QuizLevelProgress> levelProgress;

  const UserQuizStats({
    required this.totalXp,
    required this.totalQuizzesTaken,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.levelProgress,
  });

  int get totalStars =>
      levelProgress.values.fold(0, (sum, p) => sum + p.stars);

  int get completedLevelsCount =>
      levelProgress.values.where((p) => p.isCompleted).length;

  double get accuracyRate => totalQuestionsAnswered > 0
      ? (totalCorrectAnswers / totalQuestionsAnswered) * 100
      : 0.0;

  /// Scholarly rank based on earned XP
  String get rankTitle {
    if (totalXp >= 1500) return 'علّامة باحث ومتقن';
    if (totalXp >= 900) return 'مؤصل في فنون الشريعة';
    if (totalXp >= 500) return 'حافظ متقن للمتون';
    if (totalXp >= 250) return 'طالب علم مجتهد';
    if (totalXp >= 100) return 'ساعٍ في طلب العلم';
    return 'مبتدئ في رياض المعرفة';
  }

  String get rankIcon {
    if (totalXp >= 1500) return '👑';
    if (totalXp >= 900) return '📜';
    if (totalXp >= 500) return '⭐';
    if (totalXp >= 250) return '🌿';
    if (totalXp >= 100) return '📖';
    return '🌱';
  }
}
