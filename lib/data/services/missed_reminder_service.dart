import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart' show MedicationStatus;

/// Represents a missed critical medication reminder
class MissedMedicationReminder {
  final MedicationIntakeLog intake;
  final Medication medication;
  final MedicationPlan plan;
  final Duration overdueBy;

  MissedMedicationReminder({
    required this.intake,
    required this.medication,
    required this.plan,
    required this.overdueBy,
  });
}

/// Represents a missed/upcoming appointment reminder
class MissedAppointmentReminder {
  final Appointment appointment;
  final bool isUpcoming; // true = within 2 hours, false = already passed

  MissedAppointmentReminder({
    required this.appointment,
    required this.isUpcoming,
  });
}

/// Service to detect missed critical reminders for medications and appointments.
///
/// A reminder is considered "missed" when:
/// - Medication: criticalReminder=true, scheduledTime is past (>10 min grace),
///   wasTaken=false, takenTime=null (user never acted on it)
/// - Appointment: within the next 2 hours or up to 1 hour past, and user may
///   have missed the ring screen
class MissedReminderService {
  final AppDatabase db;

  MissedReminderService(this.db);

  /// Check for missed critical medication reminders today.
  ///
  /// Returns intakes where:
  /// - The medication has criticalReminder = true
  /// - scheduledTime is today and is past (+ 10 min grace period)
  /// - wasTaken = false
  /// - takenTime is null (user hasn't explicitly dismissed it either)
  Future<List<MissedMedicationReminder>> getMissedMedicationReminders() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    // Grace period: don't nag about reminders within 10 minutes of scheduled time
    final cutoff = now.subtract(const Duration(minutes: 10));

    // Get today's untaken intakes where user hasn't acted at all
    final intakes = await (db.select(db.medicationIntakeLogs)
          ..where((t) => t.scheduledTime.isBiggerOrEqualValue(startOfDay))
          ..where((t) => t.scheduledTime.isSmallerOrEqualValue(cutoff))
          ..where((t) => t.wasTaken.equals(false))
          ..where((t) => t.takenTime.isNull())
          ..orderBy([(t) => drift.OrderingTerm.asc(t.scheduledTime)]))
        .get();

    final List<MissedMedicationReminder> missed = [];

    for (final intake in intakes) {
      // Load the medication to check criticalReminder flag
      final medication = await (db.select(db.medications)
            ..where((m) => m.id.equals(intake.medicationId)))
          .getSingleOrNull();

      if (medication == null ||
          medication.status == MedicationStatus.deleted ||
          !medication.criticalReminder) {
        continue;
      }

      // Load the plan
      final plan = await (db.select(db.medicationPlans)
            ..where((p) => p.id.equals(intake.planId)))
          .getSingleOrNull();

      if (plan == null) continue;

      final overdueBy = now.difference(intake.scheduledTime);

      missed.add(MissedMedicationReminder(
        intake: intake,
        medication: medication,
        plan: plan,
        overdueBy: overdueBy,
      ));
    }

    return missed;
  }

  /// Check for missed appointment reminders.
  ///
  /// Returns appointments where:
  /// - appointmentTime is within the next 2 hours OR up to 1 hour past
  /// - Gives the user a heads-up about appointments they might have missed
  Future<List<MissedAppointmentReminder>> getMissedAppointmentReminders() async {
    final now = DateTime.now();
    // Show appointments from 1 hour ago to 2 hours ahead
    final pastCutoff = now.subtract(const Duration(hours: 1));
    final futureCutoff = now.add(const Duration(hours: 2));

    final appointments = await (db.select(db.appointments)
          ..where(
              (t) => t.appointmentTime.isBiggerOrEqualValue(pastCutoff))
          ..where(
              (t) => t.appointmentTime.isSmallerOrEqualValue(futureCutoff))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.appointmentTime)]))
        .get();

    return appointments.map((appt) {
      final isUpcoming = appt.appointmentTime.isAfter(now);
      return MissedAppointmentReminder(
        appointment: appt,
        isUpcoming: isUpcoming,
      );
    }).toList();
  }

  /// Check if there are any missed reminders at all (quick boolean check).
  Future<bool> hasMissedReminders() async {
    final meds = await getMissedMedicationReminders();
    if (meds.isNotEmpty) return true;
    final appts = await getMissedAppointmentReminders();
    return appts.isNotEmpty;
  }

  /// Mark an intake as taken.
  Future<void> markIntakeAsTaken(int intakeId) async {
    await (db.update(db.medicationIntakeLogs)
          ..where((t) => t.id.equals(intakeId)))
        .write(
      MedicationIntakeLogsCompanion(
        wasTaken: const drift.Value(true),
        takenTime: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Mark an intake as explicitly dismissed (not taken).
  Future<void> dismissIntake(int intakeId) async {
    await (db.update(db.medicationIntakeLogs)
          ..where((t) => t.id.equals(intakeId)))
        .write(
      MedicationIntakeLogsCompanion(
        wasTaken: const drift.Value(false),
        takenTime: drift.Value(DateTime.now()),
      ),
    );
  }
}
