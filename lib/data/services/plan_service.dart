import '../../database/drift_database.dart';

class PlanService {
  final AppDatabase db;
  PlanService(this.db);

  Future<List<MedicationPlan>> getPlans() {
    return db.select(db.medicationPlans).get();
  }

  Future<int> addPlan(MedicationPlansCompanion data) {
    return db.into(db.medicationPlans).insert(data);
  }
}
