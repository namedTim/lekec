import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/medication_intake_log.dart';
import 'tables/medication_plans.dart';
import 'tables/medication_schedule_rule.dart';
import 'tables/medications.dart';
import 'tables/users.dart';
import 'tables/app_settings.dart';
import 'tables/onboarding_settings.dart';
import 'tables/mood_entries.dart';
import 'tables/period_entries.dart';
import 'tables/appointments.dart';

part 'drift_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Medications,
    MedicationPlans,
    MedicationScheduleRules,
    MedicationIntakeLogs,
    AppSettings,
    OnboardingSettings,
    MoodEntries,
    PeriodEntries,
    Appointments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add status column to medications table with default value of 0 (active)
          await m.addColumn(medications, medications.status);
        }
        if (from < 3) {
          // Add intakeAdvice column to medications table
          await m.addColumn(medications, medications.intakeAdvice);
        }
        if (from < 4) {
          // Add criticalReminder column to medications table
          await m.addColumn(medications, medications.criticalReminder);
        }
        if (from < 5) {
          // Add alarm settings columns to app_settings table
          await m.addColumn(appSettings, appSettings.alarmVolume);
          await m.addColumn(appSettings, appSettings.alarmSound);
          await m.addColumn(appSettings, appSettings.alarmVibration);
          await m.addColumn(appSettings, appSettings.showKillWarning);
        }
        if (from < 6) {
          // Add onboarding settings table
          await m.createTable(onboardingSettings);
        }
        if (from < 7) {
          // Add isActive column to users table
          await m.addColumn(users, users.isActive);
        }
        if (from < 8) {
          // Add dosageAmount column to medication_intake_logs table
          await m.addColumn(medicationIntakeLogs, medicationIntakeLogs.dosageAmount);
        }
        if (from < 9) {
          // Add age column to users table
          await m.addColumn(users, users.age);
        }
        if (from < 10) {
          // Add mood and period tracking tables
          await m.createTable(moodEntries);
          await m.createTable(periodEntries);
        }
        if (from < 11) {
          // Add gender column to users table
          await m.addColumn(users, users.gender);
        }
        if (from < 12) {
          // Add appointments table
          await m.createTable(appointments);
        }
        if (from < 13) {
          // Add appointment reminder settings columns to app_settings table
          await m.addColumn(appSettings, appSettings.appointmentVolume);
          await m.addColumn(appSettings, appSettings.appointmentSound);
          await m.addColumn(appSettings, appSettings.appointmentVibration);
        }
        if (from < 14) {
          // Add criticalReminder column to appointments table
          await m.addColumn(appointments, appointments.criticalReminder);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app_database.sqlite'));

    // Use regular NativeDatabase instead of createInBackground
    // to avoid isolate-related issues
    return NativeDatabase(file, logStatements: false);
  });
}
