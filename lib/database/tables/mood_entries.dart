import 'package:drift/drift.dart';
import 'users.dart';

class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();

  /// Mood level from 1 (very bad) to 5 (great)
  IntColumn get moodLevel => integer()();

  /// Optional note about the mood
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
