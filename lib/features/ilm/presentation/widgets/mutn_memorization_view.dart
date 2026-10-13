import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import 'shamela_text_highlighter.dart';

/// Interactive self-testing and memorization view for students of Islamic mutun.
/// Allows concealing and revealing lines, bayts, or paragraphs to test recall.
class MutnMemorizationView extends StatefulWidget {
  final String content;
  final String fontFamily;
  final double fontSizeDelta;
  final double lineHeight;

  const MutnMemorizationView({
    super.key,
    required this.content,
    required this.fontFamily,
    required this.fontSizeDelta,
    required this.lineHeight,
  });

  @override
  State<MutnMemorizationView> createState() => _MutnMemorizationViewState();
}

class _MutnMemorizationViewState extends State<MutnMemorizationView> {
  final Set<int> _revealed = <int>{};

  List<String> get _paragraphs {
    return widget.content
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  void _revealAll() {
    HapticFeedback.selectionClick();
    setState(() {
      _revealed.addAll(List.generate(_paragraphs.length, (i) => i));
    });
  }

  void _hideAll() {
    HapticFeedback.selectionClick();
    setState(() {
      _revealed.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final list = _paragraphs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Helper pill
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: palette.border, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: AppIcon.sm,
                color: palette.gold,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  'اضغط على أي فقرة لكشفها أو إخفائها لاختبار حفظك',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
              ),
              TextButton(
                onPressed: _revealAll,
                child: Text(
                  'كشف الكل',
                  style: textTheme.caption.copyWith(color: palette.primary),
                ),
              ),
              TextButton(
                onPressed: _hideAll,
                child: Text(
                  'إخفاء الكل',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpace.md),

        // Interactive cards
        ...List.generate(list.length, (index) {
          final p = list[index];
          final isRevealed = _revealed.contains(index);
          final words = p.split(' ');
          final cue = words.isNotEmpty ? words.first : '...';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isRevealed) {
                    _revealed.remove(index);
                  } else {
                    _revealed.add(index);
                  }
                });
              },
              borderRadius: AppRadius.mdRadius,
              child: AnimatedContainer(
                duration: AppMotion.base,
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: isRevealed ? palette.surfaceRaised : palette.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: isRevealed ? palette.gold : palette.border,
                    width: isRevealed ? 1.5 : 1,
                  ),
                ),
                child: isRevealed
                    ? Text.rich(
                        ShamelaTextHighlighter.buildSpans(
                          text: p,
                          palette: palette,
                          textTheme: textTheme,
                          fontSizeDelta: widget.fontSizeDelta,
                          fontFamily: widget.fontFamily,
                          lineHeight: widget.lineHeight,
                        ),
                        textAlign: TextAlign.start,
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: palette.primarySoft,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              'مفتاح: $cue ...',
                              style: textTheme.caption.copyWith(
                                color: palette.primary,
                                fontWeight: FontWeight.bold,
                                fontFamily: widget.fontFamily,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.visibility_rounded,
                            size: AppIcon.sm,
                            color: palette.textMuted,
                          ),
                        ],
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
