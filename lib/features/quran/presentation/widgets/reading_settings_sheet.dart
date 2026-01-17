import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

enum ReadingMode { singleVerse, continuous, page }

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

  QuranReadingSettings({
    this.fontSize = 28.0,
    this.fontFamily = 'hafs',
    this.showTajweed = false,
    this.fontStyle = 'uthmanic',
    this.showTranslation = false,
    this.translationLanguage = 'english',
    this.translationFontSize = 16.0,
    this.backgroundColor = const Color(0xFFFFF9E6),
    this.nightMode = false,
    this.reciter = 'mishary',
    this.autoPlay = false,
    this.readingMode = ReadingMode.singleVerse,
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
    );
  }
}

class ReadingSettingsSheet extends StatefulWidget {
  final QuranReadingSettings settings;
  final ValueChanged<QuranReadingSettings> onSettingsChanged;

  const ReadingSettingsSheet({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
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
      builder: (context) => ReadingSettingsSheet(
        settings: settings,
        onSettingsChanged: onSettingsChanged,
      ),
    );
  }

  @override
  State<ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<ReadingSettingsSheet> {
  late QuranReadingSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSettings(QuranReadingSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.nightMode;
    final responsive = Responsive(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF14B8A6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'إعدادات القراءة',
                  style: TextStyle(
                    fontSize: responsive.sp(20),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FONT SIZE & PREVIEW
                  _SectionTitle('حجم الخط', isDark, responsive),
                  const SizedBox(height: 16),

                  // Preview Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _settings.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri', // Simplified for preview
                        fontSize: _settings.fontSize,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text(
                        '16',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: responsive.sp(12),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _settings.fontSize,
                          min: 16,
                          max: 48,
                          activeColor: const Color(0xFF14B8A6),
                          inactiveColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          onChanged: (val) => _updateSettings(
                            _settings.copyWith(fontSize: val),
                          ),
                        ),
                      ),
                      Text(
                        '48',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: responsive.sp(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _settings.fontSize.toInt().toString(),
                        style: TextStyle(
                          color: const Color(0xFF14B8A6),
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.sp(14),
                        ),
                      ),
                    ],
                  ),

                  _Divider(isDark),

                  // 2. TRANSLATION
                  _SectionTitle('الترجمة', isDark, responsive),
                  SwitchListTile(
                    title: Text(
                      'عرض الترجمة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: responsive.sp(16),
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    value: _settings.showTranslation,
                    // ignore: deprecated_member_use
                    activeColor: const Color(0xFF14B8A6),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => _updateSettings(
                      _settings.copyWith(showTranslation: val),
                    ),
                  ),
                  if (_settings.showTranslation)
                    _DropdownButton<String>(
                      value: _settings.translationLanguage,
                      isDark: isDark,
                      items: const [
                        DropdownMenuItem(
                          value: 'english',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'french',
                          child: Text('French'),
                        ),
                        DropdownMenuItem(value: 'urdu', child: Text('Urdu')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _updateSettings(
                            _settings.copyWith(translationLanguage: val),
                          );
                        }
                      },
                    ),

                  _Divider(isDark),

                  // 3. THEME
                  _SectionTitle('المظهر', isDark, responsive),
                  const SizedBox(height: 8),
                  _ThemeRadioOption(
                    label: 'كريمي (مريح للعين)',
                    value: const Color(0xFFFFF9E6),
                    groupValue: _settings.backgroundColor,
                    isDark: isDark,
                    onChanged: (color) => _updateSettings(
                      _settings.copyWith(
                        backgroundColor: color,
                        nightMode: false,
                      ),
                    ),
                  ),
                  _ThemeRadioOption(
                    label: 'أبيض (ساطع)',
                    value: const Color(0xFFFFFFFF),
                    groupValue: _settings.backgroundColor,
                    isDark: isDark,
                    onChanged: (color) => _updateSettings(
                      _settings.copyWith(
                        backgroundColor: color,
                        nightMode: false,
                      ),
                    ),
                  ),
                  _ThemeRadioOption(
                    label: 'داكن (Dark)',
                    value: const Color(0xFF0A0A0A),
                    groupValue: _settings.backgroundColor,
                    isDark: isDark,
                    onChanged: (color) => _updateSettings(
                      _settings.copyWith(
                        backgroundColor: color,
                        nightMode: true,
                      ),
                    ),
                  ),
                  _ThemeRadioOption(
                    label: 'أسود تماماً (OLED)',
                    value: const Color(0xFF000000),
                    groupValue: _settings.backgroundColor,
                    isDark: isDark,
                    onChanged: (color) => _updateSettings(
                      _settings.copyWith(
                        backgroundColor: color,
                        nightMode: true,
                      ),
                    ),
                  ),

                  _Divider(isDark),

                  // 4. READING MODE
                  _SectionTitle('وضع القراءة', isDark, responsive),
                  const SizedBox(height: 8),
                  _RadioOption<ReadingMode>(
                    label: 'آية واحدة',
                    value: ReadingMode.singleVerse,
                    groupValue: _settings.readingMode,
                    isDark: isDark,
                    onChanged: (val) =>
                        _updateSettings(_settings.copyWith(readingMode: val)),
                  ),
                  _RadioOption<ReadingMode>(
                    label: 'تمرير مستمر',
                    value: ReadingMode.continuous,
                    groupValue: _settings.readingMode,
                    isDark: isDark,
                    onChanged: (val) =>
                        _updateSettings(_settings.copyWith(readingMode: val)),
                  ),
                  _RadioOption<ReadingMode>(
                    label: 'صفحات (المصحف)',
                    value: ReadingMode.page,
                    groupValue: _settings.readingMode,
                    isDark: isDark,
                    onChanged: (val) =>
                        _updateSettings(_settings.copyWith(readingMode: val)),
                  ),

                  _Divider(isDark),

                  // 5. AUDIO
                  _SectionTitle('الصوت', isDark, responsive),
                  const SizedBox(height: 16),
                  _DropdownButton<String>(
                    value: _settings.reciter,
                    isDark: isDark,
                    items: const [
                      DropdownMenuItem(
                        value: 'alafasy',
                        child: Text('مشاري العفاسي'),
                      ),
                      DropdownMenuItem(
                        value: 'minshawi',
                        child: Text('محمد صديق المنشاوي'),
                      ),
                      DropdownMenuItem(
                        value: 'sudais',
                        child: Text('عبد الرحمن السديس'),
                      ),
                    ],
                    onChanged: (val) =>
                        _updateSettings(_settings.copyWith(reciter: val!)),
                  ),
                  SwitchListTile(
                    title: Text(
                      'تشغيل تلقائي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: responsive.sp(16),
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    value: _settings.autoPlay,
                    // ignore: deprecated_member_use
                    activeColor: const Color(0xFF14B8A6),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) =>
                        _updateSettings(_settings.copyWith(autoPlay: val)),
                  ),

                  const SizedBox(height: 100), // Spacing for button
                ],
              ),
            ),
          ),

          // Save Button
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: mediaQuery.padding.bottom + 24,
              top: 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSettingsChanged(_settings);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'حفظ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  final Responsive responsive;

  const _SectionTitle(this.title, this.isDark, this.responsive);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: responsive.sp(18),
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
      ),
    );
  }
}

class _ThemeRadioOption extends StatelessWidget {
  final String label;
  final Color value;
  final Color groupValue;
  final bool isDark;
  final ValueChanged<Color> onChanged;

  const _ThemeRadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<Color>(
      title: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      value: value,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      // ignore: deprecated_member_use
      activeColor: const Color(0xFF14B8A6),
      contentPadding: EdgeInsets.zero,
      // ignore: deprecated_member_use
      onChanged: (val) {
        if (val != null) {
          onChanged(val);
        }
      },
    );
  }
}

class _RadioOption<T> extends StatelessWidget {
  final String label;
  final T value;
  final T groupValue;
  final bool isDark;
  final ValueChanged<T> onChanged;

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      value: value,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      // ignore: deprecated_member_use
      activeColor: const Color(0xFF14B8A6),
      contentPadding: EdgeInsets.zero,
      // ignore: deprecated_member_use
      onChanged: (val) {
        if (val != null) {
          onChanged(val);
        }
      },
    );
  }
}

class _DropdownButton<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final bool isDark;
  final ValueChanged<T?> onChanged;

  const _DropdownButton({
    required this.value,
    required this.items,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          style: TextStyle(
            fontFamily: 'Cairo',
            color: isDark ? Colors.white : Colors.black,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        color: isDark ? Colors.white12 : Colors.grey[200],
        thickness: 1,
      ),
    );
  }
}
