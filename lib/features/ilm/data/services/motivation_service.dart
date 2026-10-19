import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../features/ilm/data/models/book_progress_model.dart';
import '../../../../features/ilm/data/models/mutun_models.dart';

/// Lightweight motivation system for Islamic learning
/// Focuses on sincerity and progress, not gamification
class MotivationService {
  static const String _milestonesKey = 'motivation_milestones';
  static const String _lastEncouragementKey = 'last_encouragement_date';
  static const String _dailyQuoteIndexKey = 'daily_quote_index';

  final SharedPreferences _prefs;

  MotivationService(this._prefs);

  // ═══════════════════════════════════════════
  // MILESTONE TRACKING
  // ═══════════════════════════════════════════

  /// Check and record milestone achievements
  Future<MilestoneTrigger?> checkMilestone({
    required int booksCompleted,
    required int currentStreak,
    required int totalPagesRead,
    required bool justCompletedBook,
    required bool justCompletedLevel,
    required bool justAchievedDailyGoal,
  }) async {
    final milestones = _loadMilestones();
    MilestoneTrigger? trigger;

    // First book completed (most special)
    if (justCompletedBook &&
        booksCompleted == 1 &&
        !milestones.contains('first_book')) {
      trigger = MilestoneTrigger(
        type: MilestoneType.firstBook,
        title: 'فتح الله عليك!',
        message: 'أتممت أول كتاب في رحلتك العلمية\n«بورك في العلم وأهله»',
        verse:
            'قُلْ هَلْ يَسْتَوِي الَّذِينَ يَعْلَمُونَ وَالَّذِينَ لَا يَعْلَمُونَ',
        verseRef: 'الزمر: 9',
        icon: '📚',
      );
      await _recordMilestone('first_book');
    }
    // Level completed
    else if (justCompletedLevel &&
        !milestones.contains(
          'level_${DateTime.now().millisecondsSinceEpoch}',
        )) {
      trigger = MilestoneTrigger(
        type: MilestoneType.levelComplete,
        title: 'أحسنت صنعًا! أتممت المستوى',
        message: 'استمر في السعي نحو العلم النافع',
        hadith:
            '«من سلك طريقًا يلتمس فيه علمًا سهّل الله له به طريقًا إلى الجنة»',
        hadithRef: 'رواه مسلم',
        icon: '🏆',
      );
      await _recordMilestone('level_${DateTime.now().millisecondsSinceEpoch}');
    }
    // 7-day streak
    else if (currentStreak == 7 && !milestones.contains('streak_7')) {
      trigger = MilestoneTrigger(
        type: MilestoneType.weekStreak,
        title: 'مواظبة مباركة!',
        message: 'أسبوع كامل من المواظبة على العلم\nاللهم بارك في وقتك وعلمك',
        hadith: '«أحب الأعمال إلى الله أدومها وإن قل»',
        hadithRef: 'متفق عليه',
        icon: '🔥',
      );
      await _recordMilestone('streak_7');
    }
    // 30-day streak
    else if (currentStreak == 30 && !milestones.contains('streak_30')) {
      trigger = MilestoneTrigger(
        type: MilestoneType.monthStreak,
        title: 'سددك الله!',
        message: 'شهر كامل من المثابرة\nهذا من توفيق الله لك',
        verse: 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا',
        verseRef: 'العنكبوت: 69',
        icon: '⭐',
      );
      await _recordMilestone('streak_30');
    }
    // 5 books milestone
    else if (booksCompleted == 5 && !milestones.contains('books_5')) {
      trigger = MilestoneTrigger(
        type: MilestoneType.booksCount,
        title: 'وفقك الله!',
        message: 'خمسة كتب أتممتها بفضل الله\nاستمر في البذل والاجتهاد',
        hadith: '«إن العلماء ورثة الأنبياء»',
        hadithRef: 'رواه أبو داود',
        icon: '📖',
      );
      await _recordMilestone('books_5');
    }
    // 10 books milestone
    else if (booksCompleted == 10 && !milestones.contains('books_10')) {
      trigger = MilestoneTrigger(
        type: MilestoneType.booksCount,
        title: 'نفع الله بك!',
        message: 'عشرة كتب أكملتها بتوفيق الله\nعلمٌ يُبنى وأجرٌ يُرجى',
        verse:
            'يَرْفَعِ اللَّهُ الَّذِينَ آمَنُوا مِنكُمْ وَالَّذِينَ أُوتُوا الْعِلْمَ دَرَجَاتٍ',
        verseRef: 'المجادلة: 11',
        icon: '🌟',
      );
      await _recordMilestone('books_10');
    }

    return trigger;
  }

  /// Get daily encouragement (shown once per day)
  Future<Encouragement?> getDailyEncouragement({
    required int currentStreak,
    required int booksCompleted,
    required bool hasReadToday,
  }) async {
    final lastDate = _prefs.getString(_lastEncouragementKey);
    final today = _todayKey();

    // Already shown today
    if (lastDate == today) return null;

    Encouragement? encouragement;

    // If hasn't read yet, gentle reminder
    if (!hasReadToday && currentStreak > 0) {
      encouragement = Encouragement(
        type: EncouragementType.gentleReminder,
        message: currentStreak >= 7
            ? 'حافظ على هذه العزيمة\nقراءة قصيرة خير من الانقطاع'
            : 'لا تفوت وردك التعليمي اليوم',
        icon: '📚',
        tone: EncouragementTone.gentle,
      );
    }
    // If has read, positive reinforcement
    else if (hasReadToday) {
      final messages = [
        'بارك الله في علمك وعملك',
        'زادك الله علمًا نافعًا',
        'أثابك الله على طلب العلم',
        'جزاك الله خيرًا على المداومة',
      ];
      encouragement = Encouragement(
        type: EncouragementType.positiveReinforcement,
        message: messages[DateTime.now().day % messages.length],
        icon: '✨',
        tone: EncouragementTone.warm,
      );
    }

    if (encouragement != null) {
      await _prefs.setString(_lastEncouragementKey, today);
    }

    return encouragement;
  }

  /// Get motivational quote for the day (rotating from collection)
  List<DailyQuote>? _quotesCache;
  static const String _lastQuoteDateKey = 'last_quote_date';

  /// Get motivational quote for the day (rotating from collection)
  Future<DailyQuote> getDailyQuote() async {
    await _ensureQuotesLoaded();

    // Emergency fallback if file empty/missing
    if (_quotesCache == null || _quotesCache!.isEmpty) {
      return DailyQuote(
        text: 'من سلك طريقًا يلتمس فيه علمًا سهّل الله له به طريقًا إلى الجنة',
        source: 'رواه مسلم',
        type: QuoteType.hadith,
      );
    }

    final today = _todayKey();
    final lastDate = _prefs.getString(_lastQuoteDateKey);
    var index = _prefs.getInt(_dailyQuoteIndexKey) ?? 0;

    // Only rotate if it's a new day
    if (lastDate != today) {
      index = Random().nextInt(_quotesCache!.length);
      await _prefs.setInt(_dailyQuoteIndexKey, index);
      await _prefs.setString(_lastQuoteDateKey, today);
    }

    return _quotesCache![index % _quotesCache!.length];
  }

  /// Manually cycle to the next quote
  Future<DailyQuote> cycleDailyQuote() async {
    await _ensureQuotesLoaded();
    if (_quotesCache == null || _quotesCache!.isEmpty) {
      return getDailyQuote();
    }

    var index = _prefs.getInt(_dailyQuoteIndexKey) ?? 0;
    index = Random().nextInt(_quotesCache!.length);

    await _prefs.setInt(_dailyQuoteIndexKey, index);
    await _prefs.setString(_lastQuoteDateKey, _todayKey());

    return _quotesCache![index];
  }

  Future<void> _ensureQuotesLoaded() async {
    if (_quotesCache != null) return;
    try {
      String dailyString;
      try {
        dailyString = await rootBundle.loadString(AppAssets.dailyMotivation);
      } catch (_) {
        dailyString = '[]';
      }
      final List<dynamic> dailyList = json.decode(dailyString);
      _quotesCache = dailyList.map((e) => DailyQuote.fromJson(e)).toList();
    } catch (e) {
      _quotesCache = [];
    }
  }

  /// Get gentle re-engagement message (after 3+ days absence)
  Encouragement? getReEngagementMessage(int daysSinceLastRead) {
    if (daysSinceLastRead < 3) return null;

    if (daysSinceLastRead >= 7) {
      return Encouragement(
        type: EncouragementType.reEngagement,
        message: 'افتقدناك يا طالب العلم\nالعودة أفضل من الانقطاع',
        icon: '🤲',
        tone: EncouragementTone.gentle,
      );
    } else if (daysSinceLastRead >= 3) {
      return Encouragement(
        type: EncouragementType.reEngagement,
        message: 'نشتاق لرؤيتك هنا\nلا يثقلن عليك الانقطاع',
        icon: '📖',
        tone: EncouragementTone.gentle,
      );
    }

    return null;
  }

  // ═══════════════════════════════════════════
  // NEXT BEST ACTION ENGINE
  // ═══════════════════════════════════════════

  /// Determines the single best action for the user to take next.
  /// Logic based on:
  /// 1. New user (Start journey)
  /// 2. Lapsed user (Re-engage)
  /// 3. Just finished book (Start next)
  /// 4. In progress (Resume)
  NextBestAction getNextBestAction({
    required MutunProgram program,
    required Map<String, BookProgress> allProgress,
  }) {
    // 1. New User Check
    if (allProgress.isEmpty) {
      final firstBook = _findFirstBook(program);
      return NextBestAction(
        type: NextActionType.startJourney,
        message:
            'استعن بالله وابدأ بـ ${firstBook?.title ?? "الكتاب الأول"}، فهو أول الغيث.',
        label: 'بسم الله أبدأ',
        book: firstBook,
      );
    }

    // 2. Find "Active" Book (Last viewed/modified)
    final sortedProgress = allProgress.values.toList()
      ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));

    final lastInteraction = sortedProgress.first;
    final lastBook = _findBookById(program, lastInteraction.bookId);

    if (lastBook == null) {
      return NextBestAction(
        type: NextActionType.programComplete,
        message: 'واصل رحلة العلم.',
        label: 'المكتبة',
        book: null,
      );
    }

    // 3. Check for Lapsed User (> 3 days)
    final daysSinceLastRead = DateTime.now()
        .difference(lastInteraction.lastReadDate)
        .inDays;
    if (daysSinceLastRead >= 3 && !lastInteraction.isCompleted) {
      return NextBestAction(
        type: NextActionType.reEngage,
        message: 'العلم يزكو بالإنفاق ويثبت بالمداومة. عُد إلى وردك.',
        label: 'استدراك ما فات',
        book: lastBook,
      );
    }

    // 4. Check status of last book
    if (lastInteraction.isCompleted) {
      // Suggest NEXT book
      final nextBook = _findNextBook(program, lastBook);
      if (nextBook != null) {
        return NextBestAction(
          type: NextActionType.startNextBook,
          message: 'هنيئًا لك! واصل الترقي في سلم العلم مع ${nextBook.title}.',
          label: 'الانتقال للتالي',
          book: nextBook,
        );
      } else {
        return NextBestAction(
          type: NextActionType.programComplete,
          message: 'الحمد لله الذي بنعمته تتم الصالحات. أتممت المنهج!',
          label: 'مراجعة الكتب',
          book: null,
        );
      }
    }

    // 5. In Progress
    if (lastInteraction.progressPercentage >= 90) {
      return NextBestAction(
        type: NextActionType.finishBook,
        message: 'فتح الله عليك، بقيت صفحات يسيرة على الختام.',
        label: 'إتمام المتن',
        book: lastBook,
      );
    } else {
      return NextBestAction(
        type: NextActionType.resumeBook,
        message: 'توقفت عند الصفحة ${lastInteraction.currentPage}، واصل مسيرك.',
        label: 'استكمال الورد',
        book: lastBook,
      );
    }
  }

  // ═══════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════

  IlmBook? _findFirstBook(MutunProgram program) {
    for (final level in program.levels) {
      if (level.books.isNotEmpty) return level.books.first;
    }
    return null;
  }

  IlmBook? _findBookById(MutunProgram program, String bookId) {
    for (final level in program.levels) {
      for (final book in level.books) {
        if (book.id == bookId) return book;
      }
    }
    return null;
  }

  IlmBook? _findNextBook(MutunProgram program, IlmBook currentBook) {
    bool foundCurrent = false;
    for (final level in program.levels) {
      for (final book in level.books) {
        if (foundCurrent) return book;
        if (book.id == currentBook.id) foundCurrent = true;
      }
    }
    return null;
  }

  String getContextualMessage({
    required double progressPercent,
    required int pagesRemaining,
  }) {
    if (progressPercent >= 90) {
      return 'شارفت على الختام، بارك الله فيك';
    } else if (progressPercent >= 75) {
      return 'الربع الأخير، أتمه على خير';
    } else if (progressPercent >= 50) {
      return 'انتصف المتن، أعانك الله';
    } else if (progressPercent >= 25) {
      return 'بداية موفقة، سدد الله خطاك';
    } else {
      return 'بسم الله، توكل على الله';
    }
  }

  // ═══════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════

  Set<String> _loadMilestones() {
    final jsonString = _prefs.getString(_milestonesKey);
    if (jsonString == null) return {};

    try {
      final List<dynamic> list = json.decode(jsonString);
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _recordMilestone(String milestone) async {
    final milestones = _loadMilestones();
    milestones.add(milestone);
    await _prefs.setString(_milestonesKey, json.encode(milestones.toList()));
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════

enum MilestoneType {
  firstBook,
  levelComplete,
  weekStreak,
  monthStreak,
  booksCount,
}

class MilestoneTrigger {
  final MilestoneType type;
  final String title;
  final String message;
  final String? verse;
  final String? verseRef;
  final String? hadith;
  final String? hadithRef;
  final String icon;

  MilestoneTrigger({
    required this.type,
    required this.title,
    required this.message,
    this.verse,
    this.verseRef,
    this.hadith,
    this.hadithRef,
    required this.icon,
  });
}

enum EncouragementType { gentleReminder, positiveReinforcement, reEngagement }

enum EncouragementTone { gentle, warm, encouraging }

class Encouragement {
  final EncouragementType type;
  final String message;
  final String icon;
  final EncouragementTone tone;

  Encouragement({
    required this.type,
    required this.message,
    required this.icon,
    required this.tone,
  });
}

enum QuoteType { quran, hadith, scholar }

class DailyQuote {
  final String text;
  final String source;
  final QuoteType type;

  DailyQuote({required this.text, required this.source, required this.type});

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      text: json['text'] as String,
      source: json['source'] as String,
      type: _parseType(json['type'] as String),
    );
  }

  static QuoteType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'quran':
        return QuoteType.quran;
      case 'hadith':
        return QuoteType.hadith;
      case 'scholar':
      default:
        return QuoteType.scholar;
    }
  }
}

enum NextActionType {
  startJourney, // New user
  resumeBook, // Active user
  finishBook, // > 90%
  startNextBook, // Finished one, start next
  reEngage, // Inactive
  programComplete, // Finished everything
}

class NextBestAction {
  final NextActionType type;
  final String message;
  final String label;
  final IlmBook? book;

  NextBestAction({
    required this.type,
    required this.message,
    required this.label,
    this.book,
  });
}
