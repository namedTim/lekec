import 'package:drift/drift.dart' as drift;
import 'package:lekec/database/drift_database.dart';

class IntakeLogService {
  final AppDatabase db;

  IntakeLogService(this.db);

  /// Load all intakes for today grouped by time
  Future<Map<String, List<Map<String, dynamic>>>> loadTodaysIntakes() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final intakes = await (db.select(db.medicationIntakeLogs)
          ..where((t) => t.scheduledTime.isBiggerOrEqualValue(startOfDay))
          ..where((t) => t.scheduledTime.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.scheduledTime)]))
        .get();

    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final intake in intakes) {
      MedicationPlan? plan;
      Medication? medication;

      if (intake.planId == 0) {
        // One-time entry - load medication directly
        medication = await (db.select(db.medications)
              ..where((t) => t.id.equals(intake.medicationId)))
            .getSingleOrNull();
      } else {
        // Regular planned intake
        plan = await (db.select(db.medicationPlans)
              ..where((t) => t.id.equals(intake.planId)))
            .getSingleOrNull();

        if (plan != null) {
          medication = await (db.select(db.medications)
                ..where((t) => t.id.equals(plan!.medicationId)))
              .getSingleOrNull();
        }
      }

      if (medication == null) continue;

      final timeKey =
          '${intake.scheduledTime.hour.toString().padLeft(2, '0')}:${intake.scheduledTime.minute.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(timeKey, () => []);
      grouped[timeKey]!.add({
        'intake': intake,
        'plan': plan,
        'medication': medication,
        'isOneTimeEntry': intake.planId == 0,
      });
    }

    return grouped;
  }

  /// Delete a one-time entry
  Future<void> deleteOneTimeEntry(int intakeId) async {
    await (db.delete(db.medicationIntakeLogs)
          ..where((t) => t.id.equals(intakeId)))
        .go();
  }

  /// Update intake status and medication count
  Future<void> updateIntakeStatus(
    int intakeId,
    bool wasTaken,
  ) async {
    // Get the intake log to find the plan and medication
    final intake = await (db.select(db.medicationIntakeLogs)
          ..where((t) => t.id.equals(intakeId)))
        .getSingleOrNull();

    if (intake == null) return;

    final plan = await (db.select(db.medicationPlans)
          ..where((t) => t.id.equals(intake.planId)))
        .getSingleOrNull();

    if (plan == null) return;

    final medication = await (db.select(db.medications)
          ..where((t) => t.id.equals(plan.medicationId)))
        .getSingleOrNull();

    // Update the intake log
    await (db.update(db.medicationIntakeLogs)
          ..where((t) => t.id.equals(intakeId)))
        .write(
      MedicationIntakeLogsCompanion(
        wasTaken: drift.Value(wasTaken),
        takenTime: drift.Value(wasTaken ? DateTime.now() : null),
      ),
    );

    // Only update medication count if status actually changed
    // If marking as taken AND it wasn't already taken, decrease the medication count
    if (wasTaken &&
        !intake.wasTaken &&
        medication != null &&
        medication.dosagesRemaining != null) {
      final newRemaining = medication.dosagesRemaining! - plan.dosageAmount;
      await (db.update(db.medications)
            ..where((t) => t.id.equals(medication.id)))
          .write(
        MedicationsCompanion(dosagesRemaining: drift.Value(newRemaining)),
      );
    }

    // If marking as not taken (was previously taken), increase the count back
    if (!wasTaken &&
        intake.wasTaken &&
        medication != null &&
        medication.dosagesRemaining != null) {
      final newRemaining = medication.dosagesRemaining! + plan.dosageAmount;
      await (db.update(db.medications)
            ..where((t) => t.id.equals(medication.id)))
          .write(
        MedicationsCompanion(dosagesRemaining: drift.Value(newRemaining)),
      );
    }
  }

  /// Create a one-time intake log entry
  Future<void> createOneTimeEntry({
    required int medicationId,
    required int userId,
  }) async {
    await db.into(db.medicationIntakeLogs).insert(
          MedicationIntakeLogsCompanion(
            userId: drift.Value(userId),
            medicationId: drift.Value(medicationId),
            planId: const drift.Value(0), // No plan for one-time entries
            scheduledTime: drift.Value(DateTime.now()),
            wasTaken: const drift.Value(true),
            takenTime: drift.Value(DateTime.now()),
          ),
        );
  }
}
