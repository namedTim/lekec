import 'package:drift/drift.dart';
import '../../database/drift_database.dart';
import '../../database/tables/period_entries.dart';

class PeriodService {
  final AppDatabase _db;

  PeriodService(this._db);

  /// Flow intensity labels in Slovenian
  static const Map<int, String> flowLabels = {
    1: 'Šibek',
    2: 'Zmeren',
    3: 'Močan',
  };

  /// Flow intensity icons
  static const Map<int, String> flowIcons = {1: '💧', 2: '💧💧', 3: '💧💧💧'};

  /// Log a period start
  Future<int> logPeriodStart({
    required int userId,
    required DateTime date,
    int? flowIntensity,
    String? note,
  }) async {
    // If there's already an active period, end it first
    final activePeriod = await getActivePeriod(userId);
    if (activePeriod != null) {
      await logPeriodEnd(
        userId: userId,
        date: date.subtract(const Duration(days: 1)),
      );
    }

    return _db
        .into(_db.periodEntries)
        .insert(
          PeriodEntriesCompanion.insert(
            userId: userId,
            entryType: PeriodEntryTypes.start,
            flowIntensity: Value(flowIntensity),
            note: Value(note),
            date: date,
          ),
        );
  }

  /// Log a period end
  Future<int> logPeriodEnd({
    required int userId,
    required DateTime date,
    String? note,
  }) async {
    return _db
        .into(_db.periodEntries)
        .insert(
          PeriodEntriesCompanion.insert(
            userId: userId,
            entryType: PeriodEntryTypes.end,
            note: Value(note),
            date: date,
          ),
        );
  }

  /// Log a period note (symptom, etc.)
  Future<int> logPeriodNote({
    required int userId,
    required DateTime date,
    required String note,
    int? flowIntensity,
  }) async {
    return _db
        .into(_db.periodEntries)
        .insert(
          PeriodEntriesCompanion.insert(
            userId: userId,
            entryType: PeriodEntryTypes.note,
            flowIntensity: Value(flowIntensity),
            note: Value(note),
            date: date,
          ),
        );
  }

  /// Delete a period entry
  Future<void> deleteEntry(int id) async {
    await (_db.delete(_db.periodEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Get the currently active period (started but not ended) for a user
  Future<PeriodEntry?> getActivePeriod(int userId) async {
    // Get the latest start entry
    final starts =
        await (_db.select(_db.periodEntries)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.entryType.equals(PeriodEntryTypes.start),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .get();

    if (starts.isEmpty) return null;

    final lastStart = starts.first;

    // Check if there's an end entry after this start
    final ends =
        await (_db.select(_db.periodEntries)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.entryType.equals(PeriodEntryTypes.end) &
                    t.date.isBiggerOrEqualValue(lastStart.date),
              )
              ..limit(1))
            .get();

    // If no end found after the last start, period is active
    return ends.isEmpty ? lastStart : null;
  }

  /// Get period entries for a user in the last N days
  Future<List<PeriodEntry>> getPeriodHistory(
    int userId, {
    int days = 90,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));

    return (_db.select(_db.periodEntries)
          ..where(
            (t) => t.userId.equals(userId) & t.date.isBiggerOrEqualValue(since),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get all completed cycles (start→end pairs) for cycle length calculation
  Future<List<Map<String, dynamic>>> getCompletedCycles(
    int userId, {
    int maxCycles = 6,
  }) async {
    final entries =
        await (_db.select(_db.periodEntries)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    (t.entryType.equals(PeriodEntryTypes.start) |
                        t.entryType.equals(PeriodEntryTypes.end)),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();

    final cycles = <Map<String, dynamic>>[];
    PeriodEntry? currentStart;

    for (final entry in entries) {
      if (entry.entryType == PeriodEntryTypes.start) {
        currentStart = entry;
      } else if (entry.entryType == PeriodEntryTypes.end &&
          currentStart != null) {
        cycles.add({
          'start': currentStart.date,
          'end': entry.date,
          'durationDays': entry.date.difference(currentStart.date).inDays + 1,
        });
        currentStart = null;
      }
    }

    // Return last N cycles
    if (cycles.length > maxCycles) {
      return cycles.sublist(cycles.length - maxCycles);
    }
    return cycles;
  }

  /// Get average cycle length in days
  Future<int?> getAverageCycleLength(int userId) async {
    // Get start entries to calculate cycle-to-cycle length
    final starts =
        await (_db.select(_db.periodEntries)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.entryType.equals(PeriodEntryTypes.start),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();

    if (starts.length < 2) return null;

    int totalDays = 0;
    int count = 0;
    for (int i = 1; i < starts.length; i++) {
      totalDays += starts[i].date.difference(starts[i - 1].date).inDays;
      count++;
    }

    return count > 0 ? (totalDays / count).round() : null;
  }

  /// Get average period duration in days
  Future<int?> getAveragePeriodDuration(int userId) async {
    final cycles = await getCompletedCycles(userId);
    if (cycles.isEmpty) return null;

    final totalDays = cycles
        .map((c) => c['durationDays'] as int)
        .reduce((a, b) => a + b);

    return (totalDays / cycles.length).round();
  }

  /// Predict next period start date
  Future<DateTime?> predictNextPeriod(int userId) async {
    final avgCycleLength = await getAverageCycleLength(userId);
    if (avgCycleLength == null) return null;

    // Get last period start
    final starts =
        await (_db.select(_db.periodEntries)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.entryType.equals(PeriodEntryTypes.start),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .get();

    if (starts.isEmpty) return null;

    return starts.first.date.add(Duration(days: avgCycleLength));
  }

  /// Get dates where user had their period (for calendar highlighting)
  Future<Set<DateTime>> getPeriodDates(int userId, {int days = 90}) async {
    final entries = await getPeriodHistory(userId, days: days);
    final dates = <DateTime>{};

    DateTime? currentStart;
    // Process in chronological order
    final sorted = entries.reversed.toList();

    for (final entry in sorted) {
      if (entry.entryType == PeriodEntryTypes.start) {
        currentStart = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        dates.add(currentStart);
      } else if (entry.entryType == PeriodEntryTypes.end &&
          currentStart != null) {
        final endDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        // Fill in all days between start and end
        var d = currentStart.add(const Duration(days: 1));
        while (!d.isAfter(endDate)) {
          dates.add(d);
          d = d.add(const Duration(days: 1));
        }
        currentStart = null;
      }
    }

    // If there's an active period, fill from start to today
    if (currentStart != null) {
      final today = DateTime.now();
      var d = currentStart.add(const Duration(days: 1));
      final endDate = DateTime(today.year, today.month, today.day);
      while (!d.isAfter(endDate)) {
        dates.add(d);
        d = d.add(const Duration(days: 1));
      }
    }

    return dates;
  }
}
