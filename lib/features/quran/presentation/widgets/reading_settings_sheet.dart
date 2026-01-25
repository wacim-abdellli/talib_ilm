import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/models/quran_models.dart';
import '../../data/services/edition_service.dart';

enum ReadingMode { singleVerse, page }

/// Reading settings model
class QuranReadingSettings {
  // Quran Text
  double fontSize;
  String fontFamily; // hafs, warsh, qalun
  bool showTajweed;
  String fontStyle; // uthmanic, traditional

  // Translation
  bool showTranslation;
  String translationLanguage;
  double translationFontSize;

  // Theme
  Color backgroundColor;
  bool nightMode;

  // Audio
  String reciter;
  bool autoPlay;

  // Reading Mode
  ReadingMode readingMode;

  // Display
  bool useEnglishNumbers;

  QuranReadingSettings({
    this.fontSize = 24.0,
    this.fontFamily = 'hafs',
    this.showTajweed = false,
    this.fontStyle = 'uthmanic',
    this.showTranslation = false,
    this.translationLanguage = 'english',
    this.translationFontSize = 16.0,
    this.backgroundColor = const Color(0xFFFFF9E6),
    this.nightMode = false,
    this.reciter = 'alafasy',
    this.autoPlay = false,
    this.readingMode = ReadingMode.page,
    this.useEnglishNumbers = false,
  });

  QuranReadingSettings copyWith({
    double? fontSize,
    String? fontFamily,
    bool? showTajweed,
    String? fontStyle,
    bool? showTranslation,
    String? translationLanguage,
    double? translationFontSize,
    Color? backgroundColor,
    bool? nightMode,
    String? reciter,
    bool? autoPlay,
    ReadingMode? readingMode,
    bool? useEnglishNumbers,
  }) {
    return QuranReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      showTajweed: showTajweed ?? this.showTajweed,
      fontStyle: fontStyle ?? this.fontStyle,
      showTranslation: showTranslation ?? this.showTranslation,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      nightMode: nightMode ?? this.nightMode,
      reciter: reciter ?? this.reciter,
      autoPlay: autoPlay ?? this.autoPlay,
      readingMode: readingMode ?? this.readingMode,
      useEnglishNumbers: useEnglishNumbers ?? this.useEnglishNumbers,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM READING SETTINGS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class ReadingSettingsSheet extends StatefulWidget {
  final QuranReadingSettings settings;
  final ValueChanged<QuranReadingSettings> onSettingsChanged;
  final ScrollController? scrollController;

  const ReadingSettingsSheet({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.scrollController,
  });

  static Future<void> show(
    BuildContext context, {
    required QuranReadingSettings settings,
    required ValueChanged<QuranReadingSettings> onSettingsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        snap: true,
        snapSizes: const [0.65, 0.95],
        builder: (context, scrollController) => ReadingSettingsSheet(
          settings: settings,
          onSettingsChanged: onSettingsChanged,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<ReadingSettingsSheet>
    with SingleTickerProviderStateMixin {
  late QuranReadingSettings _settings;
  late AnimationController _animController;
  Timer? _fontSizeDebounce;

  // FORCED: Pure Black OLED palette
  static const _darkBg = Color(0xFF000000); // PURE BLACK (FORCED)
  static const _darkSurface = Color(0xFF080A0F); // Pitch Dark surface
  static const _darkText = Color(0xFFF4F4F0); // Off-White (FORCED)
  static const _darkSubtext = Color(0xFFB8B8B8); // Soft gray
  static const _accent = Color(0xFFD4A853); // Premium Gold (FORCED)
  static const _accentDark = Color(0xFFB58E3E); // Darker Gold

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fontSizeDebounce?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _updateSettings(QuranReadingSettings newSettings) {
    HapticFeedback.selectionClick();
    setState(() => _settings = newSettings);
    // Instantly persist to parent (no page rebuild, just state update)
    widget.onSettingsChanged(newSettings);
  }

  void _updateFontSize(double size) {
    // Debounce font size changes to avoid jitter
    _fontSizeDebounce?.cancel();
    setState(() => _settings = _settings.copyWith(fontSize: size));
    _fontSizeDebounce = Timer(const Duration(milliseconds: 150), () {
      widget.onSettingsChanged(_settings);
    });
  }

  void _resetToDefaults() {
    HapticFeedback.mediumImpact();
    final defaults = QuranReadingSettings();
    setState(() => _settings = defaults);
    widget.onSettingsChanged(defaults);
  }

  void _applyPreset(String preset) {
    HapticFeedback.mediumImpact();
    QuranReadingSettings newSettings;
    switch (preset) {
      case 'night':
        newSettings = _settings.copyWith(
          nightMode: true,
          backgroundColor: _darkBg,
          fontSize: 26,
        );
        break;
      case 'mushaf':
        newSettings = _settings.copyWith(
          readingMode: ReadingMode.page,
          fontSize: 24,
          nightMode: false,
          backgroundColor: const Color(0xFFFFF9E6),
        );
        break;
      case 'focus':
        newSettings = _settings.copyWith(
          readingMode: ReadingMode.singleVerse,
          fontSize: 32,
          nightMode: true,
          backgroundColor: _darkBg,
        );
        break;
      default:
        return;
    }
    setState(() => _settings = newSettings);
    widget.onSettingsChanged(newSettings);
  }

  // SIMULATE DOWNLOAD (DLC Logic)
  void _simulateDownload(
    BuildContext context,
    String editionId,
    VoidCallback onSuccess,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _DownloadDialog(editionName: editionId);
      },
    ).then((completed) {
      if (completed == true) {
        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تثبيت الرواية بنجاح ✅',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        onSuccess();
      }
    });
  }

  Color get _bgColor => _settings.nightMode ? _darkBg : Colors.white;
  Color get _textColor => _settings.nightMode ? _darkText : Colors.black87;
  Color get _subtextColor =>
      _settings.nightMode ? _darkSubtext : Colors.grey[600]!;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final mediaQuery = MediaQuery.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ═══ HANDLE BAR ═══
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _subtextColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ═══ HEADER ═══
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accent, _accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات القراءة',
                        style: TextStyle(
                          fontSize: responsive.sp(20),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: _textColor,
                        ),
                      ),
                      Text(
                        'تخصيص إعدادات المصحف',
                        style: TextStyle(
                          fontSize: responsive.sp(12),
                          fontFamily: 'Cairo',
                          color: _subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ═══ CONTENT ═══
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ══════════════════════════════════════════════════════════
                  // SECTION 1: APPEARANCE (المظهر)
                  // ══════════════════════════════════════════════════════════
                  _SectionHeader(
                    title: 'المظهر',
                    icon: Icons.palette_outlined,
                    isDark: _settings.nightMode,
                  ),
                  const SizedBox(height: 12),

                  // Dark Mode Toggle
                  _PremiumToggle(
                    icon: Icons.dark_mode_rounded,
                    title: 'الوضع الليلي',
                    subtitle: 'مريح للعين في الإضاءة المنخفضة',
                    value: _settings.nightMode,
                    isDark: _settings.nightMode,
                    onChanged: (val) => _updateSettings(
                      _settings.copyWith(
                        nightMode: val,
                        backgroundColor: val
                            ? _darkBg
                            : const Color(0xFFFFF9E6),
                      ),
                    ),
                  ),

                  // Hindi Numbers Toggle (inverted - when ON, use Hindi numerals)
                  _PremiumToggle(
                    icon: Icons.tag_rounded,
                    title: 'الأرقام الهندية',
                    subtitle: 'عرض أرقام الآيات بالشكل ١٢٣',
                    value: !_settings.useEnglishNumbers,
                    isDark: _settings.nightMode,
                    onChanged: (val) => _updateSettings(
                      _settings.copyWith(useEnglishNumbers: !val),
                    ),
                  ),

                  // Tajweed Toggle
                  _PremiumToggle(
                    icon: Icons.color_lens_outlined,
                    title: 'تلوين التجويد',
                    subtitle: 'إظهار أحكام التجويد ملونة',
                    value: _settings.showTajweed,
                    isDark: _settings.nightMode,
                    onChanged: (val) =>
                        _updateSettings(_settings.copyWith(showTajweed: val)),
                  ),

                  const SizedBox(height: 24),

                  // ══════════════════════════════════════════════════════════
                  // SECTION 2.5: EDITION (الرواية) - NEW!
                  // ══════════════════════════════════════════════════════════
                  _SectionHeader(
                    title: 'الرواية',
                    icon: Icons.auto_stories_rounded,
                    isDark: _settings.nightMode,
                  ),
                  const SizedBox(height: 12),

                  _EditionSelector(
                    selectedReference: _settings
                        .fontFamily, // Using fontFamily to store edition ID
                    isDark: _settings.nightMode,
                    onChanged: (editionId) {
                      // DLC Logic: Simulate download for non-Hafs
                      if (editionId != 'hafs') {
                        _simulateDownload(context, editionId, () {
                          _updateSettings(
                            _settings.copyWith(fontFamily: editionId),
                          );
                        });
                      } else {
                        _updateSettings(
                          _settings.copyWith(fontFamily: editionId),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // ══════════════════════════════════════════════════════════
                  // SECTION 3: READING MODE (وضع القراءة)
                  // ══════════════════════════════════════════════════════════
                  _SectionHeader(
                    title: 'طريقة العرض',
                    icon: Icons.view_agenda_rounded,
                    isDark: _settings.nightMode,
                  ),
                  const SizedBox(height: 12),

                  // Reading Mode Selector
                  _ReadingModeSelector(
                    selected: _settings.readingMode,
                    isDark: _settings.nightMode,
                    onChanged: (mode) =>
                        _updateSettings(_settings.copyWith(readingMode: mode)),
                  ),

                  const SizedBox(height: 24),

                  // ══════════════════════════════════════════════════════════
                  // SECTION 3: TYPOGRAPHY (الخط)
                  // ══════════════════════════════════════════════════════════
                  _SectionHeader(
                    title: 'الخط',
                    icon: Icons.text_fields_rounded,
                    isDark: _settings.nightMode,
                  ),
                  const SizedBox(height: 12),

                  // Font Preview
                  _FontPreview(
                    fontSize: _settings.fontSize,
                    isDark: _settings.nightMode,
                  ),

                  const SizedBox(height: 16),

                  // Font Size Slider
                  _FontSizeSlider(
                    value: _settings.fontSize,
                    isDark: _settings.nightMode,
                    onChanged: _updateFontSize, // Debounced
                  ),

                  const SizedBox(height: 16),

                  // Font Style Selector
                  _FontStyleSelector(
                    selected: _settings.fontStyle,
                    isDark: _settings.nightMode,
                    onChanged: (style) =>
                        _updateSettings(_settings.copyWith(fontStyle: style)),
                  ),

                  const SizedBox(height: 24),

                  // ══════════════════════════════════════════════════════════
                  // SECTION 4: AUDIO (الصوت)
                  // ══════════════════════════════════════════════════════════
                  _SectionHeader(
                    title: 'التلاوة',
                    icon: Icons.mic_rounded,
                    isDark: _settings.nightMode,
                  ),
                  const SizedBox(height: 12),

                  // Reciter Dropdown
                  _ReciterSelector(
                    selected: _settings.reciter,
                    isDark: _settings.nightMode,
                    onChanged: (reciter) =>
                        _updateSettings(_settings.copyWith(reciter: reciter)),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ═══ SAVE BUTTON ═══
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              mediaQuery.padding.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: _bgColor,
              border: Border(
                top: BorderSide(color: _subtextColor.withValues(alpha: 0.1)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onSettingsChanged(_settings);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'تطبيق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD4A853)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4A853),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4A853).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM TOGGLE WIDGET (Full Row Tappable)
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _PremiumToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  static const _accent = Color(0xFFD4A853);
  static const _darkSurface = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _darkSurface : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? _accent.withValues(alpha: 0.5)
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value
                    ? _accent.withValues(alpha: 0.15)
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: value
                    ? _accent
                    : (isDark ? Colors.white60 : Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFEDEDED) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFA0A0A0)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Switch
            _AnimatedSwitch(value: value, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED SWITCH
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedSwitch extends StatelessWidget {
  final bool value;
  final bool isDark;

  const _AnimatedSwitch({required this.value, required this.isDark});

  static const _accent = Color(0xFFD4A853);
  static const _accentDark = Color(0xFFB58E3E);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: value
            ? const LinearGradient(
                colors: [_accent, _accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: value ? null : (isDark ? Colors.grey[700] : Colors.grey[300]),
        boxShadow: value
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            left: value ? 24 : 2,
            top: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: value
                  ? const Icon(Icons.check, size: 14, color: _accent)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// READING MODE SELECTOR
// ═══════════════════════════════════════════════════════════════════════════

class _ReadingModeSelector extends StatelessWidget {
  final ReadingMode selected;
  final bool isDark;
  final ValueChanged<ReadingMode> onChanged;

  const _ReadingModeSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _accent = Color(0xFFD4A853);
  static const _darkSurface = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _ModeOption(
            icon: Icons.format_quote_rounded,
            title: 'آية بآية',
            subtitle: 'التركيز على آية واحدة',
            isSelected: selected == ReadingMode.singleVerse,
            isDark: isDark,
            isFirst: true,
            onTap: () => onChanged(ReadingMode.singleVerse),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          _ModeOption(
            icon: Icons.auto_stories_rounded,
            title: 'صفحة المصحف',
            subtitle: 'عرض صفحة كاملة',
            isSelected: selected == ReadingMode.page,
            isDark: isDark,
            isLast: true,
            onTap: () => onChanged(ReadingMode.page),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    this.isFirst = false,
    this.isLast = false,
    required this.onTap,
  });

  static const _accent = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? _accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(15) : Radius.zero,
            bottom: isLast ? const Radius.circular(15) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accent.withValues(alpha: 0.2)
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? _accent
                    : (isDark ? Colors.white60 : Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? _accent
                          : (isDark ? const Color(0xFFEDEDED) : Colors.black87),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFA0A0A0)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FONT PREVIEW
// ═══════════════════════════════════════════════════════════════════════════

class _FontPreview extends StatelessWidget {
  final double fontSize;
  final bool isDark;

  const _FontPreview({required this.fontSize, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFC107).withValues(alpha: 0.3),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize * 0.75,
            color: isDark ? const Color(0xFFEDEDED) : Colors.black87,
            height: 1.8,
          ),
          child: const Text(
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FONT SIZE SLIDER
// ═══════════════════════════════════════════════════════════════════════════

class _FontSizeSlider extends StatelessWidget {
  final double value;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _FontSizeSlider({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  static const _accent = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حجم الخط',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFEDEDED) : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'صغير',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? const Color(0xFFA0A0A0) : Colors.grey[600],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _accent,
                    inactiveTrackColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                    thumbColor: _accent,
                    overlayColor: _accent.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    min: 18,
                    max: 44,
                    divisions: 13, // Snap to steps
                    onChanged: onChanged,
                  ),
                ),
              ),
              Text(
                'كبير',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? const Color(0xFFA0A0A0) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FONT STYLE SELECTOR
// ═══════════════════════════════════════════════════════════════════════════

class _FontStyleSelector extends StatelessWidget {
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _FontStyleSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _accent = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          _StyleChip(
            label: 'Amiri Quran',
            value: 'uthmanic',
            selected: selected,
            isDark: isDark,
            onTap: () => onChanged('uthmanic'),
          ),
          const SizedBox(width: 6),
          _StyleChip(
            label: 'Modern Kufi',
            value: 'traditional',
            selected: selected,
            isDark: isDark,
            onTap: () => onChanged('traditional'),
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final bool isDark;
  final VoidCallback onTap;

  const _StyleChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  static const _accent = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final isActive = value == selected;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFE6AC00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF1A1A1A)
                  : (isDark ? const Color(0xFFA0A0A0) : Colors.grey[700]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RECITER SELECTOR
// ═══════════════════════════════════════════════════════════════════════════

class _ReciterSelector extends StatelessWidget {
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _ReciterSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _accent = Color(0xFFFFC107);

  static const _reciters = [
    {'id': 'alafasy', 'name': 'مشاري العفاسي'},
    {'id': 'minshawi', 'name': 'محمد صديق المنشاوي'},
    {'id': 'sudais', 'name': 'عبد الرحمن السديس'},
    {'id': 'shuraim', 'name': 'سعود الشريم'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? const Color(0xFFA0A0A0) : Colors.grey[600],
          ),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: isDark ? const Color(0xFFEDEDED) : Colors.black87,
          ),
          items: _reciters.map((r) {
            return DropdownMenuItem(
              value: r['id'],
              child: Row(
                children: [
                  Icon(
                    Icons.mic_rounded,
                    size: 18,
                    color: selected == r['id'] ? _accent : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(r['name']!),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              HapticFeedback.selectionClick();
              onChanged(val);
            }
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRESET CARD
// ═══════════════════════════════════════════════════════════════════════════

class _PresetCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _PresetCard({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  static const _accent = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: _accent),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFEDEDED) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EDITION SELECTOR
// ═══════════════════════════════════════════════════════════════════════════

class _EditionSelector extends StatefulWidget {
  final String selectedReference;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _EditionSelector({
    required this.selectedReference,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_EditionSelector> createState() => _EditionSelectorState();
}

class _EditionSelectorState extends State<_EditionSelector> {
  List<String> _downloadedEditions = ['hafs'];

  static const _accent = Color(0xFFD4A853);

  @override
  void initState() {
    super.initState();
    _loadDownloadedEditions();
  }

  Future<void> _loadDownloadedEditions() async {
    final downloaded = await EditionService.getDownloadedEditions();
    if (mounted) {
      setState(() => _downloadedEditions = downloaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: QuranEdition.availableEditions.map((edition) {
          final isSelected = widget.selectedReference == edition.id;
          final isDownloaded = _downloadedEditions.contains(edition.id);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onChanged(edition.id);
            },
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(12),
              width: 140,
              decoration: BoxDecoration(
                color: isSelected
                    ? _accent.withValues(alpha: 0.15)
                    : (widget.isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.grey[100]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? _accent
                      : (widget.isDark ? Colors.white12 : Colors.transparent),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDownloaded
                              ? const Color(0xFF10B981)
                              : (isSelected ? _accent : Colors.grey[800]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isDownloaded ? '✓' : edition.type.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (!isDownloaded)
                        Icon(Icons.download_rounded, size: 16, color: _accent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    edition.nameArabic,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    edition.nameEnglish,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: widget.isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DOWNLOAD DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _DownloadDialog extends StatefulWidget {
  final String editionName;

  const _DownloadDialog({required this.editionName});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0.0;
  String _status = 'جاري الاتصال...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() async {
    setState(() {
      _hasError = false;
      _progress = 0.0;
      _status = 'جاري الاتصال...';
    });

    // Use real EditionService download stream
    await for (final update in EditionService.downloadEdition(
      widget.editionName,
    )) {
      if (!mounted) return;

      setState(() {
        _progress = update.progress;
        _status = update.status;
        _hasError = update.isError;
      });

      if (update.isError) {
        return; // Stop on error
      }

      if (update.progress >= 1.0) {
        // Success - close dialog after short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasError
                  ? Icons.error_outline_rounded
                  : Icons.cloud_download_rounded,
              color: _hasError ? Colors.redAccent : const Color(0xFF10B981),
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              _hasError ? 'حدث خطأ' : 'تثبيت محتوى',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasError
                  ? _status
                  : (_getEditionDisplayName(widget.editionName)),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!_hasError) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white10,
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              // Error state with retry button
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getEditionDisplayName(String id) {
    final edition = QuranEdition.availableEditions.firstWhere(
      (e) => e.id == id,
      orElse: () => QuranEdition.availableEditions.first,
    );
    return edition.nameArabic;
  }
}
