import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:lekec/database/tables/medication_intake_log.dart';
import 'package:lekec/database/tables/medication_plans.dart';
import 'package:lekec/database/tables/medication_schedule_rule.dart';
import 'package:lekec/database/tables/medications.dart';
import 'package:lekec/database/tables/users.dart';

part 'drift_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Medications,
    MedicationPlans,
    MedicationScheduleRules,
    MedicationIntakeLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app_database.sqlite'));

    return NativeDatabase.createInBackground(
      file,
      logStatements: true,
    );
  });
}
