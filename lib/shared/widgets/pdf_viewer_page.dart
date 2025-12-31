import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../../app/theme/app_colors.dart';

class PdfViewerPage extends StatefulWidget {
  final String assetPath;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.assetPath,
    required this.title,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    // Only Android / iOS supported
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final bytes = await rootBundle.load(widget.assetPath);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${widget.assetPath.split('/').last}');
    await file.writeAsBytes(bytes.buffer.asUint8List());

    setState(() {
      localPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSupported = Platform.isAndroid || Platform.isIOS;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: !isSupported
          ? const Center(
              child: Text(
                'عرض PDF غير مدعوم على هذا النظام',
                textAlign: TextAlign.center,
              ),
            )
          : localPath == null
              ? const Center(child: CircularProgressIndicator())
              : PDFView(
                  filePath: localPath!,
                  enableSwipe: true,
                  autoSpacing: true,
                  pageSnap: true,
                ),
    );
  }
}
