enum ScheduleOutcomeStatus {
  exact,
  inexactFallback,
  skippedPast,
  permissionDenied,
  failed,
}

/// Represents the typed outcome of an individual notification scheduling operation.
class ScheduleOutcome {
  final ScheduleOutcomeStatus status;
  final String? errorMessage;
  final int? notificationId;

  const ScheduleOutcome({
    required this.status,
    this.errorMessage,
    this.notificationId,
  });

  bool get isSuccessful =>
      status == ScheduleOutcomeStatus.exact ||
      status == ScheduleOutcomeStatus.inexactFallback ||
      status == ScheduleOutcomeStatus.skippedPast;

  static const exact = ScheduleOutcome(status: ScheduleOutcomeStatus.exact);
  static const skippedPast =
      ScheduleOutcome(status: ScheduleOutcomeStatus.skippedPast);
  static const permissionDenied =
      ScheduleOutcome(status: ScheduleOutcomeStatus.permissionDenied);

  @override
  String toString() =>
      'ScheduleOutcome(status: $status, id: $notificationId, error: $errorMessage)';
}

/// Aggregated result of a multi-day rolling prayer schedule batch.
class ScheduleBatchResult {
  final int totalAttempted;
  final int exactScheduled;
  final int inexactFallbackScheduled;
  final int skippedPast;
  final int failed;
  final List<String> errors;

  const ScheduleBatchResult({
    this.totalAttempted = 0,
    this.exactScheduled = 0,
    this.inexactFallbackScheduled = 0,
    this.skippedPast = 0,
    this.failed = 0,
    this.errors = const [],
  });

  bool get isSuccess => failed == 0;

  @override
  String toString() =>
      'ScheduleBatchResult(total: $totalAttempted, exact: $exactScheduled, fallback: $inexactFallbackScheduled, skipped: $skippedPast, failed: $failed)';
}
