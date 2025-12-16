import 'package:drift/drift.dart';
import 'package:lekec/database/tables/users.dart';
import 'package:lekec/database/tables/medications.dart';

class MedicationPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get medicationId => integer().references(Medications, #id)();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  RealColumn get dosageAmount => real()();  // mg, ml, unit, etc.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

}
