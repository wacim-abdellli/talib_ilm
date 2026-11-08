import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/models/surah_objectives_card.dart';
import '../../data/services/quran_surah_objectives_service.dart';

/// Scholarly bottom sheet presenting the comprehensive objectives, themes,
/// naming reasons, and virtues of a Quranic Surah (بطاقة التعريف بالسورة ومقاصدها).
class SurahObjectivesSheet extends StatefulWidget {
  final int surahNumber;
  final void Function(int surah, int ayah)? onNavigateToVerse;

  const SurahObjectivesSheet({
    super.key,
    required this.surahNumber,
    this.onNavigateToVerse,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    void Function(int surah, int ayah)? onNavigateToVerse,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.92,
      enableDrag: false,
      builder: (_) => SurahObjectivesSheet(
        surahNumber: surahNumber,
        onNavigateToVerse: onNavigateToVerse,
      ),
    );
  }

  @override
  State<SurahObjectivesSheet> createState() => _SurahObjectivesSheetState();
}

class _SurahObjectivesSheetState extends State<SurahObjectivesSheet> {
  final QuranSurahObjectivesService _service = QuranSurahObjectivesService();
  final ScrollController _scrollController = ScrollController();

  SurahObjectivesCard? _card;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCard() async {
    setState(() => _loading = true);
    try {
      final card = await _service.getSurahObjectives(widget.surahNumber);
      if (!mounted) return;
      setState(() {
        _card = card;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _copyObjective(String text, String surahName) {
    HapticFeedback.selectionClick();
    Clipboard.setData(
      ClipboardData(text: 'مقصد سورة $surahName:\n$text\n[مركز تفسير للدراسات القرآنية]'),
    );
    AppSnackbar.success(context, 'تم نسخ مقصد السورة');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpace.md,
        bottom: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // 2. Header Bar
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
            ),
            child: Row(
              children: [
                const IconBadge(icon: Icons.menu_book_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _card != null ? 'سورة ${_card!.name}' : 'بطاقة السورة',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'التعريف بالسورة ومقاصدها ومحاورها',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  color: palette.textMuted,
                  onPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.xs),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.xs),

          // 3. Main Content
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(palette.primary),
                        ),
                        const SizedBox(height: AppSpace.md),
                        Text(
                          'جارٍ تحميل بطاقة التعريف بالسورة...',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : _card == null
                    ? Center(
                        child: Text(
                          'تعذر تحميل بيانات السورة',
                          style: textTheme.bodyMedium
                              .copyWith(color: palette.textMuted),
                        ),
                      )
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ListView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.lg,
                            vertical: AppSpace.xs,
                          ),
                          children: [
                            _buildSurahIdentityCard(context, _card!),
                            const SizedBox(height: AppSpace.md),
                            _buildMainObjectiveCard(context, _card!),
                            const SizedBox(height: AppSpace.md),
                            _buildThematicSectionsCard(context, _card!),
                            const SizedBox(height: AppSpace.md),
                            if (_card!.otherNames.isNotEmpty ||
                                _card!.namingReason.isNotEmpty) ...[
                              _buildNamingCard(context, _card!),
                              const SizedBox(height: AppSpace.md),
                            ],
                            if (_card!.virtues.isNotEmpty) ...[
                              _buildVirtuesCard(context, _card!),
                              const SizedBox(height: AppSpace.md),
                            ],
                            if (_card!.connectionWithPrevious.isNotEmpty) ...[
                              _buildConnectionCard(context, _card!),
                              const SizedBox(height: AppSpace.md),
                            ],
                          ],
                        ),
                      ),
          ),

          const SizedBox(height: AppSpace.xs),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.xs),

          // 4. Bottom Actions Bar
          if (_card != null)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'قراءة السورة (ص ${_card!.startPage})',
                      icon: Icons.auto_stories_rounded,
                      onPressed: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                        widget.onNavigateToVerse?.call(_card!.surahNumber, 1);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  AppIconButton(
                    icon: Icons.copy_rounded,
                    tooltip: 'نسخ مقصد السورة',
                    onPressed: () =>
                        _copyObjective(_card!.mainObjective, _card!.name),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSurahIdentityCard(BuildContext context, SurahObjectivesCard card) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.gold.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: palette.gold.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${card.surahNumber}',
                  style: textTheme.titleMedium.copyWith(
                    color: palette.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سورة ${card.vocalizedName}',
                      style: textTheme.titleMedium.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${card.englishName} • ${card.englishMeaning}',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            alignment: WrapAlignment.spaceAround,
            children: [
              _buildMetricBadge(
                context,
                label: 'مكان النزول',
                value: card.revelationPlace,
                icon: Icons.location_on_outlined,
              ),
              _buildMetricBadge(
                context,
                label: 'ترتيب النزول',
                value: 'رقم ${card.revelationOrder}',
                icon: Icons.format_list_numbered_rounded,
              ),
              _buildMetricBadge(
                context,
                label: 'عدد الآيات',
                value: '${card.versesCount} آية',
                icon: Icons.numbers_rounded,
              ),
              _buildMetricBadge(
                context,
                label: 'صفحة البداية',
                value: 'صفحة ${card.startPage}',
                icon: Icons.bookmark_outline_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcon.sm, color: palette.primary),
          const SizedBox(width: AppSpace.xxs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
              Text(
                value,
                style: textTheme.captionBold.copyWith(
                  color: palette.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainObjectiveCard(
    BuildContext context,
    SurahObjectivesCard card,
  ) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.center_focus_strong_rounded,
                size: AppIcon.md,
                color: palette.gold,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  'المقصد الرئيس للسورة',
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  'مركز تفسير',
                  style: textTheme.captionBold.copyWith(color: palette.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.smRadius,
              border: BorderDirectional(
                start: BorderSide(color: palette.gold, width: 3),
              ),
            ),
            child: Text(
              card.mainObjective,
              style: textTheme.bodyMedium.copyWith(
                color: palette.text,
                height: 1.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThematicSectionsCard(
    BuildContext context,
    SurahObjectivesCard card,
  ) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree_rounded,
                size: AppIcon.md,
                color: palette.primary,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  'محاور وموضوعات السورة (${card.thematicSections.length})',
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'تقسيم موضوعي تحليلي لآيات السورة الكريمة (انقر للانتقال للآيات):',
            style: textTheme.caption.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpace.sm),
          ...card.thematicSections.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final section = entry.value;

            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
              child: Semantics(
                button: true,
                label: 'الانتقال إلى ${section.title}',
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    widget.onNavigateToVerse?.call(
                      card.surahNumber,
                      section.startAyah,
                    );
                  },
                  borderRadius: AppRadius.smRadius,
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.smRadius,
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xs,
                          children: [
                            Text(
                              '$idx. ${section.title}',
                              style: textTheme.captionBold.copyWith(
                                color: palette.text,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: palette.primary.withValues(alpha: 0.12),
                                borderRadius: AppRadius.pillRadius,
                              ),
                              child: Text(
                                'الآيات ${section.startAyah} - ${section.endAyah}',
                                style: textTheme.captionBold.copyWith(
                                  color: palette.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (section.description.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            section.description,
                            style: textTheme.bodySmall.copyWith(
                              color: palette.textMuted,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNamingCard(BuildContext context, SurahObjectivesCard card) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.label_outline_rounded,
                size: AppIcon.md,
                color: palette.primary,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                'أسماء السورة وسبب التسمية',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (card.otherNames.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: card.otherNames.map((name) {
                return Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    name,
                    style: textTheme.captionBold.copyWith(color: palette.text),
                  ),
                );
              }).toList(),
            ),
          ],
          if (card.namingReason.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              card.namingReason,
              style: textTheme.bodySmall.copyWith(
                color: palette.text,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVirtuesCard(BuildContext context, SurahObjectivesCard card) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_outline_rounded,
                size: AppIcon.md,
                color: palette.gold,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                'فضائل السورة وخصائصها المستفيضة',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          ...card.virtues.map((v) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsetsDirectional.only(top: AppSpace.xs),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      v,
                      style: textTheme.bodySmall.copyWith(
                        color: palette.text,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    SurahObjectivesCard card,
  ) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                size: AppIcon.md,
                color: palette.primary,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                'مناسبة السورة لما قبلها في المصحف',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            card.connectionWithPrevious,
            style: textTheme.bodySmall.copyWith(
              color: palette.text,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
