import 'package:drift/drift.dart';
import '../../database/drift_database.dart';

/// Per-user water tracking + reminder settings.
///
/// Goal/reminder fields live on the `Users` table; intake events on
/// `WaterIntakeLogs`. The shape of this service mirrors [MoodService] so the
/// user-page sections can be written symmetrically.
class WaterService {
  final AppDatabase _db;

  WaterService(this._db);

  /// Standard quick-add buttons surfaced by the log sheet, in millilitres.
  /// 200 ml glass, 330 ml can, 500 ml bottle. The sheet also offers a
  /// custom slider on top of these.
  static const List<int> quickAddPresetsMl = [200, 330, 500];

  // ── Intake events ──────────────────────────────────────────────────────

  /// Log a single intake event of [amountMl] for [userId].
  /// [loggedAt] is optional and defaults to now.
  Future<int> logIntake({
    required int userId,
    required int amountMl,
    DateTime? loggedAt,
  }) {
    return _db.into(_db.waterIntakeLogs).insert(
          WaterIntakeLogsCompanion.insert(
            userId: userId,
            amountMl: amountMl,
            loggedAt: loggedAt != null ? Value(loggedAt) : const Value.absent(),
          ),
        );
  }

  /// Delete a single intake event (for "undo" affordances).
  Future<void> deleteIntake(int id) async {
    await (_db.delete(_db.waterIntakeLogs)..where((t) => t.id.equals(id))).go();
  }

  /// Sum of all intakes today (local-time day window) for [userId], in ml.
  Future<int> getTodayTotal(int userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sumExp = _db.waterIntakeLogs.amountMl.sum();
    final query = _db.selectOnly(_db.waterIntakeLogs)
      ..addColumns([sumExp])
      ..where(
        _db.waterIntakeLogs.userId.equals(userId) &
            _db.waterIntakeLogs.loggedAt.isBiggerOrEqualValue(startOfDay) &
            _db.waterIntakeLogs.loggedAt.isSmallerThanValue(endOfDay),
      );

    final row = await query.getSingle();
    // sum() returns null when there are no rows.
    return (row.read(sumExp) ?? 0).toInt();
  }

  /// Timestamp of the most recent intake for [userId], or null if none.
  /// Used by the dashboard's time-island to decide whether the user is
  /// actively logging hydration (and therefore wants to see today's progress
  /// inline) — after a long quiet stretch the panel hides itself again.
  Future<DateTime?> getLastIntakeTime(int userId) async {
    final last = await (_db.select(_db.waterIntakeLogs)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
          ..limit(1))
        .getSingleOrNull();
    return last?.loggedAt;
  }

  /// Most recently logged intake amount for [userId], in millilitres.
  /// Used by the water-reminder notification's "Sem spil" button so a tap
  /// re-logs the same size the user picked last time. Falls back to 200 ml
  /// (a kozarec) when this user has no prior intakes.
  Future<int> getLastIntakeAmount(int userId) async {
    final last = await (_db.select(_db.waterIntakeLogs)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
          ..limit(1))
        .getSingleOrNull();
    return last?.amountMl ?? 200;
  }

  /// Today's intakes ordered newest-first. Used by the history list inside
  /// the Voda section so a misclick can be undone.
  Future<List<WaterIntakeLog>> getTodayEntries(int userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_db.select(_db.waterIntakeLogs)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.loggedAt.isBiggerOrEqualValue(startOfDay) &
                t.loggedAt.isSmallerThanValue(endOfDay),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
        .get();
  }

  /// Per-day totals for the last [days] days (oldest → newest). Days with no
  /// intake are included with `totalMl: 0` so callers can render a flat bar
  /// chart without holes.
  Future<List<Map<String, dynamic>>> getDailyTotals(
    int userId, {
    int days = 7,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final entries = await (_db.select(_db.waterIntakeLogs)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.loggedAt.isBiggerOrEqualValue(start),
          ))
        .get();

    // Bucket by yyyy-mm-dd in local time.
    final byDate = <String, int>{};
    for (final e in entries) {
      final d = e.loggedAt;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      byDate[key] = (byDate[key] ?? 0) + e.amountMl;
    }

    final result = <Map<String, dynamic>>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result.add({
        'date': date,
        'dateKey': key,
        'totalMl': byDate[key] ?? 0,
      });
    }
    return result;
  }

  // ── Settings (goal + reminders) ────────────────────────────────────────

  /// Convenience wrapper around the user row for the water UI. Falls back to
  /// the schema defaults if the user has somehow been deleted between the
  /// page opening and a settings read.
  Future<WaterSettings> getSettings(int userId) async {
    final user = await (_db.select(_db.users)
          ..where((t) => t.id.equals(userId)))
        .getSingleOrNull();
    if (user == null) return WaterSettings.defaults;
    return WaterSettings(
      goalMl: user.dailyWaterGoalMl,
      reminderEnabled: user.waterReminderEnabled,
      startHour: user.waterReminderStartHour,
      endHour: user.waterReminderEndHour,
      intervalMinutes: user.waterReminderIntervalMinutes,
    );
  }

  /// Update the daily goal. Clamped to a sane range (200–4000 ml) so a
  /// typo can't break the progress UI.
  Future<void> setGoal(int userId, int goalMl) {
    final clamped = goalMl.clamp(200, 4000);
    return (_db.update(_db.users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(dailyWaterGoalMl: Value(clamped)),
    );
  }

  /// Update reminder settings as a single write. Caller should follow this
  /// with `NotificationService.scheduleWaterReminders(user)` (or
  /// `cancelWaterReminders` when disabling) so the OS schedule matches the
  /// stored intent.
  Future<void> setReminderSettings(
    int userId, {
    bool? enabled,
    int? startHour,
    int? endHour,
    int? intervalMinutes,
  }) {
    return (_db.update(_db.users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        waterReminderEnabled:
            enabled == null ? const Value.absent() : Value(enabled),
        waterReminderStartHour: startHour == null
            ? const Value.absent()
            : Value(startHour.clamp(0, 23)),
        waterReminderEndHour: endHour == null
            ? const Value.absent()
            : Value(endHour.clamp(0, 23)),
        waterReminderIntervalMinutes: intervalMinutes == null
            ? const Value.absent()
            : Value(intervalMinutes.clamp(15, 360)),
      ),
    );
  }
}

/// Plain immutable carrier for the water-related fields on a user row.
/// Kept here (not in the table file) because it's purely a service-layer
/// convenience — the Drift-generated `User` already holds the raw columns.
class WaterSettings {
  final int goalMl;
  final bool reminderEnabled;
  final int startHour;
  final int endHour;
  final int intervalMinutes;

  const WaterSettings({
    required this.goalMl,
    required this.reminderEnabled,
    required this.startHour,
    required this.endHour,
    required this.intervalMinutes,
  });

  static const WaterSettings defaults = WaterSettings(
    goalMl: 2000,
    reminderEnabled: false,
    startHour: 8,
    endHour: 22,
    intervalMinutes: 120,
  );
}
