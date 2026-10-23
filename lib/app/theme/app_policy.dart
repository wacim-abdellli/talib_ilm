/// System-wide policy tokens for timeouts, intervals, polling rates, and retention budgets.
///
/// Centralized in theme layer to comply with tokenization rules and decouple
/// non-UI services from widget animation tokens (AppMotion).
class AppPolicy {
  const AppPolicy._();

  // Network & Async Timeouts
  static const Duration networkFast = Duration(seconds: 3);
  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration networkMedium = Duration(seconds: 20);
  static const Duration networkLong = Duration(seconds: 30);
  static const Duration networkRetry = Duration(seconds: 10);
  static const Duration microPause = Duration(milliseconds: 50);
  static const Duration debounce = Duration(milliseconds: 500);
  static const Duration seekStep = Duration(seconds: 5);

  // Periodic Intervals & Polling
  static const Duration oneSecond = Duration(seconds: 1);
  static const Duration pollingActive = Duration(seconds: 10);
  static const Duration pollingStandard = Duration(seconds: 30);
  static const Duration compassFallback = Duration(milliseconds: 600);
  static const Duration sensorCheck = Duration(milliseconds: 2500);

  // Storage & Cache Retention Budgets
  static const int maxStoredReadingSessions = 500;
  static const int maxReadingSessionAgeDays = 90;
  static const int maxCachedDownloadedBooks = 1000;
}
