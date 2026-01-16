import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class for calm, minimal, and spiritually respectful micro-interactions.
/// Design Philosophy:
/// - "Sakinah" (Tranquility): Movements should be slow and organic, not bouncy.
/// - "Waqar" (Dignity): Feedback should be subtle, not jarring.
class MicroInteractions {
  MicroInteractions._();

  // ═══════════════════════════════════════════
  // 1. HAPTICS (Subtle Feedback)
  // ═══════════════════════════════════════════

  /// A barely perceptible click for standard interactions.
  /// Usage: Tab changes, list item taps, card touches.
  static Future<void> politeTap() async {
    await HapticFeedback.selectionClick();
  }

  /// A gentle impact for confirming actions.
  /// Usage: Bookmarking, saving settings, checkboxes.
  static Future<void> confirm() async {
    await HapticFeedback.lightImpact();
  }

  /// A distinct but soft vibration for achievements.
  /// Usage: Completing a book, finishing a wirth.
  static Future<void> achievement() async {
    await HapticFeedback.mediumImpact();
  }

  // ═══════════════════════════════════════════
  // 2. DURATIONS (Deliberate Timing)
  // ═══════════════════════════════════════════

  // Slower than standard material durations to induce calmness.
  static const Duration fast = Duration(milliseconds: 300); // Standard is 200
  static const Duration medium = Duration(milliseconds: 600); // Standard is 400
  static const Duration slow = Duration(
    milliseconds: 1000,
  ); // For contemplative fades

  // ═══════════════════════════════════════════
  // 3. CURVES (Organic Motion)
  // ═══════════════════════════════════════════

  /// Smooth ease-in-out for general movement.
  static const Curve natural = Curves.easeInOutCubic;

  /// Slow deceleration for entering elements (Respectful entry).
  static const Curve respectfulEntry = Curves.easeOutQuart;

  // ═══════════════════════════════════════════
  // 4. TRANSITION BUILDERS
  // ═══════════════════════════════════════════

  /// A "Breathing" fade effect. Good for text that appears (e.g., intentions).
  static Widget breatheIn(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: natural),
      child: child,
    );
  }

  /// A subtle scale-up effect "Noor" (Light expanding).
  static Widget lightExpand(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: respectfulEntry)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
