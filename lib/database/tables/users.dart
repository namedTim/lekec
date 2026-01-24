import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()(); // UUID
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
