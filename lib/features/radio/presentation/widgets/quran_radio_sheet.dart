import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/quran_radio_model.dart';
import '../../data/services/quran_radio_service.dart';

class QuranRadioSheet extends StatefulWidget {
  const QuranRadioSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuranRadioSheet(),
    );
  }

  @override
  State<QuranRadioSheet> createState() => _QuranRadioSheetState();
}

class _QuranRadioSheetState extends State<QuranRadioSheet> {
  final QuranRadioService _radioService = QuranRadioService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'الكل';

  final List<String> _categories = [
    'الكل',
    'كبار القراء',
    'رواية ورش',
    'تلاوات خاشعة',
    'الحرمين الشريفين',
    'تفاسير وعلوم',
    'أذكار ورقيا',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QuranRadioStation> _filterStations(List<QuranRadioStation> all) {
    final query = _searchController.text.trim();
    var list = all;

    if (_selectedCategory != 'الكل') {
      list = list.where((s) => s.category == _selectedCategory).toList();
    }

    if (query.isNotEmpty) {
      list = list.where((s) {
        return s.name.contains(query) || s.rawName.contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: AnimatedBuilder(
        animation: _radioService,
        builder: (context, _) {
          final stations = _filterStations(_radioService.stations);
          final current = _radioService.currentStation;
          final isPlaying = _radioService.isPlaying;
          final isConnecting = _radioService.isConnecting;

          return Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsetsDirectional.only(
                    top: AppSpace.md,
                    bottom: AppSpace.sm,
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Icon(
                        Icons.radio_rounded,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إذاعة القرآن الكريم',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: palette.text,
                            fontFamily: AppTextStyles.cairo,
                          ),
                        ),
                        Text(
                          'بث مباشر 24 ساعة بدون انقطاع',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: palette.textMuted,
                            fontFamily: AppTextStyles.cairo,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.textMuted,
                      ),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),

              // Active Player Dock (if any station selected)
              if (current != null) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xl,
                    vertical: AppSpace.xs,
                  ),
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: AppRadius.lgRadius,
                      border: Border.all(color: palette.primary),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Pulsing live indicator
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: isPlaying ? palette.goldSoft : palette.surfaceMuted,
                                borderRadius: AppRadius.pillRadius,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPlaying ? palette.gold : palette.textSubtle,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.xs),
                                  Text(
                                    'مباشر',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: isPlaying ? palette.gold : palette.textSubtle,
                                      fontFamily: AppTextStyles.cairo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                current.name,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: palette.text,
                                  fontFamily: AppTextStyles.cairo,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Play / Pause / Buffering button
                            if (isConnecting)
                              SizedBox(
                                width: AppSize.buttonH,
                                height: AppSize.buttonH,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: palette.primary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                onPressed: () => _radioService.togglePlay(current),
                                icon: Icon(
                                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                  color: palette.primary,
                                ),
                                iconSize: 36,
                                tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                              ),
                            // Stop button
                            IconButton(
                              onPressed: () => _radioService.stop(),
                              icon: Icon(
                                Icons.stop_rounded,
                                color: palette.textMuted,
                              ),
                              tooltip: 'إيقاف البث',
                            ),
                          ],
                        ),

                        // Error message if any
                        if (_radioService.errorMessage != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: AppSpace.xs),
                            child: Text(
                              _radioService.errorMessage!,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: palette.error,
                                fontFamily: AppTextStyles.cairo,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              // Search Bar
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.xs,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.search_rounded,
                        color: palette.textMuted,
                      ),
                      hintText: 'ابحث باسم القارئ أو الإذاعة...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: palette.textSubtle,
                        fontFamily: AppTextStyles.cairo,
                      ),
                      border: InputBorder.none,
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.text,
                      fontFamily: AppTextStyles.cairo,
                    ),
                  ),
                ),
              ),

              // Category Chips
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xl,
                  ),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpace.sm),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(
                        cat,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected ? palette.onPrimary : palette.textMuted,
                          fontFamily: AppTextStyles.cairo,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: palette.primary,
                      backgroundColor: palette.surface,
                      side: BorderSide(
                        color: isSelected ? palette.primary : palette.border,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpace.xs),

              // Station List
              Expanded(
                child: stations.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد إذاعات مطابقة',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: palette.textMuted,
                            fontFamily: AppTextStyles.cairo,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsetsDirectional.only(
                          start: AppSpace.xl,
                          end: AppSpace.xl,
                          top: AppSpace.xs,
                          bottom: AppSpace.xl,
                        ),
                        itemCount: stations.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpace.xs),
                        itemBuilder: (context, index) {
                          final station = stations[index];
                          final isThisStation = current?.id == station.id;

                          return Container(
                            decoration: BoxDecoration(
                              color: isThisStation ? palette.primarySoft : palette.surface,
                              borderRadius: AppRadius.mdRadius,
                              border: Border.all(
                                color: isThisStation ? palette.primary : palette.border,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isThisStation ? palette.primary : palette.surfaceMuted,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  color: isThisStation ? palette.onPrimary : palette.textMuted,
                                ),
                              ),
                              title: Text(
                                station.name,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: palette.text,
                                  fontFamily: AppTextStyles.cairo,
                                ),
                              ),
                              subtitle: Text(
                                station.category,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: palette.textMuted,
                                  fontFamily: AppTextStyles.cairo,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () => _radioService.togglePlay(station),
                                icon: Icon(
                                  isThisStation && isPlaying
                                      ? Icons.pause_circle_rounded
                                      : Icons.play_circle_outline_rounded,
                                  color: isThisStation ? palette.primary : palette.textMuted,
                                ),
                                iconSize: 32,
                                tooltip: isThisStation && isPlaying ? 'إيقاف' : 'تشغيل',
                              ),
                              onTap: () => _radioService.playStation(station),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
