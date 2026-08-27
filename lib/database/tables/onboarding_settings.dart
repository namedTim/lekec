import 'package:drift/drift.dart';

enum UserType {
  personal,    // Using app for themselves
  family,      // Using for family
  caregiver,   // Medical practitioner or helping elderly
}

class OnboardingSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get userType => intEnum<UserType>().nullable()();
  TextColumn get familyName => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
