import 'dart:math';

/// A utility class for "Psychological" progress feedback.
/// Design Philosophy:
/// - No Points/XP -> Focus on Barakah (Blessing).
/// - No Streak Shame -> Focus on Thabat (Steadfastness).
/// - No Competitiveness -> Focus on Niyyah (Intention).
class ProgressPsychology {
  ProgressPsychology._();

  // ═══════════════════════════════════════════
  // 1. PROGRESS LABELS (Planting Metaphor)
  // ═══════════════════════════════════════════

  /// Returns a metaphorical label for progress based on percentage.
  /// Uses the concept of "Planting Knowledge" (Gharas al-Ilm).
  static String getProgressLabel(double percent) {
    if (percent <= 0) return 'بذر النية'; // Sowing the intention
    if (percent < 25) return 'أول الغيث'; // First rain
    if (percent < 50) return 'سقي الغرس'; // Watering the planting
    if (percent < 75) return 'اشتداد العود'; // Strengthening of the stem
    if (percent < 100) return 'قرب الحصاد'; // Approaching harvest
    return 'جني الثمار'; // Harvesting fruits
  }

  // ═══════════════════════════════════════════
  // 2. CONSISTENCY (Thabat over Streaks)
  // ═══════════════════════════════════════════

  /// Returns encouragement based on days active.
  /// Avoids "chains" or "breaking" terminology.
  static String getConsistencyMessage(int days) {
    if (days <= 1) {
      return 'خطوة في طريق العلم'; // A step on the path of knowledge
    }
    if (days < 7) return 'بداية المواظبة'; // Beginning of consistency
    if (days < 30) return 'ثبات مبارك'; // Blessed steadfastness
    if (days < 40) return 'عادة في الخير'; // A habit in goodness
    return 'من المداومين بإذن الله'; // Among the consistent ones, by Allah's permission
  }

  // ═══════════════════════════════════════════
  // 3. INTENTION REMINDERS (Niyyah)
  // ═══════════════════════════════════════════

  /// Random Niyyah updates to rotate silently.
  static String getIntentionReminder() {
    final reminders = [
      'نويت رفع الجهل عن نفسي وعن غيري', // Remove ignorance
      'اللهم اجعل هذا العمل خالصاً لوجهك الكريم', // Purely for Your face
      'طلب العلم فريضة، وتقرب إلى الله', // Seeking knowledge is obligatory/closeness
      'أحياء للعلم وحفظ للشريعة', // Reviving knowledge and preserving Sharia
    ];
    return reminders[Random().nextInt(reminders.length)];
  }

  // ═══════════════════════════════════════════
  // 4. CLOSING DUAS (Post-Reading)
  // ═══════════════════════════════════════════

  static String getPostReadingDua() {
    return 'اللهم انفعني بما علمتني، وعلمني ما ينفعني، وزدني علمًا';
  }

  // ═══════════════════════════════════════════
  // UI PLACEMENT SUGGESTIONS
  // ═══════════════════════════════════════════
  // - Intention Reminder: Fade in at the top of the reading page for 3 seconds then fade out.
  // - Progress Label: Display subtle text under the progress bar in the Book Card.
  // - Consistency: Display in the profile summary, "Thabat: X Days".
}
