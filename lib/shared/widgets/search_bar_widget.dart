import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = _isFocused
        ? context.goldColor
        : context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08);
    final borderWidth = _isFocused ? 1.5 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: context.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? context.goldColor.withValues(alpha: isDark ? 0.2 : 0.1)
                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: _isFocused ? 14 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            const SizedBox(width: 14),
            // Leading Icon
            Icon(
              Icons.search_rounded,
              size: 20,
              color: _isFocused ? context.goldColor : context.textSecondaryColor,
            ),
            const SizedBox(width: 10),
            // TextField
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
                cursorColor: context.goldColor,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: context.textTertiaryColor,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            // Trailing Actions
            if (_hasText)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.textSecondaryColor,
                ),
                onPressed: _clearSearch,
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),

            // Separation line
            Container(
              height: 20,
              width: 1,
              color: context.outlineVariantColor,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // Filter Button
            IconButton(
              icon: Icon(Icons.tune_rounded, size: 19, color: context.primaryColor),
              onPressed: widget.onFilterTap,
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
