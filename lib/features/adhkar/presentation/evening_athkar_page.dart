import 'package:flutter/material.dart';
import 'adhkar_session_page.dart';
import '../data/adhkar_models.dart';

class EveningAthkarPage extends StatelessWidget {
  const EveningAthkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdhkarSessionPage(
      category: AdhkarCategory.evening,
    );
  }
}
