import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../data/models/khatmah_plan.dart';
import '../../data/services/khatmah_plan_service.dart';
import '../khatmah_page.dart';

class QuranKhatmahEntry extends StatefulWidget {
  final int suggestedStartPage;
  final Future<void> Function(int page) onOpenPage;

  const QuranKhatmahEntry({
    super.key,
    required this.suggestedStartPage,
    required this.onOpenPage,
  });

  @override
  State<QuranKhatmahEntry> createState() => _QuranKhatmahEntryState();
}

class _QuranKhatmahEntryState extends State<QuranKhatmahEntry> {
  late Future<List<KhatmahPlan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = KhatmahPlanService.getPlans();
  }

  Future<void> _openPlanner() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => KhatmahPage(
          suggestedStartPage: widget.suggestedStartPage,
          onOpenPage: widget.onOpenPage,
        ),
      ),
    );
    if (mounted) {
      setState(() => _plansFuture = KhatmahPlanService.getPlans());
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: FutureBuilder<List<KhatmahPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          final plans = snapshot.data ?? const <KhatmahPlan>[];
          final current = plans.where((plan) => !plan.isComplete).firstOrNull;
          final featuredPlan = current ?? plans.firstOrNull;
          final title = featuredPlan?.title ?? 'خطة ختم القرآن';
          final subtitle = current == null
              ? featuredPlan?.isComplete == true
                    ? 'أتممت هذه الختمة • أنشئ خطة جديدة متى شئت'
                    : 'نظّم وردك وتابع تقدمك حتى إتمام الختمة'
              : current.isPaused
              ? 'الخطة متوقفة مؤقتًا • ${current.completedPages} من ${current.totalPages} صفحة'
              : 'بقي اليوم ${current.pagesRemainingToday(DateTime.now())} صفحة • ${current.completedPages} من ${current.totalPages}';

          return AppCard(
            onTap: _openPlanner,
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: palette.onPrimarySoft,
                    size: AppIcon.md,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (featuredPlan == null)
                            Text(
                              'ابدأ',
                              style: text.captionBold.copyWith(
                                color: palette.primary,
                              ),
                            )
                          else
                            Text(
                              '${plans.length} خطة',
                              style: text.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.caption.copyWith(color: palette.textMuted),
                      ),
                      if (featuredPlan != null) ...[
                        const SizedBox(height: AppSpace.sm),
                        AppProgress(progress: featuredPlan.progress),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Icon(
                  Icons.chevron_left_rounded,
                  color: palette.textMuted,
                  size: AppIcon.md,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
