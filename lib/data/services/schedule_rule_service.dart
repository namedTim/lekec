import '../../database/drift_database.dart';

class ScheduleRuleService {
  final AppDatabase db;
  ScheduleRuleService(this.db);

  Future<List<MedicationScheduleRule>> getRulesForPlan(int planId) {
    return (db.select(
      db.medicationScheduleRules,
    )..where((r) => r.planId.equals(planId))).get();
  }

  Future<int> createRule(MedicationScheduleRulesCompanion data) {
    return db.into(db.medicationScheduleRules).insert(data);
  }
}
