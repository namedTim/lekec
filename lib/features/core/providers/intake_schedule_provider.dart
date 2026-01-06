import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/services/intake_schedule_generator.dart';
import '../../../data/services/plan_service.dart';
import 'database_provider.dart';

part 'intake_schedule_provider.g.dart';

@riverpod
IntakeScheduleGenerator intakeScheduleGenerator(Ref ref) {
  final db = ref.watch(databaseProvider);
  return IntakeScheduleGenerator(db);
}

@riverpod
PlanService planService(Ref ref) {
  final db = ref.watch(databaseProvider);
  return PlanService(db);
}
