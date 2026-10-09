import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

/// Modern loading indicator using theme tokens
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const AppLoadingIndicator({super.key, this.size = 40, this.strokeWidth = 3});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: palette.primary,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Empty state widget conforming to Calm Scholar design direction
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  /// Factory for favorites empty state
  factory AppEmptyState.favorites() {
    return const AppEmptyState(
      icon: Icons.bookmark_border_rounded,
      title: 'لا توجد مفضلات بعد',
      subtitle: 'ابدأ بإضافة المحتوى المفضل لديك',
    );
  }

  /// Factory for search empty state
  factory AppEmptyState.search() {
    return const AppEmptyState(
      icon: Icons.search_off_rounded,
      title: 'لا توجد نتائج',
      subtitle: 'جرب كلمات بحث مختلفة',
    );
  }

  /// Factory for books empty state
  factory AppEmptyState.books() {
    return const AppEmptyState(
      icon: Icons.menu_book_rounded,
      title: 'لا توجد كتب',
      subtitle: 'ستظهر الكتب هنا قريباً',
    );
  }

  /// Factory for prayers empty state
  factory AppEmptyState.prayers() {
    return const AppEmptyState(
      icon: Icons.access_time_rounded,
      title: 'جارٍ تحميل أوقات الصلاة',
      subtitle: 'يرجى الانتظار...',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 96px primarySoft circle with 40 icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: AppIcon.hero,
                  color: palette.onPrimarySoft,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              title,
              style: textTheme.titleSmall.copyWith(color: palette.text),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpace.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  subtitle!,
                  style: textTheme.bodySmall.copyWith(color: palette.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpace.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
