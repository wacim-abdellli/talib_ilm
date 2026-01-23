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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF000000) : const Color(0xFFFBFAF8);
    final navBorder = isDark
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFE8E6E3);

    return Scaffold(
      extendBody: true,
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
          color: navBg,
          border: Border(top: BorderSide(color: navBorder, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'الرئيسية',
                  isDark ? const Color(0xFF00D9C0) : null,
                ),
                _buildNavItem(
                  1,
                  Icons.access_time_filled_rounded,
                  Icons.access_time_rounded,
                  'الصلاة',
                  isDark ? const Color(0xFF3B9EFF) : null,
                ),
                _buildNavItem(
                  2,
                  Icons.auto_stories_rounded,
                  Icons.auto_stories_outlined,
                  'العلم',
                  isDark ? const Color(0xFFA855F7) : null,
                ),
                _buildNavItem(
                  3,
                  Icons.spa_rounded,
                  Icons.spa_outlined,
                  'الأذكار',
                  isDark ? const Color(0xFFFFD600) : null, // Gold
                ),
                _buildNavItem(
                  4,
                  Icons.dashboard_rounded,
                  Icons.dashboard_outlined,
                  'المزيد',
                  isDark ? const Color(0xFFFFFFFF) : null, // White for More
                  gradientBase: isDark ? const Color(0xFF666666) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    Color? darkActiveColor, {
    Color? gradientBase,
  }) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve Colors
    final Color activeColor = isDark
        ? (darkActiveColor ?? const Color(0xFF6A9A9A))
        : const Color(0xFF6A9A9A);

    final Color inactiveColor = isDark
        ? const Color(0xFF666666)
        : const Color(0xFF9A9A9A);

    final Color labelColor = (isDark && isActive)
        ? const Color(0xFFFFFFFF)
        : (isActive ? activeColor : inactiveColor);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isActive ? 64 : 48,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isActive && isDark
                    ? LinearGradient(
                        colors: [
                          activeColor.withValues(alpha: 0.25),
                          activeColor.withValues(alpha: 0.1),
                        ],
                      )
                    : (isActive
                          ? LinearGradient(
                              colors: [
                                activeColor.withValues(alpha: 0.15),
                                activeColor.withValues(alpha: 0.08),
                              ],
                            )
                          : null),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isActive && isDark
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(
                            alpha: 0.2,
                          ), // Reduced from 0.4
                          blurRadius: 8, // Reduced from 12
                          spreadRadius: -4, // Reduced from -2
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                size: isActive ? 26 : 24,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
                height: 1,
                fontFamily: 'Cairo',
              ),
              child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
