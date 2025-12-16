import 'package:drift/drift.dart';

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get defaultDosageMg => real().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get nationalCode => integer().nullable()();

}
