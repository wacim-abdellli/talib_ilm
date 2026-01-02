import 'package:flutter/material.dart';
import 'adhkar_session_page.dart';
import '../data/adhkar_models.dart';

class MorningAthkarPage extends StatelessWidget {
  const MorningAthkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdhkarSessionPage(
      category: AdhkarCategory.morning,
    );
  }
}
