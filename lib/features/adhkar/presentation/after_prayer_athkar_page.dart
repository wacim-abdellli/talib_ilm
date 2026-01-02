import 'package:flutter/material.dart';
import 'adhkar_session_page.dart';
import '../data/adhkar_models.dart';

class AfterPrayerAthkarPage extends StatelessWidget {
  final String? prayerName;

  const AfterPrayerAthkarPage({super.key, this.prayerName});

  @override
  Widget build(BuildContext context) {
    final contextLabel =
        prayerName == null ? 'بعد الصلاة' : 'بعد صلاة $prayerName';
    return AdhkarSessionPage(
      category: AdhkarCategory.afterPrayer,
      contextLabel: contextLabel,
    );
  }
}
