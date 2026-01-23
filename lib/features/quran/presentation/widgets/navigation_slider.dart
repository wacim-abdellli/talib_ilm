import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thin page progress slider for Quran navigation
///
/// Features:
/// - Minimal visual footprint
/// - Instant page jump
/// - Haptic feedback
/// - RTL support (604 → 1)
class QuranNavigationSlider extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final bool isDark;
  final bool showLabel;

  const QuranNavigationSlider({
    super.key,
    required this.currentPage,
    this.totalPages = 604,
    required this.onPageChanged,
    this.isDark = false,
    this.showLabel = true,
  });

  @override
  State<QuranNavigationSlider> createState() => _QuranNavigationSliderState();
}

class _QuranNavigationSliderState extends State<QuranNavigationSlider> {
  late double _sliderValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentPage.toDouble();
  }

  @override
  void didUpdateWidget(QuranNavigationSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.currentPage != widget.currentPage) {
      _sliderValue = widget.currentPage.toDouble();
    }
  }

  void _onSliderChanged(double value) {
    setState(() => _sliderValue = value);
    HapticFeedback.selectionClick();
  }

  void _onSliderEnd(double value) {
    setState(() => _isDragging = false);
    final page = value.round();
    widget.onPageChanged(page);
  }

  void _onSliderStart(double value) {
    setState(() => _isDragging = true);
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDark
        ? const Color(0xFF00D9C0)
        : const Color(0xFFD4A853);
    final trackColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final textColor = widget.isDark ? Colors.white70 : Colors.black54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page indicator (shown while dragging or if showLabel is true)
        if (_isDragging || widget.showLabel)
          AnimatedOpacity(
            opacity: _isDragging ? 1.0 : 0.6,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'صفحة ${_toArabicNumber(_sliderValue.round())}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isDragging ? accentColor : textColor,
                ),
              ),
            ),
          ),

        // Slider
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: accentColor,
              inactiveTrackColor: trackColor,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
                pressedElevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl, // RTL: 1 on right, 604 on left
              child: Slider(
                value: _sliderValue.clamp(1, widget.totalPages.toDouble()),
                min: 1,
                max: widget.totalPages.toDouble(),
                onChanged: _onSliderChanged,
                onChangeStart: _onSliderStart,
                onChangeEnd: _onSliderEnd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact page indicator (no slider, just display)
class QuranPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;

  const QuranPageIndicator({
    super.key,
    required this.currentPage,
    this.totalPages = 604,
    this.isDark = false,
  });

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black54;
    final progress = currentPage / totalPages;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page number
        Text(
          '${_toArabicNumber(currentPage)} / ${_toArabicNumber(totalPages)}',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: textColor),
        ),
        const SizedBox(width: 8),
        // Mini progress bar
        SizedBox(
          width: 40,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                isDark ? const Color(0xFF00D9C0) : const Color(0xFFD4A853),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
