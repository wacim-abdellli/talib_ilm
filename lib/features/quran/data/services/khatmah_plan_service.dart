import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/async_lock.dart';
import '../models/khatmah_plan.dart';

/// Persists local Khatmah plans and page-completion records.
class KhatmahPlanService {
  KhatmahPlanService._();

  static const String _storageKey = 'quran_khatmah_plans_v1';
  static const int _schemaVersion = 1;
  static final AsyncLock _lock = AsyncLock();

  static Future<List<KhatmahPlan>> getPlans({bool includeArchived = false}) =>
      _lock.synchronized(() async {
        final prefs = await SharedPreferences.getInstance();
        final plans = _decodePlans(prefs.getString(_storageKey));
        final visible = includeArchived
            ? plans
            : plans.where((plan) => !plan.isArchived).toList();
        visible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return visible;
      });

  static Future<KhatmahPlan> createPlan({
    required String title,
    required int startPage,
    required int pagesPerDay,
    DateTime? targetDate,
    DateTime? now,
  }) async {
    final createdAt = _dateOnly(now ?? DateTime.now());
    final cleanTitle = _validateTitle(title);
    _validatePageGoal(startPage, pagesPerDay);
    final cleanTarget = targetDate == null ? null : _dateOnly(targetDate);
    if (cleanTarget != null && cleanTarget.isBefore(createdAt)) {
      throw ArgumentError('Target date must be today or later.');
    }

    return _transaction((plans) {
      final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      final plan = KhatmahPlan(
        id: id,
        title: cleanTitle,
        startPage: startPage,
        pagesPerDay: pagesPerDay,
        completedPageNumbers: const {},
        createdAt: createdAt,
        targetDate: cleanTarget,
      );
      plans.add(plan);
      return plan;
    });
  }

  static Future<KhatmahPlan> updatePlan({
    required String id,
    required String title,
    required int pagesPerDay,
    DateTime? targetDate,
    required bool useTargetDate,
  }) async {
    final cleanTitle = _validateTitle(title);
    final cleanTarget = useTargetDate && targetDate != null
        ? _dateOnly(targetDate)
        : null;
    final today = _dateOnly(DateTime.now());
    if (cleanTarget != null && cleanTarget.isBefore(today)) {
      throw ArgumentError('Target date must be today or later.');
    }

    return _transaction((plans) {
      final index = plans.indexWhere((plan) => plan.id == id);
      if (index < 0) throw StateError('Khatmah plan not found.');
      final current = plans[index];
      _validatePageGoal(current.startPage, pagesPerDay);
      final updated = current.copyWith(
        title: cleanTitle,
        pagesPerDay: pagesPerDay,
        targetDate: cleanTarget,
        clearTargetDate: cleanTarget == null,
      );
      plans[index] = updated;
      return updated;
    });
  }

  static Future<KhatmahPlan> recordPages({
    required String id,
    required int pages,
    DateTime? date,
  }) {
    if (pages < 1 || pages > KhatmahPlan.mushafPageCount) {
      throw ArgumentError('Pages to record must be between 1 and 604.');
    }

    final recordedDate = _dateOnly(date ?? DateTime.now());
    return _transaction((plans) {
      final index = plans.indexWhere((plan) => plan.id == id);
      if (index < 0) throw StateError('Khatmah plan not found.');
      final current = plans[index];
      if (current.isArchived || current.isPaused || current.isComplete) {
        throw StateError('This Khatmah plan cannot record progress.');
      }
      final pagesToRecord = current.nextUnreadPages(pages);
      if (pagesToRecord.isEmpty) return current;
      final updated = _markPagesComplete(current, pagesToRecord, recordedDate);
      plans[index] = updated;
      return updated;
    });
  }

  /// Automatically credits a page after the reader confirms it was actively viewed.
  /// A page is credited to each active plan whose range includes that page.
  static Future<void> recordPageRead({required int page, DateTime? date}) {
    if (page < 1 || page > KhatmahPlan.mushafPageCount) {
      throw ArgumentError('Page must be between 1 and 604.');
    }

    final recordedDate = _dateOnly(date ?? DateTime.now());
    return _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final plans = _decodePlans(prefs.getString(_storageKey));
      var changed = false;
      for (var index = 0; index < plans.length; index++) {
        final current = plans[index];
        if (current.isArchived ||
            current.isPaused ||
            current.isComplete ||
            !current.includesPage(page) ||
            current.completedPageNumbers.contains(page)) {
          continue;
        }
        plans[index] = _markPagesComplete(current, [page], recordedDate);
        changed = true;
      }
      if (changed) {
        await prefs.setString(
          _storageKey,
          jsonEncode({
            'version': _schemaVersion,
            'plans': plans.map((plan) => plan.toJson()).toList(),
          }),
        );
      }
    });
  }

  static KhatmahPlan _markPagesComplete(
    KhatmahPlan current,
    Iterable<int> pages,
    DateTime date,
  ) {
    final completedPageNumbers = Set<int>.of(current.completedPageNumbers);
    var newlyCompleted = 0;
    for (final page in pages) {
      if (current.includesPage(page) && completedPageNumbers.add(page)) {
        newlyCompleted++;
      }
    }
    if (newlyCompleted == 0) return current;

    final dailyProgress = Map<String, int>.of(current.dailyProgress);
    final key = _dateKey(date);
    dailyProgress[key] = (dailyProgress[key] ?? 0) + newlyCompleted;
    final completed = completedPageNumbers.length == current.totalPages;
    return current.copyWith(
      completedPageNumbers: completedPageNumbers,
      dailyProgress: dailyProgress,
      completedAt: completed ? _dateOnly(date) : null,
      clearCompletedAt: !completed,
    );
  }

  static Future<KhatmahPlan> setPaused({
    required String id,
    required bool paused,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    return _transaction((plans) {
      final index = plans.indexWhere((plan) => plan.id == id);
      if (index < 0) throw StateError('Khatmah plan not found.');
      final current = plans[index];
      if (current.isArchived || current.isComplete) return current;
      if (paused && !current.isPaused) {
        final updated = current.copyWith(pausedAt: today);
        plans[index] = updated;
        return updated;
      }
      if (!paused && current.isPaused) {
        final pausedAt = current.pausedAt!;
        final pausedDays = today.difference(pausedAt).inDays;
        final shiftedTarget = current.targetDate?.add(
          Duration(days: pausedDays < 0 ? 0 : pausedDays),
        );
        final updated = current.copyWith(
          pausedAt: null,
          clearPausedAt: true,
          targetDate: shiftedTarget,
          clearTargetDate: shiftedTarget == null,
        );
        plans[index] = updated;
        return updated;
      }
      return current;
    });
  }

  static Future<KhatmahPlan> setArchived({
    required String id,
    required bool archived,
  }) {
    return _transaction((plans) {
      final index = plans.indexWhere((plan) => plan.id == id);
      if (index < 0) throw StateError('Khatmah plan not found.');
      final updated = plans[index].copyWith(isArchived: archived);
      plans[index] = updated;
      return updated;
    });
  }

  static Future<void> deletePlan(String id) {
    return _transaction((plans) {
      plans.removeWhere((plan) => plan.id == id);
    });
  }

  static Future<T> _transaction<T>(
    FutureOr<T> Function(List<KhatmahPlan> plans) action,
  ) {
    return _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final plans = _decodePlans(prefs.getString(_storageKey));
      final result = await action(plans);
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'version': _schemaVersion,
          'plans': plans.map((plan) => plan.toJson()).toList(),
        }),
      );
      return result;
    });
  }

  static List<KhatmahPlan> _decodePlans(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != _schemaVersion) return [];
      final rawPlans = decoded['plans'];
      if (rawPlans is! List) return [];
      final plans = <KhatmahPlan>[];
      for (final rawPlan in rawPlans) {
        if (rawPlan is! Map) continue;
        try {
          plans.add(
            KhatmahPlan.fromJson(
              rawPlan.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        } on FormatException {
          // Skip an invalid record while retaining healthy plans.
        }
      }
      return plans;
    } on FormatException {
      return [];
    }
  }

  static String _validateTitle(String title) {
    final clean = title.trim();
    if (clean.isEmpty || clean.length > 60) {
      throw ArgumentError('Plan title must contain 1 to 60 characters.');
    }
    return clean;
  }

  static void _validatePageGoal(int startPage, int pagesPerDay) {
    if (startPage < 1 || startPage > KhatmahPlan.mushafPageCount) {
      throw ArgumentError('Start page must be between 1 and 604.');
    }
    if (pagesPerDay < 1 || pagesPerDay > KhatmahPlan.mushafPageCount) {
      throw ArgumentError('Daily pages must be between 1 and 604.');
    }
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
