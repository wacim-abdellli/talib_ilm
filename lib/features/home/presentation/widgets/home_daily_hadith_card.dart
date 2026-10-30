import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../hadith/data/models/hadith_models.dart';
import '../../../hadith/data/services/hadith_service.dart';
import '../../../hadith/presentation/pages/hadith_explorer_page.dart';
import '../../../hadith/presentation/widgets/hadith_card.dart';

class HomeDailyHadithCard extends StatefulWidget {
  const HomeDailyHadithCard({super.key});

  @override
  State<HomeDailyHadithCard> createState() => _HomeDailyHadithCardState();
}

class _HomeDailyHadithCardState extends State<HomeDailyHadithCard> {
  final HadithService _service = HadithService();
  GradedHadith? _hadith;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyHadith();
  }

  Future<void> _loadDailyHadith() async {
    final h = await _service.getDailyHadith();
    if (!mounted) return;
    setState(() {
      _hadith = h;
      _isLoading = false;
    });
  }

  Future<void> _cycleHadith() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });
    final h = await _service.getRandomHadith(excludeId: _hadith?.id);
    if (!mounted) return;
    setState(() {
      _hadith = h;
      _isLoading = false;
    });
  }

  void _openExplorer(BuildContext context) {
    Navigator.push(
      context,
      buildFadeRoute(page: const HadithExplorerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_isLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: palette.border),
        ),
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: palette.primary,
        ),
      );
    }

    if (_hadith == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header Row
        Row(
          children: [
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.xs),
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: AppRadius.mdRadius,
              ),
              child: Icon(
                Icons.format_quote_rounded,
                color: palette.primary,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      AppStrings.homeHadithTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: palette.text,
                        fontFamily: AppTextStyles.cairo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xs,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      'ﷺ',
                      style: AppTextStyles.caption.copyWith(
                        color: palette.primary,
                        fontFamily: AppTextStyles.amiri,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shuffle / Next Hadith
                IconButton(
                  onPressed: _cycleHadith,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: palette.textMuted,
                  ),
                  tooltip: 'حديث آخر',
                ),
                // Open Explorer Pill Button
                Container(
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: palette.primary,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadius.pillRadius,
                      onTap: () => _openExplorer(context),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'المزيد',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: palette.primary,
                                fontFamily: AppTextStyles.cairo,
                              ),
                            ),
                            Icon(
                              Icons.chevron_left_rounded,
                              color: palette.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xs),

        // Display the HadithCard
        HadithCard(
          hadith: _hadith!,
          initiallyExpanded: false,
        ),
      ],
    );
  }
}
