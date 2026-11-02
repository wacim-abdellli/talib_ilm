import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';

/// Interactive modal sheet to guide users through OEM battery optimization exemptions,
/// ensuring on-time Adhan alarms across aggressive Android OEM task killers (MIUI, OneUI, EMUI).
class BatteryReliabilitySheet extends StatefulWidget {
  const BatteryReliabilitySheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.90,
      builder: (_) => const BatteryReliabilitySheet(),
    );
  }

  @override
  State<BatteryReliabilitySheet> createState() => _BatteryReliabilitySheetState();
}

class _BatteryReliabilitySheetState extends State<BatteryReliabilitySheet> {
  bool _isOptimizedExempt = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (mounted) {
        setState(() {
          _isOptimizedExempt = status.isGranted;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestExemption() async {
    HapticFeedback.lightImpact();
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (mounted) {
        setState(() {
          _isOptimizedExempt = status.isGranted;
        });
        if (status.isGranted) {
          AppSnackbar.success(
            context,
            'تم استثناء التطبيق بنجاح، وستعمل تنبيهات الأذان بدقة كاملة.',
            hasNavBar: true,
          );
        }
      }
    } catch (_) {
      // Gracefully ignore platform exception
    }
  }

  Future<void> _openSystemSettings() async {
    HapticFeedback.lightImpact();
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppSheet(
        titleText: 'ضمان دقة الأذان والتنبيهات',
        icon: Icons.alarm_on_rounded,
        showCloseButton: true,
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.xl,
          AppSpace.md,
          AppSpace.xl,
          AppSpace.xxl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'لحماية أذان الفجر والصلوات من الإيقاف أو التأخير بواسطة ميزات توفير الطاقة في هاتفك، يُرجى تفعيل استثناء التطبيق من قيود البطارية.',
                style: textTheme.body.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Status Card
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: _isOptimizedExempt ? palette.primarySoft : palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: _isOptimizedExempt ? palette.primary : palette.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isOptimizedExempt
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: _isOptimizedExempt ? palette.primary : palette.textSubtle,
                      size: AppIcon.md,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOptimizedExempt
                                ? 'التطبيق محمي من إيقاف النظام'
                                : 'التطبيق معرض لقيود توفير الطاقة',
                            style: textTheme.titleSmall.copyWith(
                              color: _isOptimizedExempt
                                  ? palette.primary
                                  : palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            _isOptimizedExempt
                                ? 'تم تفعيل استثناء البطارية بنجاح، ستصل التنبيهات في وقتها.'
                                : 'قد تقوم بعض الأنظمة (مثل شاومي وسامسونج) بتأخير الأذان أثناء نوم الهاتف.',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpace.xl),

              // Action Buttons
              if (!_isOptimizedExempt && Platform.isAndroid) ...[
                AppButton(
                  label: 'طلب استثناء توفير الطاقة',
                  icon: Icons.battery_charging_full_rounded,
                  onPressed: _requestExemption,
                  isLoading: _loading,
                ),
                const SizedBox(height: AppSpace.sm),
              ],

              AppButton.outline(
                label: 'فتح إعدادات النظام للتطبيق',
                icon: Icons.settings_rounded,
                onPressed: _openSystemSettings,
              ),

              const SizedBox(height: AppSpace.xxl),

              // OEM-specific instructions
              Text(
                'تعليمات حسب نوع هاتفك:',
                style: textTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: AppSpace.sm),

              _buildOemInstructionCard(
                palette: palette,
                textTheme: textTheme,
                brand: 'شاومي / ريدمي / بوكو (Xiaomi / POCO)',
                steps:
                    '1. تفعيل (التشغيل التلقائي Autostart).\n2. في توفير طاقة البطارية: اختيار (لا توجد قيود No restrictions).',
              ),
              const SizedBox(height: AppSpace.xs),

              _buildOemInstructionCard(
                palette: palette,
                textTheme: textTheme,
                brand: 'سامسونج (Samsung)',
                steps:
                    '1. في إعدادات التطبيق -> البطارية: اختيار (غير مقيد Unrestricted).\n2. إضافة التطبيق إلى قائمة (التطبيقات التي لا تنام أبداً Never sleeping apps).',
              ),
              const SizedBox(height: AppSpace.xs),

              _buildOemInstructionCard(
                palette: palette,
                textTheme: textTheme,
                brand: 'هواوي / هونر (Huawei / Honor)',
                steps:
                    'في إعدادات البطارية -> إدارة التشغيل (App Launch): تحويل التطبيق إلى (إدارة يدوية Manage manually) مع السماح بالتشغيل في الخلفية.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOemInstructionCard({
    required AppPalette palette,
    required AppTextTheme textTheme,
    required String brand,
    required String steps,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            brand,
            style: textTheme.caption.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            steps,
            style: textTheme.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
