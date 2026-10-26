import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_tag.dart';

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
        curve: Curves.easeOutCubic,
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
              // Top Bar: Logo lockup and Skip action
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: AppLogoSize.sm),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          'طالب العلم',
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                          ),
                        ),
                      ],
                    ),
                    Semantics(
                      button: true,
                      label: 'تخطي الشرح والبدء فوراً',
                      child: AppButton.text(
                        label: 'تخطي',
                        onPressed: _finishOnboarding,
                      ),
                    ),
                  ],
                ),
              ),

              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
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
                        'المصحف الشريف بالرسم العثماني بروايتين',
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

              // Bottom Navigation: Indicator Dots & Action Button
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: AppMotion.base,
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs,
                          ),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected ? palette.primary : palette.border,
                            borderRadius: AppRadius.pillRadius,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpace.xl),

                    // Primary Action Button
                    SizedBox(
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
                  ],
                ),
              ),
            ],
          ),
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
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.md,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.md),
          // Large Hero Emblem
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.border,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Tag
          AppTag(
            label: tag,
            fg: palette.primary,
            bg: palette.primarySoft,
          ),
          const SizedBox(height: AppSpace.md),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.title.copyWith(
              color: palette.text,
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.body.copyWith(
              color: palette.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Feature highlights card
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: Column(
              children: highlights.map((text) {
                return Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: AppSpace.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: palette.primary,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          text,
                          style: textTheme.bodySmall.copyWith(
                            color: palette.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
