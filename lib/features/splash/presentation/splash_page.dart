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
      duration: AppMotion.deliberate + AppMotion.oneSecond,
    );

    // Staggered fluid entrance animations
    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: AppMotion.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: AppMotion.easeOut),
    ));

    _emblemScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.75, curve: AppMotion.easeOut),
      ),
    );

    _emblemFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.75, curve: AppMotion.easeIn),
    );

    _titleFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.85, curve: AppMotion.easeIn),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.85, curve: AppMotion.easeOut),
    ));

    _bottomFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.50, 0.95, curve: AppMotion.easeIn),
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
    final totalSplashDuration = AppMotion.deliberate + AppMotion.oneSecond + AppMotion.base;
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
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: AppPalette.splashWhite,
      body: SafeArea(
        child: InkWell(
          onTap: _proceedToHome,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
              vertical: AppSpace.md,
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
                          // 1. Top Section: Noble Salam & Prominent Sacred Basmalah
                          SlideTransition(
                            position: _headerSlide,
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  top: AppSpace.sm,
                                ),
                                child: Semantics(
                                  header: true,
                                  label: 'السلام عليكم ورحمة الله وبركاته',
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Noble Salam Greeting
                                      Text(
                                        'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ',
                                        textAlign: TextAlign.center,
                                        style: textTheme.label.copyWith(
                                          color: AppPalette.splashGold,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),

                                      const SizedBox(height: AppSpace.xs),

                                      // Prominent Sacred Basmalah with ornamental delimiters
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '۞',
                                            style: textTheme.sacred.copyWith(
                                              color: AppPalette.splashGold,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpace.sm),
                                          Flexible(
                                            child: Text(
                                              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                              textAlign: TextAlign.center,
                                              style: textTheme.sacredLarge.copyWith(
                                                color: AppPalette.splashGold,
                                                fontWeight: FontWeight.bold,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpace.sm),
                                          Text(
                                            '۞',
                                            style: textTheme.sacred.copyWith(
                                              color: AppPalette.splashGold,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 2. Center Section: Squircle Badge with New Logo, Title, and Subtitle
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              vertical: AppSpace.md,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Squircle Badge with New Brand Logo
                                ScaleTransition(
                                  scale: _emblemScale,
                                  child: FadeTransition(
                                    opacity: _emblemFade,
                                    child: Semantics(
                                      label: 'شعار تطبيق طالب العلم',
                                      image: true,
                                      child: Container(
                                        width: 130,
                                        height: 130,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppPalette.splashWhite,
                                          borderRadius: AppRadius.xlRadius,
                                          border: Border.all(
                                            color: AppPalette.splashGold
                                                .withValues(alpha: 0.35),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Image.asset(
                                          'assets/branding/symbol_on_light.png',
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: AppSpace.lg),

                                // Animated Title, Subtitle, and Quranic Du'a
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
                                            color: AppPalette.splashText,
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
                                            color: AppPalette.splashTextMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        const SizedBox(height: AppSpace.sm),

                                        // Minimalist Qur'anic Prayer Chip
                                        Container(
                                          padding: const EdgeInsetsDirectional.symmetric(
                                            horizontal: AppSpace.md,
                                            vertical: AppSpace.xxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppPalette.splashGoldSoft,
                                            borderRadius: AppRadius.pillRadius,
                                          ),
                                          child: Text(
                                            '﴿ رَبِّ زِدْنِي عِلْمًا ﴾',
                                            style: textTheme.caption.copyWith(
                                              color: AppPalette.splashGold,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Bottom Section: Fast Progress Bar & Prophetic Hadith
                          FadeTransition(
                            opacity: _bottomFade,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                bottom: AppSpace.sm,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Sleek Golden Progress Bar
                                  SizedBox(
                                    width: 90,
                                    child: ClipRRect(
                                      borderRadius: AppRadius.pillRadius,
                                      child: AnimatedBuilder(
                                        animation: _animController,
                                        builder: (context, _) =>
                                            LinearProgressIndicator(
                                          value: _animController.value,
                                          backgroundColor:
                                              AppPalette.splashGoldSoft,
                                          valueColor:
                                              const AlwaysStoppedAnimation<Color>(
                                            AppPalette.splashGold,
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
                                      color: AppPalette.splashTextSubtle,
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
