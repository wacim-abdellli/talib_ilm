import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../app/theme/app_colors.dart';

class PdfViewerPage extends StatelessWidget {
  final String assetPath;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.assetPath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: PDFView(
        filePath: assetPath,
        enableSwipe: true,
        autoSpacing: true,
        pageSnap: true,
      ),
    );
  }
}
