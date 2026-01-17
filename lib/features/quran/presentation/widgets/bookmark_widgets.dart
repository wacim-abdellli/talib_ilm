import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/bookmark_service.dart';

/// Continue reading card widget
class ContinueReadingCard extends StatelessWidget {
  final LastReadPosition position;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const ContinueReadingCard({
    super.key,
    required this.position,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'واصل القراءة',
                            style: TextStyle(
                              fontSize: responsive.sp(14),
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            'سورة ${position.surahName}',
                            style: TextStyle(
                              fontSize: responsive.sp(20),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onDismiss != null)
                      IconButton(
                        onPressed: onDismiss,
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoBadge(
                      icon: Icons.bookmark_border,
                      label: 'آية ${position.verseNumber}',
                    ),
                    const SizedBox(width: 12),
                    _InfoBadge(
                      icon: Icons.article_outlined,
                      label: 'صفحة ${position.pageNumber}',
                    ),
                    const SizedBox(width: 12),
                    _InfoBadge(
                      icon: Icons.layers_outlined,
                      label: 'جزء ${position.juzNumber}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تقدم السورة',
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: Colors.white.withValues(alpha: 0.7),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          '${(position.surahProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: position.surahProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

/// Bookmark card widget with swipe to delete
class BookmarkCard extends StatelessWidget {
  final QuranBookmark bookmark;
  final bool nightMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    this.nightMode = false,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Dismissible(
      key: Key(bookmark.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: nightMode ? const Color(0xFF0A0A0A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: Color(0xFF14B8A6), width: 3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'سورة ${bookmark.surahName}',
                          style: TextStyle(
                            fontSize: responsive.sp(13),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14B8A6),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'آية ${bookmark.verseNumber}',
                        style: TextStyle(
                          fontSize: responsive.sp(13),
                          fontWeight: FontWeight.w600,
                          color: nightMode
                              ? Colors.white
                              : Colors.grey.shade800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bookmark.versePreview,
                    style: TextStyle(
                      fontSize: responsive.sp(16),
                      color: nightMode ? Colors.white : Colors.grey.shade700,
                      fontFamily: 'Amiri',
                      height: 1.6,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(bookmark.createdAt),
                        style: TextStyle(
                          fontSize: responsive.sp(11),
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'صفحة ${bookmark.pageNumber} • جزء ${bookmark.juzNumber}',
                        style: TextStyle(
                          fontSize: responsive.sp(11),
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
