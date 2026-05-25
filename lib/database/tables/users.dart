import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()(); // UUID
  TextColumn get name => text()();
  IntColumn get age => integer().nullable()();

  /// Gender: 'male', 'female', or 'other'. Nullable for backwards compatibility.
  TextColumn get gender => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  // ── Water tracking ─────────────────────────────────────────────────────
  // Per-user settings for the Voda section. Kept on Users so each person in
  // a multi-user install can have their own goal and reminder cadence.

  /// Daily intake goal in millilitres. Default 2000 ml (8 × 250 ml glass).
  IntColumn get dailyWaterGoalMl =>
      integer().withDefault(const Constant(2000))();

  /// Whether recurring water reminders are scheduled for this user.
  BoolColumn get waterReminderEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Hour of the day (0–23) at which water reminders begin.
  IntColumn get waterReminderStartHour =>
      integer().withDefault(const Constant(8))();

  /// Hour of the day (0–23) after which no more water reminders fire.
  /// End is exclusive of the hour — i.e. 22 means the last possible
  /// reminder fires at 21:xx within the interval.
  IntColumn get waterReminderEndHour =>
      integer().withDefault(const Constant(22))();

  /// Minutes between water reminders within the active window.
  IntColumn get waterReminderIntervalMinutes =>
      integer().withDefault(const Constant(120))();
}
