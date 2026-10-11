import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

/// Shimmer loading state view for the Ilm library.
class IlmLoadingView extends StatelessWidget {
  const IlmLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: AppSpace.screenPadding,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const SizedBox(height: AppSpace.md),
              const ShimmerBookCard(),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                height: 500,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpace.md,
                    mainAxisSpacing: AppSpace.md,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => const ShimmerBookCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
