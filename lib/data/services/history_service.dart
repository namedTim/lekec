import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';

class HistoryService {
  final AppDatabase db;

  HistoryService(this.db);

  /// Subquery selecting the ids of all currently active (non-deactivated)
  /// users. Used via `isInQuery` to scope the history loaders, so a user
  /// removed via `_deactivateUser` no longer contributes intakes / moods /
  /// appointments to the history view.
  drift.JoinedSelectStatement<dynamic, dynamic> _activeUserIdsQuery() {
    return db.selectOnly(db.users)
      ..addColumns([db.users.id])
      ..where(db.users.isActive.equals(true));
  }

  /// Load medication history with pagination and optional user filter
  Future<List<Map<String, dynamic>>> loadHistory({
    required int limit,
    required int offset,
    bool? onlyTaken,
    bool? onlyMissed,
    int? userId,
  }) async {
    final now = DateTime.now();

    // Build query with joins
    var query = db.select(db.medicationIntakeLogs).join([
      drift.innerJoin(
        db.medications,
        db.medications.id.equalsExp(db.medicationIntakeLogs.medicationId),
      ),
      drift.leftOuterJoin(
        db.medicationPlans,
        db.medicationPlans.id.equalsExp(db.medicationIntakeLogs.planId),
      ),
    ]);

    // Only show past and current medications (not future)
    query = query
      ..where(db.medicationIntakeLogs.scheduledTime.isSmallerOrEqualValue(now));

    // Apply user filter
    if (userId != null) {
      query = query..where(db.medicationIntakeLogs.userId.equals(userId));
    } else {
      // Hide intakes belonging to deactivated users.
      query = query..where(
        db.medicationIntakeLogs.userId.isInQuery(_activeUserIdsQuery()),
      );
    }

    // Apply filter
    if (onlyTaken == true) {
      query = query..where(db.medicationIntakeLogs.wasTaken.equals(true));
    } else if (onlyMissed == true) {
      query = query..where(db.medicationIntakeLogs.wasTaken.equals(false));
    }

    // Order by scheduled time descending (newest first)
    query = query
      ..orderBy([
        drift.OrderingTerm.desc(db.medicationIntakeLogs.scheduledTime),
      ]);

    // Apply pagination
    query = query..limit(limit, offset: offset);

    final results = await query.get();

    return results.map((row) {
      final intake = row.readTable(db.medicationIntakeLogs);
      final medication = row.readTable(db.medications);
      final plan = row.readTableOrNull(db.medicationPlans);

      return {
        'type': 'medication',
        'intake': intake,
        'medication': medication,
        'plan': plan,
        'date': DateTime(
          intake.scheduledTime.year,
          intake.scheduledTime.month,
          intake.scheduledTime.day,
        ),
        'sortTime': intake.scheduledTime,
      };
    }).toList();
  }

  /// Load mood history with pagination and optional user filter
  Future<List<Map<String, dynamic>>> loadMoodHistory({
    required int limit,
    required int offset,
    int? userId,
  }) async {
    final now = DateTime.now();

    var query = db.select(db.moodEntries)
      ..where((t) => t.createdAt.isSmallerOrEqualValue(now))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);

    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    } else {
      query = query
        ..where((t) => t.userId.isInQuery(_activeUserIdsQuery()));
    }

    final results = await query.get();

    return results.map((entry) {
      return {
        'type': 'mood',
        'mood': entry,
        'date': DateTime(
          entry.createdAt.year,
          entry.createdAt.month,
          entry.createdAt.day,
        ),
        'sortTime': entry.createdAt,
      };
    }).toList();
  }

  /// Load appointment history with pagination and optional user filter
  Future<List<Map<String, dynamic>>> loadAppointmentHistory({
    required int limit,
    required int offset,
    int? userId,
  }) async {
    final now = DateTime.now();

    var query = db.select(db.appointments)
      ..where((t) => t.appointmentTime.isSmallerOrEqualValue(now))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.appointmentTime)])
      ..limit(limit, offset: offset);

    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    } else {
      query = query
        ..where((t) => t.userId.isInQuery(_activeUserIdsQuery()));
    }

    final results = await query.get();

    return results.map((appt) {
      return {
        'type': 'appointment',
        'appointment': appt,
        'date': DateTime(
          appt.appointmentTime.year,
          appt.appointmentTime.month,
          appt.appointmentTime.day,
        ),
        'sortTime': appt.appointmentTime,
      };
    }).toList();
  }

  /// Load water intake history with pagination and optional user filter.
  /// Same shape as the other loaders so it merges cleanly in the history
  /// screen's combined list.
  Future<List<Map<String, dynamic>>> loadWaterHistory({
    required int limit,
    required int offset,
    int? userId,
  }) async {
    final now = DateTime.now();

    var query = db.select(db.waterIntakeLogs)
      ..where((t) => t.loggedAt.isSmallerOrEqualValue(now))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.loggedAt)])
      ..limit(limit, offset: offset);

    if (userId != null) {
      query = query..where((t) => t.userId.equals(userId));
    } else {
      query = query
        ..where((t) => t.userId.isInQuery(_activeUserIdsQuery()));
    }

    final results = await query.get();
    return results.map((entry) {
      return {
        'type': 'water',
        'water': entry,
        'date': DateTime(
          entry.loggedAt.year,
          entry.loggedAt.month,
          entry.loggedAt.day,
        ),
        'sortTime': entry.loggedAt,
      };
    }).toList();
  }

  /// Get all active users
  Future<List<User>> getActiveUsers() async {
    return (db.select(db.users)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
        .get();
  }
}
