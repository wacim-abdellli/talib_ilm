import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

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

    // Styling constants
    final borderColor = isDark
        ? (_isFocused ? AppColors.primary : const Color(0xFF1F1F1F))
        : (_isFocused
              ? AppColors.primary
              : const Color(0xFFE7E5E4)); // Light Stone
    final borderWidth = _isFocused ? 2.0 : 1.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          isDark
              ? BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                )
              : BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            const SizedBox(width: 16),
            // Leading Icon
            Icon(
              Icons.search,
              size: 20,
              color: isDark ? const Color(0xFF666666) : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            // TextField
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                style: AppText.body.copyWith(
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppText.body.copyWith(
                    color: isDark
                        ? const Color(0xFF666666)
                        : AppColors.textSecondary.withValues(alpha: 0.6),
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
                  Icons.close,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFA1A1A1)
                      : AppColors.textSecondary,
                ),
                onPressed: _clearSearch,
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),

            // Separation line
            Container(
              height: 24,
              width: 1,
              color: isDark
                  ? const Color(0xFF333333)
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // Filter Button
            IconButton(
              icon: const Icon(Icons.tune, size: 20, color: AppColors.primary),
              onPressed: widget.onFilterTap,
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
