import 'package:drift/drift.dart' show Value;
import 'package:lekec/database/tables/medications.dart';
import '../../database/drift_database.dart';

class MockDataService {
  final AppDatabase db;
  MockDataService(this.db);

  Future<void> insertMock() async {
    final userId = await db.into(db.users).insert(
      UsersCompanion.insert(
        name: "John",
      ),
    );

    final med1 = await db.into(db.medications).insert(
      MedicationsCompanion.insert(
        medType: MedicationType.pills,
        name: "Nalgesin S",

        notes: Value("Če je potrebno."),
      ),
    );

    final plan1 = await db.into(db.medicationPlans).insert(
      MedicationPlansCompanion.insert(
        userId: userId,
        medicationId: med1,
        dosageAmount: 500.00,
        startDate: DateTime.now(),
      ),
    );

    await db.into(db.medicationScheduleRules).insert(
      MedicationScheduleRulesCompanion.insert(
        planId: plan1,
        ruleType: "daily",
      ),
    );

    await db.into(db.medicationScheduleRules).insert(
      MedicationScheduleRulesCompanion.insert(
        planId: plan1,
        ruleType: "weekly",
        isActive: Value(false),
      ),
    );
  }
}
