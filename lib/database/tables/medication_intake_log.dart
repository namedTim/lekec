import 'package:drift/drift.dart';
import 'package:lekec/database/tables/medication_plans.dart';
import 'package:lekec/database/tables/medications.dart';
import 'package:lekec/database/tables/users.dart';

class MedicationIntakeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get planId => integer().references(MedicationPlans, #id)();
  IntColumn get medicationId => integer().references(Medications, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get scheduledTime => dateTime()();
  DateTimeColumn get takenTime => dateTime().nullable()(); // Set when user takes ANY action (taken or not taken)

  BoolColumn get wasTaken => boolean().withDefault(const Constant(false))();
}