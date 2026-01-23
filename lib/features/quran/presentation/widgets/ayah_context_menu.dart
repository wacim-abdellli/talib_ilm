import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import 'tafsir_sheet.dart';
import 'ayah_notes_dialog.dart';
import '../../data/services/quran_bookmark_service.dart';

/// Context menu for ayah actions
/// Shows on long-press or tap on verse marker
class AyahContextMenu extends StatelessWidget {
  final int surah;
  final int ayah;
  final String ayahText;
  final bool isDark;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onShare;

  const AyahContextMenu({
    super.key,
    required this.surah,
    required this.ayah,
    required this.ayahText,
    this.isDark = false,
    this.onPlayAudio,
    this.onShare,
  });

  /// Show context menu
  static Future<void> show(
    BuildContext context, {
    required int surah,
    required int ayah,
    required String ayahText,
    bool isDark = false,
    VoidCallback? onPlayAudio,
    VoidCallback? onShare,
  }) {
    HapticFeedback.mediumImpact();

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AyahContextMenu(
        surah: surah,
        ayah: ayah,
        ayahText: ayahText,
        isDark: isDark,
        onPlayAudio: onPlayAudio,
        onShare: onShare,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white54 : Colors.black45;
    final accentColor = isDark
        ? const Color(0xFF00D9C0)
        : const Color(0xFFD4A853);

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.6, // Max 60% of screen
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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

            // Ayah info header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$surah:$ayah',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'خيارات الآية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // Menu options (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.auto_stories_rounded,
                      label: 'التفسير',
                      subtitle: 'ابن كثير • السعدي',
                      color: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        TafsirSheet.show(
                          context,
                          surah: surah,
                          ayah: ayah,
                          ayahText: ayahText,
                          isDark: isDark,
                        );
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.bookmark_add_rounded,
                      label: 'حفظ الآية',
                      subtitle: 'إضافة إلى المفضلة',
                      color: Colors.amber.shade600,
                      onTap: () async {
                        Navigator.pop(context);
                        await QuranBookmarkService.instance.bookmarkAyah(
                          surah,
                          ayah,
                        );
                        if (context.mounted) {
                          AppSnackbar.success(context, 'تم حفظ الآية');
                        }
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.edit_note_rounded,
                      label: 'ملاحظاتي',
                      subtitle: 'إضافة ملاحظة شخصية',
                      color: Colors.blue.shade400,
                      onTap: () {
                        Navigator.pop(context);
                        AyahNotesDialog.show(
                          context,
                          surah: surah,
                          ayah: ayah,
                          ayahText: ayahText,
                          isDark: isDark,
                        );
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.play_circle_rounded,
                      label: 'استماع',
                      subtitle: 'تشغيل الآية',
                      color: Colors.green.shade500,
                      onTap: () {
                        Navigator.pop(context);
                        onPlayAudio?.call();
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.copy_rounded,
                      label: 'نسخ',
                      subtitle: 'نسخ نص الآية',
                      color: Colors.purple.shade400,
                      onTap: () {
                        Navigator.pop(context);
                        final text = '$ayahText\n\n[$surah:$ayah]';
                        Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          AppSnackbar.success(context, 'تم النسخ');
                        }
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.share_rounded,
                      label: 'مشاركة',
                      subtitle: 'مشاركة الآية',
                      color: Colors.teal.shade400,
                      onTap: () {
                        Navigator.pop(context);
                        onShare?.call();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white54 : Colors.black45;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: subtleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: subtleColor, size: 20),
          ],
        ),
      ),
    );
  }
}
