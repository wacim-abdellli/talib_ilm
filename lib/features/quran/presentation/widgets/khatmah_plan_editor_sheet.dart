import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../data/models/khatmah_plan.dart';

enum _PlanGoalMode { dailyPages, targetDate }

class KhatmahPlanDraft {
  final String title;
  final int startPage;
  final int pagesPerDay;
  final DateTime? targetDate;

  const KhatmahPlanDraft({
    required this.title,
    required this.startPage,
    required this.pagesPerDay,
    required this.targetDate,
  });
}

class KhatmahPlanEditorSheet extends StatefulWidget {
  final KhatmahPlan? plan;
  final int suggestedStartPage;

  const KhatmahPlanEditorSheet({
    super.key,
    this.plan,
    required this.suggestedStartPage,
  });

  static Future<KhatmahPlanDraft?> show({
    required BuildContext context,
    KhatmahPlan? plan,
    required int suggestedStartPage,
  }) {
    return AppSheet.show<KhatmahPlanDraft>(
      context: context,
      builder: (_) => KhatmahPlanEditorSheet(
        plan: plan,
        suggestedStartPage: suggestedStartPage,
      ),
    );
  }

  @override
  State<KhatmahPlanEditorSheet> createState() => _KhatmahPlanEditorSheetState();
}

class _KhatmahPlanEditorSheetState extends State<KhatmahPlanEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _startPageController;
  late final TextEditingController _dailyPagesController;
  late _PlanGoalMode _goalMode;
  late DateTime _targetDate;
  String? _error;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    final today = DateUtils.dateOnly(DateTime.now());
    _titleController = TextEditingController(text: plan?.title ?? 'ختمة جديدة');
    final startPageText =
        '${plan?.startPage ?? widget.suggestedStartPage.clamp(1, 604)}';
    _startPageController = TextEditingController.fromValue(
      TextEditingValue(
        text: startPageText,
        selection: TextSelection.collapsed(offset: startPageText.length),
      ),
    );
    final dailyPagesText = '${plan?.pagesPerDay ?? 5}';
    _dailyPagesController = TextEditingController.fromValue(
      TextEditingValue(
        text: dailyPagesText,
        selection: TextSelection.collapsed(offset: dailyPagesText.length),
      ),
    );
    _goalMode = plan?.targetDate == null
        ? _PlanGoalMode.dailyPages
        : _PlanGoalMode.targetDate;
    final savedTarget = plan?.targetDate;
    _targetDate = savedTarget != null && !savedTarget.isBefore(today)
        ? savedTarget
        : today.add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startPageController.dispose();
    _dailyPagesController.dispose();
    super.dispose();
  }

  Future<void> _chooseTargetDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate.isBefore(today) ? today : _targetDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
      helpText: 'اختر موعد الختم',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (picked != null && mounted) {
      setState(() {
        _targetDate = DateUtils.dateOnly(picked);
        _error = null;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final startPage = _isEditing
        ? widget.plan!.startPage
        : int.tryParse(_startPageController.text.trim());
    final enteredPages = int.tryParse(_dailyPagesController.text.trim());

    if (title.isEmpty || title.length > 60) {
      setState(() => _error = 'اكتب اسمًا من حرف واحد إلى 60 حرفًا.');
      return;
    }
    if (startPage == null || startPage < 1 || startPage > 604) {
      setState(() => _error = 'رقم صفحة البداية يجب أن يكون بين 1 و 604.');
      return;
    }
    if (enteredPages == null || enteredPages < 1 || enteredPages > 604) {
      setState(() => _error = 'عدد الصفحات يجب أن يكون بين 1 و 604.');
      return;
    }

    var pagesPerDay = enteredPages;
    DateTime? targetDate;
    if (_goalMode == _PlanGoalMode.targetDate) {
      targetDate = _targetDate;
      final days =
          targetDate.difference(DateUtils.dateOnly(DateTime.now())).inDays + 1;
      final remainingPages = _isEditing
          ? widget.plan!.remainingPages
          : KhatmahPlan.mushafPageCount - startPage + 1;
      pagesPerDay = (remainingPages + days - 1) ~/ days;
    }

    Navigator.of(context).pop(
      KhatmahPlanDraft(
        title: title,
        startPage: startPage,
        pagesPerDay: pagesPerDay,
        targetDate: targetDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final remainingPages = _isEditing
        ? widget.plan!.remainingPages
        : KhatmahPlan.mushafPageCount -
              (int.tryParse(_startPageController.text) ?? 1) +
              1;
    final daysUntilTarget =
        _targetDate.difference(DateUtils.dateOnly(DateTime.now())).inDays + 1;
    final suggestedPages = daysUntilTarget > 0
        ? (remainingPages + daysUntilTarget - 1) ~/ daysUntilTarget
        : remainingPages;

    return AppSheet(
      titleText: _isEditing ? 'تعديل خطة الختمة' : 'إنشاء خطة ختمة',
      icon: Icons.flag_rounded,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 60,
              textInputAction: TextInputAction.next,
              decoration: _decoration(context, 'اسم الخطة'),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: _startPageController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.end,
                textInputAction: TextInputAction.next,
                decoration: _decoration(context, 'ابدأ من الصفحة (1–604)'),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            Text(
              'كيف تريد تنظيم الختمة؟',
              style: text.label.copyWith(color: palette.text),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                ChoiceChip(
                  label: const Text('عدد صفحات يومي'),
                  selected: _goalMode == _PlanGoalMode.dailyPages,
                  onSelected: (_) => setState(() {
                    _goalMode = _PlanGoalMode.dailyPages;
                    _error = null;
                  }),
                ),
                ChoiceChip(
                  label: const Text('موعد لختم القرآن'),
                  selected: _goalMode == _PlanGoalMode.targetDate,
                  onSelected: (_) => setState(() {
                    _goalMode = _PlanGoalMode.targetDate;
                    _error = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (_goalMode == _PlanGoalMode.dailyPages)
              TextField(
                controller: _dailyPagesController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.end,
                decoration: _decoration(context, 'صفحات الورد اليومي (1–604)'),
              )
            else
              _TargetDateTile(
                date: _targetDate,
                suggestedPages: suggestedPages,
                onTap: _chooseTargetDate,
              ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(_error!, style: text.caption.copyWith(color: palette.error)),
            ],
            const SizedBox(height: AppSpace.lg),
            AppButton(
              label: _isEditing ? 'حفظ التعديلات' : 'إنشاء الخطة',
              icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String label) {
    final palette = context.palette;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: palette.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
    );
  }
}

class _TargetDateTile extends StatelessWidget {
  final DateTime date;
  final int suggestedPages;
  final VoidCallback onTap;

  const _TargetDateTile({
    required this.date,
    required this.suggestedPages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final localizations = MaterialLocalizations.of(context);
    final formatted = localizations.formatMediumDate(date);

    return Material(
      color: palette.surfaceMuted,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: palette.primary),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatted,
                      style: text.body.copyWith(color: palette.text),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'المطلوب تقريبًا $suggestedPages صفحة يوميًا',
                      style: text.caption.copyWith(color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_calendar_rounded, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
