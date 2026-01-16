import 'package:flutter/material.dart';
import '../../../../shared/widgets/empty_state.dart';

/// Islamic-friendly empty state configurations for the Ilm page.
/// These states provide motivational context using scholarly tone.
class IlmEmptyStates {
  IlmEmptyStates._();

  /// 1. New User (No Progress)
  /// "The beginning of rain is a drop. Seek help from Allah and start."
  static Widget newUser({required VoidCallback onStart}) {
    return EmptyState(
      icon: Icons.spa_outlined,
      title: 'بداية الغيث قطرة',
      subtitle: 'استعن بالله وابدأ رحلتك في طلب العلم من هنا.',
      actionLabel: 'بسم الله أبدأ',
      onAction: onStart,
    );
  }

  /// 2. Lapsed User (Stopped for 7+ days)
  /// "We missed you! A little continuous is better than a lot interrupted."
  static Widget lapsedUser({required VoidCallback onResume}) {
    return EmptyState(
      icon: Icons.auto_stories_outlined,
      title: 'اشتقنا إليك!',
      subtitle: 'قليل دائم خير من كثير منقطع. عُد إلى وردك.',
      actionLabel: 'استدراك ما فات',
      onAction: onResume,
    );
  }

  /// 3. Completed Book
  /// "Congratulations! A big step. Don't stop, knowledge is a sea."
  static Widget bookCompleted({required VoidCallback onNext}) {
    return EmptyState(
      icon: Icons.verified_outlined,
      title: 'مبارك! خطوة كبيرة',
      subtitle: 'أنهيت هذا المتن بفضل الله. لا تتوقف، فالعلم بحر.',
      actionLabel: 'الانتقال للكتاب التالي',
      onAction: onNext,
    );
  }
}
