import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/daily_ayah_dua.dart';
import '../../data/repositories/daily_ayah_dua_repository.dart';

class HomeDailyAyahDuaCard extends StatefulWidget {
  const HomeDailyAyahDuaCard({super.key});

  @override
  State<HomeDailyAyahDuaCard> createState() => _HomeDailyAyahDuaCardState();
}

class _HomeDailyAyahDuaCardState extends State<HomeDailyAyahDuaCard> {
  final DailyAyahDuaRepository _repository = DailyAyahDuaRepository.instance;
  late DailyAyahDua _item;

  @override
  void initState() {
    super.initState();
    _item = _repository.getDailyItem();
  }

  void _cycleNext() {
    HapticFeedback.lightImpact();
    setState(() {
      _item = _repository.getRandomItem(excludingId: _item.id);
    });
  }

  void _copy() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _item.shareableText));
    AppSnackbar.success(context, 'تم نسخ الذكر إلى الحافظة');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isAyah = _item.isAyah;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: palette.border,
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Badge, Title & Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                decoration: BoxDecoration(
                  color: isAyah ? palette.primarySoft : palette.goldSoft,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(
                  isAyah ? Icons.auto_awesome_rounded : Icons.menu_book_rounded,
                  color: isAyah ? palette.primary : palette.gold,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xxs,
                  children: [
                    Text(
                      'آية ودعاء اليوم',
                      style: textTheme.titleSmall.copyWith(
                        color: palette.text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isAyah ? palette.primarySoft : palette.goldSoft,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        _item.typeLabel,
                        style: textTheme.caption.copyWith(
                          color: isAyah ? palette.primary : palette.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                color: palette.textMuted,
                tooltip: 'قبس آخر',
                onPressed: _cycleNext,
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                color: palette.textMuted,
                tooltip: 'نسخ',
                onPressed: _copy,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),

          // Compact Sacred Body (1-2 lines max)
          Text(
            _item.formattedText,
            style: textTheme.sacred.copyWith(
              color: palette.text,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.xs),

          // Citation & Topic
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _item.source,
                style: textTheme.caption.copyWith(
                  color: palette.textSubtle,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                '· ${_item.topic}',
                style: textTheme.caption.copyWith(
                  color: palette.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
