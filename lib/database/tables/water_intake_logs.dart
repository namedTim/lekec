import 'package:drift/drift.dart';
import 'users.dart';

/// One row per logged water intake. Daily totals are computed by summing
/// `amountMl` for a given `userId` over a date window — there's no
/// pre-aggregated "today" row, so an intake can be edited or deleted later
/// without rebalancing anything.
class WaterIntakeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();

  /// Amount of water logged, in millilitres.
  IntColumn get amountMl => integer()();

  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
}
