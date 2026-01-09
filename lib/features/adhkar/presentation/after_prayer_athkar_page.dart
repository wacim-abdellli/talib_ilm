import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import 'adhkar_session_page.dart';
import '../data/adhkar_models.dart';

class AfterPrayerAthkarPage extends StatelessWidget {
  final String? prayerName;

  const AfterPrayerAthkarPage({super.key, this.prayerName});

  @override
  Widget build(BuildContext context) {
    final contextLabel = AppStrings.afterPrayerTitle(prayerName);
    return AdhkarSessionPage(
      category: AdhkarCategory.afterPrayer,
      contextLabel: contextLabel,
    );
  }
}
