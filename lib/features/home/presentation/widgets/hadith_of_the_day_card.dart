import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HadithOfTheDayCard extends StatelessWidget {
  final String arabicText;
  final String source;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const HadithOfTheDayCard({
    super.key,
    required this.arabicText,
    required this.source,
    this.isFavorite = false,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'حديث نبوي',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: const Color(0xFF3B82F6),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quote decoration
          Container(
            padding: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFF3B82F6), width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arabic text
                Text(
                  arabicText,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.9,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.fade,
                  maxLines: 8,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Source and actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Ultra light slate
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        source,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: arabicText));
                },
                icon: const Icon(Icons.copy_rounded, size: 20),
                color: const Color(0xFF64748B),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_rounded, size: 20),
                color: const Color(0xFF64748B),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
