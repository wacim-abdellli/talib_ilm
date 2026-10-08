import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_ui.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';

class DuasMiscPage extends StatelessWidget {
  DuasMiscPage({super.key});

  final AthkarService _service = AthkarService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const UnifiedAppBar(title: AppStrings.duasTitle, showBack: true),
      body: Container(
        color: context.backgroundColor,
        child: FutureBuilder<AthkarCatalog>(
          future: _service.loadCatalog(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data?.byId('duas')?.items ?? const [];
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.menu_book_outlined,
                title: AppStrings.duasEmptyTitle,
                subtitle: AppStrings.duasEmptyMessage,
                actionLabel: AppStrings.actionBack,
                onAction: () => Navigator.pop(context),
              );
            }

            return ListView.separated(
              padding: AppUi.screenPadding,
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppUi.gapMD),
              itemBuilder: (context, index) {
                final item = items[index];
                return _DuaCard(item: item);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final AthkarItem item;

  const _DuaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppUi.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.outlineVariantColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.arabic,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
            ],
          ),
          if (item.transliteration.isNotEmpty) ...[
            const SizedBox(height: AppUi.gapSM),
            Text(
              item.transliteration,
              style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
            ),
          ],
          if (item.meaning.isNotEmpty) ...[
            const SizedBox(height: AppUi.gapSM),
            Text(
              item.meaning,
              style: TextStyle(fontSize: 15, color: context.textPrimaryColor),
            ),
          ],
        ],
      ),
    );
  }
}
