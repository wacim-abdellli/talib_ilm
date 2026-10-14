import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/navigation/fade_page_route.dart';

/// Luxury Islamic landing splash screen with illuminated Basmalah,
/// sacred emblem, fluid entrance animation, and fast seamless auto-navigation.
class SplashPage extends StatefulWidget {
  final bool autoNavigate;

  const SplashPage({
    super.key,
    this.autoNavigate = true,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _emblemScale;
  late final Animation<double> _emblemFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _bottomFade;

  Timer? _timer;
  bool _navigated = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.splash,
    );

    // Staggered fluid entrance animations
    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: AppMotion.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: AppMotion.easeOut),
    ));

    _emblemScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.85, curve: AppMotion.easeOut),
      ),
    );

    _emblemFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.85, curve: AppMotion.easeIn),
    );

    _titleFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.95, curve: AppMotion.easeIn),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.95, curve: AppMotion.easeOut),
    ));

    _bottomFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.55, 1.0, curve: AppMotion.easeIn),
    );

    _animController.forward();

    if (widget.autoNavigate) {
      _startStartupInitialization();
    }
  }

  Future<void> _startStartupInitialization() async {
    // Warm up repository and prayer schedules in background without blocking UI
    unawaited(QuranRepository.instance.ensureLoaded(604).catchError((_) {}));
    unawaited(PrayerScheduleService().refreshSchedulesIfNeeded().catchError((_) {}));

    final elapsed = DateTime.now().difference(_startTime ?? DateTime.now());
    final totalSplashDuration = AppMotion.splash + AppMotion.oneSecond;
    final remaining = totalSplashDuration - elapsed;

    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    _proceedToHome();
  }

  void _proceedToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        buildFadeRoute(page: const AppShell()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: InkWell(
          onTap: _proceedToHome,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
              vertical: AppSpace.lg,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Top Section: Majestic Golden Calligraphic Basmalah
                          SlideTransition(
                            position: _headerSlide,
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  top: AppSpace.xl,
                                ),
                                child: Semantics(
                                  header: true,
                                  label: 'بسم الله الرحمن الرحيم',
                                  child: Text(
                                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                    textAlign: TextAlign.center,
                                    style: textTheme.sacredLarge.copyWith(
                                      color: palette.gold,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 2. Center Section: Squircle Badge with New Logo, Title, and Subtitle
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              vertical: AppSpace.xl,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Squircle Badge with Ambient Glow
                                ScaleTransition(
                                  scale: _emblemScale,
                                  child: FadeTransition(
                                    opacity: _emblemFade,
                                    child: Semantics(
                                      label: 'شعار تطبيق طالب العلم',
                                      image: true,
                                      child: Container(
                                        width: 128,
                                        height: 128,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: palette.surfaceRaised,
                                          borderRadius: AppRadius.xlRadius,
                                          border: Border.all(
                                            color: palette.gold.withValues(alpha: 0.28),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Image.asset(
                                          palette.logoSymbol,
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: AppSpace.lg),

                                // Animated Title & Subtitle
                                SlideTransition(
                                  position: _titleSlide,
                                  child: FadeTransition(
                                    opacity: _titleFade,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // App Name
                                        Text(
                                          'طَالِبُ العِلْمِ',
                                          textAlign: TextAlign.center,
                                          style: textTheme.display.copyWith(
                                            color: palette.text,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),

                                        const SizedBox(height: AppSpace.xs),

                                        // Sacred Tagline
                                        Text(
                                          'زَادُ الْمُسْلِمِ فِي طَلَبِ الْعِلْمِ النَّافِعِ',
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodySmall.copyWith(
                                            color: palette.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Bottom Section: Golden Progress Line & Prophetic Hadith
                          FadeTransition(
                            opacity: _bottomFade,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                bottom: AppSpace.md,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Sleek Golden Progress Bar
                                  SizedBox(
                                    width: 96,
                                    child: ClipRRect(
                                      borderRadius: AppRadius.pillRadius,
                                      child: AnimatedBuilder(
                                        animation: _animController,
                                        builder: (context, _) =>
                                            LinearProgressIndicator(
                                          value: _animController.value,
                                          backgroundColor: palette.goldSoft,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            palette.gold,
                                          ),
                                          minHeight: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: AppSpace.sm),

                                  // Prophetic Hadith
                                  Text(
                                    '«مَنْ سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقاً إِلَى الْجَنَّةِ»',
                                    textAlign: TextAlign.center,
                                    style: textTheme.caption.copyWith(
                                      color: palette.textSubtle,
                                      fontStyle: FontStyle.italic,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
