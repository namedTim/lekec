import 'package:drift/drift.dart';
import 'users.dart';

class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();

  /// Appointment title (e.g., "Pregled pri zdravniku")
  TextColumn get title => text()();

  /// Optional note with additional details
  TextColumn get note => text().nullable()();

  /// Date and time of the appointment
  DateTimeColumn get appointmentTime => dateTime()();

  /// When this record was created
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
