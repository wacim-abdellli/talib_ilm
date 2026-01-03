import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../shared/widgets/primary_app_bar.dart';

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PrimaryAppBar(
        title: 'اتجاه القبلة',
        showBack: true,
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
