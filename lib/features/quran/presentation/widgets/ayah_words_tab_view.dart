import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/services/quran_tafsir_service.dart';

class AyahWordsTabView extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const AyahWordsTabView({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  State<AyahWordsTabView> createState() => _AyahWordsTabViewState();
}

class _AyahWordsTabViewState extends State<AyahWordsTabView> {
  late Future<List<WordMeaning>> _wordsFuture;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void didUpdateWidget(covariant AyahWordsTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber ||
        oldWidget.ayahNumber != widget.ayahNumber) {
      _loadWords();
    }
  }

  void _loadWords() {
    _wordsFuture = QuranTafsirService.fetchWordMeanings(
      widget.surahNumber,
      widget.ayahNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return FutureBuilder<List<WordMeaning>>(
      future: _wordsFuture,
      initialData: QuranTafsirService.getCachedWordMeanings(
        widget.surahNumber,
        widget.ayahNumber,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            (snapshot.data == null || snapshot.data!.isEmpty)) {
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AppSpace.sm,
                  horizontal: AppSpace.md,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  children: [
                    AppSkeleton(width: 80, height: 22),
                    Spacer(),
                    AppSkeleton(width: 130, height: 18),
                  ],
                ),
              );
            },
          );
        }

        final words = snapshot.data ?? const [];

        if (words.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: AppIcon.lg,
                    color: palette.textMuted,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'المصحف يعمل كاملاً دون إنترنت',
                    style: textTheme.bodySmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'معاني الكلمات المفردة تتطلب اتصالاً لحفظها تلقائياً على جهازك للاستخدام لاحقاً بدون إنترنت.',
                    style: textTheme.caption.copyWith(color: palette.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppButton.outline(
                    label: 'إعادة المحاولة',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _loadWords();
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: words.length,
          itemBuilder: (context, index) {
            final item = words[index];
            final hasTranslit = item.transliteration != null &&
                item.transliteration!.isNotEmpty;

            return Container(
              margin: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpace.sm,
                horizontal: AppSpace.md,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: palette.border.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.word,
                          style: textTheme.sacred.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        if (hasTranslit) ...[
                          const SizedBox(height: AppSpace.xxs),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: palette.goldSoft,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              item.transliteration!,
                              style: textTheme.captionBold.copyWith(
                                color: palette.gold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    flex: 6,
                    child: Text(
                      item.meaning,
                      textAlign: TextAlign.end,
                      style: textTheme.bodySmallMedium.copyWith(
                        color: palette.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
