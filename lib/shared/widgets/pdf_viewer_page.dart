import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import 'primary_app_bar.dart';

class PdfViewerPage extends StatefulWidget {
  final String assetPath;
  final String title;
  final int initialPage;
  final void Function(int page, int totalPages)? onPageChanged;
  final bool showAppBar;

  const PdfViewerPage({
    super.key,
    required this.assetPath,
    required this.title,
    this.initialPage = 1,
    this.onPageChanged,
    this.showAppBar = true,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final PdfViewerController _controller;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _currentPage = widget.initialPage < 1 ? 1 : widget.initialPage;
  }

  Future<void> _jumpToPage(int page) async {
    if (_totalPages == 0) return;
    final safePage =
        page < 1 ? 1 : (page > _totalPages ? _totalPages : page);
    _controller.jumpToPage(safePage);
  }

  Future<void> _showJumpDialog() async {
    if (_totalPages == 0) return;

    final controller =
        TextEditingController(text: _currentPage.toString());
    final requested = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('الانتقال لصفحة', style: AppText.heading),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final parsed = int.tryParse(value);
              Navigator.pop(context, parsed);
            },
            decoration: InputDecoration(
              hintText: '1 - $_totalPages',
              hintStyle: AppText.caption,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: AppText.body),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('البداية', style: AppText.body),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: const Text('انتقال', style: AppText.body),
            ),
          ],
        );
      },
    );

    if (requested != null) {
      await _jumpToPage(requested);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? PrimaryAppBar(
              title: widget.title,
              showBack: true,
            )
          : null,
      body: Stack(
        children: [
          SfPdfViewer.asset(
            widget.assetPath,
            controller: _controller,
            initialPageNumber: _currentPage,
            scrollDirection: PdfScrollDirection.vertical,
            pageLayoutMode: PdfPageLayoutMode.continuous,
            enableDoubleTapZooming: true,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            onDocumentLoaded: (details) {
              if (!mounted) return;
              final total = details.document.pages.count;
              final safePage = _currentPage < 1
                  ? 1
                  : (_currentPage > total ? total : _currentPage);
              final shouldJump = safePage != _currentPage;
              setState(() {
                _totalPages = total;
                _currentPage = safePage;
              });
              if (shouldJump) {
                _controller.jumpToPage(safePage);
              }
            },
            onPageChanged: (details) {
              if (!mounted) return;
              setState(() => _currentPage = details.newPageNumber);
              widget.onPageChanged?.call(
                details.newPageNumber,
                _totalPages,
              );
            },
            onDocumentLoadFailed: (details) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(details.description)),
              );
            },
          ),
          if (_totalPages == 0)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          if (_totalPages > 0)
            Positioned(
              right: 12,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _showJumpDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          '$_currentPage / $_totalPages',
                          key: ValueKey('$_currentPage-$_totalPages'),
                          style: AppText.caption,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
