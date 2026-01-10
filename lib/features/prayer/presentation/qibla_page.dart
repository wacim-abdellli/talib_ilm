import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/constants/app_strings.dart';
import '../../../shared/widgets/primary_app_bar.dart';

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UnifiedAppBar(
        title: AppStrings.qiblaTitle,
        showBack: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Text(
            AppStrings.qiblaComingSoon,
            style: AppText.body,
          ),
        ),
      ),
    );
  }
}
