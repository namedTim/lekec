import 'package:drift/drift.dart';

enum MedicationType {
  pills,
  ampules,
  applications,
  capsules,
  drops,
  grams,
  injections,
  milligrams,
  milliliters,
  patches,
  pieces,
  portions,
  puffs,
  sprays,
  tablespoons,
  units,
  micrograms,
}

enum MedicationStatus {
  active,
  deleted,
}

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get dosagesRemaining => real().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get nationalCode => integer().nullable()();
  IntColumn get medType => intEnum<MedicationType>()();
  IntColumn get status => intEnum<MedicationStatus>().withDefault(const Constant(0))();
  TextColumn get intakeAdvice => text().nullable()();
}
