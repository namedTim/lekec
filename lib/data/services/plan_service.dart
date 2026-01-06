import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';

class PlanService {
  final AppDatabase db;
  PlanService(this.db);

  Future<List<MedicationPlan>> getPlans() {
    return db.select(db.medicationPlans).get();
  }

  Future<int> addPlan(MedicationPlansCompanion data) {
    return db.into(db.medicationPlans).insert(data);
  }

  /// Create a complete medication plan with schedule rules
  Future<int> createMedicationPlan({
    required int userId,
    required int medicationId,
    required DateTime startDate,
    required double dosageAmount,
    required double? initialQuantity,
    required String ruleType,
    required List<String> times,
  }) async {
    // Update medication with initial quantity if provided
    if (initialQuantity != null) {
      await (db.update(db.medications)
            ..where((t) => t.id.equals(medicationId)))
          .write(
        MedicationsCompanion(dosagesRemaining: drift.Value(initialQuantity)),
      );
    }

    // Create medication plan
    final planId = await db.into(db.medicationPlans).insert(
          MedicationPlansCompanion.insert(
            userId: userId,
            medicationId: medicationId,
            startDate: startDate,
            dosageAmount: dosageAmount,
            isActive: const drift.Value(true),
          ),
        );

    // Create schedule rule (if not "as needed")
    if (ruleType != 'asNeeded' && times.isNotEmpty) {
      await db.into(db.medicationScheduleRules).insert(
            MedicationScheduleRulesCompanion.insert(
              planId: planId,
              ruleType: ruleType,
              timesOfDay: drift.Value(jsonEncode(times)),
              isActive: const drift.Value(true),
            ),
          );
    }

    return planId;
  }
}
