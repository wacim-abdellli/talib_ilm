import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/services/motivation_service.dart';

/// Displays daily motivational quote from Quran/Hadith
class DailyMotivationCard extends StatelessWidget {
  final DailyQuote quote;
  final VoidCallback? onReload;

  const DailyMotivationCard({super.key, required this.quote, this.onReload});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    Color accentColor;
    String typeLabel;
    IconData typeIcon;

    switch (quote.type) {
      case QuoteType.quran:
        accentColor = const Color(0xFF2E7D32);
        typeLabel = 'قرآن كريم';
        typeIcon = Icons.menu_book;
        break;
      case QuoteType.hadith:
        accentColor = const Color(0xFF1976D2);
        typeLabel = 'حديث نبوي';
        typeIcon = Icons.format_quote;
        break;
      case QuoteType.scholar:
        accentColor = AppColors.primary;
        typeLabel = 'قول مأثور';
        typeIcon = Icons.lightbulb_outline;
        break;
    }

    return Container(
      padding: EdgeInsets.all(responsive.wp(4.5)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accentColor.withValues(alpha: 0.08),
            accentColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          Row(
            children: [
              Icon(typeIcon, size: responsive.sp(14), color: accentColor),
              SizedBox(width: 6),
              Text(
                typeLabel,
                style: TextStyle(
                  fontSize: responsive.sp(12),
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: '${quote.text}\n\n${quote.source}'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم النسخ', textAlign: TextAlign.center),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: accentColor.withValues(alpha: 0.6),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (onReload != null) ...[
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onReload,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color: accentColor,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),

          SizedBox(height: responsive.hp(1.2)),

          // Quote text
          Text(
            quote.text,
            style: TextStyle(
              fontSize: responsive.sp(15),
              height: 1.8,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),

          SizedBox(height: responsive.hp(1)),

          // Source
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '— ${quote.source}',
                style: TextStyle(
                  fontSize: responsive.sp(12),
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows milestone achievement celebration dialog
class MilestoneCelebrationDialog extends StatelessWidget {
  final MilestoneTrigger milestone;

  const MilestoneCelebrationDialog({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: responsive.wp(85)),
        padding: EdgeInsets.all(responsive.wp(6)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDF7), Color(0xFFFFF9E6)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: responsive.wp(20),
              height: responsive.wp(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    const Color(0xFFE8C252).withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  milestone.icon,
                  style: TextStyle(fontSize: responsive.sp(40)),
                ),
              ),
            ),

            SizedBox(height: responsive.hp(2)),

            // Title
            Text(
              milestone.title,
              style: TextStyle(
                fontSize: responsive.sp(20),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: responsive.hp(1)),

            // Message
            Text(
              milestone.message,
              style: TextStyle(
                fontSize: responsive.sp(14),
                height: 1.6,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Verse or Hadith
            if (milestone.verse != null || milestone.hadith != null) ...[
              SizedBox(height: responsive.hp(2)),
              Container(
                padding: EdgeInsets.all(responsive.wp(4)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      milestone.verse ?? milestone.hadith ?? '',
                      style: TextStyle(
                        fontSize: responsive.sp(13),
                        height: 1.7,
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: responsive.hp(0.8)),
                    Text(
                      milestone.verseRef ?? milestone.hadithRef ?? '',
                      style: TextStyle(
                        fontSize: responsive.sp(11),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: responsive.hp(2.5)),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: responsive.hp(1.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'الحمد لله',
                  style: TextStyle(
                    fontSize: responsive.sp(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, MilestoneTrigger milestone) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MilestoneCelebrationDialog(milestone: milestone),
    );
  }
}

/// Small encouragement banner (for gentle reminders)
class EncouragementBanner extends StatelessWidget {
  final Encouragement encouragement;
  final VoidCallback? onDismiss;

  const EncouragementBanner({
    super.key,
    required this.encouragement,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    Color backgroundColor;
    Color textColor;

    switch (encouragement.tone) {
      case EncouragementTone.gentle:
        backgroundColor = const Color(0xFFFFF9E6);
        textColor = const Color(0xFF8B6914);
        break;
      case EncouragementTone.warm:
        backgroundColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF166534);
        break;
      case EncouragementTone.encouraging:
        backgroundColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1E40AF);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.wp(4),
        vertical: responsive.hp(1.2),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            encouragement.icon,
            style: TextStyle(fontSize: responsive.sp(18)),
          ),
          SizedBox(width: responsive.wp(3)),
          Expanded(
            child: Text(
              encouragement.message,
              style: TextStyle(
                fontSize: responsive.sp(13),
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                size: responsive.sp(16),
                color: textColor.withValues(alpha: 0.6),
              ),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Progress insight card (non-competitive analytics)
class ProgressInsightCard extends StatelessWidget {
  final String insight;
  final String detail;
  final IconData icon;
  final Color color;

  const ProgressInsightCard({
    super.key,
    required this.insight,
    required this.detail,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Container(
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(responsive.wp(2.5)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: responsive.sp(20), color: color),
          ),
          SizedBox(width: responsive.wp(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: responsive.sp(12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contextual progress message (shown in book view)
class ContextualProgressMessage extends StatelessWidget {
  final String message;

  const ContextualProgressMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.wp(3),
        vertical: responsive.hp(0.8),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: responsive.sp(14),
            color: AppColors.primary,
          ),
          SizedBox(width: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: responsive.sp(12),
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
