import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/medication_intake_log.dart';
import 'tables/medication_plans.dart';
import 'tables/medication_schedule_rule.dart';
import 'tables/medications.dart';
import 'tables/users.dart';
import 'tables/app_settings.dart';

part 'drift_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Medications,
    MedicationPlans,
    MedicationScheduleRules,
    MedicationIntakeLogs,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add status column to medications table with default value of 0 (active)
          await m.addColumn(medications, medications.status);
        }
        if (from < 3) {
          // Add intakeAdvice column to medications table
          await m.addColumn(medications, medications.intakeAdvice);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app_database.sqlite'));

    return NativeDatabase.createInBackground(file, logStatements: true);
  });
}
