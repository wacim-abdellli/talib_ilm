import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

/// Page info model
class QuranPageInfo {
  final int pageNumber;
  final int juzNumber;
  final bool isCurrentPage;

  const QuranPageInfo({
    required this.pageNumber,
    required this.juzNumber,
    this.isCurrentPage = false,
  });
}

/// Pages Grid View with thumbnails
class PagesGridView extends StatelessWidget {
  final int? currentPage;
  final void Function(int pageNumber)? onPageTap;

  const PagesGridView({super.key, this.currentPage, this.onPageTap});

  // Get juz number for a page
  int _getJuzForPage(int pageNumber) {
    // Approximate juz boundaries (page numbers)
    const juzStartPages = [
      1,
      22,
      42,
      62,
      82,
      102,
      121,
      142,
      162,
      182,
      201,
      222,
      242,
      262,
      282,
      302,
      322,
      342,
      362,
      382,
      402,
      422,
      442,
      462,
      482,
      502,
      522,
      542,
      562,
      582,
    ];

    for (int i = juzStartPages.length - 1; i >= 0; i--) {
      if (pageNumber >= juzStartPages[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3 / 4, // Page shape
        ),
        itemCount: 604,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          final juzNumber = _getJuzForPage(pageNumber);
          final isCurrent = pageNumber == currentPage;

          return PageGridCell(
            pageNumber: pageNumber,
            juzNumber: juzNumber,
            isCurrentPage: isCurrent,
            onTap: () => onPageTap?.call(pageNumber),
          );
        },
      ),
    );
  }
}

/// Individual page grid cell
class PageGridCell extends StatelessWidget {
  final int pageNumber;
  final int juzNumber;
  final bool isCurrentPage;
  final VoidCallback? onTap;

  const PageGridCell({
    super.key,
    required this.pageNumber,
    required this.juzNumber,
    this.isCurrentPage = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPage
              ? const Color(0xFF14B8A6)
              : (isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE2E8F0)),
          width: isCurrentPage ? 2 : 1,
        ),
        boxShadow: isCurrentPage && isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                // Juz badge (top-right)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ج$juzNumber',
                      style: TextStyle(
                        fontSize: responsive.sp(10),
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),

                // Page number (centered)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pageNumber.toString(),
                        style: TextStyle(
                          fontSize: responsive.sp(24),
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.grey.shade800,
                        ),
                      ),

                      // Current page indicator
                      if (isCurrentPage) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF14B8A6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick page jump widget with slider
class PageJumpSlider extends StatefulWidget {
  final int currentPage;
  final void Function(int page) onPageSelected;

  const PageJumpSlider({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<PageJumpSlider> createState() => _PageJumpSliderState();
}

class _PageJumpSliderState extends State<PageJumpSlider> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentPage.toDouble();
  }

  @override
  void didUpdateWidget(PageJumpSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _sliderValue = widget.currentPage.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with current page
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'انتقل إلى صفحة',
                style: TextStyle(
                  fontSize: responsive.sp(14),
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.grey.shade700,
                  fontFamily: 'Cairo',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_sliderValue.toInt()}',
                  style: TextStyle(
                    fontSize: responsive.sp(16),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF14B8A6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF14B8A6),
              inactiveTrackColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              thumbColor: const Color(0xFF14B8A6),
              overlayColor: const Color(0xFF14B8A6).withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _sliderValue,
              min: 1,
              max: 604,
              onChanged: (value) {
                setState(() {
                  _sliderValue = value;
                });
              },
              onChangeEnd: (value) {
                widget.onPageSelected(value.toInt());
              },
            ),
          ),

          // Range labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: TextStyle(
                  fontSize: responsive.sp(12),
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
              Text(
                '604',
                style: TextStyle(
                  fontSize: responsive.sp(12),
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
