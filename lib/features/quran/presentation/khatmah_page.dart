import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/models/khatmah_plan.dart';
import '../data/services/khatmah_plan_service.dart';
import 'widgets/khatmah_plan_card.dart';
import 'widgets/khatmah_plan_editor_sheet.dart';

class KhatmahPage extends StatefulWidget {
  final int suggestedStartPage;
  final Future<void> Function(int page) onOpenPage;

  const KhatmahPage({
    super.key,
    required this.suggestedStartPage,
    required this.onOpenPage,
  });

  @override
  State<KhatmahPage> createState() => _KhatmahPageState();
}

class _KhatmahPageState extends State<KhatmahPage> {
  List<KhatmahPlan> _plans = [];
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await KhatmahPlanService.getPlans(includeArchived: true);
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, 'تعذر تحميل خطط الختمة. حاول مرة أخرى.');
    }
  }

  Future<void> _createPlan() async {
    final draft = await KhatmahPlanEditorSheet.show(
      context: context,
      suggestedStartPage: widget.suggestedStartPage,
    );
    if (draft == null || !mounted) return;

    try {
      await KhatmahPlanService.createPlan(
        title: draft.title,
        startPage: draft.startPage,
        pagesPerDay: draft.pagesPerDay,
        targetDate: draft.targetDate,
      );
      await _loadPlans();
      if (mounted) {
        AppSnackbar.success(context, 'تم إنشاء خطة الختمة.');
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'تعذر إنشاء الخطة. راجع البيانات وحاول مرة أخرى.',
        );
      }
    }
  }

  Future<void> _editPlan(KhatmahPlan plan) async {
    final draft = await KhatmahPlanEditorSheet.show(
      context: context,
      plan: plan,
      suggestedStartPage: plan.nextPage,
    );
    if (draft == null || !mounted) return;

    try {
      await KhatmahPlanService.updatePlan(
        id: plan.id,
        title: draft.title,
        pagesPerDay: draft.pagesPerDay,
        targetDate: draft.targetDate,
        useTargetDate: draft.targetDate != null,
      );
      await _loadPlans();
      if (mounted) {
        AppSnackbar.success(context, 'تم تحديث خطة الختمة.');
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'تعذر تحديث الخطة. راجع الموعد والورد اليومي.',
        );
      }
    }
  }

  Future<void> _recordPages(KhatmahPlan plan) async {
    final controller = TextEditingController(
      text:
          '${plan.pagesRemainingToday(DateTime.now()).clamp(1, plan.remainingPages)}',
    );
    String? inputError;
    final pages = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('تسجيل القراءة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الصفحات التالية في خطتك تبدأ من الصفحة ${plan.nextPage}.'),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'عدد الصفحات التي قرأتها',
                  helperText: 'من 1 إلى ${plan.remainingPages} صفحة',
                  errorText: inputError,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < 1 || value > plan.remainingPages) {
                  setDialogState(() {
                    inputError = 'أدخل عددًا بين 1 و${plan.remainingPages}.';
                  });
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('تسجيل'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (pages == null || !mounted) return;

    try {
      final updated = await KhatmahPlanService.recordPages(
        id: plan.id,
        pages: pages,
      );
      final recordedPages = updated.completedPages - plan.completedPages;
      await _loadPlans();
      if (!mounted) return;
      AppSnackbar.success(
        context,
        updated.isComplete
            ? 'تقبل الله، أتممت هذه الختمة.'
            : 'تم تسجيل $recordedPages صفحة في خطتك.',
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'تعذر تسجيل الصفحات في هذه الخطة.');
      }
    }
  }

  Future<void> _togglePause(KhatmahPlan plan, {required bool paused}) async {
    try {
      await KhatmahPlanService.setPaused(id: plan.id, paused: paused);
      await _loadPlans();
      if (mounted) {
        AppSnackbar.success(
          context,
          paused ? 'تم إيقاف الخطة مؤقتًا.' : 'تمت متابعة الخطة.',
        );
      }
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'تعذر تحديث حالة الخطة.');
    }
  }

  Future<void> _toggleArchive(
    KhatmahPlan plan, {
    required bool archived,
  }) async {
    try {
      await KhatmahPlanService.setArchived(id: plan.id, archived: archived);
      await _loadPlans();
      if (mounted) {
        AppSnackbar.success(
          context,
          archived ? 'تمت أرشفة الخطة.' : 'أعيدت الخطة إلى خططك.',
        );
      }
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'تعذر تحديث أرشيف الخطط.');
    }
  }

  Future<void> _deletePlan(KhatmahPlan plan) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف خطة الختمة؟'),
        content: Text('سيتم حذف «${plan.title}» وتقدمها المسجل من هذا الجهاز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    try {
      await KhatmahPlanService.deletePlan(plan.id);
      await _loadPlans();
      if (mounted) AppSnackbar.success(context, 'تم حذف الخطة.');
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'تعذر حذف الخطة.');
    }
  }

  Future<void> _startReading(KhatmahPlan plan) async {
    await widget.onOpenPage(plan.nextPage);
    await _loadPlans();
  }

  List<KhatmahPlan> get _visiblePlans => _plans.where((plan) {
    return _showArchived ? plan.isArchived : !plan.isArchived;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final visiblePlans = _visiblePlans;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const PrimaryAppBar(title: 'خطة ختم القرآن', showBack: true),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: palette.primary))
          : RefreshIndicator(
              onRefresh: _loadPlans,
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.lg,
                  AppSpace.md,
                  AppSpace.lg,
                  AppSpace.xxxl,
                ),
                children: [
                  Text(
                    'ختمة على وتيرتك',
                    style: text.title.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'تُحسب الصفحة تلقائيًا بعد بقائها مفتوحة 15 ثانية في المصحف. أضف يدويًا ما تقرؤه خارجه.',
                    style: text.bodySmall.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppButton(
                    label: 'إنشاء خطة ختمة',
                    icon: Icons.add_rounded,
                    onPressed: _createPlan,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.menu_book_rounded),
                        label: Text('خططي'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.archive_outlined),
                        label: Text('الأرشيف'),
                      ),
                    ],
                    selected: {_showArchived},
                    onSelectionChanged: (selection) {
                      HapticFeedback.selectionClick();
                      setState(() => _showArchived = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                  if (visiblePlans.isEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpace.xxl,
                      ),
                      child: EmptyState(
                        icon: _showArchived
                            ? Icons.archive_outlined
                            : Icons.flag_outlined,
                        title: _showArchived
                            ? 'لا توجد خطط مؤرشفة'
                            : 'لم تنشئ خطة ختمة بعد',
                        subtitle: _showArchived
                            ? 'ستظهر هنا الخطط التي تختار أرشفتها.'
                            : 'اختر وردًا يوميًا أو موعدًا مناسبًا، وتابع تقدمك صفحةً بعد صفحة.',
                        actionLabel: _showArchived ? null : 'إنشاء أول خطة',
                        onAction: _showArchived ? null : _createPlan,
                      ),
                    )
                  else
                    for (final plan in visiblePlans) ...[
                      KhatmahPlanCard(
                        key: ValueKey(plan.id),
                        plan: plan,
                        onStartReading: () => _startReading(plan),
                        onRecordPages: () => _recordPages(plan),
                        onEdit: () => _editPlan(plan),
                        onPause: () => _togglePause(plan, paused: true),
                        onResume: () => _togglePause(plan, paused: false),
                        onArchive: () => _toggleArchive(plan, archived: true),
                        onRestore: () => _toggleArchive(plan, archived: false),
                        onDelete: () => _deletePlan(plan),
                      ),
                      const SizedBox(height: AppSpace.md),
                    ],
                  if (!_showArchived &&
                      _plans.where((plan) => !plan.isArchived).length >= 5)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpace.sm,
                      ),
                      child: Text(
                        'للحفاظ على وضوح المتابعة، يمكنك أرشفة الخطط المكتملة أو غير النشطة.',
                        textAlign: TextAlign.center,
                        style: text.caption.copyWith(color: palette.textMuted),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
