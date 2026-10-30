import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Centralized, production-grade share coordinator for iOS and Android.
///
/// Ensures iOS and iPadOS always receive a non-null [sharePositionOrigin]
/// anchor rect, preventing `UIActivityViewController` presentation drops,
/// especially from within modal bottom sheets or custom dialogs.
class AppShare {
  AppShare._();

  /// Safely shares [text] with an optional [subject].
  ///
  /// Pass [context] from the triggering widget to anchor the share popover
  /// correctly on iOS/iPadOS. If [context] is null or unmounted, falls back to
  /// a safe screen anchor.
  static Future<ShareResult> share(
    BuildContext? context,
    String text, {
    String? subject,
  }) async {
    final origin = _resolveOrigin(context);
    try {
      return await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('AppShare.share failed: $e');
      return const ShareResult(
        'error',
        ShareResultStatus.unavailable,
      );
    }
  }

  /// Safely shares [files] with an optional [subject] and [text].
  static Future<ShareResult> shareXFiles(
    BuildContext? context,
    List<XFile> files, {
    String? subject,
    String? text,
  }) async {
    final origin = _resolveOrigin(context);
    try {
      return await Share.shareXFiles(
        files,
        subject: subject,
        text: text,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('AppShare.shareXFiles failed: $e');
      return const ShareResult(
        'error',
        ShareResultStatus.unavailable,
      );
    }
  }

  @visibleForTesting
  static Rect resolveOrigin(BuildContext? context) => _resolveOrigin(context);

  static Rect _resolveOrigin(BuildContext? context) {
    if (context != null && context.mounted) {
      try {
        final renderObject = context.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize) {
          final size = renderObject.size;
          if (size.width > 0 && size.height > 0) {
            final position = renderObject.localToGlobal(Offset.zero);
            return position & size;
          }
        }
      } catch (_) {
        // Fall back to media query
      }

      try {
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        final w = screenSize.width > 0 ? screenSize.width : 320.0;
        final h = screenSize.height > 0 ? screenSize.height : 480.0;
        return Rect.fromLTWH(0, h * 0.4, w, h * 0.2);
      } catch (_) {
        // Fall back to hardcoded rect
      }
    }

    return const Rect.fromLTWH(0, 200, 320, 200);
  }
}
