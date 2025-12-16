import 'package:drift/drift.dart';
import 'package:lekec/database/tables/users.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // 'system', 'light', 'dark'
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  
  IntColumn get defaultUserId => integer().nullable().references(Users, #id)();
}
