import 'package:flutter/material.dart';
import 'adhkar_session_page.dart';
import '../data/adhkar_models.dart';

class SleepingAthkarPage extends StatelessWidget {
  const SleepingAthkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdhkarSessionPage(category: AdhkarCategory.sleeping);
  }
}
