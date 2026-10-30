import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../adhkar/presentation/adhkar_page.dart';
import '../../more/presentation/widgets/theme_selector_sheet.dart';
import '../data/models/encyclopedia_section.dart';
import '../data/models/salaf_gem.dart';
import '../data/repositories/salaf_gems_repository.dart';
import 'salaf_gems_explorer_page.dart';
import 'widgets/encyclopedia_daily_card.dart';
import 'widgets/encyclopedia_hub_card.dart';
import 'widgets/encyclopedia_section_panel.dart';

class KalemTayebPortalPage extends StatefulWidget {
  const KalemTayebPortalPage({super.key});

  @override
  State<KalemTayebPortalPage> createState() => _KalemTayebPortalPageState();
}

class _KalemTayebPortalPageState extends State<KalemTayebPortalPage> {
  final SalafGemsRepository _repository = SalafGemsRepository.instance;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _hikamSectionKey = GlobalKey();
  final GlobalKey _imanSectionKey = GlobalKey();

  List<EncyclopediaGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    _groups = _repository.getEncyclopediaGroups();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: AppMotion.slow,
        curve: Curves.easeInOut,
      );
    }
  }

  void _openSection(EncyclopediaSection section) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      buildFadeRoute(
        page: SalafGemsExplorerPage(
          pageTitle: section.title,
          initialSectionId: section.id,
          initialAuthor: section.targetAuthor,
          initialCategory: section.targetCategory,
        ),
      ),
    );
  }

  void _openAllGems() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      buildFadeRoute(
        page: const SalafGemsExplorerPage(
          pageTitle: 'الموسوعة الشاملة لكافة الآثار',
        ),
      ),
    );
  }

  void _openFavorites() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      buildFadeRoute(
        page: const SalafGemsExplorerPage(
          pageTitle: 'المفضلة من الدرر والآثار',
        ),
      ),
    );
  }

  void _openAdhkar() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      buildFadeRoute(
        page: const AdhkarPage(showBack: true),
      ),
    );
  }

  void _openJawamea() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      buildFadeRoute(
        page: const SalafGemsExplorerPage(
          pageTitle: 'جوامع الكلم وفضائل الأعمال',
          initialCategory: 'فضائل الأعمال',
        ),
      ),
    );
  }

  void _onDailySectionTap(SalafGem gem) {
    Navigator.of(context).push(
      buildFadeRoute(
        page: SalafGemsExplorerPage(
          pageTitle: gem.topic.isNotEmpty ? gem.topic : gem.category,
          initialTopic: gem.topic.isNotEmpty ? gem.topic : null,
          initialCategory: gem.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الكلم الطيب',
              style: textTheme.title.copyWith(
                color: palette.text,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'موسوعة الفوائد والحكم والرقائق الإيمانية',
              style: textTheme.caption.copyWith(
                color: palette.gold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'البحث في الموسوعة',
            icon: Icon(
              Icons.search_rounded,
              color: palette.gold,
              size: AppIcon.md,
            ),
            onPressed: _openAllGems,
          ),
          IconButton(
            tooltip: 'المفضلة المحفوظة',
            icon: Icon(
              Icons.bookmark_border_rounded,
              color: palette.gold,
              size: AppIcon.md,
            ),
            onPressed: _openFavorites,
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Quranic Banner (Screenshot 3)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceRaised,
                      borderRadius: AppRadius.lgRadius,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: palette.shadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '«مَن كَانَ يُرِيدُ الْعِزَّةَ فَلِلَّهِ الْعِزَّةُ جَمِيعًا ۚ إِلَيْهِ يَصْعَدُ الْكَلِمُ الطَّيِّبُ وَالْعَمَلُ الصَّالِحُ يَرْفَعُهُ»',
                          textAlign: TextAlign.center,
                          style: textTheme.sacred.copyWith(
                            color: palette.gold,
                            height: 1.9,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          'سورة فاطر: 10',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.md),

                  // 2x2 Grand Hub Grid (Screenshot 3)
                  Row(
                    children: [
                      Expanded(
                        child: EncyclopediaHubCard(
                          title: 'فوائد وحكم',
                          subtitle: 'موسوعة الفوائد والحكم',
                          icon: Icons.menu_book_rounded,
                          accentColor: palette.gold,
                          onTap: () => _scrollToKey(_hikamSectionKey),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: EncyclopediaHubCard(
                          title: 'أدعية وأذكار',
                          subtitle: 'موسوعة الأدعية والأذكار',
                          icon: Icons.chat_bubble_outline_rounded,
                          accentColor: palette.primary,
                          onTap: _openAdhkar,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: EncyclopediaHubCard(
                          title: 'جوامع الكلم',
                          subtitle: 'جوامع الكلم وفضائل الأعمال',
                          icon: Icons.star_border_rounded,
                          accentColor: palette.gold,
                          onTap: _openJawamea,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: EncyclopediaHubCard(
                          title: 'مقالات إيمانية',
                          subtitle: 'مقالات ورقائق إيمانية',
                          icon: Icons.edit_note_rounded,
                          accentColor: palette.primary,
                          onTap: () => _scrollToKey(_imanSectionKey),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpace.lg),

                  // Featured Daily Card (Screenshot 3)
                  EncyclopediaDailyCard(
                    onOpenGemSection: _onDailySectionTap,
                  ),

                  const SizedBox(height: AppSpace.lg),

                  // Big Action Pill: "تصفح كامل الموسوعة والبحث الشامل"
                  Material(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.pillRadius,
                    child: InkWell(
                      onTap: _openAllGems,
                      borderRadius: AppRadius.pillRadius,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.lg,
                          vertical: AppSpace.md,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.gold.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.explore_rounded,
                              color: palette.gold,
                              size: AppIcon.sm,
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                'الانتقال لتصفح كامل الموسوعة والبحث الشامل',
                                style: textTheme.titleSmall.copyWith(
                                  color: palette.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grouped Section Panels
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.md,
              0,
              AppSpace.md,
              AppSpace.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = _groups[index];
                  Key? panelKey;
                  if (group.id == 'salaf_gems_group') {
                    panelKey = _hikamSectionKey;
                  } else if (group.id == 'iman_articles') {
                    panelKey = _imanSectionKey;
                  }

                  return Padding(
                    key: panelKey,
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpace.lg,
                    ),
                    child: EncyclopediaSectionPanel(
                      group: group,
                      onSelectSection: _openSection,
                    ),
                  );
                },
                childCount: _groups.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: palette.surface,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => ThemeSelectorSheet.show(context),
                  icon: Icon(
                    Icons.dark_mode_outlined,
                    color: palette.textMuted,
                    size: AppIcon.sm,
                  ),
                  label: Text(
                    'قراءة ليلية',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: _openFavorites,
                  icon: Icon(
                    Icons.bookmark_outline_rounded,
                    color: palette.textMuted,
                    size: AppIcon.sm,
                  ),
                  label: Text(
                    'المفضلة',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: palette.textMuted,
                    size: AppIcon.sm,
                  ),
                  label: Text(
                    'عودة',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
