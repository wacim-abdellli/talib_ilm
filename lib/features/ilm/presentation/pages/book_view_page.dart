import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../data/models/mutun_models.dart';

class BookViewPage extends StatelessWidget {
  final IlmBook book;

  const BookViewPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(book.title, style: AppText.heading),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المتن'),
              Tab(text: 'الشرح'),
              Tab(text: 'الدروس'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlaceholderView(title: 'المتن'),
            _PlaceholderView(title: 'الشرح'),
            _PlaceholderView(title: 'الدروس'),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  final String title;

  const _PlaceholderView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'سيتم إضافة $title لاحقًا',
        style: AppText.secondary,
      ),
    );
  }
}
