import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Lightweight, resilient service to monitor device internet connectivity.
/// Notifies UI when device enters or leaves offline state (e.g. airplane mode, no signal).
class OfflineConnectivityService {
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
    // Initial check
    checkConnectivity();

    // Listen for live connection changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  /// Manually query current connectivity
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

    // A device is considered offline if results is empty or only contains .none
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);

    final offline = !hasConnection;
    if (isOfflineNotifier.value != offline) {
      isOfflineNotifier.value = offline;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
