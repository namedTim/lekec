import '../../database/drift_database.dart';

class MedicationService {
  final AppDatabase db;
  MedicationService(this.db);

  Future<List<Medication>> getAll() => db.select(db.medications).get();

  Future<int> createMedication(MedicationsCompanion data) {
    return db.into(db.medications).insert(data);
  }
}
