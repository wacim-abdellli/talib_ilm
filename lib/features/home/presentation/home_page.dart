import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الرئيسية',
          style: AppText.heading,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _PrayerCard(),
            SizedBox(height: 16),
            _AdhkarCard(),
            SizedBox(height: 16),
            _ContinueIlmCard(),
          ],
        ),
      ),
    );
  }
}
class _PrayerCard extends StatelessWidget {
  const _PrayerCard();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('الصلاة', style: AppText.heading),
          SizedBox(height: 8),
          Text(
            'الصلاة القادمة: الظهر',
            style: AppText.ui,
          ),
          SizedBox(height: 4),
          Text(
            'بعد 01:25 ساعة',
            style: AppText.secondary,
          ),
        ],
      ),
    );
  }
}
class _AdhkarCard extends StatelessWidget {
  const _AdhkarCard();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('الأذكار اليومية', style: AppText.heading),
          SizedBox(height: 8),
          Text(
            'أذكار الصباح',
            style: AppText.ui,
          ),
          SizedBox(height: 4),
          Text(
            'لم تبدأ بعد',
            style: AppText.secondary,
          ),
        ],
      ),
    );
  }
}
class _ContinueIlmCard extends StatelessWidget {
  const _ContinueIlmCard();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('تابع طلب العلم', style: AppText.heading),
          SizedBox(height: 8),
          Text(
            'المستوى التمهيدي',
            style: AppText.ui,
          ),
          SizedBox(height: 4),
          Text(
            'الأصول الثلاثة',
            style: AppText.secondary,
          ),
        ],
      ),
    );
  }
}
class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
