import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_ui.dart';

import '../../features/home/presentation/home_page.dart';
import '../../features/prayer/presentation/prayer_page.dart';
import '../../features/adhkar/presentation/adhkar_page.dart';
import '../../features/ilm/presentation/ilm_page.dart';
import '../../features/more/presentation/more_page.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({
    super.key,
    this.initialIndex = 0,
  }); // Default to Home which is usually first index in simpler layouts, but here we will rearrange to match new specs

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

  // Define Pages: Home, Prayer, Ilm, Adhkar, More (Library)
  // Mapping based on USER REQUEST icons:
  // 0: Home (Icons.home_rounded)
  // 1: Prayer (Icons.access_time_rounded)
  // 2: Ilm (Icons.menu_book_rounded)
  // 3: Adhkar (Icons.auto_awesome_rounded)
  // 4: More/Library (Icons.more_horiz_rounded)

  @override
  Widget build(BuildContext context) {
    // Re-ordering pages to match the new nav bar order request
    final pages = [
      HomePage(isActive: _currentIndex == 0),
      const PrayerPage(),
      const IlmPage(),
      const AdhkarPage(),
      const MorePage(),
    ];

    return Scaffold(
      extendBody:
          true, // Important for floating/rounded effects if needed, but safe here with solid container
      body: Stack(
        children: List.generate(pages.length, (index) {
          final active = index == _currentIndex;
          return AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: AppUi.animationNormal,
            curve: Curves.easeOut,
            child: IgnorePointer(ignoring: !active, child: pages[index]),
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  'الرئيسية',
                  const Color(0xFF14B8A6),
                ),
                _buildNavItem(
                  1,
                  Icons.access_time_rounded,
                  'الصلاة',
                  const Color(0xFF3B82F6),
                ),
                _buildNavItem(
                  2,
                  Icons.menu_book_rounded,
                  'العلم',
                  const Color(0xFF8B5CF6),
                ),
                _buildNavItem(
                  3,
                  Icons.auto_awesome_rounded,
                  'الأذكار',
                  const Color(0xFFF59E0B),
                ),
                _buildNavItem(
                  4,
                  Icons.more_horiz_rounded,
                  'المزيد',
                  const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color color) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isActive ? 24 : 22,
              color: isActive ? color : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? color : const Color(0xFF94A3B8),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
