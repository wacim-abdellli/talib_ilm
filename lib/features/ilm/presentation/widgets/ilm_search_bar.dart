import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

/// A minimalist, high-craft search bar for the Ilm library.
/// Provides built-in debouncing (200ms via [AppMotion.base]), native RTL support,
/// and smooth, distraction-free focus interactions without circular ink bleed.
class IlmSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClear;
  final String hintText;

  const IlmSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    this.onClear,
    this.hintText = 'ابحث في المتون والكتب والشروح...',
  });

  @override
  State<IlmSearchBar> createState() => _IlmSearchBarState();
}

class _IlmSearchBarState extends State<IlmSearchBar> {
  late final FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus != _isFocused && mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _handleControllerChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText && mounted) {
      setState(() => _hasText = hasText);
    }
  }

  void _onChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppMotion.base, () {
      if (mounted) {
        widget.onSearchChanged(query.trim());
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    widget.controller.clear();
    widget.onSearchChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: AppSpace.screenPadding,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        textDirection: TextDirection.rtl,
        style: context.text.body.copyWith(
          color: palette.text,
        ),
        cursorColor: palette.primary,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: context.text.bodySmall.copyWith(
            color: palette.textMuted,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isFocused ? palette.primary : palette.textMuted,
            size: AppIcon.md,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: palette.textMuted,
                    size: AppIcon.sm,
                  ),
                  tooltip: 'مسح البحث',
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: palette.surfaceMuted,
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: BorderSide(color: palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: BorderSide(color: palette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: BorderSide(
              color: palette.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
