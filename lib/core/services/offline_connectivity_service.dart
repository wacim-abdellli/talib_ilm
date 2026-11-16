import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// Lightweight, resilient service to monitor device internet connectivity.
/// Notifies UI when device enters or leaves offline state (e.g. airplane mode, no signal)
/// and refreshes cleanly when returning to the foreground or when real requests succeed.
class OfflineConnectivityService with WidgetsBindingObserver {
  static final OfflineConnectivityService _instance =
      OfflineConnectivityService._internal();
  factory OfflineConnectivityService() => _instance;

  OfflineConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final ValueNotifier<bool> isOfflineNotifier = ValueNotifier<bool>(false);

  bool get isOffline => overrideForTesting ?? isOfflineNotifier.value;

  @visibleForTesting
  static bool? overrideForTesting;

  @visibleForTesting
  static void setOverrideForTesting(bool? value) {
    overrideForTesting = value;
    _instance.isOfflineNotifier.value = value ?? false;
  }

  void _init() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    // Initial check
    checkConnectivity();

    // Listen for live connection changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkConnectivity();
    }
  }

  /// Called when an actual network request (e.g. audio stream or page fetch) succeeds,
  /// clearing any stale offline banner immediately.
  void reportOnline() {
    if (overrideForTesting != null) return;
    if (isOfflineNotifier.value) {
      isOfflineNotifier.value = false;
    }
  }

  /// Manually query current connectivity. Returns `true` if offline, `false` if connected.
  Future<bool> checkConnectivity() async {
    if (overrideForTesting != null) {
      isOfflineNotifier.value = overrideForTesting!;
      return overrideForTesting!;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return isOfflineNotifier.value;
    } catch (_) {
      // In case of platform channel error, assume not offline to avoid false alerts
      isOfflineNotifier.value = false;
      return false;
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (overrideForTesting != null) {
      isOfflineNotifier.value = overrideForTesting!;
      return;
    }

    // Consider any active transport (including .other for hotspots/tunnels/dual-SIM)
    // as connected. Only .none and .bluetooth indicate lack of internet interface.
    final hasConnection = results.any(
      (r) =>
          r != ConnectivityResult.none && r != ConnectivityResult.bluetooth,
    );

    final offline = results.isEmpty || !hasConnection;
    if (isOfflineNotifier.value != offline) {
      isOfflineNotifier.value = offline;
    }
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _subscription?.cancel();
  }
}
