import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../data/models/khatmah_plan.dart';

enum _PlanAction { record, edit, pause, resume, archive, restore, delete }

class KhatmahPlanCard extends StatelessWidget {
  final KhatmahPlan plan;
  final VoidCallback onStartReading;
  final VoidCallback onRecordPages;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const KhatmahPlanCard({
    super.key,
    required this.plan,
    required this.onStartReading,
    required this.onRecordPages,
    required this.onEdit,
    required this.onPause,
    required this.onResume,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final today = DateTime.now();
    final todayPages = plan.pagesPlannedFor(today);
    final remainingToday = plan.pagesRemainingToday(today);
    final isActionable = !plan.isArchived && !plan.isPaused && !plan.isComplete;
    final estimatedDate = plan.estimatedFinishDate(today);
    final targetLabel = plan.isComplete
        ? 'اكتملت الختمة${plan.completedAt == null ? '' : ' • ${MaterialLocalizations.of(context).formatMediumDate(plan.completedAt!)}'}'
        : plan.targetDate != null
        ? 'موعد الختم: ${MaterialLocalizations.of(context).formatMediumDate(plan.targetDate!)}'
        : estimatedDate == null
        ? 'موعد الإكمال غير محدد'
        : 'موعد متوقع: ${MaterialLocalizations.of(context).formatMediumDate(estimatedDate)}';

    String assignmentLabel;
    if (plan.isComplete) {
      assignmentLabel = 'أتممت صفحات الخطة كلها';
    } else if (plan.isArchived) {
      assignmentLabel = 'الخطة مؤرشفة';
    } else if (plan.isPaused) {
      assignmentLabel = 'الخطة متوقفة مؤقتًا';
    } else if (remainingToday == 0) {
      assignmentLabel = 'أتممت ورد اليوم • يمكنك مواصلة القراءة متى شئت';
    } else {
      assignmentLabel = 'الورد التالي يبدأ من الصفحة ${plan.nextPage}';
    }

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<_PlanAction>(
                tooltip: 'إدارة الخطة',
                icon: Icon(Icons.more_vert_rounded, color: palette.textMuted),
                onSelected: (action) {
                  switch (action) {
                    case _PlanAction.record:
                      onRecordPages();
                    case _PlanAction.edit:
                      onEdit();
                    case _PlanAction.pause:
                      onPause();
                    case _PlanAction.resume:
                      onResume();
                    case _PlanAction.archive:
                      onArchive();
                    case _PlanAction.restore:
                      onRestore();
                    case _PlanAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (isActionable)
                    const PopupMenuItem(
                      value: _PlanAction.record,
                      child: Text('تسجيل قراءة خارج التطبيق'),
                    ),
                  if (!plan.isArchived && !plan.isComplete) ...[
                    const PopupMenuItem(
                      value: _PlanAction.edit,
                      child: Text('تعديل الخطة'),
                    ),
                    PopupMenuItem(
                      value: plan.isPaused
                          ? _PlanAction.resume
                          : _PlanAction.pause,
                      child: Text(
                        plan.isPaused ? 'متابعة الخطة' : 'إيقاف مؤقت',
                      ),
                    ),
                  ],
                  PopupMenuItem(
                    value: plan.isArchived
                        ? _PlanAction.restore
                        : _PlanAction.archive,
                    child: Text(
                      plan.isArchived ? 'إعادة إلى خططي' : 'أرشفة الخطة',
                    ),
                  ),
                  const PopupMenuItem(
                    value: _PlanAction.delete,
                    child: Text('حذف الخطة'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${plan.completedPages} من ${plan.totalPages} صفحة',
                  style: text.bodySmall.copyWith(color: palette.textMuted),
                ),
              ),
              Text(
                '${(plan.progress * 100).round()}%',
                style: text.label.copyWith(
                  color: plan.isComplete ? palette.gold : palette.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          AppProgress(progress: plan.progress),
          const SizedBox(height: AppSpace.md),
          Text(
            assignmentLabel,
            style: text.body.copyWith(
              color: isActionable ? palette.text : palette.textMuted,
            ),
          ),
          if (!plan.isComplete && !plan.isPaused && !plan.isArchived) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              'ورد اليوم: أُنجز ${plan.pagesRecordedOn(today)} من $todayPages • بقي $remainingToday',
              style: text.caption.copyWith(color: palette.textMuted),
            ),
          ],
          const SizedBox(height: AppSpace.xs),
          Text(
            targetLabel,
            style: text.caption.copyWith(color: palette.textMuted),
          ),
          if (isActionable) ...[
            const SizedBox(height: AppSpace.md),
            AppButton.tonal(
              label: remainingToday == 0 ? 'تابع القراءة' : 'ابدأ ورد اليوم',
              icon: Icons.menu_book_rounded,
              onPressed: onStartReading,
            ),
          ],
        ],
      ),
    );
  }
}
