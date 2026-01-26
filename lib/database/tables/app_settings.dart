import 'package:drift/drift.dart';
import 'users.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 'system', 'light', 'dark'
  TextColumn get themeMode => text().withDefault(const Constant('system'))();

  IntColumn get defaultUserId => integer().nullable().references(Users, #id)();

  // Critical alarm settings
  RealColumn get alarmVolume => real().withDefault(const Constant(0.8))();
  TextColumn get alarmSound =>
      text().withDefault(const Constant('nokia.mp3'))();
  BoolColumn get alarmVibration =>
      boolean().withDefault(const Constant(true))();

  // Notification settings
  BoolColumn get showKillWarning =>
      boolean().withDefault(const Constant(true))();
}
