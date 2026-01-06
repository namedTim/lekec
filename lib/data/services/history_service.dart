import 'package:drift/drift.dart' as drift;
import 'package:lekec/database/drift_database.dart';

class HistoryService {
  final AppDatabase db;

  HistoryService(this.db);

  /// Load medication history with pagination
  /// Returns a list of entries with medication, plan, and intake details
  Future<List<Map<String, dynamic>>> loadHistory({
    required int limit,
    required int offset,
    bool? onlyTaken,
    bool? onlyMissed,
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
    query = query..where(db.medicationIntakeLogs.scheduledTime.isSmallerOrEqualValue(now));

    // Apply filter
    if (onlyTaken == true) {
      query = query..where(db.medicationIntakeLogs.wasTaken.equals(true));
    } else if (onlyMissed == true) {
      query = query..where(db.medicationIntakeLogs.wasTaken.equals(false));
    }

    // Order by scheduled time descending (newest first)
    query = query..orderBy([
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
        'intake': intake,
        'medication': medication,
        'plan': plan,
        'date': DateTime(
          intake.scheduledTime.year,
          intake.scheduledTime.month,
          intake.scheduledTime.day,
        ),
      };
    }).toList();
  }
}
