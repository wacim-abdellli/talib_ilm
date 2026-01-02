import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';

class DuasMiscPage extends StatelessWidget {
  DuasMiscPage({super.key});

  final AthkarService _service = AthkarService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('أدعية وأذكار', style: AppText.headingXL),
        leading: const AppBackButton(),
      ),
      body: FutureBuilder<AthkarCatalog>(
        future: _service.loadCatalog(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data?.byId('duas')?.items ?? const [];
          if (items.isEmpty) {
            return const SizedBox.shrink();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _DuaCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final AthkarItem item;

  const _DuaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.6,
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.arabic,
            style: AppText.athkarBody.copyWith(color: AppColors.textPrimary),
          ),
          if (item.transliteration.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.transliteration,
              style: AppText.body.copyWith(color: secondary),
            ),
          ],
          if (item.meaning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.meaning,
              style: AppText.body.copyWith(color: secondary),
            ),
          ],
        ],
      ),
    );
  }
}
