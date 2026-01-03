import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/pressable_scale.dart';

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
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
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
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: _navIcon(Icons.auto_stories),
            label: 'العلم',
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.self_improvement),
            label: 'الأذكار',
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.access_time),
            label: 'الصلاة',
          ),
          BottomNavigationBarItem(
            icon: _navIcon(Icons.local_library),
            label: 'المكتبة',
          ),
        ],
      ),
    );
  }
}
