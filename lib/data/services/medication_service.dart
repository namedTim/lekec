import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';

class MedicationService {
  final AppDatabase db;
  MedicationService(this.db);

  Future<List<Medication>> getAll() => db.select(db.medications).get();

  Future<int> createMedication(MedicationsCompanion data) {
    return db.into(db.medications).insert(data);
  }

  /// Find or create a medication by name and type
  Future<int> findOrCreateMedication(String name, MedicationType medType) async {
    final existingMeds = await (db.select(db.medications)
          ..where((m) => m.name.equals(name))
          ..where((m) => m.medType.equalsValue(medType)))
        .get();

    if (existingMeds.isNotEmpty) {
      return existingMeds.first.id;
    }

    return await db.into(db.medications).insert(
          MedicationsCompanion(
            name: drift.Value(name),
            medType: drift.Value(medType),
          ),
        );
  }

  /// Delete a medication by ID
  Future<void> deleteMedication(int medicationId) async {
    await (db.delete(db.medications)..where((m) => m.id.equals(medicationId)))
        .go();
  }

  /// Load all medications with their plan details and schedule info
  Future<List<Map<String, dynamic>>> loadMedicationsWithDetails() async {
    final query = await db.select(db.medications).join([
      drift.leftOuterJoin(
        db.medicationPlans,
        db.medicationPlans.medicationId.equalsExp(db.medications.id),
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
            frequency = 'Vsakih $hours ${hours == 1 ? 'uro' : hours < 5 ? 'ure' : 'ur'}';
            // Load today's scheduled times for this plan
            if (plan != null) {
              final today = DateTime.now();
              final startOfDay = DateTime(today.year, today.month, today.day);
              final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
              
              final scheduledTimes = await (db.select(db.medicationIntakeLogs)
                    ..where((t) => t.planId.equals(plan.id))
                    ..where((t) => t.scheduledTime.isBiggerOrEqualValue(startOfDay))
                    ..where((t) => t.scheduledTime.isSmallerOrEqualValue(endOfDay))
                    ..orderBy([(t) => drift.OrderingTerm.asc(t.scheduledTime)]))
                  .get();
              
              times = scheduledTimes.map((log) {
                final time = log.scheduledTime;
                return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              }).toList();
            }
            break;
          case 'dayInterval':
            final days = rule.intervalDays ?? 0;
            frequency = 'Vsakih $days ${days == 1 ? 'dan' : days == 2 ? 'dneva' : days < 5 ? 'dni' : 'dni'}';
            break;
          case 'weekly':
            if (rule.daysOfWeek != null) {
              final daysOfWeek = (jsonDecode(rule.daysOfWeek!) as List<dynamic>).cast<int>();
              final dayNames = ['Pon', 'Tor', 'Sre', 'Čet', 'Pet', 'Sob', 'Ned'];
              final selectedDays = daysOfWeek.map((d) => dayNames[d - 1]).join(', ');
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

      result.add({
        'id': medication.id,
        'name': medication.name,
        'dosage': plan != null ? plan.dosageAmount : 1.0,
        'remaining': medication.dosagesRemaining?.toInt() ?? 0,
        'frequency': frequency,
        'times': times,
        'medType': medication.medType,
        'plan': plan,
      });
    }

    return result;
  }
}
