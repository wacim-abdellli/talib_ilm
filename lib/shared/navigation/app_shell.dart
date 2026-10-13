import 'package:flutter/material.dart';

import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../shared/widgets/nav_bar.dart';

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
  final Set<int> _loadedTabs = <int>{};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _loadedTabs.add(_currentIndex);
  }

  void selectTab(int index) {
    final clamped = index.clamp(0, 4);
    if (_currentIndex != clamped && mounted) {
      setState(() {
        _currentIndex = clamped;
        _loadedTabs.add(clamped);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _loadedTabs.contains(0)
          ? TickerMode(
              enabled: _currentIndex == 0,
              child: HomePage(isActive: _currentIndex == 0),
            )
          : const SizedBox.shrink(),
      _loadedTabs.contains(1)
          ? TickerMode(
              enabled: _currentIndex == 1,
              child: const PrayerPage(),
            )
          : const SizedBox.shrink(),
      _loadedTabs.contains(2)
          ? TickerMode(
              enabled: _currentIndex == 2,
              child: const IlmPage(),
            )
          : const SizedBox.shrink(),
      _loadedTabs.contains(3)
          ? TickerMode(
              enabled: _currentIndex == 3,
              child: const AdhkarPage(),
            )
          : const SizedBox.shrink(),
      _loadedTabs.contains(4)
          ? TickerMode(
              enabled: _currentIndex == 4,
              child: const MorePage(),
            )
          : const SizedBox.shrink(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedIndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavBar(
          currentIndex: _currentIndex,
          onTap: selectTab,
          items: const [
            NavBarItem(
              icon: Icons.home_rounded,
              label: AppStrings.navHome,
            ),
            NavBarItem(
              icon: Icons.access_time_rounded,
              label: AppStrings.navPrayer,
            ),
            NavBarItem(
              icon: Icons.auto_stories_rounded,
              label: 'العلم',
            ),
            NavBarItem(
              icon: Icons.spa_rounded,
              label: 'الأذكار',
            ),
            NavBarItem(
              icon: Icons.dashboard_rounded,
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }
}

/// Fast, smooth transitions between persistent stacked pages preserving state
class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = AppMotion.fast,
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppMotion.easeOut,
      ),
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _currentIndex = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: IndexedStack(
        index: _currentIndex,
        children: widget.children,
      ),
    );
  }
}
