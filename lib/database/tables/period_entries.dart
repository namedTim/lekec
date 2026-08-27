import 'package:drift/drift.dart';
import 'users.dart';

/// Types of period entries
class PeriodEntryTypes {
  static const String start = 'start';
  static const String end = 'end';
  static const String note = 'note';
}

class PeriodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();

  /// Type of entry: 'start', 'end', 'note'
  TextColumn get entryType => text()();

  /// Flow intensity 1 (light) to 3 (heavy), nullable for end/note types
  IntColumn get flowIntensity => integer().nullable()();

  /// Optional note
  TextColumn get note => text().nullable()();

  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
