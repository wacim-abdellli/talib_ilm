import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../data/models/mutun_models.dart';
import 'book_view_page.dart';

class LevelBooksPage extends StatelessWidget {
  final IlmLevel level;

  const LevelBooksPage({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(level.title, style: AppText.heading)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: level.books.length,
        itemBuilder: (context, index) {
          final book = level.books[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookViewPage(book: book)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: AppText.heading),
                  const SizedBox(height: 4),
                  Text(book.author, style: AppText.secondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
