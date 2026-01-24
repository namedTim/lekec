import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';

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
    final upcomingIntakes =
        await (db.select(db.medicationIntakeLogs)
              ..where((t) => t.scheduledTime.isBiggerOrEqualValue(startOfDay))
              ..where((t) => t.scheduledTime.isSmallerThanValue(endOfDay))
              ..where((t) => t.wasTaken.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.scheduledTime)]))
            .get();

    if (upcomingIntakes.isEmpty) return null;

    // Find the next medication to take
    MedicationIntakeLog? nextIntake;

    // Check for medications within the "ready to take" window (up to 5 minutes past scheduled time)
    for (final intake in upcomingIntakes) {
      final scheduledTime = intake.scheduledTime;
      final timeDiff = now.difference(scheduledTime);

      // If it's within 5 minutes past scheduled time, show it as ready to take
      if (timeDiff.inSeconds >= 0 && timeDiff.inMinutes < 5) {
        nextIntake = intake;
        break;
      }

      // If it's more than 5 minutes past, skip to the next medication
      if (timeDiff.inMinutes >= 5) {
        continue;
      }

      // If it's future, this is the next one
      if (timeDiff.inSeconds < 0) {
        nextIntake = intake;
        break;
      }
    }

    // If no medication found (all overdue by more than 5 minutes), get the next upcoming one
    if (nextIntake == null) {
      for (final intake in upcomingIntakes) {
        if (now.isBefore(intake.scheduledTime)) {
          nextIntake = intake;
          break;
        }
      }
    }

    // If still no medication found, return null
    if (nextIntake == null) return null;

    // Load medication details
    Medication? medication;
    MedicationPlan? plan;

    plan = await (db.select(
      db.medicationPlans,
    )..where((t) => t.id.equals(nextIntake!.planId))).getSingleOrNull();

    if (plan != null) {
      medication = await (db.select(
        db.medications,
      )..where((t) => t.id.equals(plan!.medicationId))).getSingleOrNull();
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

    final intakes =
        await (db.select(db.medicationIntakeLogs)
              ..where((t) => t.scheduledTime.isBiggerOrEqualValue(startOfDay))
              ..where((t) => t.scheduledTime.isSmallerThanValue(endOfDay))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.scheduledTime)]))
            .get();

    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final intake in intakes) {
      // Load plan
      final plan = await (db.select(
        db.medicationPlans,
      )..where((t) => t.id.equals(intake.planId))).getSingleOrNull();

      if (plan == null) continue;

      // Load medication
      final medication = await (db.select(
        db.medications,
      )..where((t) => t.id.equals(plan.medicationId))).getSingleOrNull();

      if (medication == null) continue;

      // Check if it's a one-time entry
      final rule = await (db.select(
        db.medicationScheduleRules,
      )..where((t) => t.planId.equals(plan.id))).getSingleOrNull();

      final isOneTime = rule?.ruleType == 'oneTime';

      final timeKey =
          '${intake.scheduledTime.hour.toString().padLeft(2, '0')}:${intake.scheduledTime.minute.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(timeKey, () => []);
      grouped[timeKey]!.add({
        'intake': intake,
        'plan': plan,
        'medication': medication,
        'isOneTimeEntry': isOneTime,
      });
    }

    return grouped;
  }

  /// Delete a one-time entry
  Future<void> deleteOneTimeEntry(int intakeId) async {
    await (db.delete(
      db.medicationIntakeLogs,
    )..where((t) => t.id.equals(intakeId))).go();
  }

  /// Update intake status and medication count
  Future<void> updateIntakeStatus(int intakeId, bool wasTaken) async {
    // Get the intake log to find the plan and medication
    final intake = await (db.select(
      db.medicationIntakeLogs,
    )..where((t) => t.id.equals(intakeId))).getSingleOrNull();

    if (intake == null) return;

    final plan = await (db.select(
      db.medicationPlans,
    )..where((t) => t.id.equals(intake.planId))).getSingleOrNull();

    if (plan == null) return;

    final medication = await (db.select(
      db.medications,
    )..where((t) => t.id.equals(plan.medicationId))).getSingleOrNull();

    // Update the intake log
    await (db.update(
      db.medicationIntakeLogs,
    )..where((t) => t.id.equals(intakeId))).write(
      MedicationIntakeLogsCompanion(
        wasTaken: drift.Value(wasTaken),
        takenTime: drift.Value(
          DateTime.now(),
        ), // Set for both taken and not taken
      ),
    );

    // Only update medication count if status actually changed
    // If marking as taken AND it wasn't already taken, decrease the medication count
    if (wasTaken &&
        !intake.wasTaken &&
        medication != null &&
        medication.dosagesRemaining != null) {
      final newRemaining = medication.dosagesRemaining! - plan.dosageAmount;
      await (db.update(
        db.medications,
      )..where((t) => t.id.equals(medication.id))).write(
        MedicationsCompanion(dosagesRemaining: drift.Value(newRemaining)),
      );
    }

    // If marking as not taken (was previously taken), increase the count back
    if (!wasTaken &&
        intake.wasTaken &&
        medication != null &&
        medication.dosagesRemaining != null) {
      final newRemaining = medication.dosagesRemaining! + plan.dosageAmount;
      await (db.update(
        db.medications,
      )..where((t) => t.id.equals(medication.id))).write(
        MedicationsCompanion(dosagesRemaining: drift.Value(newRemaining)),
      );
    }
  }

  /// Create a one-time intake log entry
  Future<void> createOneTimeEntry({
    required int medicationId,
    required int userId,
    required double dosageAmount,
  }) async {
    // Create a plan for one-time entry to store dosage
    final planId = await db
        .into(db.medicationPlans)
        .insert(
          MedicationPlansCompanion.insert(
            userId: userId,
            medicationId: medicationId,
            startDate: DateTime.now(),
            dosageAmount: dosageAmount,
            isActive: const drift.Value(
              false,
            ), // Mark as inactive so it doesn't show in meds list
          ),
        );

    // Create schedule rule with 'oneTime' type
    await db
        .into(db.medicationScheduleRules)
        .insert(
          MedicationScheduleRulesCompanion.insert(
            planId: planId,
            ruleType: 'oneTime',
            isActive: const drift.Value(false),
          ),
        );

    // Create the intake log entry
    await db
        .into(db.medicationIntakeLogs)
        .insert(
          MedicationIntakeLogsCompanion(
            userId: drift.Value(userId),
            medicationId: drift.Value(medicationId),
            planId: drift.Value(planId),
            scheduledTime: drift.Value(DateTime.now()),
            wasTaken: const drift.Value(true),
            takenTime: drift.Value(DateTime.now()),
          ),
        );
  }
}
