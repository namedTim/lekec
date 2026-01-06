import 'package:drift/drift.dart' as drift;
import 'package:lekec/database/drift_database.dart';

class IntakeLogService {
  final AppDatabase db;

  IntakeLogService(this.db);

  /// Get the next medication that needs to be taken
  /// Returns medication info, time until next dose, and if it's overdue
  Future<Map<String, dynamic>?> getNextMedication() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all intakes for today that haven't been taken yet
    final upcomingIntakes = await (db.select(db.medicationIntakeLogs)
          ..where((t) => t.scheduledTime.isBiggerOrEqualValue(startOfDay))
          ..where((t) => t.scheduledTime.isSmallerThanValue(endOfDay))
          ..where((t) => t.wasTaken.equals(false))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.scheduledTime)]))
        .get();

    if (upcomingIntakes.isEmpty) return null;

    // Find the next or current overdue medication
    MedicationIntakeLog? nextIntake;
    
    // First check for overdue medications (within 3 minutes grace period)
    for (final intake in upcomingIntakes) {
      final scheduledTime = intake.scheduledTime;
      final timeDiff = now.difference(scheduledTime);
      
      // If it's overdue (past scheduled time) but within 3 minutes, prioritize it
      if (timeDiff.inSeconds >= 0 && timeDiff.inMinutes < 3) {
        nextIntake = intake;
        break;
      }
    }
    
    // If no overdue medication, get the next upcoming one
    nextIntake ??= upcomingIntakes.first;

    // Load medication details
    Medication? medication;
    MedicationPlan? plan;

    if (nextIntake.planId == 0) {
      medication = await (db.select(db.medications)
            ..where((t) => t.id.equals(nextIntake!.medicationId)))
          .getSingleOrNull();
    } else {
      plan = await (db.select(db.medicationPlans)
            ..where((t) => t.id.equals(nextIntake!.planId)))
          .getSingleOrNull();

      if (plan != null) {
        medication = await (db.select(db.medications)
              ..where((t) => t.id.equals(plan!.medicationId)))
            .getSingleOrNull();
      }
    }

    if (medication == null) return null;

    final scheduledTime = nextIntake.scheduledTime;
    final timeDiff = now.difference(scheduledTime);
    final isOverdue = timeDiff.inSeconds >= 0;
    final timeUntil = isOverdue ? Duration.zero : scheduledTime.difference(now);

    return {
      'medication': medication,
      'plan': plan,
      'intake': nextIntake,
      'scheduledTime': scheduledTime,
      'timeUntil': timeUntil,
      'isOverdue': isOverdue,
      'overdueMinutes': isOverdue ? timeDiff.inMinutes : 0,
    };
  }

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
