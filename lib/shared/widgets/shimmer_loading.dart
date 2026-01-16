import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBookCard extends StatelessWidget {
  const ShimmerBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildShimmer(
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Left color bar
            Container(
              width: 8,
              height:
                  120, // To match spec "Left color bar 120 height"? Or full card? Assuming centered vertical strip or similar.
              // Actually "Left color bar: 8 width, 120 height" usually implies a decorative strip.
              // Let's make it a small rounded bar inside.
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Two text lines
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Progress bar
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
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
}

class ShimmerPrayerTile extends StatelessWidget {
  const ShimmerPrayerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildShimmer(
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Guessing radius
          border: Border.all(color: Colors.white), // Invisible but takes space
        ),
        child: Row(
          children: [
            // Circle left 32 diameter
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Maybe time on right?
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerPrayerList extends StatelessWidget {
  final int count;
  const ShimmerPrayerList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: const ShimmerPrayerTile(),
        ),
      ),
    );
  }
}

class ShimmerHadithCard extends StatelessWidget {
  const ShimmerHadithCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildShimmer(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Multiple text lines
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(width: 200, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 150, height: 16, color: Colors.white),
                const SizedBox(height: 24),
                // Source line
                Container(width: 100, height: 14, color: Colors.white),
              ],
            ),
            Positioned(
              top: 0,
              left:
                  0, // Arabic LTR mirror? usually trailing right or leading left. Top-right requested.
              // "Circle top-right: 24 diameter". In RTL context, right is start.
              // Let's assume standard visual right.
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper
Widget _buildShimmer({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: child,
  );
}
