import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_palette.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_logo.dart';
import 'widgets/onboarding_hero_header_card.dart';

/// Luxury Calm Scholar first-run onboarding screen.
/// Exactly 3 pages, skippable from every screen, shown once via SharedPreferences.
/// Fully RTL, accessible, responsive to text scaling (1.0x - 2.0x), and strictly tokenized.
class OnboardingPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingPage({
    super.key,
    this.onCompleted,
  });

  static const String prefKey = 'has_completed_first_run_onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 3;
  static const double _dividerHairlineHeight = AppSpace.xxs / 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingPage.prefKey, true);

    if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      buildFadeRoute(
        page: const AppShell(),
        duration: AppMotion.debounce,
      ),
    );
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: AppMotion.base,
        curve: AppMotion.easeOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // 1. Grounded Editorial Top Brand Header
              _buildTopHeader(
                palette: palette,
                textTheme: textTheme,
              ),

              // 2. Page Content Carousel
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildPage(
                      palette: palette,
                      textTheme: textTheme,
                      tag: 'القرآن والعلم',
                      icon: Icons.menu_book_rounded,
                      title: 'القرآن الكريم والمتون العلمية',
                      description:
                          'تلاوة وتدبر آيات الذكر الحكيم بالرسم العثماني بروايتي حفص وورش، مع تصفح متون طالب العلم وشروحها المعتمدة دون اتصال بالإنترنت.',
                      highlights: const [
                        'المصحف الشريف بالرسم العثماني',
                        'متون العقيدة والفقه والحديث واللغة',
                        'شروح صوتية ومقروءة للمتون المعتمدة',
                      ],
                    ),
                    _buildPage(
                      palette: palette,
                      textTheme: textTheme,
                      tag: 'المواقيت والقبلة',
                      icon: Icons.mosque_rounded,
                      title: 'مواقيت الصلاة والأذان الشريف',
                      description:
                          'حساب دقيق لمواقيت الصلاة وفق الطرق الفلكية المعتمدة، مع تنبيهات الأذان بصوت شيوخ الحرمين وبوصلة دقيقة لتحديد اتجاه القبلة المشرفة.',
                      highlights: const [
                        'حساب فلكي دقيق لمواقيت الصلوات الخمس',
                        'تنبيهات الأذان والتذكير المسبق والإقامة',
                        'بوصلة القبلة الدقيقة مع المسافة إلى مكة',
                      ],
                    ),
                    _buildPage(
                      palette: palette,
                      textTheme: textTheme,
                      tag: 'الأذكار والورد',
                      icon: Icons.favorite_rounded,
                      title: 'حصن المسلم والورد اليومي',
                      description:
                          'أذكار الصباح والمساء والصلوات موثقة بالأدلة الصحيحة، مع مسبحة إلكترونية متطورة ومتابعة مستمرة لوردك اليومي في القراءة والذكر.',
                      highlights: const [
                        'أذكار اليوم والليلة من صحيح السنة المطهرة',
                        'مسبحة إلكترونية تفاعلية مع عداد الإنجاز',
                        'متابعة الورد اليومي وختمات القرآن الكريم',
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Grounded Bottom Navigation Dock
              _buildBottomDock(palette: palette),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader({
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.xl,
        end: AppSpace.xl,
        top: AppSpace.md,
        bottom: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          bottom: BorderSide(color: palette.border),
        ),
        boxShadow: palette.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Framed Sacred Emblem Badge
              Container(
                width: AppSize.tap,
                height: AppSize.tap,
                padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                decoration: BoxDecoration(
                  color: palette.splashCardBg,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: palette.splashCardBorder,
                    width: 1.2,
                  ),
                  boxShadow: palette.shadow,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.smRadius,
                  child: const AppLogo(size: AppLogoSize.md),
                ),
              ),
              const SizedBox(width: AppSpace.md),

              // Brand Title
              Expanded(
                child: Text(
                  'طالب العلم',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium.copyWith(
                    color: palette.text,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),

              // Tactile Outlined Skip Capsule
              Semantics(
                button: true,
                label: 'تخطي الشرح والبدء فوراً',
                child: AppButton.outline(
                  label: 'تخطي',
                  size: AppButtonSize.sm,
                  onPressed: _finishOnboarding,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          // Full-Width 3-Segment Editorial Chapter Progress Track
          Row(
            children: List.generate(_totalPages, (index) {
              final isCurrent = index == _currentPage;
              final isPast = index < _currentPage;
              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: index < _totalPages - 1 ? AppSpace.sm : 0.0,
                  ),
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    curve: AppMotion.easeOut,
                    height: AppSpace.xs,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? palette.primary
                          : (isPast ? palette.gold : palette.border),
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock({required AppPalette palette}) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.border),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: AppButton(
          label: _currentPage == _totalPages - 1
              ? 'ابدأ الاستخدام'
              : 'التالي',
          icon: _currentPage == _totalPages - 1
              ? Icons.check_circle_rounded
              : Icons.arrow_back_rounded,
          onPressed: _nextPage,
        ),
      ),
    );
  }

  Widget _buildPage({
    required AppPalette palette,
    required AppTextTheme textTheme,
    required String tag,
    required IconData icon,
    required String title,
    required String description,
    required List<String> highlights,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minViewportHeight = (constraints.maxHeight - (AppSpace.md * 2))
            .clamp(0.0, double.infinity);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minViewportHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illuminated Two-Tone Manuscript Hero Header Card
                OnboardingHeroHeaderCard(
                  tag: tag,
                  icon: icon,
                  title: title,
                  description: description,
                ),
                const SizedBox(height: AppSpace.md),

                // Structured Editorial Feature Highlights Card
                AppCard(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < highlights.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              vertical: AppSpace.sm,
                            ),
                            child: Divider(
                              height: _dividerHairlineHeight,
                              thickness: _dividerHairlineHeight,
                              color: palette.border,
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: AppSize.tagMinHeight,
                              height: AppSize.tagMinHeight,
                              decoration: BoxDecoration(
                                color: palette.primarySoft,
                                borderRadius: AppRadius.smRadius,
                                border: Border.all(
                                  color: palette.splashCardBorder,
                                ),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: AppIcon.sm,
                                color: palette.onPrimarySoft,
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Text(
                                highlights[i],
                                style: textTheme.bodySmallBold.copyWith(
                                  color: palette.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
