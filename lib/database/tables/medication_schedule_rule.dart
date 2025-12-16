import 'package:drift/drift.dart';
import 'medication_plans.dart';

class MedicationScheduleRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().references(MedicationPlans, #id)();

  /// "daily", "hourInterval", "dayInterval", "weekly", "cyclic"
  TextColumn get ruleType => text()();

  // For time(s) of day: ["08:00", "20:00"]
  TextColumn get timesOfDay => text().nullable()();   // store JSON list

  // For weekly: [1,3,5]
  TextColumn get daysOfWeek => text().nullable()();   // JSON list

  // For intervals:
  IntColumn get intervalHours => integer().nullable()();
  IntColumn get intervalDays => integer().nullable()();

  // For cyclic schedules:
  IntColumn get cycleDaysOn => integer().nullable()();
  IntColumn get cycleDaysOff => integer().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();


}
