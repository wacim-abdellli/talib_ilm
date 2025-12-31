import 'package:flutter/material.dart';
import 'package:talib_ilm/features/ilm/presentation/pages/level_books_page.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/services/asset_service.dart';
import '../data/models/mutun_models.dart';

class IlmPage extends StatelessWidget {
  const IlmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('العلم', style: AppText.heading)),
      body: FutureBuilder<MutunProgram>(
        future: AssetService.loadMutunProgram(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('فشل تحميل المنهج'));
          }

          final levels = snapshot.data!.levels
            ..sort((a, b) => a.order.compareTo(b.order));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              return _LevelCard(level: levels[index]);
            },
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final IlmLevel level;

  const _LevelCard({required this.level});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LevelBooksPage(level: level),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level.title, style: AppText.heading),
                  const SizedBox(height: 6),
                  Text(level.description, style: AppText.secondary),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
