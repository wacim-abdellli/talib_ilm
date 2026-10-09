import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';

/// Modern loading indicator with teal color
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const AppLoadingIndicator({super.key, this.size = 40, this.strokeWidth = 3});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: context.primaryColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Empty state widget for when there's no content
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
      icon: Icons.bookmark_border,
      title: 'لا توجد مفضلات بعد',
      subtitle: 'ابدأ بإضافة المحتوى المفضل لديك',
    );
  }

  /// Factory for search empty state
  factory AppEmptyState.search() {
    return const AppEmptyState(
      icon: Icons.search_off,
      title: 'لا توجد نتائج',
      subtitle: 'جرب كلمات بحث مختلفة',
    );
  }

  /// Factory for books empty state
  factory AppEmptyState.books() {
    return const AppEmptyState(
      icon: Icons.menu_book_outlined,
      title: 'لا توجد كتب',
      subtitle: 'ستظهر الكتب هنا قريباً',
    );
  }

  /// Factory for prayers empty state
  factory AppEmptyState.prayers() {
    return const AppEmptyState(
      icon: Icons.access_time_outlined,
      title: 'جارٍ تحميل أوقات الصلاة',
      subtitle: 'يرجى الانتظار...',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: context.textTertiaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 15, color: context.textTertiaryColor),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
