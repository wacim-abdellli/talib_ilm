import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_ui.dart';
import '../../app/theme/theme_colors.dart';

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
  });

  /// Allows any descendant page to cleanly switch bottom navigation tab
  static bool switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    if (state != null) {
      state.selectTab(index);
      return true;
    }
    return false;
  }

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

  void selectTab(int index) {
    if (_currentIndex != index && mounted) {
      setState(() => _currentIndex = index.clamp(0, 4));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(isActive: _currentIndex == 0),
      const PrayerPage(),
      const IlmPage(),
      const AdhkarPage(),
      const MorePage(),
    ];

    final isDark = context.isDark;

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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF182222).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? context.primaryColor.withValues(alpha: 0.25)
                    : context.outlineVariantColor,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'الرئيسية',
                ),
                _buildNavItem(
                  1,
                  Icons.access_time_filled_rounded,
                  Icons.access_time_rounded,
                  'الصلاة',
                ),
                _buildNavItem(
                  2,
                  Icons.auto_stories_rounded,
                  Icons.auto_stories_outlined,
                  'العلم',
                ),
                _buildNavItem(
                  3,
                  Icons.spa_rounded,
                  Icons.spa_outlined,
                  'الأذكار',
                ),
                _buildNavItem(
                  4,
                  Icons.dashboard_rounded,
                  Icons.dashboard_outlined,
                  'المزيد',
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
  ) {
    final isActive = _currentIndex == index;
    final isDark = context.isDark;

    final Color activeColor = context.primaryColor;
    final Color inactiveColor = context.textTertiaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isActive ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: isActive ? 52 : 40,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            activeColor.withValues(alpha: isDark ? 0.28 : 0.16),
                            activeColor.withValues(alpha: isDark ? 0.14 : 0.08),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  size: isActive ? 22 : 20,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                  height: 1,
                  fontFamily: 'Cairo',
                ),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

