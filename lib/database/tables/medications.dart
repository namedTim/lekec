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

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get defaultDosageMg => real().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get nationalCode => integer().nullable()();
  IntColumn get medType => intEnum<MedicationType>()();
}
