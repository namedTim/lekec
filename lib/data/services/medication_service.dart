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

      if (rule != null && rule.timesOfDay != null) {
        final timesList = (jsonDecode(rule.timesOfDay!) as List)
            .map((e) => e.toString())
            .toList();
        times = timesList;
        frequency = '${times.length}x dnevno';
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
