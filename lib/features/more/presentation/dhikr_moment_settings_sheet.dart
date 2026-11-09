import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/services/dhikr_moment_service.dart';

class DhikrMomentSettingsSheet {
  static Future<void> show(BuildContext context) async {
    var settings = await DhikrMomentService.load();
    late StateSetter setModalState;
    if (!context.mounted) return;
    Future<void> pickWindowTime(bool isStart) async {
      final minutes = isStart ? settings.startMinutes : settings.endMinutes;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      );
      if (picked == null) return;
      final value = picked.hour * 60 + picked.minute;
      setModalState(() {
        settings = isStart
            ? settings.copyWith(startMinutes: value)
            : settings.copyWith(endMinutes: value);
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          setModalState = setState;
          final preview = switch (settings.content) {
            DhikrMomentContent.names => ('الرَّحْمَنُ', 'واسع الرحمة بخلقه'),
            DhikrMomentContent.adhkar => (
              'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
              'تنزيهٌ لله وحمدٌ له',
            ),
            DhikrMomentContent.duas => (
              'رَبِّ زِدْنِي عِلْمًا',
              'دعاءٌ قرآني قصير',
            ),
            DhikrMomentContent.quran => (
              'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
              'الشرح • ٦',
            ),
            DhikrMomentContent.hadith => (
              'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
              'صحيح البخاري • ١',
            ),
            DhikrMomentContent.mixed => (
              'تذكيرٌ يتجدد خلال يومك',
              'ذكر • دعاء • آية • حديث',
            ),
          };
          final colors = Theme.of(context).colorScheme;
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .88,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.lg,
                  AppSpace.sm,
                  AppSpace.lg,
                  AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: AppRadius.mdRadius,
                          ),
                          child: Icon(Icons.spa_rounded, color: colors.primary),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'لحظة ذكر',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'اختر ما تحب أن يذكّرك به يومك',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: settings.enabled,
                          onChanged: (value) async {
                            setModalState(
                              () =>
                                  settings = settings.copyWith(enabled: value),
                            );
                            if (value &&
                                DhikrMomentService.supportsFloatingOverlay &&
                                !await DhikrMomentService.hasOverlayPermission()) {
                              await DhikrMomentService.requestOverlayPermission();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpace.lg),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: AppRadius.lgRadius,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    settings.content == DhikrMomentContent.mixed
                                        ? 'لَحْظَةٌ لِقَلْبِكَ'
                                        : 'مِثَالٌ عَلَى الْبِطَاقَة',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.onPrimary.withValues(
                                            alpha: .78,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  Text(
                                    preview.$1,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: colors.onPrimary,
                                          height: 1.5,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    preview.$2,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.onPrimary.withValues(
                                            alpha: .82,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.lg),
                            Text(
                              'ماذا تريد أن يظهر؟',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpace.sm),
                            Wrap(
                              spacing: AppSpace.sm,
                              runSpacing: AppSpace.xs,
                              children: [
                                for (final option in DhikrMomentContent.values)
                                  ChoiceChip(
                                    avatar: Icon(switch (option) {
                                      DhikrMomentContent.names =>
                                        Icons.auto_awesome_rounded,
                                      DhikrMomentContent.adhkar =>
                                        Icons.favorite_rounded,
                                      DhikrMomentContent.duas =>
                                        Icons.volunteer_activism_rounded,
                                      DhikrMomentContent.quran =>
                                        Icons.menu_book_rounded,
                                      DhikrMomentContent.hadith =>
                                        Icons.format_quote_rounded,
                                      DhikrMomentContent.mixed =>
                                        Icons.shuffle_rounded,
                                    }, size: AppIcon.xs),
                                    label: Text(switch (option) {
                                      DhikrMomentContent.mixed => 'رحلة متنوعة',
                                      DhikrMomentContent.adhkar => 'الأذكار',
                                      DhikrMomentContent.names => 'أسماء الله',
                                      DhikrMomentContent.duas => 'أدعية',
                                      DhikrMomentContent.quran => 'آيات قرآنية',
                                      DhikrMomentContent.hadith => 'من السنة',
                                    }),
                                    selected: settings.content == option,
                                    onSelected: (_) => setModalState(
                                      () => settings = settings.copyWith(
                                        content: option,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.lg),
                            Text(
                              'متى تحب أن تراها؟',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              'حتى ${settings.timesPerDay} ${settings.timesPerDay == 1 ? 'مرة' : 'مرات'} خلال الفترة التي تختارها',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Slider(
                                value: settings.timesPerDay.toDouble(),
                                min: 1,
                                max: DhikrMomentService.maxAppearancesPerDay
                                    .toDouble(),
                                divisions:
                                    DhikrMomentService.maxAppearancesPerDay - 1,
                                label: '${settings.timesPerDay}',
                                onChanged: (value) => setModalState(
                                  () => settings = settings.copyWith(
                                    timesPerDay: value.round(),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => pickWindowTime(true),
                                    icon: const Icon(Icons.wb_sunny_outlined),
                                    label: Text(
                                      'من ${_formatMomentTime(settings.startMinutes)}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => pickWindowTime(false),
                                    icon: const Icon(
                                      Icons.nights_stay_outlined,
                                    ),
                                    label: Text(
                                      'إلى ${_formatMomentTime(settings.endMinutes)}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.md),
                            if (DhikrMomentService.supportsFloatingOverlay)
                              TextButton.icon(
                                onPressed:
                                    DhikrMomentService.requestOverlayPermission,
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text(
                                  'فتح إعدادات الظهور فوق التطبيقات',
                                ),
                              )
                            else
                              Text(
                                'على iPhone تظهر كتذكيرات مجدولة، إذ لا يسمح النظام ببطاقة فوق التطبيقات.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    FilledButton.icon(
                      onPressed: () async {
                        if (settings.endMinutes <= settings.startMinutes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('اختر وقت انتهاء بعد وقت البدء.'),
                            ),
                          );
                          return;
                        }
                        final ready = await DhikrMomentService.save(settings);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (!ready && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'حُفظت الإعدادات، لكن تعذر تفعيل التذكيرات. تحقق من الأذونات.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('حفظ لحظة الذكر'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatMomentTime(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
