import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:alarm/alarm.dart';
import '../../../../database/drift_database.dart';
//import '../../../../data/services/mock_data_service.dart';
import '../../../../data/services/notification_service.dart';
import '../../core/providers/database_provider.dart';

part 'dev_actions_provider.g.dart';

class DevActions {
  final AppDatabase db;

  DevActions(this.db);

  Future<void> clearDatabase() async {
    // Cancel all alarms and notifications BEFORE deleting DB records
    await Alarm.stopAll();
    await NotificationService().cancelAllNotifications();

    await db.delete(db.users).go();
    await db.delete(db.medications).go();
    await db.delete(db.medicationPlans).go();
    await db.delete(db.medicationScheduleRules).go();
    await db.delete(db.medicationIntakeLogs).go();
  }

  Future<void> insertMockData() async {
    //await MockDataService(db).insertMock();
  }
}

@riverpod
DevActions devActions(Ref ref) {
  return DevActions(ref.watch(databaseProvider));
}
