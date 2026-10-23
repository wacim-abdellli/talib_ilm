import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/async_lock.dart';
import '../catalogs/islamic_quiz_catalog.dart';
import '../models/islamic_quiz_models.dart';

/// Result summary of recording a completed quiz session.
class QuizRecordResult {
  final int earnedXp;
  final int earnedStars;
  final bool isNewHighScore;
  final bool newlyUnlockedNextLevel;
  final String? nextLevelTitle;
  final double scorePercentage;
  final bool hasPassed;

  const QuizRecordResult({
    required this.earnedXp,
    required this.earnedStars,
    required this.isNewHighScore,
    required this.newlyUnlockedNextLevel,
    this.nextLevelTitle,
    required this.scorePercentage,
    required this.hasPassed,
  });
}

/// Persistent service managing quiz level progression, XP, stars, and unlock state.
class QuizProgressService {
  final SharedPreferences _prefs;
  final AsyncLock _lock = AsyncLock();

  QuizProgressService(this._prefs);

  static const String _keyXp = 'quiz_total_xp';
  static const String _keyQuizzesCount = 'quiz_total_quizzes';
  static const String _keyQuestionsAnswered = 'quiz_total_questions_answered';
  static const String _keyCorrectAnswers = 'quiz_total_correct';
  static const String _keyDailyLastDate = 'quiz_daily_last_date';

  /// Records the score of a quiz level, calculates XP and stars, and unlocks the next level.
  /// Enforces input bounds and session idempotency (duplicate completion ID does not double XP/counters).
  Future<QuizRecordResult> recordLevelResult({
    required String levelId,
    required int correctCount,
    required int totalQuestions,
    required int maxStreak,
    String? sessionCompletionId,
  }) =>
      _lock.synchronized(() async {
        if (totalQuestions <= 0) {
          return const QuizRecordResult(
            earnedXp: 0,
            earnedStars: 0,
            isNewHighScore: false,
            newlyUnlockedNextLevel: false,
            scorePercentage: 0.0,
            hasPassed: false,
          );
        }

        final safeCorrect = correctCount.clamp(0, totalQuestions);
        final safeStreak = maxStreak.clamp(0, totalQuestions);
        final scorePercentage = (safeCorrect / totalQuestions) * 100;
        final hasPassed = scorePercentage >= 70.0;

        // Idempotency check: prevent duplicate counter increments for same session completion
        if (sessionCompletionId != null) {
          final tokenKey = 'quiz_completion_token_$sessionCompletionId';
          if (_prefs.getBool(tokenKey) == true) {
            final prevStars = _prefs.getInt('quiz_stars_$levelId') ?? 0;
            return QuizRecordResult(
              earnedXp: 0,
              earnedStars: prevStars,
              isNewHighScore: false,
              newlyUnlockedNextLevel: false,
              scorePercentage: scorePercentage,
              hasPassed: hasPassed,
            );
          }
          await _prefs.setBool(tokenKey, true);
        }

        // Calculate stars
        int stars = 0;
        if (scorePercentage >= 99.9) {
          stars = 3;
        } else if (scorePercentage >= 80.0) {
          stars = 2;
        } else if (scorePercentage >= 70.0) {
          stars = 1;
        }

        // Calculate XP
        int xpEarned = safeCorrect * 10;
        if (safeStreak >= 3) {
          xpEarned += (safeStreak * 3);
        }
        if (stars == 3) {
          xpEarned += 50; // Perfect score bonus
        } else if (stars == 2) {
          xpEarned += 25; // Great score bonus
        }

        // Persist totals
        final currentXp = _prefs.getInt(_keyXp) ?? 0;
        await _prefs.setInt(_keyXp, currentXp + xpEarned);

        final currentQuizzes = _prefs.getInt(_keyQuizzesCount) ?? 0;
        await _prefs.setInt(_keyQuizzesCount, currentQuizzes + 1);

        final currentQuestions = _prefs.getInt(_keyQuestionsAnswered) ?? 0;
        await _prefs.setInt(
            _keyQuestionsAnswered, currentQuestions + totalQuestions);

        final currentCorrect = _prefs.getInt(_keyCorrectAnswers) ?? 0;
        await _prefs.setInt(_keyCorrectAnswers, currentCorrect + safeCorrect);

        // Persist level high score and stars
        final prevScore = _prefs.getInt('quiz_score_$levelId') ?? 0;
        final isNewHighScore = safeCorrect > prevScore;
        if (isNewHighScore) {
          await _prefs.setInt('quiz_score_$levelId', safeCorrect);
        }

        final prevStars = _prefs.getInt('quiz_stars_$levelId') ?? 0;
        if (stars > prevStars) {
          await _prefs.setInt('quiz_stars_$levelId', stars);
        }

        if (hasPassed) {
          await _prefs.setBool('quiz_completed_$levelId', true);
        }

        // Unlock next level if passed with >= 70%
        bool newlyUnlocked = false;
        String? nextLevelTitle;

        if (hasPassed) {
          final fan = IslamicQuizCatalog.getFanForLevel(levelId);
          if (fan != null) {
            final currentIndex =
                fan.levels.indexWhere((lvl) => lvl.id == levelId);
            if (currentIndex != -1 && currentIndex + 1 < fan.levels.length) {
              final nextLevel = fan.levels[currentIndex + 1];
              final alreadyUnlocked =
                  _prefs.getBool('quiz_unlocked_${nextLevel.id}') ?? false;
              if (!alreadyUnlocked) {
                await _prefs.setBool('quiz_unlocked_${nextLevel.id}', true);
                newlyUnlocked = true;
                nextLevelTitle = nextLevel.title;
              }
            }
          }
        }

        return QuizRecordResult(
          earnedXp: xpEarned,
          earnedStars: stars,
          isNewHighScore: isNewHighScore,
          newlyUnlockedNextLevel: newlyUnlocked,
          nextLevelTitle: nextLevelTitle,
          scorePercentage: scorePercentage,
          hasPassed: hasPassed,
        );
      });

  /// Checks if a level is unlocked. Level 1 of any discipline is always unlocked.
  bool isLevelUnlocked(String levelId, int levelNumber, String? prevLevelId) {
    if (levelNumber <= 1) return true;
    final explicitlyUnlocked =
        _prefs.getBool('quiz_unlocked_$levelId') ?? false;
    if (explicitlyUnlocked) return true;

    if (prevLevelId != null) {
      final prevCompleted =
          _prefs.getBool('quiz_completed_$prevLevelId') ?? false;
      return prevCompleted;
    }
    return false;
  }

  /// Retrieves progress for a specific level.
  QuizLevelProgress getLevelProgress(
    String levelId,
    int levelNumber,
    String? prevLevelId,
    int totalQuestions,
  ) {
    final unlocked = isLevelUnlocked(levelId, levelNumber, prevLevelId);
    final highScore = _prefs.getInt('quiz_score_$levelId') ?? 0;
    final stars = _prefs.getInt('quiz_stars_$levelId') ?? 0;
    final isCompleted = _prefs.getBool('quiz_completed_$levelId') ?? false;

    return QuizLevelProgress(
      levelId: levelId,
      isUnlocked: unlocked,
      highScore: highScore,
      totalQuestions: totalQuestions,
      stars: stars,
      isCompleted: isCompleted,
    );
  }

  /// Aggregates all user stats and level achievements.
  UserQuizStats getUserStats() {
    final totalXp = _prefs.getInt(_keyXp) ?? 0;
    final totalQuizzes = _prefs.getInt(_keyQuizzesCount) ?? 0;
    final totalQuestions = _prefs.getInt(_keyQuestionsAnswered) ?? 0;
    final totalCorrect = _prefs.getInt(_keyCorrectAnswers) ?? 0;

    final levelProgress = <String, QuizLevelProgress>{};

    for (final fan in IslamicQuizCatalog.founoun) {
      String? prevId;
      for (final level in fan.levels) {
        final progress = getLevelProgress(
          level.id,
          level.levelNumber,
          prevId,
          level.totalQuestions,
        );
        levelProgress[level.id] = progress;
        prevId = level.id;
      }
    }

    return UserQuizStats(
      totalXp: totalXp,
      totalQuizzesTaken: totalQuizzes,
      totalQuestionsAnswered: totalQuestions,
      totalCorrectAnswers: totalCorrect,
      levelProgress: levelProgress,
    );
  }

  /// Whether the daily challenge was already taken today.
  bool isDailyChallengeCompletedToday() {
    final lastDateStr = _prefs.getString(_keyDailyLastDate);
    if (lastDateStr == null) return false;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    return lastDateStr == todayStr;
  }

  /// Marks today's daily challenge completed and awards bonus XP.
  /// Enforces single completion per day.
  Future<void> markDailyChallengeCompleted(
    int correct,
    int total, {
    String? sessionCompletionId,
  }) =>
      _lock.synchronized(() async {
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        final lastDateStr = _prefs.getString(_keyDailyLastDate);
        if (lastDateStr == todayStr) {
          // Already completed today, do not award duplicate XP
          return;
        }

        if (sessionCompletionId != null) {
          final tokenKey = 'quiz_daily_token_$sessionCompletionId';
          if (_prefs.getBool(tokenKey) == true) {
            return;
          }
          await _prefs.setBool(tokenKey, true);
        }

        await _prefs.setString(_keyDailyLastDate, todayStr);

        final safeCorrect = total > 0 ? correct.clamp(0, total) : 0;
        final currentXp = _prefs.getInt(_keyXp) ?? 0;
        final xp = (safeCorrect * 12) + 20; // Extra daily bonus XP
        await _prefs.setInt(_keyXp, currentXp + xp);
      });

  static const String _keySessionPrefix = 'quiz_active_session_';

  /// Saves the active progress of a quiz session so the user can resume where they left off.
  Future<void> saveActiveSession(
    String sessionId,
    QuizActiveSession session,
  ) async {
    final raw = jsonEncode(session.toJson());
    await _prefs.setString('$_keySessionPrefix$sessionId', raw);
  }

  /// Retrieves the saved active quiz session, if any.
  /// Automatically purges corrupt session records to prevent persistent crashes.
  QuizActiveSession? getActiveSession(String sessionId) {
    final raw = _prefs.getString('$_keySessionPrefix$sessionId');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _prefs.remove('$_keySessionPrefix$sessionId');
        return null;
      }
      return QuizActiveSession.fromJson(decoded);
    } catch (_) {
      _prefs.remove('$_keySessionPrefix$sessionId');
      return null;
    }
  }

  /// Clears the active session once the quiz is finished or reset.
  Future<void> clearActiveSession(String sessionId) async {
    await _prefs.remove('$_keySessionPrefix$sessionId');
  }
}

/// Represents an active ongoing quiz session allowing seamless resume if interrupted.
class QuizActiveSession {
  final int currentIndex;
  final int correctAnswers;
  final int currentStreak;
  final int maxStreak;
  final List<int?> userAnswers;
  final String? sessionId;
  final int catalogVersion;

  const QuizActiveSession({
    required this.currentIndex,
    required this.correctAnswers,
    required this.currentStreak,
    required this.maxStreak,
    required this.userAnswers,
    this.sessionId,
    this.catalogVersion = 1,
  });

  Map<String, dynamic> toJson() => {
        'currentIndex': currentIndex,
        'correctAnswers': correctAnswers,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'userAnswers': userAnswers,
        'sessionId': sessionId,
        'catalogVersion': catalogVersion,
      };

  factory QuizActiveSession.fromJson(Map<String, dynamic> json) {
    return QuizActiveSession(
      currentIndex: (json['currentIndex'] as int? ?? 0).clamp(0, 9999),
      correctAnswers: (json['correctAnswers'] as int? ?? 0).clamp(0, 9999),
      currentStreak: (json['currentStreak'] as int? ?? 0).clamp(0, 9999),
      maxStreak: (json['maxStreak'] as int? ?? 0).clamp(0, 9999),
      userAnswers: (json['userAnswers'] as List<dynamic>?)
              ?.map((e) => e as int?)
              .toList() ??
          [],
      sessionId: json['sessionId'] as String?,
      catalogVersion: json['catalogVersion'] as int? ?? 1,
    );
  }
}
