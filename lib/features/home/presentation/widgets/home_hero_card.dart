import 'package:flutter/material.dart';

class HomeHeroCard extends StatelessWidget {
  final String nextPrayer;
  final String timeRemaining;
  final String nextPrayerTime;

  const HomeHeroCard({
    super.key,
    required this.nextPrayer,
    required this.timeRemaining,
    required this.nextPrayerTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Icon with teal gradient
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mosque_outlined,
                color: Colors.white,
                size: 36,
              ),
            ),

            const SizedBox(height: 20),

            // Prayer name
            Text(
              nextPrayer,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),

            const SizedBox(height: 12),

            // Countdown
            Text(
              timeRemaining,
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1,
                letterSpacing: -2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),

            const SizedBox(height: 16),

            // Time pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Color(0xFF14B8A6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    nextPrayerTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
