import 'dart:async';
import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
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

  @override
  void initState() {
    super.initState();
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
      _timer = Timer(AppMotion.splash, _proceedToHome);
    }
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top: Sacred Basmalah with Full Shakl (Tashkeel)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: AppSpace.md),
                      child: Semantics(
                        header: true,
                        label: 'بسم الله الرحمن الرحيم',
                        child: Text(
                          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                          textAlign: TextAlign.center,
                          style: textTheme.sacredLarge.copyWith(
                            color: palette.gold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Center: Sacred Emblem & App Identity
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Illuminated Masterpiece Emblem
                              Semantics(
                                label: 'شعار تطبيق طالب العلم',
                                image: true,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: palette.surfaceRaised,
                                    borderRadius: AppRadius.xlRadius,
                                    border: Border.all(
                                      color: palette.border,
                                      width: 1.5,
                                    ),
                                    boxShadow: palette.shadow,
                                  ),
                                  padding: const EdgeInsetsDirectional.all(
                                    AppSpace.md,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: AppRadius.lgRadius,
                                    child: Image.asset(
                                      palette.logoSymbol,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.xl),

                              // App Name
                              Text(
                                'طالبُ العِلْمِ',
                                textAlign: TextAlign.center,
                                style: textTheme.display.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),

                              // Sacred Motto / Tagline
                              Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.md,
                                ),
                                child: Text(
                                  'زادُ المسلمِ في طَلَبِ العِلمِ النَّافِعِ',
                                  textAlign: TextAlign.center,
                                  style: textTheme.body.copyWith(
                                    color: palette.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom: Dignified Progress & Subtitle
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpace.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 120,
                            child: ClipRRect(
                              borderRadius: AppRadius.pillRadius,
                              child: AnimatedBuilder(
                                animation: _animController,
                                builder: (context, _) => LinearProgressIndicator(
                                  value: _animController.value,
                                  backgroundColor: palette.surfaceMuted,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    palette.gold,
                                  ),
                                  minHeight: 3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            '«مَنْ سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقاً إِلَى الْجَنَّةِ»',
                            textAlign: TextAlign.center,
                            style: textTheme.caption.copyWith(
                              color: palette.textSubtle,
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
          ),
        ),
      ),
    );
  }
}
