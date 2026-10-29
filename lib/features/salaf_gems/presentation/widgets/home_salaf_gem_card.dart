import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyGem();
  }

  Future<void> _loadDailyGem() async {
    setState(() => _isLoading = true);
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
    final isFav = await _repository.toggleFavorite(_currentGem!.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  void _copyGem() {
    if (_currentGem == null) return;
    Clipboard.setData(ClipboardData(text: _currentGem!.shareableText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الأثر والمصدر إلى الحافظة',
          style: context.text.body.copyWith(
            color: context.palette.onPrimary,
          ),
        ),
        backgroundColor: context.palette.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openExplorer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SalafGemsExplorerPage(),
      ),
    );
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
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          color: palette.primary,
        ),
      );
    }

    final gem = _currentGem;
    if (gem == null) return const SizedBox.shrink();

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
                        color: palette.primarySoft,
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
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: palette.border,
                              ),
                            ),
                            child: Text(
                              gem.category,
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

                // Main Quote
                Text(
                  gem.text,
                  style: textTheme.sacred.copyWith(
                    color: palette.text,
                    height: 1.75,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: AppSpace.md),

                // Author & Attribution
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: AppSpace.xs,
                      height: AppSpace.md,
                      decoration: BoxDecoration(
                        color: palette.gold,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        gem.role.isNotEmpty
                            ? '${gem.author} · ${gem.role}'
                            : gem.author,
                        style: textTheme.label.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (gem.sourceRef.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'المصدر: ${gem.sourceRef}',
                    style: textTheme.caption.copyWith(
                      color: palette.textSubtle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpace.md),

                // Footer Actions & Full Explorer Link
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
                        ),
                      ),
                      onPressed: () => _openExplorer(context),
                      icon: Icon(
                        Icons.auto_stories_rounded,
                        color: palette.primary,
                      ),
                      label: Text(
                        'تصفح الموسوعة ←',
                        style: textTheme.label.copyWith(
                          color: palette.primary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          color: palette.textMuted,
                          tooltip: 'نسخ الأثر',
                          onPressed: _copyGem,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          color: palette.textMuted,
                          tooltip: 'مشاركة كبطاقة',
                          onPressed: () => SalafGemShareSheet.show(context, gem),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: _isFavorite ? palette.primary : palette.textMuted,
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
