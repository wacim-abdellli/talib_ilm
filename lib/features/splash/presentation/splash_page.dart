import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/navigation/fade_page_route.dart';

/// Luxury landing splash screen with Basmalah with shakl, illuminated emblem,
/// and smooth transition to the main app shell.
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
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;
  bool _navigated = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: AppMotion.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: AppMotion.easeOut,
      ),
    );

    _animController.forward();

    if (widget.autoNavigate) {
      _startStartupInitialization();
    }
  }

  Future<void> _startStartupInitialization() async {
    // Warm up repository in background without stalling main UI isolate
    unawaited(QuranRepository.instance.ensureLoaded(604).catchError((_) {}));
    // Warm up and refresh prayer & adhan notification schedules
    unawaited(PrayerScheduleService().refreshSchedulesIfNeeded().catchError((_) {}));

    final elapsed = DateTime.now().difference(_startTime ?? DateTime.now());
    final remaining = AppMotion.splash - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    _proceedToHome();
  }

  void _proceedToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      buildFadeRoute(page: const AppShell()),
    );
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
              vertical: AppSpace.lg,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
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
                              // Top: Sacred Salam Greeting & Basmalah
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  top: AppSpace.sm,
                                ),
                                child: Semantics(
                                  header: true,
                                  label: 'السلام عليكم ورحمة الله وبركاته',
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ',
                                        textAlign: TextAlign.center,
                                        style: textTheme.titleSmall.copyWith(
                                          color: AppPalette.splashGold,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpace.xxs),
                                      Text(
                                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                        textAlign: TextAlign.center,
                                        style: textTheme.caption.copyWith(
                                          color: AppPalette.splashTextSubtle,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Center: Minimalist Sacred Emblem & App Identity
                              Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  vertical: AppSpace.md,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Minimalist Luxury Emblem
                                    Semantics(
                                      label: 'شعار تطبيق طالب العلم',
                                      image: true,
                                      child: Image.asset(
                                        'assets/branding/symbol_on_light.png',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.md),

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

                                    // Sacred Motto / Tagline
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

                              // Bottom: Dignified Progress & Prophetic Hadith
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  bottom: AppSpace.sm,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: ClipRRect(
                                        borderRadius: AppRadius.pillRadius,
                                        child: AnimatedBuilder(
                                          animation: _animController,
                                          builder: (context, _) => LinearProgressIndicator(
                                            value: _animController.value,
                                            backgroundColor: AppPalette.splashGoldSoft,
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              AppPalette.splashGold,
                                            ),
                                            minHeight: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.sm),
                                    Text(
                                      '«مَنْ سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقاً إِلَى الْجَنَّةِ»',
                                      textAlign: TextAlign.center,
                                      style: textTheme.caption.copyWith(
                                        color: AppPalette.splashTextSubtle,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
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
        ),
      ),
    );
  }
}
