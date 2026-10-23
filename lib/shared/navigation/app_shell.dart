import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../core/services/adhkar_reminder_service.dart';
import '../../core/services/fasting_reminder_service.dart';
import '../../core/services/flip_to_stop_service.dart';
import '../../core/services/foreground_prayer_service.dart';
import '../../core/services/home_widget_service.dart';
import '../../core/services/notification_router.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/prayer_schedule_service.dart';
import '../../features/adhkar/presentation/after_prayer_athkar_page.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/icon_badge.dart';
import '../../shared/widgets/nav_bar.dart';
import '../../shared/widgets/notification_onboarding_dialog.dart';

import '../../features/home/presentation/home_page.dart';
import '../../features/prayer/presentation/prayer_page.dart';
import '../../features/adhkar/presentation/adhkar_page.dart';
import '../../features/ilm/presentation/ilm_page.dart';
import '../../features/more/presentation/more_page.dart';
import 'fade_page_route.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({
    super.key,
    this.initialIndex = 0,
  });

  static _AppShellState? _activeState;

  /// Checks if AppShell is mounted and ready to receive navigation actions
  static bool get isAppShellReady =>
      _activeState != null && _activeState!.mounted;

  /// Allows any descendant page or external service to cleanly switch bottom navigation tab
  static bool switchToTab(BuildContext? context, int index) {
    if (context != null) {
      final state = context.findAncestorStateOfType<_AppShellState>();
      if (state != null) {
        state.selectTab(index);
        return true;
      }
    }
    if (_activeState != null && _activeState!.mounted) {
      _activeState!.selectTab(index);
      return true;
    }
    return false;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late int _currentIndex;
  final Set<int> _loadedTabs = <int>{};

  @override
  void initState() {
    super.initState();
    AppShell._activeState = this;
    WidgetsBinding.instance.addObserver(this);
    themeService.addListener(_onThemeChanged);
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _loadedTabs.add(_currentIndex);
    ForegroundPrayerService().start();
    unawaited(_initPrayerNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationOnboardingDialog.checkAndShow(context);
        NotificationRouter.consumePendingPayload(context);
      }
    });
  }

  void _onThemeChanged() {
    unawaited(HomeWidgetService.updateAllWidgets());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ForegroundPrayerService().start();
      unawaited(PrayerScheduleService().refreshSchedulesIfNeeded());
      unawaited(HomeWidgetService.updateAllWidgets(force: true));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      unawaited(HomeWidgetService.updateAllWidgets(force: true));
    }
  }

  Future<void> _initPrayerNotifications() async {
    try {
      final notif = NotificationService();
      await notif.init();
      await PrayerScheduleService().refreshSchedulesIfNeeded();
      unawaited(HomeWidgetService.updateAllWidgets());
      final adhkarService = AdhkarReminderService(notificationService: notif);
      final adhkarSettings = await adhkarService.getSettings();
      await adhkarService.applySchedules(adhkarSettings);
      unawaited(FastingReminderService(notificationService: notif).syncSchedules());
      await FlipToStopService().init();
    } catch (e) {
      debugPrint('AppShell prayer notifications init error: $e');
    }
  }

  @override
  void dispose() {
    if (AppShell._activeState == this) {
      AppShell._activeState = null;
    }
    themeService.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    ForegroundPrayerService().stop();
    FlipToStopService().dispose();
    super.dispose();
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
      body: Stack(
        children: [
          AnimatedIndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          SafeArea(
            child: ValueListenableBuilder<ActivePrayerAlert?>(
              valueListenable: ForegroundPrayerService().activeAlert,
              builder: (context, alert, _) {
                if (alert == null) return const SizedBox.shrink();
                return _buildPrayerAlertBanner(context, alert);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(
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
    );
  }

  Widget _buildPrayerAlertBanner(
    BuildContext context,
    ActivePrayerAlert alert,
  ) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Material(
        color: palette.surfaceRaised,
        elevation: 8,
        borderRadius: AppRadius.lgRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.md),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: palette.gold,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const IconBadge(icon: Icons.mosque_rounded),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حان الآن وقت صلاة ${alert.prayerName}',
                          style: textTheme.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          alert.prayerName.contains('فجر')
                              ? 'الصلاة خير من النوم.. حي على الصلاة'
                              : 'حي على الصلاة.. حي على الفلاح',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'إغلاق التنبيه',
                    color: palette.textMuted,
                    onPressed: () => ForegroundPrayerService().dismissAlert(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: 'إيقاف الأذان',
                    size: AppButtonSize.sm,
                    icon: Icons.volume_off_rounded,
                    onPressed: () => ForegroundPrayerService().dismissAlert(),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  AppButton(
                    label: 'أذكار الصلاة',
                    size: AppButtonSize.sm,
                    icon: Icons.menu_book_rounded,
                    onPressed: () {
                      ForegroundPrayerService().dismissAlert();
                      Navigator.push(
                        context,
                        buildFadeRoute(
                          page: AfterPrayerAthkarPage(
                            prayerName: alert.prayerName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
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
