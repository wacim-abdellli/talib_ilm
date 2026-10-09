import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';
import 'app_card.dart';
import 'app_skeleton.dart';

class ShimmerBookCard extends StatelessWidget {
  const ShimmerBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: AppCard(
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              Container(
                width: AppSpace.sm,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: context.palette.surfaceMuted,
                  borderRadius: AppRadius.smRadius,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppSkeleton.line(height: 18, width: double.infinity),
                    const SizedBox(height: AppSpace.sm),
                    AppSkeleton.line(height: 18, width: 120),
                    const SizedBox(height: AppSpace.lg),
                    AppSkeleton.line(height: 6, width: double.infinity),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerPrayerTile extends StatelessWidget {
  const ShimmerPrayerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const AppSkeleton.circle(size: 32),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppSkeleton.line(width: 80, height: 14),
                    const SizedBox(height: AppSpace.sm),
                    AppSkeleton.line(width: 120, height: 10),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              AppSkeleton.line(width: 50, height: 20),
            ],
          ),
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
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpace.md),
          child: ShimmerPrayerTile(),
        ),
      ),
    );
  }
}

class ShimmerHadithCard extends StatelessWidget {
  const ShimmerHadithCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton.line(height: 16),
            const SizedBox(height: AppSpace.sm),
            AppSkeleton.line(height: 16),
            const SizedBox(height: AppSpace.sm),
            AppSkeleton.line(width: 200, height: 16),
            const SizedBox(height: AppSpace.xxl),
            AppSkeleton.line(width: 100, height: 14),
          ],
        ),
      ),
    );
  }
}

class ShimmerHeroCard extends StatelessWidget {
  const ShimmerHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: AppCard(
        borderRadius: AppRadius.xlRadius,
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          children: [
            const AppSkeleton.circle(size: 64),
            const SizedBox(height: AppSpace.lg),
            AppSkeleton.line(width: 100, height: 20),
            const SizedBox(height: AppSpace.sm),
            AppSkeleton.line(width: 200, height: 48),
            const SizedBox(height: AppSpace.lg),
            AppSkeleton.line(width: 100, height: 32),
          ],
        ),
      ),
    );
  }
}
