import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/app_shell.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../prayer/presentation/qibla_page.dart';

/// Re-architected Home Header: Dual-tier luxury Islamic editorial layout
/// Tier 1: Brand emblem badge + Personalized greeting & du'a + Quick actions (Search & Qibla)
/// Tier 2: Interactive Location pill & Gregorian/Hijri Calendar pill
class HomeHeader extends StatelessWidget {
  final String city;
  final String greeting;
  final String? greetingSubtitle;
  final VoidCallback? onLocationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onQiblaTap;
  final VoidCallback? onEmblemTap;
  final VoidCallback? onDateTap;

  const HomeHeader({
    super.key,
    required this.city,
    required this.greeting,
    this.greetingSubtitle,
    this.onLocationTap,
    this.onSearchTap,
    this.onQiblaTap,
    this.onEmblemTap,
    this.onDateTap,
  });

  void _defaultEmblemTap(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSize.buttonH,
                height: AppSpace.xs,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Container(
                width: AppSize.navH,
                height: AppSize.navH,
                padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(
                    color: palette.gold,
                    width: 1.5,
                  ),
                  boxShadow: palette.shadow,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.mdRadius,
                  child: Image.asset(palette.logoSymbol, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'طالب العلم',
                style: textTheme.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                '«مَن سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً، سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقاً إِلَى الجَنَّةِ»',
                textAlign: TextAlign.center,
                style: textTheme.sacred.copyWith(
                  color: palette.gold,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'تطبيق إسلامي شامل لطلب العلم الشرعي، حفظ المتون، القرآن الكريم، ومواقيت الصلاة.',
                textAlign: TextAlign.center,
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _defaultDateTap(BuildContext context, String hijri) {
    final palette = context.palette;
    final textTheme = context.text;
    final now = DateTime.now();
    final gregorian = '${now.day}/${now.month}/${now.year} م';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSize.buttonH,
                height: AppSpace.xs,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Icon(
                Icons.calendar_month_rounded,
                size: AppIcon.hero,
                color: palette.gold,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'التاريخ اليوم',
                style: textTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                hijri,
                style: textTheme.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.gold,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'الموافق ميلادياً: $gregorian',
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final date = DateTime.now();

    String hijriStr = '';
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.fromDate(date);
      hijriStr = '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {}

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==========================================
        // Tier 1: Brand & Greeting + Action Controls
        // ==========================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sacred Emblem Badge
            Semantics(
              label: 'شعار طالب العلم',
              button: true,
              child: Tooltip(
                message: 'طالب العلم',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEmblemTap ?? () => _defaultEmblemTap(context),
                    borderRadius: AppRadius.mdRadius,
                    child: Container(
                      width: AppSize.tap,
                      height: AppSize.tap,
                      decoration: BoxDecoration(
                        color: palette.surfaceRaised,
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: palette.gold.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: palette.shadow,
                      ),
                      padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                      child: ClipRRect(
                        borderRadius: AppRadius.smRadius,
                        child: Image.asset(
                          palette.logoSymbol,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),

            // Dignified Greeting & Spiritual Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          greeting,
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Container(
                        width: AppSpace.xs,
                        height: AppSpace.xs,
                        decoration: BoxDecoration(
                          color: palette.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs / 2),
                  Text(
                    greetingSubtitle ?? 'حيّاك الله في رياض العلم والخير',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),

            // Quick Action Buttons (Search & Qibla)
            _HeaderCircleAction(
              icon: Icons.search_rounded,
              tooltip: 'البحث في المتون والكتب',
              onTap: onSearchTap ?? () => AppShell.switchToTab(context, 2),
            ),
            const SizedBox(width: AppSpace.xs),
            _HeaderCircleAction(
              icon: Icons.explore_outlined,
              tooltip: 'اتجاه القبلة',
              onTap: onQiblaTap ?? () {
                Navigator.push(context, buildFadeRoute(page: const QiblaPage()));
              },
            ),
          ],
        ),

        const SizedBox(height: AppSpace.md),

        // ==========================================
        // Tier 2: Dedicated Interactive Status Strip
        // ==========================================
        Row(
          children: [
            // Interactive Location Pill
            Expanded(
              flex: 2,
              child: _HeaderLocationChip(
                city: city,
                onTap: onLocationTap ?? () => AppShell.switchToTab(context, 1),
              ),
            ),
            if (hijriStr.isNotEmpty) ...[
              const SizedBox(width: AppSpace.sm),
              // Hijri Date Pill (Calendar icon, clean typography, no star)
              Expanded(
                flex: 3,
                child: _HeaderDateChip(
                  hijriStr: hijriStr,
                  onTap: onDateTap ?? () => _defaultDateTap(context, hijriStr),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeaderCircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderCircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: AppSize.tap,
      height: AppSize.tap,
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
        boxShadow: palette.shadow,
      ),
      child: AppIconButton(
        icon: icon,
        tooltip: tooltip,
        iconSize: AppIcon.md,
        color: palette.text,
        onPressed: onTap,
      ),
    );
  }
}

class _HeaderLocationChip extends StatelessWidget {
  final String city;
  final VoidCallback? onTap;

  const _HeaderLocationChip({
    required this.city,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Semantics(
      label: 'موقع الصلاة: $city. اضغط لتفاصيل مواقيت الصلاة',
      button: true,
      child: Tooltip(
        message: 'مواقيت الصلاة في $city',
        child: Material(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.pillRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pillRadius,
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSize.tap),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border),
                boxShadow: palette.shadow,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: AppIcon.sm,
                    color: palette.gold,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      city,
                      style: textTheme.caption.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs / 2),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: AppIcon.sm,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderDateChip extends StatelessWidget {
  final String hijriStr;
  final VoidCallback? onTap;

  const _HeaderDateChip({
    required this.hijriStr,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Semantics(
      label: 'التاريخ الهجري: $hijriStr',
      button: true,
      child: Tooltip(
        message: 'التاريخ الهجري',
        child: Material(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.pillRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pillRadius,
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSize.tap),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border),
                boxShadow: palette.shadow,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: AppIcon.sm,
                    color: palette.gold,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        hijriStr,
                        style: textTheme.caption.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

