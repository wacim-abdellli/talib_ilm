import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/app_overflow_menu.dart';
import '../data/adhkar_models.dart';
import 'adhkar_session_page.dart';

class AdhkarPage extends StatelessWidget {
  const AdhkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final highlights = <AdhkarCategory>[
      AdhkarCategory.morning,
      AdhkarCategory.evening,
    ];
    final secondary = <AdhkarCategory>[
      AdhkarCategory.afterPrayer,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأذكار', style: AppText.headingXL),
        actions: const [AppOverflowMenu()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('أذكار اليوم', style: AppText.heading),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: PageView.builder(
              itemCount: highlights.length,
              controller: PageController(viewportFraction: 0.92),
              reverse: Directionality.of(context) == TextDirection.rtl,
              itemBuilder: (context, index) {
                final category = highlights[index];
                return Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _HighlightCard(
                    category: category,
                    onTap: () => _openSession(context, category),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text('أذكار أخرى', style: AppText.heading),
          const SizedBox(height: 12),
          ...secondary.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PressableCard(
                onTap: () => _openSession(context, category),
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(category.label, style: AppText.heading),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSession(BuildContext context, AdhkarCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdhkarSessionPage(category: category),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final AdhkarCategory category;
  final VoidCallback onTap;

  const _HighlightCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0.2),
        AppColors.primaryAlt.withValues(alpha: 0.12),
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );

    return PressableCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconFor(category),
            color: AppColors.textPrimary.withValues(alpha: 0.7),
          ),
          const Spacer(),
          Text(category.label, style: AppText.heading),
          const SizedBox(height: 6),
          Text(
            'ابدأ بها اليوم',
            style: AppText.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AdhkarCategory category) {
    switch (category) {
      case AdhkarCategory.morning:
        return Icons.wb_sunny_outlined;
      case AdhkarCategory.evening:
        return Icons.nights_stay_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }
}
