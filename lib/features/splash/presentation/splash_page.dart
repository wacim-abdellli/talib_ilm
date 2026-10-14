import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/navigation/fade_page_route.dart';

/// Luxury Islamic landing splash screen with illuminated Basmalah,
/// sacred 12-point rosette emblem, fluid breathing animation,
/// and smooth dignified auto-navigation.
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

  late final Animation<double> _entranceFade;
  late final Animation<double> _emblemScale;

  Timer? _timer;
  bool _navigated = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Entrance and launch progress animation (~2.2 seconds)
    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.deliberate + AppMotion.oneSecond + AppMotion.deliberate,
    );

    _entranceFade = CurvedAnimation(
      parent: _animController,
      curve: AppMotion.easeOut,
    );

    // Staggered entrance and organic breathing sequence
    _emblemScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.90, end: 1.0)
            .chain(CurveTween(curve: AppMotion.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.03)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_animController);

    _animController.forward();

    if (widget.autoNavigate) {
      _startStartupInitialization();
    }
  }

  void _startStartupInitialization() {
    final elapsed = DateTime.now().difference(_startTime ?? DateTime.now());
    final totalSplashDuration =
        AppMotion.deliberate + AppMotion.oneSecond + AppMotion.deliberate;
    final remaining = totalSplashDuration - elapsed;

    if (remaining > Duration.zero) {
      _timer = Timer(remaining, _proceedToHome);
    } else {
      _proceedToHome();
    }
  }

  void _proceedToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();
    _timer = null;
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
    _timer = null;
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.splashBg,
      body: SafeArea(
        child: InkWell(
          onTap: _proceedToHome,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.lg,
              ),
              child: FadeTransition(
                opacity: _entranceFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Noble Salam & Sacred Basmalah with Rosettes
                    Semantics(
                      header: true,
                      label:
                          'السلام عليكم ورحمة الله وبركاته - بسم الله الرحمن الرحيم',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ',
                            textAlign: TextAlign.center,
                            style: textTheme.label.copyWith(
                              color: palette.gold,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '۞',
                                style: textTheme.sacred.copyWith(
                                  color: palette.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Flexible(
                                child: Text(
                                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                  textAlign: TextAlign.center,
                                  style: textTheme.sacredLarge.copyWith(
                                    color: palette.gold,
                                    fontWeight: FontWeight.bold,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Text(
                                '۞',
                                style: textTheme.sacred.copyWith(
                                  color: palette.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpace.lg),

                    // 2. Center Illuminated Rosette Medallion with Brand Symbol
                    Semantics(
                      label: 'شعار تطبيق طالب العلم',
                      image: true,
                      child: ScaleTransition(
                        scale: _emblemScale,
                        child: SizedBox(
                          width: 144,
                          height: 144,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 12-Point Islamic Rosette perimeter
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _IslamicRosettePainter(
                                    goldColor: palette.gold,
                                    strokeColor: palette.splashCardBorder,
                                  ),
                                ),
                              ),

                              // Inner illuminated medallion disc
                              Container(
                                width: 124,
                                height: 124,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: palette.splashCardBg,
                                  border: Border.all(
                                    color: palette.splashCardBorder,
                                    width: 1.2,
                                  ),
                                  boxShadow: palette.shadow,
                                ),
                                child: Image.asset(
                                  palette.logoSymbol,
                                  width: 82,
                                  height: 82,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpace.lg),

                    // 3. App Title, Sacred Tagline, and Qur'anic Du'a Chip
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'طَالِبُ العِلْمِ',
                          textAlign: TextAlign.center,
                          style: textTheme.display.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          'زَادُ الْمُسْلِمِ فِي طَلَبِ الْعِلْمِ الشَّرْعِيِّ',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall.copyWith(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.lg,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.goldSoft,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: palette.splashCardBorder,
                              width: 1.0,
                            ),
                          ),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '۞ ',
                                  style: textTheme.caption.copyWith(
                                    color: palette.gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'رَبِّ زِدْنِي عِلْمًا',
                                  style: textTheme.caption.copyWith(
                                    color: palette.gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ۞',
                                  style: textTheme.caption.copyWith(
                                    color: palette.gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpace.xl),

                    // 4. Sleek Golden Progress Bar & Prophetic Hadith
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 96,
                          child: ClipRRect(
                            borderRadius: AppRadius.pillRadius,
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) => LinearProgressIndicator(
                                value: _animController.value,
                                backgroundColor: palette.goldSoft,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.gold,
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
                            color: palette.textSubtle,
                            fontStyle: FontStyle.italic,
                            height: 1.45,
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
      ),
    );
  }
}

/// Custom painter for the delicate 12-point Islamic rosette outer halo
class _IslamicRosettePainter extends CustomPainter {
  final Color goldColor;
  final Color strokeColor;

  const _IslamicRosettePainter({
    required this.goldColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4.0;

    // Outer subtle hairline circle
    final circlePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, circlePaint);

    // 12 Rosette accents around the circumference
    final dotPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final angle = (i * math.pi) / 6.0;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      // Cardinal points (0, 90, 180, 270) have 4-point diamond stars;
      // intermediate points have refined dots
      if (i % 3 == 0) {
        final path = Path()
          ..moveTo(x, y - 3.5)
          ..lineTo(x + 3.0, y)
          ..lineTo(x, y + 3.5)
          ..lineTo(x - 3.0, y)
          ..close();
        canvas.drawPath(path, dotPaint);
      } else {
        canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicRosettePainter oldDelegate) {
    return oldDelegate.goldColor != goldColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
