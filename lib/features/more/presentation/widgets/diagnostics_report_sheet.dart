import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/local_diagnostics_service.dart';
import '../../../../core/services/offline_connectivity_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_states.dart';

/// Privacy-first sheet presenting local diagnostics, network state, and export actions.
class DiagnosticsReportSheet extends StatefulWidget {
  const DiagnosticsReportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppSheet.show<void>(
      context: context,
      builder: (_) => const DiagnosticsReportSheet(),
    );
  }

  @override
  State<DiagnosticsReportSheet> createState() => _DiagnosticsReportSheetState();
}

class _DiagnosticsReportSheetState extends State<DiagnosticsReportSheet> {
  final LocalDiagnosticsService _diagnostics = LocalDiagnosticsService();
  late Future<List<DiagnosticEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _diagnostics.loadEvents();
    OfflineConnectivityService().checkConnectivity();
  }

  Future<void> _copyReport() async {
    await _diagnostics.loadEvents();
    final report = _diagnostics.buildShareableReport();
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    AppSnackbar.success(context, 'تم نسخ تقرير التشخيص إلى الحافظة');
  }

  Future<void> _clearLogs() async {
    await _diagnostics.clearEvents();
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _eventsFuture = _diagnostics.loadEvents();
    });
    AppSnackbar.success(context, 'تم مسح سجل التشخيص المحلي');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppSheet(
        titleText: 'التشخيص والدعم الفني',
        icon: Icons.health_and_safety_rounded,
        showCloseButton: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: OfflineConnectivityService().isOfflineNotifier,
              builder: (context, isOffline, _) {
                return AppCard(
                  color: isOffline ? palette.errorSoft : palette.primarySoft,
                  border: Border.all(
                    color: isOffline ? palette.error : palette.border,
                  ),
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOffline
                                ? Icons.wifi_off_rounded
                                : Icons.verified_user_outlined,
                            size: AppIcon.sm,
                            color: isOffline ? palette.error : palette.primary,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              isOffline
                                  ? 'حالة الشبكة: غير متصل حالياً'
                                  : 'حالة الشبكة: متصل بالإنترنت',
                              style: textTheme.bodyBold.copyWith(
                                color: palette.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        'جميع السجلات تُحفظ محلياً على جهازك فقط ولا يتم إرسال أي بيانات تلقائياً.',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpace.md),
            Flexible(
              child: FutureBuilder<List<DiagnosticEvent>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const AppLoadingIndicator();
                  }
                  final items = snapshot.data ?? _diagnostics.recentEvents;
                  if (items.isEmpty) {
                    return const SingleChildScrollView(
                      child: AppEmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'لا توجد أعطال مسجلة',
                        subtitle:
                            'يعمل التطبيق بشكل طبيعي ولم تُرصد أخطاء حتى الآن.',
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.xs),
                    itemBuilder: (context, index) {
                      final event = items[index];
                      final isErr = event.severity == 'error';
                      final isWarn = event.severity == 'warn';
                      final badgeColor = isErr
                          ? palette.error
                          : (isWarn ? palette.gold : palette.primary);
                      final badgeBg = isErr
                          ? palette.errorSoft
                          : (isWarn ? palette.goldSoft : palette.primarySoft);
                      final ts = event.timestamp
                          .toIso8601String()
                          .replaceFirst('T', ' ')
                          .substring(0, 19);

                      return AppCard(
                        color: palette.surface,
                        border: Border.all(color: palette.border),
                        padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.xs,
                                    vertical: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: AppRadius.smRadius,
                                  ),
                                  child: Text(
                                    '${event.severity}/${event.category}',
                                    style: textTheme.captionBold.copyWith(
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Expanded(
                                  child: Text(
                                    ts,
                                    style: textTheme.caption.copyWith(
                                      color: palette.textSubtle,
                                    ),
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              event.message,
                              style: textTheme.caption.copyWith(
                                color: palette.text,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'نسخ التقرير',
                    icon: Icons.copy_rounded,
                    onPressed: _copyReport,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: AppButton.outline(
                    label: 'مسح السجل',
                    icon: Icons.delete_sweep_rounded,
                    onPressed: _clearLogs,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
