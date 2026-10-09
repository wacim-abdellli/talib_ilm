import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onFilterTap;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
    this.hintText = 'ابحث في الكتب والدروس',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      if (mounted) setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus != _isFocused) {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(query);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final borderColor = _isFocused ? palette.primary : palette.border;
    final borderWidth = _isFocused ? 2.0 : 1.0;

    return AnimatedContainer(
      duration: AppMotion.fast,
      height: AppSize.inputH,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            const SizedBox(width: AppSpace.md),
            Icon(
              Icons.search_rounded,
              size: AppIcon.md,
              color: _isFocused ? palette.primary : palette.textSubtle,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                style: textTheme.body.copyWith(color: palette.text),
                cursorColor: palette.primary,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: textTheme.bodySmall.copyWith(color: palette.textSubtle),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
            ),
            if (_hasText)
              IconButton(
                tooltip: 'مسح البحث',
                icon: Icon(
                  Icons.close_rounded,
                  size: AppIcon.md,
                  color: palette.textSubtle,
                ),
                onPressed: _clearSearch,
              ),
            Container(
              height: 20,
              width: 1,
              color: palette.border,
              margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            ),
            IconButton(
              tooltip: 'تصفية',
              icon: Icon(
                Icons.tune_rounded,
                size: AppIcon.md,
                color: palette.primary,
              ),
              onPressed: widget.onFilterTap,
            ),
            const SizedBox(width: AppSpace.xs),
          ],
        ),
      ),
    );
  }
}
