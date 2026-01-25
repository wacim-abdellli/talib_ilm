import 'package:flutter/material.dart';
import '../../data/services/quran_bookmark_service.dart';

/// Notes dialog for adding personal notes to ayahs
class AyahNotesDialog extends StatefulWidget {
  final int surah;
  final int ayah;
  final String ayahText;
  final bool isDark;

  const AyahNotesDialog({
    super.key,
    required this.surah,
    required this.ayah,
    required this.ayahText,
    this.isDark = false,
  });

  /// Show notes dialog
  static Future<void> show(
    BuildContext context, {
    required int surah,
    required int ayah,
    required String ayahText,
    bool isDark = false,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AyahNotesDialog(
        surah: surah,
        ayah: ayah,
        ayahText: ayahText,
        isDark: isDark,
      ),
    );
  }

  @override
  State<AyahNotesDialog> createState() => _AyahNotesDialogState();
}

class _AyahNotesDialogState extends State<AyahNotesDialog> {
  final _controller = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasExistingNote = false;

  @override
  void initState() {
    super.initState();
    _loadExistingNote();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNote() async {
    final note = await QuranBookmarkService.instance.getNote(
      widget.surah,
      widget.ayah,
    );
    if (mounted) {
      setState(() {
        if (note != null) {
          _controller.text = note.note;
          _hasExistingNote = true;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_controller.text.trim().isEmpty) {
      // Delete note if empty
      if (_hasExistingNote) {
        await QuranBookmarkService.instance.deleteNote(
          widget.surah,
          widget.ayah,
        );
      }
    } else {
      setState(() => _isSaving = true);
      await QuranBookmarkService.instance.saveNote(
        widget.surah,
        widget.ayah,
        _controller.text.trim(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteNote() async {
    await QuranBookmarkService.instance.deleteNote(widget.surah, widget.ayah);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final subtleColor = widget.isDark ? Colors.white54 : Colors.black45;
    // Use premium gold accent
    const accentColor = Color(0xFFD4A853);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ملاحظاتي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (_hasExistingNote)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: const Color(0xFFEF9A9A),
                    ),
                    onPressed: _deleteNote,
                    tooltip: 'حذف الملاحظة',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Ayah reference
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.surah}:${widget.ayah}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: subtleColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note input
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextField(
                controller: _controller,
                maxLines: 5,
                minLines: 3,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظتك هنا...',
                  hintStyle: TextStyle(color: subtleColor),
                  filled: true,
                  fillColor: widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(fontFamily: 'Cairo', color: subtleColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'حفظ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
