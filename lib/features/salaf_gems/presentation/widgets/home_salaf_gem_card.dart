import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/salaf_gem.dart';
import '../../data/repositories/salaf_gems_repository.dart';
import '../salaf_gems_explorer_page.dart';
import 'salaf_gem_share_sheet.dart';

class HomeSalafGemCard extends StatefulWidget {
  const HomeSalafGemCard({super.key});

  @override
  State<HomeSalafGemCard> createState() => _HomeSalafGemCardState();
}

class _HomeSalafGemCardState extends State<HomeSalafGemCard> {
  final SalafGemsRepository _repository = SalafGemsRepository.instance;
  SalafGem? _currentGem;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentGem = _repository.getFallbackGem();
    _loadDailyGem();
  }

  Future<void> _loadDailyGem() async {
    final gem = await _repository.getDailyGem();
    final isFav = await _repository.isFavorite(gem.id);
    if (!mounted) return;
    setState(() {
      _currentGem = gem;
      _isFavorite = isFav;
      _isLoading = false;
    });
  }

  Future<void> _loadRandomGem() async {
    HapticFeedback.lightImpact();
    final next = await _repository.getRandomGem(excludingId: _currentGem?.id);
    final isFav = await _repository.isFavorite(next.id);
    if (!mounted) return;
    setState(() {
      _currentGem = next;
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_currentGem == null) return;
    HapticFeedback.lightImpact();
    final isFav = await _repository.toggleFavorite(_currentGem!.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  void _copyGem() {
    if (_currentGem == null) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _currentGem!.shareableText));
    AppSnackbar.success(context, 'تم نسخ الأثر والمصدر إلى الحافظة بنجاح');
  }

  void _openExplorer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SalafGemsExplorerPage(),
      ),
    );
  }

  String _formatCategory(String cat) {
    if (cat.contains('الصحابة')) return 'مِنْ أَقْوَالِ الصَّحَابَةِ';
    if (cat.contains('النبوي') || cat.contains('نبوية')) return 'وَصَايَا نَبَوِيَّةٌ شَرِيفَة';
    if (cat.contains('العلم')) return 'فِي طَلَبِ العِلْمِ';
    if (cat.contains('زهد') || cat.contains('رقائق')) return 'رَقَائِقُ القُلُوبِ';
    return 'دُرَرُ السَّلَفِ';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (_isLoading) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: palette.border,
          ),
        ),
      );
    }

    final gem = _currentGem ?? _repository.getFallbackGem();
    final categoryLabel = _formatCategory(gem.category);

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(
          color: palette.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.xlRadius,
          onTap: () => _openExplorer(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Title Badge & Shuffle Action
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                      decoration: BoxDecoration(
                        color: palette.goldSoft,
                        borderRadius: AppRadius.mdRadius,
                      ),
                      child: Icon(
                        Icons.format_quote_rounded,
                        color: palette.gold,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        children: [
                          Text(
                            'قَبَسٌ مِنَ السَّلَفِ',
                            style: textTheme.titleSmall.copyWith(
                              color: palette.text,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceMuted,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: palette.border,
                              ),
                            ),
                            child: Text(
                              categoryLabel,
                              style: textTheme.caption.copyWith(
                                color: palette.primary,
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
                      onPressed: _loadRandomGem,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),

                // Scholar Identity Row (Dignified Gold Marker, No Avatar Circle)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: AppSpace.xs,
                      height: AppSpace.lg,
                      decoration: BoxDecoration(
                        color: palette.gold,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gem.author,
                            style: textTheme.label.copyWith(
                              color: palette.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (gem.role.isNotEmpty)
                            Text(
                              gem.role,
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),

                // Main Quote Container with Shakl-friendly Line Height
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Text(
                    '«${gem.cleanText}»',
                    style: textTheme.sacred.copyWith(
                      color: palette.text,
                      height: 1.9,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),

                // Scholarly Source Citation
                if (gem.sourceRef.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: palette.gold,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          'العَزْوُ وَالتَّخْرِيجُ: ${gem.sourceRef}',
                          style: textTheme.caption.copyWith(
                            color: palette.textSubtle,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],

                // Footer Actions & Full Explorer Link
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
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
                              horizontal: AppSpace.md,
                              vertical: AppSpace.xs,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_stories_rounded,
                                  color: palette.primary,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  'تصفح الموسوعة ←',
                                  style: textTheme.label.copyWith(
                                    color: palette.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          color: palette.textMuted,
                          tooltip: 'نسخ الأثر والتخريج',
                          onPressed: _copyGem,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          color: palette.textMuted,
                          tooltip: 'مشاركة البطاقة الدعوية',
                          onPressed: () => SalafGemShareSheet.show(context, gem),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: _isFavorite ? palette.gold : palette.textMuted,
                          ),
                          tooltip: _isFavorite ? 'إزالة من المفضلة' : 'حفظ في المفضلة',
                          onPressed: _toggleFavorite,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
