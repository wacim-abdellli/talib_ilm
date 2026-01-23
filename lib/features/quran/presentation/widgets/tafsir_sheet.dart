import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/tafsir_models.dart';
import '../../data/services/tafsir_service.dart';

/// Tafsir Bottom Sheet - Beautiful tafsir viewer
///
/// Features:
/// - Ayah text at top
/// - Source selector (segmented)
/// - Scrollable tafsir body
/// - Font size controls
/// - Copy/Share actions
class TafsirSheet extends StatefulWidget {
  final int surah;
  final int ayah;
  final String ayahText;
  final bool isDark;

  const TafsirSheet({
    super.key,
    required this.surah,
    required this.ayah,
    required this.ayahText,
    this.isDark = false,
  });

  /// Show tafsir sheet
  static Future<void> show(
    BuildContext context, {
    required int surah,
    required int ayah,
    required String ayahText,
    bool isDark = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TafsirSheet(
        surah: surah,
        ayah: ayah,
        ayahText: ayahText,
        isDark: isDark,
      ),
    );
  }

  @override
  State<TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends State<TafsirSheet> {
  TafsirSource _selectedSource = TafsirSource.ibnKathir;
  TafsirData? _tafsir;
  bool _isLoading = true;
  double _fontSize = 18;

  @override
  void initState() {
    super.initState();
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    setState(() => _isLoading = true);

    final tafsir = await TafsirService.instance.getTafsir(
      surah: widget.surah,
      ayah: widget.ayah,
      source: _selectedSource,
    );

    if (mounted) {
      setState(() {
        _tafsir = tafsir;
        _isLoading = false;
      });
    }
  }

  void _onSourceChanged(TafsirSource source) {
    if (source != _selectedSource) {
      setState(() => _selectedSource = source);
      _loadTafsir();
    }
  }

  void _copyTafsir() {
    if (_tafsir != null && _tafsir!.isNotEmpty) {
      final text =
          '${widget.ayahText}\n\n${_selectedSource.displayName}:\n${_tafsir!.text}';
      Clipboard.setData(ClipboardData(text: text));
      AppSnackbar.success(context, 'تم النسخ');
    }
  }

  void _shareTafsir() {
    if (_tafsir != null && _tafsir!.isNotEmpty) {
      final text =
          '﴿${widget.ayahText}﴾\n[${widget.surah}:${widget.ayah}]\n\n${_selectedSource.displayName}:\n${_tafsir!.text}';
      Share.share(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final subtleColor = widget.isDark ? Colors.white54 : Colors.black45;
    final accentColor = widget.isDark
        ? const Color(0xFF00D9C0)
        : const Color(0xFFD4A853);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: subtleColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'تفسير الآية ${widget.ayah}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                // Font size controls
                _buildFontButton(Icons.remove, () {
                  if (_fontSize > 14) setState(() => _fontSize -= 2);
                }, subtleColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${_fontSize.toInt()}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: subtleColor,
                    ),
                  ),
                ),
                _buildFontButton(Icons.add, () {
                  if (_fontSize < 28) setState(() => _fontSize += 2);
                }, subtleColor),
              ],
            ),
          ),

          // Ayah text
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              widget.ayahText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                height: 1.8,
                color: textColor,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Source selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSourceSelector(accentColor, textColor, subtleColor),
          ),

          const SizedBox(height: 16),

          // Tafsir content
          Flexible(
            child: _buildTafsirContent(textColor, subtleColor, accentColor),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: subtleColor.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.copy_rounded,
                    label: 'نسخ',
                    onTap: _copyTafsir,
                    color: subtleColor,
                    textColor: textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'مشاركة',
                    onTap: _shareTafsir,
                    color: accentColor,
                    textColor: textColor,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildFontButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildSourceSelector(
    Color accentColor,
    Color textColor,
    Color subtleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: TafsirSource.values.map((source) {
          final isSelected = source == _selectedSource;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onSourceChanged(source),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  source.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? (widget.isDark ? Colors.black : Colors.white)
                        : textColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTafsirContent(
    Color textColor,
    Color subtleColor,
    Color accentColor,
  ) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
        ),
      );
    }

    if (_tafsir == null || _tafsir!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: subtleColor),
            const SizedBox(height: 12),
            Text(
              'التفسير غير متوفر',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'يتطلب اتصال بالإنترنت للتحميل الأول',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: subtleColor,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        _tafsir!.text,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: _fontSize,
          height: 1.9,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? (widget.isDark ? Colors.black : Colors.white)
                  : textColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? (widget.isDark ? Colors.black : Colors.white)
                    : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
