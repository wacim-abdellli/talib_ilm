import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('اتجاه القبلة', style: AppText.headingXL),
      ),
      body: const Center(
        child: Text(
          'بوصلة القبلة ستضاف قريبًا',
          style: AppText.body,
        ),
      ),
    );
  }
}
