import 'dart:convert';
import 'dart:developer' as developer;
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart' show MedicationStatus;

/// Service to generate future medication intake entries
class IntakeScheduleGenerator {
  final AppDatabase db;

  /// How many days ahead to generate entries
  static const int generationHorizonDays = 30;

  IntakeScheduleGenerator(this.db);

  /// Generate intake entries for all active plans
  /// Returns number of entries created
  Future<int> generateScheduledIntakes({DateTime? fromDate}) async {
    final now = fromDate ?? DateTime.now();
    final horizon = now.add(Duration(days: generationHorizonDays));

    developer.log(
      'Generating intake schedule from $now to $horizon',
      name: 'IntakeScheduler',
    );

    // Get all active plans
    final activePlans = await (db.select(
      db.medicationPlans,
    )..where((p) => p.isActive.equals(true))).get();

    int totalGenerated = 0;

    for (final plan in activePlans) {
      // Skip plans belonging to deleted medications
      final medication = await (db.select(
        db.medications,
      )..where((m) => m.id.equals(plan.medicationId))).getSingleOrNull();
      if (medication == null || medication.status == MedicationStatus.deleted) {
        developer.log(
          'Plan ${plan.id}: skipping - medication ${plan.medicationId} is deleted or missing',
          name: 'IntakeScheduler',
        );
        continue;
      }

      final generated = await _generateForPlan(plan, now, horizon);
      totalGenerated += generated;
      developer.log(
        'Plan ${plan.id}: generated $generated entries',
        name: 'IntakeScheduler',
      );
    }

    developer.log(
      'Total generated: $totalGenerated intake entries',
      name: 'IntakeScheduler',
    );
    return totalGenerated;
  }

  /// Generate entries for a single plan
  Future<int> _generateForPlan(
    MedicationPlan plan,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    // Get schedule rules for this plan
    final rules =
        await (db.select(db.medicationScheduleRules)
              ..where((r) => r.planId.equals(plan.id))
              ..where((r) => r.isActive.equals(true)))
            .get();

    if (rules.isEmpty) {
      developer.log(
        'Warning: Plan ${plan.id} has no active rules',
        name: 'IntakeScheduler',
      );
      return 0;
    }

    // Instead of skipping the whole plan when entries exist,
    // find the last existing future entry and generate from there onward.
    // This ensures the schedule is always extended to the full horizon.
    var effectiveFrom = fromDate;

    final latestEntry = await (db.select(db.medicationIntakeLogs)
          ..where((log) => log.planId.equals(plan.id))
          ..where((log) => log.scheduledTime.isBiggerOrEqualValue(fromDate))
          ..orderBy([(log) => drift.OrderingTerm.desc(log.scheduledTime)])
          ..limit(1))
        .getSingleOrNull();

    if (latestEntry != null) {
      // Start generating from one minute after the last existing entry
      // so the per-entry duplicate check handles any overlap
      effectiveFrom = latestEntry.scheduledTime.add(const Duration(minutes: 1));

      if (!effectiveFrom.isBefore(toDate)) {
        developer.log(
          'Plan ${plan.id}: schedule already covers horizon (last entry: ${latestEntry.scheduledTime})',
          name: 'IntakeScheduler',
        );
        return 0;
      }

      developer.log(
        'Plan ${plan.id}: extending schedule from $effectiveFrom to $toDate',
        name: 'IntakeScheduler',
      );
    }

    int count = 0;
    for (final rule in rules) {
      count += await _generateFromRule(plan, rule, effectiveFrom, toDate);
    }

    return count;
  }

  /// Generate entries based on a specific rule
  Future<int> _generateFromRule(
    MedicationPlan plan,
    MedicationScheduleRule rule,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final scheduledTimes = <DateTime>[];

    // Use plan start date if it's after fromDate
    final startDate = plan.startDate.isAfter(fromDate)
        ? plan.startDate
        : fromDate;

    // Respect plan end date if set
    final endDate = plan.endDate != null && plan.endDate!.isBefore(toDate)
        ? plan.endDate!
        : toDate;

    switch (rule.ruleType) {
      case 'daily':
        scheduledTimes.addAll(_generateDailySchedule(rule, startDate, endDate));
        break;
      case 'weekly':
        scheduledTimes.addAll(
          _generateWeeklySchedule(rule, startDate, endDate),
        );
        break;
      case 'hourInterval':
        scheduledTimes.addAll(
          _generateHourIntervalSchedule(rule, startDate, endDate),
        );
        break;
      case 'dayInterval':
        scheduledTimes.addAll(
          _generateIntervalSchedule(rule, startDate, endDate),
        );
        break;
      case 'cyclic':
        scheduledTimes.addAll(
          _generateCyclicSchedule(rule, startDate, endDate),
        );
        break;
      case 'asNeeded':
        // No scheduled entries for "as needed" medications
        return 0;
      default:
        developer.log(
          'Unknown rule type: ${rule.ruleType}',
          name: 'IntakeScheduler',
        );
    }

    // Insert all scheduled times into the database, avoiding duplicates
    int insertedCount = 0;
    for (final scheduledTime in scheduledTimes) {
      // Check if entry already exists for this plan and scheduled time
      final existing =
          await (db.select(db.medicationIntakeLogs)
                ..where((log) => log.planId.equals(plan.id))
                ..where((log) => log.scheduledTime.equals(scheduledTime)))
              .getSingleOrNull();

      if (existing == null) {
        await db
            .into(db.medicationIntakeLogs)
            .insert(
              MedicationIntakeLogsCompanion.insert(
                planId: plan.id,
                medicationId: plan.medicationId,
                userId: plan.userId,
                scheduledTime: scheduledTime,
              ),
            );
        insertedCount++;
      }
    }

    return insertedCount;
  }

  /// Generate schedule for "daily" rule with specific times
  List<DateTime> _generateDailySchedule(
    MedicationScheduleRule rule,
    DateTime start,
    DateTime end,
  ) {
    final times = <DateTime>[];

    if (rule.timesOfDay == null) return times;

    final timesList = (jsonDecode(rule.timesOfDay!) as List<dynamic>)
        .cast<String>();

    var currentDate = DateTime(start.year, start.month, start.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      for (final timeStr in timesList) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final scheduled = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        );

        if ((scheduled.isAfter(start) || scheduled.isAtSameMomentAs(start)) &&
            scheduled.isBefore(end)) {
          times.add(scheduled);
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return times;
  }

  /// Generate schedule for "weekly" rule (specific days of week)
  List<DateTime> _generateWeeklySchedule(
    MedicationScheduleRule rule,
    DateTime start,
    DateTime end,
  ) {
    final times = <DateTime>[];

    if (rule.daysOfWeek == null || rule.timesOfDay == null) return times;

    final daysOfWeek = (jsonDecode(rule.daysOfWeek!) as List<dynamic>)
        .cast<int>();
    final timesList = (jsonDecode(rule.timesOfDay!) as List<dynamic>)
        .cast<String>();

    var currentDate = DateTime(start.year, start.month, start.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      // weekday: 1=Monday, 7=Sunday
      if (daysOfWeek.contains(currentDate.weekday)) {
        for (final timeStr in timesList) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          final scheduled = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          if ((scheduled.isAfter(start) || scheduled.isAtSameMomentAs(start)) &&
              scheduled.isBefore(end)) {
            times.add(scheduled);
          }
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return times;
  }

  /// Generate schedule for "hourInterval" rule (every N hours)
  List<DateTime> _generateHourIntervalSchedule(
    MedicationScheduleRule rule,
    DateTime start,
    DateTime end,
  ) {
    final times = <DateTime>[];

    if (rule.intervalHours == null || rule.timesOfDay == null) return times;

    final timesList = (jsonDecode(rule.timesOfDay!) as List<dynamic>)
        .cast<String>();

    if (timesList.isEmpty) return times;

    // Parse start time from first time in list
    final parts = timesList[0].split(':');
    final startHour = int.parse(parts[0]);
    final startMinute = int.parse(parts[1]);

    // Start from the first occurrence of this time at or after start date
    var current = DateTime(
      start.year,
      start.month,
      start.day,
      startHour,
      startMinute,
    );

    // If start time today is before the plan start, move to next occurrence
    while (current.isBefore(start)) {
      current = current.add(Duration(hours: rule.intervalHours!));
    }

    // Generate entries every N hours (continuously adding hours, wrapping days)
    while (current.isBefore(end)) {
      times.add(current);
      current = current.add(Duration(hours: rule.intervalHours!));
    }

    return times;
  }

  /// Generate schedule for "dayInterval" rule (every N days)
  List<DateTime> _generateIntervalSchedule(
    MedicationScheduleRule rule,
    DateTime start,
    DateTime end,
  ) {
    final times = <DateTime>[];

    if (rule.intervalDays == null || rule.timesOfDay == null) return times;

    final timesList = (jsonDecode(rule.timesOfDay!) as List<dynamic>)
        .cast<String>();

    if (timesList.isEmpty) return times;

    // Parse start time from first time in list
    final parts = timesList[0].split(':');
    final startHour = int.parse(parts[0]);
    final startMinute = int.parse(parts[1]);

    // Start from the first occurrence of this time at or after start date
    var current = DateTime(
      start.year,
      start.month,
      start.day,
      startHour,
      startMinute,
    );

    // If start time today is before the plan start, move to next occurrence
    while (current.isBefore(start)) {
      current = current.add(Duration(days: rule.intervalDays!));
    }

    // Generate entries every N days
    while (current.isBefore(end)) {
      times.add(current);
      current = current.add(Duration(days: rule.intervalDays!));
    }

    return times;
  }

  /// Generate schedule for "cyclic" rule (N days on, M days off)
  List<DateTime> _generateCyclicSchedule(
    MedicationScheduleRule rule,
    DateTime start,
    DateTime end,
  ) {
    final times = <DateTime>[];

    if (rule.cycleDaysOn == null ||
        rule.cycleDaysOff == null ||
        rule.timesOfDay == null) {
      return times;
    }

    final timesList = (jsonDecode(rule.timesOfDay!) as List<dynamic>)
        .cast<String>();

    var currentDate = DateTime(start.year, start.month, start.day);
    final cycleDuration = rule.cycleDaysOn! + rule.cycleDaysOff!;

    var dayInCycle = 0;

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      // Check if we're in the "on" phase of the cycle
      if (dayInCycle < rule.cycleDaysOn!) {
        for (final timeStr in timesList) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          final scheduled = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          if ((scheduled.isAfter(start) || scheduled.isAtSameMomentAs(start)) &&
              scheduled.isBefore(end)) {
            times.add(scheduled);
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
      dayInCycle = (dayInCycle + 1) % cycleDuration;
    }

    return times;
  }

  /// Regenerate schedule for a specific plan (call after plan update)
  Future<void> regeneratePlanSchedule(int planId) async {
    developer.log(
      'Regenerating schedule for plan $planId',
      name: 'IntakeScheduler',
    );

    // Delete future untaken entries for this plan
    await (db.delete(db.medicationIntakeLogs)
          ..where((log) => log.planId.equals(planId))
          ..where((log) => log.scheduledTime.isBiggerThanValue(DateTime.now()))
          ..where((log) => log.wasTaken.equals(false)))
        .go();

    // Regenerate
    final plan = await (db.select(
      db.medicationPlans,
    )..where((p) => p.id.equals(planId))).getSingle();

    final now = DateTime.now();
    final horizon = now.add(Duration(days: generationHorizonDays));

    await _generateForPlan(plan, now, horizon);
  }

  /// Remove duplicate intake log entries (keeps the first occurrence)
  /// Returns the number of duplicates removed
  Future<int> removeDuplicateEntries() async {
    developer.log(
      'Removing duplicate intake log entries',
      name: 'IntakeScheduler',
    );

    // Get all intake logs ordered by id (oldest first)
    final allLogs = await (db.select(
      db.medicationIntakeLogs,
    )..orderBy([(t) => drift.OrderingTerm.asc(t.id)])).get();

    // Track seen (planId, scheduledTime) combinations
    final seen = <String>{};
    final duplicateIds = <int>[];

    for (final log in allLogs) {
      final key = '${log.planId}_${log.scheduledTime.millisecondsSinceEpoch}';
      if (seen.contains(key)) {
        // This is a duplicate
        duplicateIds.add(log.id);
      } else {
        seen.add(key);
      }
    }

    // Delete duplicates
    for (final id in duplicateIds) {
      await (db.delete(
        db.medicationIntakeLogs,
      )..where((log) => log.id.equals(id))).go();
    }

    developer.log(
      'Removed ${duplicateIds.length} duplicate entries',
      name: 'IntakeScheduler',
    );

    return duplicateIds.length;
  }
}
