import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import 'package:alarm/alarm.dart';
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import 'notification_service.dart';

class MedicationService {
  final AppDatabase db;
  MedicationService(this.db);

  Future<List<Medication>> getAll() => db.select(db.medications).get();

  Future<int> createMedication(MedicationsCompanion data) {
    return db.into(db.medications).insert(data);
  }

  /// Find or create a medication by name and type
  Future<int> findOrCreateMedication(
    String name,
    MedicationType medType,
  ) async {
    final existingMeds =
        await (db.select(db.medications)
              ..where((m) => m.name.equals(name))
              ..where((m) => m.medType.equalsValue(medType))
              ..where((m) => m.status.equalsValue(MedicationStatus.active)))
            .get();

    if (existingMeds.isNotEmpty) {
      return existingMeds.first.id;
    }

    return await db
        .into(db.medications)
        .insert(
          MedicationsCompanion(
            name: drift.Value(name),
            medType: drift.Value(medType),
          ),
        );
  }

  /// Soft delete a medication by ID (mark as deleted)
  /// Also deletes future intake logs and cancels all alarms/notifications
  Future<void> deleteMedication(int medicationId) async {
    final now = DateTime.now();

    // Get ALL intake logs for this medication (not just future ones)
    // to ensure we cancel any currently-ringing or recently-scheduled alarms
    final allIntakes =
        await (db.select(db.medicationIntakeLogs)
              ..where((log) => log.medicationId.equals(medicationId)))
            .get();

    // Cancel all alarms and notifications for ALL intakes of this medication
    final notificationService = NotificationService();
    for (final intake in allIntakes) {
      // Cancel alarm (for critical reminders) - safe to call even if not set
      await Alarm.stop(intake.id);

      // Cancel notification (for regular reminders)
      await notificationService.cancelNotification(intake.id);
    }

    // Also stop any alarms that the Alarm package still has registered
    // in case IDs got out of sync
    final activeAlarms = await Alarm.getAlarms();
    for (final alarm in activeAlarms) {
      // Check if this alarm belongs to an intake of this medication
      if (allIntakes.any((intake) => intake.id == alarm.id)) {
        await Alarm.stop(alarm.id);
      }
    }

    // Mark medication as deleted
    await (db.update(
      db.medications,
    )..where((m) => m.id.equals(medicationId))).write(
      MedicationsCompanion(status: drift.Value(MedicationStatus.deleted)),
    );

    // Deactivate all plans for this medication so they are not regenerated
    await (db.update(db.medicationPlans)
          ..where((p) => p.medicationId.equals(medicationId)))
        .write(const MedicationPlansCompanion(isActive: drift.Value(false)));

    // Deactivate all schedule rules for this medication's plans
    final plans = await (db.select(
      db.medicationPlans,
    )..where((p) => p.medicationId.equals(medicationId))).get();
    for (final plan in plans) {
      await (db.update(
        db.medicationScheduleRules,
      )..where((r) => r.planId.equals(plan.id))).write(
        const MedicationScheduleRulesCompanion(isActive: drift.Value(false)),
      );
    }

    // Delete all future intake logs (keep historical data)
    await (db.delete(db.medicationIntakeLogs)
          ..where((log) => log.medicationId.equals(medicationId))
          ..where((log) => log.scheduledTime.isBiggerOrEqualValue(now)))
        .go();
  }

  /// Load all medications with their plan details and schedule info
  Future<List<Map<String, dynamic>>> loadMedicationsWithDetails() async {
    final query =
        await (db.select(
          db.medications,
        )..where((m) => m.status.equalsValue(MedicationStatus.active))).join([
          drift.innerJoin(
            db.medicationPlans,
            db.medicationPlans.medicationId.equalsExp(db.medications.id) &
                db.medicationPlans.isActive.equals(true),
          ),
          drift.leftOuterJoin(
            db.medicationScheduleRules,
            db.medicationScheduleRules.planId.equalsExp(db.medicationPlans.id),
          ),
        ]).get();

    final result = <Map<String, dynamic>>[];
    for (final row in query) {
      final medication = row.readTable(db.medications);
      final plan = row.readTableOrNull(db.medicationPlans);
      final rule = row.readTableOrNull(db.medicationScheduleRules);

      String frequency = 'Po potrebi';
      List<String> times = [];

      if (rule != null) {
        // Parse times if available
        if (rule.timesOfDay != null) {
          final timesList = (jsonDecode(rule.timesOfDay!) as List)
              .map((e) => e.toString())
              .toList();
          times = timesList;
        }

        // Format frequency based on rule type
        switch (rule.ruleType) {
          case 'daily':
            frequency = '${times.length}x dnevno';
            break;
          case 'hourInterval':
            final hours = rule.intervalHours ?? 0;
            // Find the next scheduled time for this plan
            if (plan != null) {
              final now = DateTime.now();

              final nextIntake =
                  await (db.select(db.medicationIntakeLogs)
                        ..where((t) => t.planId.equals(plan.id))
                        ..where(
                          (t) => t.scheduledTime.isBiggerOrEqualValue(now),
                        )
                        ..orderBy([
                          (t) => drift.OrderingTerm.asc(t.scheduledTime),
                        ])
                        ..limit(1))
                      .getSingleOrNull();

              if (nextIntake != null) {
                final time = nextIntake.scheduledTime;
                times = [
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                ];
              }
            }

            // Fallback to the start time from rule if no intakes scheduled yet
            if (times.isEmpty && rule.timesOfDay != null) {
              final timesList = (jsonDecode(rule.timesOfDay!) as List)
                  .map((e) => e.toString())
                  .toList();
              times = timesList;
            }

            frequency =
                'Vsakih $hours ${hours == 1
                    ? 'uro'
                    : hours < 5
                    ? 'ure'
                    : 'ur'}';
            break;
          case 'dayInterval':
            final days = rule.intervalDays ?? 0;
            // Find the next scheduled time for this plan
            if (plan != null) {
              final now = DateTime.now();

              final nextIntake =
                  await (db.select(db.medicationIntakeLogs)
                        ..where((t) => t.planId.equals(plan.id))
                        ..where(
                          (t) => t.scheduledTime.isBiggerOrEqualValue(now),
                        )
                        ..orderBy([
                          (t) => drift.OrderingTerm.asc(t.scheduledTime),
                        ])
                        ..limit(1))
                      .getSingleOrNull();

              if (nextIntake != null) {
                final time = nextIntake.scheduledTime;
                times = [
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                ];
              }
            }

            // Fallback to the start time from rule if no intakes scheduled yet
            if (times.isEmpty && rule.timesOfDay != null) {
              final timesList = (jsonDecode(rule.timesOfDay!) as List)
                  .map((e) => e.toString())
                  .toList();
              times = timesList;
            }

            frequency =
                'Vsakih $days ${days == 1
                    ? 'dan'
                    : days == 2
                    ? 'dneva'
                    : days < 5
                    ? 'dni'
                    : 'dni'}';
            break;
          case 'weekly':
            if (rule.daysOfWeek != null) {
              final daysOfWeek = (jsonDecode(rule.daysOfWeek!) as List<dynamic>)
                  .cast<int>()
                  .toList()
                ..sort();
              final dayNames = [
                'Pon',
                'Tor',
                'Sre',
                'Čet',
                'Pet',
                'Sob',
                'Ned',
              ];
              final selectedDays = daysOfWeek
                  .map((d) => dayNames[d - 1])
                  .join(', ');
              frequency = 'V $selectedDays';
            }
            break;
          case 'cyclic':
            final daysOn = rule.cycleDaysOn ?? 0;
            final daysOff = rule.cycleDaysOff ?? 0;
            frequency = 'Ciklično ($daysOn dni / $daysOff dni pavze)';
            break;
          case 'asNeeded':
            frequency = 'Po potrebi';
            break;
          default:
            frequency = '${times.length}x dnevno';
        }
      }

      // "HH:MM" sorts lexicographically — same order as chronologically.
      // Guarantees the detail screen + the medication card display times
      // in order regardless of the order the user originally entered them.
      times.sort();

      result.add({
        'id': medication.id,
        'name': medication.name,
        'dosage': plan != null ? plan.dosageAmount : 1.0,
        'remaining': medication.dosagesRemaining?.toInt() ?? 0,
        'frequency': frequency,
        'times': times,
        'medType': medication.medType,
        'intakeAdvice': medication.intakeAdvice,
        'criticalReminder': medication.criticalReminder,
        'plan': plan,
      });
    }

    return result;
  }
}
