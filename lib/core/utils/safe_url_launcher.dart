import 'package:url_launcher/url_launcher.dart';

/// Trust boundary enforcer for all outbound external application and web links.
/// Strictly restricts outbound URIs to secure HTTPS endpoints and approved native schemas.
class SafeUrlLauncher {
  SafeUrlLauncher._();

  static const Set<String> _allowedSchemes = {'https', 'vnd.youtube'};

  /// Validates whether a URI adheres to security boundaries.
  /// Rejects unencrypted HTTP, file, content, and script injections.
  static bool isSafeUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (!_allowedSchemes.contains(scheme)) {
      return false;
    }
    final fullString = uri.toString().toLowerCase();
    if (fullString.contains('javascript:') ||
        fullString.contains('data:') ||
        fullString.contains('file:')) {
      return false;
    }
    return true;
  }

  /// Safely launches an outbound URL if and only if it passes security validation.
  static Future<bool> launchSafeUrl(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    if (!isSafeUri(uri)) {
      return false;
    }
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
