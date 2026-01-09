import 'package:flutter/material.dart';
import '../../../../app/theme/app_ui.dart';

class HomeZone extends StatelessWidget {
  final Widget child;

  const HomeZone({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppUi.gapLG,
      ),
      child: child,
    );
  }
}
