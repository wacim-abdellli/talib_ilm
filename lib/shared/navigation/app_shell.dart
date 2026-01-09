import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/pressable_scale.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_ui.dart';

import '../../features/home/presentation/home_page.dart';
import '../../features/prayer/presentation/prayer_page.dart';
import '../../features/adhkar/presentation/adhkar_page.dart';
import '../../features/ilm/presentation/ilm_page.dart';
import '../../features/library/presentation/library_page.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 2});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  Widget _navIcon(IconData icon) {
    return PressableScale(child: Icon(icon));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const IlmPage(),
      const AdhkarPage(),
      HomePage(isActive: _currentIndex == 2),
      const PrayerPage(),
      const LibraryPage(),
    ];

    return Scaffold(
      body: Stack(
        children: List.generate(pages.length, (index) {
          final active = index == _currentIndex;
          return AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: AppUi.animationNormal,
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: !active,
              child: pages[index],
            ),
          );
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: _navIcon(Icons.auto_stories_outlined),
            label: AppStrings.navIlm,
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.self_improvement_outlined),
            label: AppStrings.navAdhkar,
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.home_outlined),
            label: AppStrings.navHome,
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.access_time_outlined),
            label: AppStrings.navPrayer,
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.local_library_outlined),
            label: AppStrings.navLibrary,
          ),
        ],
      ),
    );
  }
}
