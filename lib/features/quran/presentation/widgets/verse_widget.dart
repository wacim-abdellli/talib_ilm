import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import 'ayah_context_menu.dart';

/// Verse data model
class VerseData {
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String? translation;
  final String? tafsir;
  final bool isBookmarked;

  const VerseData({
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    this.translation,
    this.tafsir,
    this.isBookmarked = false,
  });
}

/// Beautiful verse widget with RTL layout
class VerseWidget extends StatefulWidget {
  final VerseData verse;
  final double fontSize;
  final bool showTranslation;
  final bool showTafsir;
  final bool nightMode;
  final VoidCallback? onBookmark;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  final VoidCallback? onTafsir;

  const VerseWidget({
    super.key,
    required this.verse,
    this.fontSize = 28.0,
    this.showTranslation = false,
    this.showTafsir = false,
    this.nightMode = false,
    this.onBookmark,
    this.onPlay,
    this.onShare,
    this.onTafsir,
  });

  @override
  State<VerseWidget> createState() => _VerseWidgetState();
}

class _VerseWidgetState extends State<VerseWidget>
    with SingleTickerProviderStateMixin {
  bool _showActions = false;
  bool _tafsirExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleActions() {
    setState(() {
      _showActions = !_showActions;
    });
    if (_showActions) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _copyVerse() {
    final text =
        '${widget.verse.arabicText}\n\n[${widget.verse.surahNumber}:${widget.verse.verseNumber}]';
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.success(context, 'تم نسخ الآية');
    _toggleActions();
  }

  void _openContextMenu(BuildContext context, bool isDark) {
    // Use callback if provided, otherwise open context menu
    if (widget.onTafsir != null) {
      widget.onTafsir!();
    } else {
      AyahContextMenu.show(
        context,
        surah: widget.verse.surahNumber,
        ayah: widget.verse.verseNumber,
        ayahText: widget.verse.arabicText,
        isDark: isDark,
        onPlayAudio: widget.onPlay,
        onShare: widget.onShare,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = widget.nightMode;

    // Colors based on mode
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryColor = isDark
        ? const Color(0xFFA1A1A1)
        : const Color(0xFF64748B);
    final surfaceColor = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFF1F5F9);

    return GestureDetector(
      onTap: _toggleActions,
      onLongPress: () => _openContextMenu(context, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main verse content
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic text (main content)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arabic verse text with inline verse number
                        RichText(
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              fontFamily: 'Amiri', // Uthmanic-style font
                              height: 2.0,
                            ),
                            children: [
                              TextSpan(text: widget.verse.arabicText),
                              const TextSpan(text: ' '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: VerseNumberBadge(
                                  number: widget.verse.verseNumber,
                                  nightMode: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Translation (optional)
            if (widget.showTranslation && widget.verse.translation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.verse.translation!,
                  style: TextStyle(
                    fontSize: responsive.sp(16),
                    color: secondaryColor,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],

            // Tafsir (optional, expandable)
            if (widget.showTafsir && widget.verse.tafsir != null) ...[
              const SizedBox(height: 8),
              _TafsirSection(
                tafsir: widget.verse.tafsir!,
                expanded: _tafsirExpanded,
                nightMode: isDark,
                onToggle: () {
                  setState(() {
                    _tafsirExpanded = !_tafsirExpanded;
                  });
                },
              ),
            ],

            // Action buttons (show on tap)
            if (_showActions) ...[
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _ActionButtonsRow(
                  nightMode: isDark,
                  isBookmarked: widget.verse.isBookmarked,
                  onCopy: _copyVerse,
                  onShare: () {
                    widget.onShare?.call();
                    _toggleActions();
                  },
                  onBookmark: () {
                    widget.onBookmark?.call();
                    _toggleActions();
                  },
                  onPlay: () {
                    widget.onPlay?.call();
                    _toggleActions();
                  },
                  onTafsir: () {
                    _openContextMenu(context, isDark);
                    _toggleActions();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Decorative verse number badge with arabesque pattern
class VerseNumberBadge extends StatelessWidget {
  final int number;
  final bool nightMode;
  final double size;

  const VerseNumberBadge({
    super.key,
    required this.number,
    this.nightMode = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: nightMode
              ? const Color(0xFF14B8A6).withValues(alpha: 0.6)
              : const Color(0xFF14B8A6),
          width: 1.5,
        ),
        // Subtle gradient for arabesque effect
        gradient: RadialGradient(
          colors: [
            nightMode
                ? const Color(0xFF14B8A6).withValues(alpha: 0.1)
                : const Color(0xFF14B8A6).withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative corner elements (arabesque pattern)
          ...List.generate(4, (index) {
            return Positioned(
              top: index < 2 ? 2 : null,
              bottom: index >= 2 ? 2 : null,
              left: index % 2 == 0 ? 2 : null,
              right: index % 2 == 1 ? 2 : null,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nightMode
                      ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
                      : const Color(0xFF14B8A6).withValues(alpha: 0.2),
                ),
              ),
            );
          }),
          // Verse number
          Text(
            _toArabicNumerals(number),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
              color: nightMode
                  ? const Color(0xFF14B8A6).withValues(alpha: 0.9)
                  : const Color(0xFF14B8A6),
            ),
          ),
        ],
      ),
    );
  }

  String _toArabicNumerals(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}

/// Expandable tafsir section
class _TafsirSection extends StatelessWidget {
  final String tafsir;
  final bool expanded;
  final bool nightMode;
  final VoidCallback onToggle;

  const _TafsirSection({
    required this.tafsir,
    required this.expanded,
    required this.nightMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final surfaceColor = nightMode
        ? const Color(0xFF0F0F0F)
        : const Color(0xFFE2E8F0);
    final textColor = nightMode
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: nightMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with toggle
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 18,
                    color: const Color(0xFF14B8A6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'التفسير',
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF14B8A6),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: const Color(0xFF14B8A6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                tafsir,
                style: TextStyle(
                  fontSize: responsive.sp(14),
                  color: textColor,
                  height: 1.8,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Action buttons row
class _ActionButtonsRow extends StatelessWidget {
  final bool nightMode;
  final bool isBookmarked;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback onPlay;
  final VoidCallback onTafsir;

  const _ActionButtonsRow({
    required this.nightMode,
    required this.isBookmarked,
    required this.onCopy,
    required this.onShare,
    required this.onBookmark,
    required this.onPlay,
    required this.onTafsir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: nightMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: nightMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: nightMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.copy_rounded,
            label: 'نسخ',
            nightMode: nightMode,
            onTap: onCopy,
          ),
          _ActionButton(
            icon: Icons.share_outlined,
            label: 'مشاركة',
            nightMode: nightMode,
            onTap: onShare,
          ),
          _ActionButton(
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: 'حفظ',
            nightMode: nightMode,
            isActive: isBookmarked,
            onTap: onBookmark,
          ),
          _ActionButton(
            icon: Icons.play_circle_outline,
            label: 'استماع',
            nightMode: nightMode,
            onTap: onPlay,
          ),
          _ActionButton(
            icon: Icons.auto_stories_outlined,
            label: 'تفسير',
            nightMode: nightMode,
            onTap: onTafsir,
          ),
        ],
      ),
    );
  }
}

/// Individual action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool nightMode;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.nightMode,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(0xFF14B8A6)
        : (nightMode
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.grey.shade600);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontFamily: 'Cairo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative verse separator
class VerseSeparator extends StatelessWidget {
  final bool nightMode;

  const VerseSeparator({super.key, this.nightMode = false});

  @override
  Widget build(BuildContext context) {
    final color = nightMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      height: 1,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, color]),
              ),
            ),
          ),
          // Center decoration
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nightMode
                  ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
                  : const Color(0xFF14B8A6).withValues(alpha: 0.2),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, Colors.transparent]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Surah bismillah header
class BismillahHeader extends StatelessWidget {
  final bool nightMode;
  final double fontSize;

  const BismillahHeader({
    super.key,
    this.nightMode = false,
    this.fontSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: nightMode ? Colors.white : const Color(0xFF0F172A),
          fontFamily: 'Amiri',
          height: 1.8,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Surah title header with decorative border
class SurahTitleHeader extends StatelessWidget {
  final String surahName;
  final int surahNumber;
  final int versesCount;
  final bool isMakki;
  final bool nightMode;

  const SurahTitleHeader({
    super.key,
    required this.surahName,
    required this.surahNumber,
    required this.versesCount,
    required this.isMakki,
    this.nightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final borderColor = nightMode
        ? const Color(0xFF14B8A6).withValues(alpha: 0.5)
        : const Color(0xFF14B8A6).withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        gradient: LinearGradient(
          colors: [
            nightMode
                ? const Color(0xFF14B8A6).withValues(alpha: 0.1)
                : const Color(0xFF14B8A6).withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Surah number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF14B8A6),
            ),
            child: Center(
              child: Text(
                surahNumber.toString(),
                style: TextStyle(
                  fontSize: responsive.sp(16),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Surah name
          Text(
            'سورة $surahName',
            style: TextStyle(
              fontSize: responsive.sp(24),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF14B8A6),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),

          // Info row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(
                label: isMakki ? 'مكية' : 'مدنية',
                nightMode: nightMode,
              ),
              const SizedBox(width: 12),
              _InfoChip(label: '$versesCount آية', nightMode: nightMode),
            ],
          ),
        ],
      ),
    );
  }
}

/// Info chip for surah header
class _InfoChip extends StatelessWidget {
  final String label;
  final bool nightMode;

  const _InfoChip({required this.label, required this.nightMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: nightMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: nightMode
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.grey.shade600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
