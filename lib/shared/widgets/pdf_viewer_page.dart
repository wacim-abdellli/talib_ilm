import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/app_ui.dart';
import 'primary_app_bar.dart';

class PdfViewerPage extends StatefulWidget {
  final String assetPath;
  final String title;
  final int initialPage;
  final void Function(int page, int totalPages)? onPageChanged;
  final bool showAppBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final VoidCallback? onResetRequested;

  const PdfViewerPage({
    super.key,
    required this.assetPath,
    required this.title,
    this.initialPage = 1,
    this.onPageChanged,
    this.showAppBar = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onResetRequested,
  });

  @override
  State<PdfViewerPage> createState() => PdfViewerPageState();
}

class PdfViewerPageState extends State<PdfViewerPage> {
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
    final safePage = page < 1 ? 1 : (page > _totalPages ? _totalPages : page);
    _controller.jumpToPage(safePage);
  }

  void resetToStart() {
    if (_totalPages == 0) return;
    _controller.jumpToPage(1);
  }

  Future<void> _showJumpDialog() async {
    if (_totalPages == 0) return;

    final controller = TextEditingController(text: _currentPage.toString());
    final requested = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.pdfJumpTitle, style: AppText.heading),
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
              hintText: AppStrings.pageRangeHint(_totalPages),
              hintStyle: AppText.caption,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.pdfJumpCancel, style: AppText.body),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 1),
              child: Text(AppStrings.pdfJumpStart, style: AppText.body),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: Text(AppStrings.pdfJumpGo, style: AppText.body),
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
      appBar: widget.showAppBar
          ? UnifiedAppBar(title: widget.title, showBack: true)
          : null,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
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
                widget.onPageChanged?.call(details.newPageNumber, _totalPages);
              },
              onDocumentLoadFailed: (details) {
                if (!mounted) return;
                MediaQuery.of(context);
                AppSnackbar.success(context, AppStrings.bookProgressSaved);
              },
            ),
            if (_totalPages == 0)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            if (_totalPages > 0)
              Positioned(
                right: AppUi.gapMD,
                bottom: AppUi.gapMD,
                child: SafeArea(
                  top: false,
                  child: AnimatedContainer(
                    duration: AppUi.animationMedium,
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppUi.radiusPill),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppUi.radiusPill),
                      onTap: _showJumpDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppUi.gapMD,
                          vertical: AppUi.gapSM,
                        ),
                        child: AnimatedSwitcher(
                          duration: AppUi.animationFast,
                          child: Text(
                            AppStrings.pageCounter(_currentPage, _totalPages),
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
      ),
    );
  }
}
