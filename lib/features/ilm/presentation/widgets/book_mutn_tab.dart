import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/catalogs/mutun_digital_catalog.dart';
import '../../data/models/mutun_models.dart';
import 'mutn_digital_reader.dart';

enum MutnReadingMode {
  digital,
  pdf,
}

class BookMutnTab extends StatefulWidget {
  final IlmBook book;
  final String mutunPdfPath;
  final Future<int> mutunInitialPage;
  final GlobalKey<PdfViewerPageState> mutnPdfKey;
  final Future<void> Function(int page, int total) onPageChanged;

  const BookMutnTab({
    super.key,
    required this.book,
    required this.mutunPdfPath,
    required this.mutunInitialPage,
    required this.mutnPdfKey,
    required this.onPageChanged,
  });

  @override
  State<BookMutnTab> createState() => _BookMutnTabState();
}

class _BookMutnTabState extends State<BookMutnTab> {
  MutnReadingMode _mode = MutnReadingMode.digital;
  bool _modeLoaded = false;
  MutunDigitalEntry? _digitalEntry;

  @override
  void initState() {
    super.initState();
    _digitalEntry = MutunDigitalCatalog.getEntry(widget.book.id);
    _loadReadingMode();
  }

  Future<void> _loadReadingMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('mutn_reader_mode_${widget.book.id}');
    if (!mounted) return;

    setState(() {
      if (savedMode == 'pdf' && widget.mutunPdfPath.isNotEmpty) {
        _mode = MutnReadingMode.pdf;
      } else if (_digitalEntry != null) {
        _mode = MutnReadingMode.digital;
      } else if (widget.mutunPdfPath.isNotEmpty) {
        _mode = MutnReadingMode.pdf;
      } else {
        _mode = MutnReadingMode.digital;
      }
      _modeLoaded = true;
    });
  }

  Future<void> _setReadingMode(MutnReadingMode newMode) async {
    if (_mode == newMode) return;
    HapticFeedback.selectionClick();
    setState(() => _mode = newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mutn_reader_mode_${widget.book.id}',
      newMode == MutnReadingMode.pdf ? 'pdf' : 'digital',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final hasPdf = widget.mutunPdfPath.isNotEmpty;
    final hasDigital = _digitalEntry != null;

    if (!hasPdf && !hasDigital) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: AppEmptyState(
            icon: Icons.menu_book_outlined,
            title: AppStrings.bookMutnEmptyTitle,
            subtitle: AppStrings.bookMutnEmptyMessage,
            action: AppButton(
              label: AppStrings.actionBack,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    }

    if (!_modeLoaded) {
      return Center(
        child: CircularProgressIndicator(
          color: palette.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    return Column(
      children: [
        // Mode Switcher Pill (Only if both digital and PDF exist)
        if (hasPdf && hasDigital)
          Container(
            color: palette.surfaceRaised,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeOption(
                  label: 'النص الرقمي المحقق',
                  icon: Icons.auto_stories_rounded,
                  mode: MutnReadingMode.digital,
                  palette: palette,
                  textTheme: textTheme,
                ),
                const SizedBox(width: AppSpace.sm),
                _buildModeOption(
                  label: 'النسخة المصورة PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  mode: MutnReadingMode.pdf,
                  palette: palette,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),

        // Main Reader View
        Expanded(
          child: _mode == MutnReadingMode.digital && hasDigital
              ? FutureBuilder<int>(
                  future: widget.mutunInitialPage,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: palette.primary,
                          strokeWidth: 2.5,
                        ),
                      );
                    }
                    return MutnDigitalReaderView(
                      book: widget.book,
                      digitalEntry: _digitalEntry!,
                      initialPage: snapshot.data!,
                      onPageChanged: widget.onPageChanged,
                    );
                  },
                )
              : FutureBuilder<int>(
                  future: widget.mutunInitialPage,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: palette.primary,
                          strokeWidth: 2.5,
                        ),
                      );
                    }
                    return PdfViewerPage(
                      key: widget.mutnPdfKey,
                      title: AppStrings.bookMutnTitle,
                      assetPath: widget.mutunPdfPath,
                      showAppBar: false,
                      initialPage: snapshot.data!,
                      onPageChanged: widget.onPageChanged,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
    required MutnReadingMode mode,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () => _setReadingMode(mode),
      borderRadius: AppRadius.pillRadius,
      child: AnimatedContainer(
        duration: AppMotion.base,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? palette.primarySoft : Colors.transparent,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: isSelected ? palette.primary : palette.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIcon.sm,
              color: isSelected ? palette.primary : palette.textMuted,
            ),
            const SizedBox(width: AppSpace.xs),
            Text(
              label,
              style: textTheme.caption.copyWith(
                color: isSelected ? palette.primary : palette.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
