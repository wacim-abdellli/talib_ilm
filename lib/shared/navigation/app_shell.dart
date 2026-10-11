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

/// Smoothly transitions between persistent stacked pages preserving state
class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = AppMotion.base,
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _currentIndex;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = null;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOut,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _previousIndex = null;
        });
      }
    });
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _previousIndex = _currentIndex;
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
    final orderedIndices = <int>[];
    for (var i = 0; i < widget.children.length; i++) {
      if (i != _currentIndex && i != _previousIndex) {
        orderedIndices.add(i);
      }
    }
    if (_previousIndex != null && _previousIndex != _currentIndex) {
      orderedIndices.add(_previousIndex!);
    }
    orderedIndices.add(_currentIndex);

    return Stack(
      fit: StackFit.expand,
      children: orderedIndices.map((i) {
        final isCurrent = i == _currentIndex;
        final isPrevious = i == _previousIndex;

        if (!isCurrent && !isPrevious) {
          return KeyedSubtree(
            key: ValueKey(i),
            child: Offstage(
              offstage: true,
              child: TickerMode(
                enabled: false,
                child: widget.children[i],
              ),
            ),
          );
        }

        if (isCurrent) {
          Widget child = widget.children[i];
          if (_previousIndex != null) {
            child = FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.012),
                  end: Offset.zero,
                ).animate(_animation),
                child: child,
              ),
            );
          }
          return KeyedSubtree(
            key: ValueKey(i),
            child: IgnorePointer(
              ignoring: false,
              child: TickerMode(
                enabled: true,
                child: child,
              ),
            ),
          );
        }

        // Previous index is visible underneath during animation, with touches disabled
        return KeyedSubtree(
          key: ValueKey(i),
          child: IgnorePointer(
            ignoring: true,
            child: TickerMode(
              enabled: false,
              child: widget.children[i],
            ),
          ),
        );
      }).toList(),
    );
  }
}
