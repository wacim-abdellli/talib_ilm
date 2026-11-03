import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/adhkar_models.dart';

/// Luxury presentation card for an AthkarItem in a recitation session.
class AdhkarSessionCard extends StatelessWidget {
  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u0652\u0670\u0640]');

  final AthkarItem item;
  final int repeat;
  final bool isDone;
  final VoidCallback? onTap;
  final double fontScale;
  final double defaultFontScale;
  final bool showTashkeel;
  final VoidCallback? onShare;
  final VoidCallback? onToggleTashkeel;
  final VoidCallback? onCycleFontSize;
  final VoidCallback? onIncreaseFontSize;
  final VoidCallback? onDecreaseFontSize;
  final VoidCallback? onResetFontSize;

  const AdhkarSessionCard({
    super.key,
    required this.item,
    required this.repeat,
    required this.isDone,
    this.onTap,
    this.fontScale = 1.0,
    this.defaultFontScale = 1.0,
    this.showTashkeel = true,
    this.onShare,
    this.onToggleTashkeel,
    this.onCycleFontSize,
    this.onIncreaseFontSize,
    this.onDecreaseFontSize,
    this.onResetFontSize,
  });

  String _cleanText(String text) {
    if (showTashkeel) return text;
    return text.replaceAll(_tashkeelRegex, '');
  }

  (String countLabel, String? occasionLabel) get _parsedMeta {
    final cd = item.countDescription.trim();

    final String defaultCount;
    if (repeat == 1) {
      defaultCount = 'مرة واحدة';
    } else if (repeat == 2) {
      defaultCount = 'مرتان';
    } else if (repeat >= 3 && repeat <= 10) {
      defaultCount = '$repeat مرات';
    } else {
      defaultCount = '$repeat مرة';
    }

    if (cd.isEmpty) {
      return (defaultCount, null);
    }

    // Match parenthesized conditions: "مَرَّةً وَاحِدَةً (عِنْدَ الْخُرُوجِ)"
    final parenMatch = RegExp(r'^(.*?)\s*[\(（](.*?)[\)）]$').firstMatch(cd);
    if (parenMatch != null) {
      final countPart = parenMatch.group(1)?.trim() ?? '';
      final contextPart = parenMatch.group(2)?.trim() ?? '';
      final cleanCount = _cleanCountWord(countPart, defaultCount);
      return (cleanCount, contextPart.isNotEmpty ? contextPart : null);
    }

    // Known phrases that specify situational context
    for (final phrase in const [
      'دُبُرَ كُلِّ صَلَاةٍ',
      'دبر كل صلاة',
      'عِنْدَ النَّوْمِ',
      'عند النوم',
      'عِنْدَ الْقِيَامِ مِنَ الْمَجْلِسِ',
      'من خاتمة سورة البقرة',
      'فِي اليَوْمِ',
      'في اليوم',
      'فِي الْمَجْلِسِ',
      'في المجلس',
      'أَوْ يُكْثِرُ مِنْهَا',
      'أَوْ حَسَبَ الْقُدْرَةِ',
    ]) {
      if (cd.contains(phrase)) {
        final idx = cd.indexOf(phrase);
        final countPart = cd.substring(0, idx).trim();
        final contextPart = cd.substring(idx).trim();
        final cleanCount = _cleanCountWord(countPart, defaultCount);
        return (cleanCount, contextPart.isNotEmpty ? contextPart : null);
      }
    }

    final hasRepeatWord = cd.contains('مرة') ||
        cd.contains('مَرَّة') ||
        cd.contains('مرات') ||
        cd.contains('مَرَّات');

    if (!hasRepeatWord) {
      if (cd.length <= 20) {
        return (cd, null);
      }
      return (defaultCount, cd);
    }

    return (_cleanCountWord(cd, defaultCount), null);
  }

  static String _cleanCountWord(String raw, String fallback) {
    final clean = raw.trim();
    if (clean.isEmpty) return fallback;
    if (clean == 'مَرَّةً وَاحِدَةً' || clean == 'مرة واحدة') return 'مرة واحدة';
    if (clean == 'ثَلَاثَ مَرَّاتٍ' || clean == '3 مَرَّاتٍ' || clean == '3 مرات') return '3 مرات';
    if (clean == 'أَرْبَعَ مَرَّاتٍ' || clean == '4 مَرَّاتٍ') return '4 مرات';
    if (clean == 'سَبْعَ مَرَّاتٍ' || clean == '7 مَرَّاتٍ') return '7 مرات';
    if (clean == 'عَشْرَ مَرَّاتٍ' || clean == '10 مَرَّاتٍ' || clean == '10 مرات') return '10 مرات';
    if (clean == 'ثَلَاثًا وَثَلَاثِينَ مَرَّةً' || clean == '33 مَرَّةً') return '33 مرة';
    if (clean == 'مِائَةَ مَرَّةٍ' || clean == '100 مَرَّةً' || clean == '100 مرة') return '100 مرة';
    if (clean.length <= 16) return clean;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _parsedMeta;
    final countLabel = meta.$1;
    final occasionLabel = meta.$2;
    final palette = context.palette;
    final textTheme = context.text;
    final arabicText = _cleanText(item.arabic);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.xs,
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: AppCard(
            onTap: onTap,
            padding: AppSpace.cardPadding,
            border: Border.all(
              color: isDone
                  ? palette.gold.withValues(alpha: 0.5)
                  : palette.border,
              width: isDone ? 1.5 : 1,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header: Repetition badge + Quick action controls
                Row(
                  children: [
                    // Target repetition badge (Safely constrained to prevent horizontal overflow)
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Tooltip(
                          message: item.countDescription.isNotEmpty
                              ? item.countDescription
                              : countLabel,
                          child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isDone ? palette.goldSoft : palette.surfaceMuted,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: isDone
                                  ? palette.gold.withValues(alpha: 0.4)
                                  : palette.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDone ? Icons.check_circle_rounded : Icons.repeat_rounded,
                                size: AppIcon.sm,
                                color: isDone ? palette.gold : palette.textMuted,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Flexible(
                                child: Text(
                                  countLabel,
                                  style: textTheme.caption.copyWith(
                                    color: isDone ? palette.gold : palette.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                      ),
                    ),
                    // Font Size Controls (Minimize & Maximize)
                    if (onIncreaseFontSize != null || onDecreaseFontSize != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xxs,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minimize button (-)
                            Tooltip(
                              message: 'تصغير الخط',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onDecreaseFontSize,
                                  borderRadius: AppRadius.pillRadius,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: AppIcon.xs,
                                      color: onDecreaseFontSize != null
                                          ? palette.text
                                          : palette.textMuted.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Current scale percentage indicator
                            Tooltip(
                              message:
                                  'إعادة ضبط الحجم (${(defaultFontScale * 100).round()}%)',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onResetFontSize,
                                  borderRadius: AppRadius.pillRadius,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.symmetric(
                                      horizontal: AppSpace.xs,
                                      vertical: AppSpace.xxs,
                                    ),
                                    child: Text(
                                      '${(fontScale * 100).round()}%',
                                      style: textTheme.caption.copyWith(
                                        color:
                                            (fontScale - defaultFontScale).abs() >
                                                0.01
                                            ? palette.gold
                                            : palette.textMuted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Maximize button (+)
                            Tooltip(
                              message: 'تكبير الخط',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onIncreaseFontSize,
                                  borderRadius: AppRadius.pillRadius,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: AppIcon.xs,
                                      color: onIncreaseFontSize != null
                                          ? palette.text
                                          : palette.textMuted.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Quick share button
                    if (onShare != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      Tooltip(
                        message: 'مشاركة الذكر',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onShare,
                            borderRadius: AppRadius.pillRadius,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.all(
                                AppSpace.xs,
                              ),
                              child: Icon(
                                Icons.share_outlined,
                                size: AppIcon.sm,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Occasion / Instruction Banner (if present, displayed completely without clipping)
                if (occasionLabel != null && occasionLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: palette.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: AppIcon.xs,
                          color: palette.gold,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(
                          child: Text(
                            occasionLabel,
                            textAlign: TextAlign.center,
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.md),

                // Arabic Sacred Text with responsive scaling and generous line height
                Text(
                  arabicText,
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.linear(fontScale),
                  style: textTheme.sacredLarge.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                    height: 2.3,
                  ),
                ),

                // Fadl (Virtue) if present
                if (item.fadl.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: AppIcon.sm,
                          color: palette.gold,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text(
                            item.fadl,
                            textAlign: TextAlign.center,
                            textScaler: TextScaler.linear(fontScale.clamp(0.85, 1.5)),
                            style: textTheme.captionBold.copyWith(
                              color: palette.gold,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rawi & Hadith Source Citation (Complete, never clipped, no dots)
                if (item.source.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: AppIcon.sm,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Flexible(
                        child: Text(
                          item.source,
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(fontScale.clamp(0.85, 1.4)),
                          style: textTheme.captionBold.copyWith(
                            color: palette.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating circular chevron button flanking the dhikr card.
class FloatingChevronButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isHighlighted;
  final VoidCallback onTap;

  const FloatingChevronButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isHighlighted ? palette.primary : palette.surface.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          elevation: isHighlighted ? 3 : 1,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHighlighted ? palette.primary : palette.border,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: AppIcon.md,
                color: isHighlighted ? palette.onPrimary : palette.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ergonomic bottom navigation pill button with clear label and RTL arrow.
class NavigationPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLeadingIcon;
  final bool isHighlighted;
  final bool isEnabled;
  final VoidCallback? onTap;

  const NavigationPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isLeadingIcon,
    this.isHighlighted = false,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final bgColor = isHighlighted
        ? palette.primary
        : (isEnabled ? palette.surface : palette.surfaceMuted);
    final fgColor = isHighlighted
        ? palette.onPrimary
        : (isEnabled ? palette.text : palette.textMuted);
    final borderColor = isHighlighted
        ? palette.primary
        : (isEnabled ? palette.border : Colors.transparent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: AppRadius.pillRadius,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeadingIcon) ...[
                Icon(icon, size: AppIcon.sm, color: fgColor),
                const SizedBox(width: AppSpace.xs),
              ],
              Text(
                label,
                style: (isHighlighted ? context.text.labelBold : context.text.label).copyWith(
                  color: fgColor,
                ),
              ),
              if (!isLeadingIcon) ...[
                const SizedBox(width: AppSpace.xs),
                Icon(icon, size: AppIcon.sm, color: fgColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
