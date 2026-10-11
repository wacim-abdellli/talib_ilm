import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';

/// Quick Jump Bottom Sheet for direct page or landmark navigation in the Mushaf (Wahi style).
class QuickJumpSheet extends StatefulWidget {
  final ValueChanged<int> onJumpToPage;

  const QuickJumpSheet({
    super.key,
    required this.onJumpToPage,
  });

  static const List<QuickPreset> presets = [
    QuickPreset(label: 'الفاتحة', page: 1, subtitle: 'ص ١'),
    QuickPreset(label: 'آية الكرسي', page: 42, subtitle: 'ص ٤٢'),
    QuickPreset(label: 'سورة الكهف', page: 293, subtitle: 'ص ٢٩٣'),
    QuickPreset(label: 'سورة يس', page: 440, subtitle: 'ص ٤٤٠'),
    QuickPreset(label: 'سورة الملك', page: 562, subtitle: 'ص ٥٦٢'),
    QuickPreset(label: 'جزء عم', page: 582, subtitle: 'ص ٥٨٢'),
  ];

  @override
  State<QuickJumpSheet> createState() => _QuickJumpSheetState();
}

class _QuickJumpSheetState extends State<QuickJumpSheet> {
  final TextEditingController _pageController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _submitPage() {
    final text = _pageController.text.trim();
    final page = int.tryParse(text);
    if (page == null || page < 1 || page > 604) {
      setState(() {
        _errorMessage = 'الرجاء إدخال رقم صفحة بين ١ و ٦٠٤';
      });
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    widget.onJumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.explore_rounded,
                    color: palette.gold,
                    size: AppIcon.sm,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الانتقال السريع في المصحف',
                      style: context.text.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'اختر صفحة بين ١ و ٦٠٤ أو محطة مشهورة',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.lg),

          // Direct Page Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: context.text.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'رقم الصفحة (١ - ٦٠٤)',
                    hintStyle: context.text.bodySmall.copyWith(
                      color: palette.textMuted,
                    ),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
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
                      borderSide: BorderSide(color: palette.gold, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _submitPage(),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              AppButton(
                label: 'انتقال',
                onPressed: _submitPage,
              ),
            ],
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              _errorMessage!,
              style: context.text.caption.copyWith(
                color: palette.error,
              ),
              textAlign: TextAlign.start,
            ),
          ],

          const SizedBox(height: AppSpace.lg),

          Text(
            'محطات وسور متكررة',
            style: context.text.label.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          // Preset Chips Grid
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: QuickJumpSheet.presets.map((preset) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    widget.onJumpToPage(preset.page);
                  },
                  borderRadius: AppRadius.pillRadius,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          preset.label,
                          style: context.text.caption.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          preset.subtitle,
                          style: context.text.caption.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpace.lg),
        ],
      ),
    );
  }
}

class QuickPreset {
  final String label;
  final int page;
  final String subtitle;

  const QuickPreset({
    required this.label,
    required this.page,
    required this.subtitle,
  });
}
