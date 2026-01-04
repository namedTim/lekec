import 'dart:convert';
import 'dart:developer' as developer;
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';

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
    
    developer.log('Generating intake schedule from $now to $horizon', name: 'IntakeScheduler');
    
    // Get all active plans
    final activePlans = await (db.select(db.medicationPlans)
      ..where((p) => p.isActive.equals(true)))
      .get();
    
    int totalGenerated = 0;
    
    for (final plan in activePlans) {
      final generated = await _generateForPlan(plan, now, horizon);
      totalGenerated += generated;
      developer.log('Plan ${plan.id}: generated $generated entries', name: 'IntakeScheduler');
    }
    
    developer.log('Total generated: $totalGenerated intake entries', name: 'IntakeScheduler');
    return totalGenerated;
  }

  /// Generate entries for a single plan
  Future<int> _generateForPlan(
    MedicationPlan plan,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    // Get schedule rules for this plan
    final rules = await (db.select(db.medicationScheduleRules)
      ..where((r) => r.planId.equals(plan.id))
      ..where((r) => r.isActive.equals(true)))
      .get();
    
    if (rules.isEmpty) {
      developer.log('Warning: Plan ${plan.id} has no active rules', name: 'IntakeScheduler');
      return 0;
    }

    // Check if entries already exist in this range to avoid duplicates
    final existingCount = await _countExistingEntries(
      plan.id,
      fromDate,
      toDate,
    );
    
    if (existingCount > 0) {
      developer.log('Plan ${plan.id}: $existingCount entries already exist, skipping', name: 'IntakeScheduler');
      return 0;
    }

    int count = 0;
    for (final rule in rules) {
      count += await _generateFromRule(plan, rule, fromDate, toDate);
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
        scheduledTimes.addAll(
          _generateDailySchedule(rule, startDate, endDate),
        );
        break;
      case 'weekly':
        scheduledTimes.addAll(
          _generateWeeklySchedule(rule, startDate, endDate),
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
        developer.log('Unknown rule type: ${rule.ruleType}', name: 'IntakeScheduler');
    }

    // Insert all scheduled times into the database
    for (final scheduledTime in scheduledTimes) {
      await db.into(db.medicationIntakeLogs).insert(
        MedicationIntakeLogsCompanion.insert(
          planId: plan.id,
          medicationId: plan.medicationId,
          userId: plan.userId,
          scheduledTime: scheduledTime,
        ),
      );
    }

    return scheduledTimes.length;
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
        
        if (scheduled.isAfter(start) && scheduled.isBefore(end)) {
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
          
          if (scheduled.isAfter(start) && scheduled.isBefore(end)) {
            times.add(scheduled);
          }
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
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
        
        if (scheduled.isAfter(start) && scheduled.isBefore(end)) {
          times.add(scheduled);
        }
      }
      currentDate = currentDate.add(Duration(days: rule.intervalDays!));
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
          
          if (scheduled.isAfter(start) && scheduled.isBefore(end)) {
            times.add(scheduled);
          }
        }
      }
      
      currentDate = currentDate.add(const Duration(days: 1));
      dayInCycle = (dayInCycle + 1) % cycleDuration;
    }
    
    return times;
  }

  /// Count existing entries to avoid duplicates
  Future<int> _countExistingEntries(
    int planId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final query = db.select(db.medicationIntakeLogs)
      ..where((log) => log.planId.equals(planId))
      ..where((log) => log.scheduledTime.isBiggerOrEqualValue(fromDate))
      ..where((log) => log.scheduledTime.isSmallerOrEqualValue(toDate));
    
    final results = await query.get();
    return results.length;
  }

  /// Regenerate schedule for a specific plan (call after plan update)
  Future<void> regeneratePlanSchedule(int planId) async {
    developer.log('Regenerating schedule for plan $planId', name: 'IntakeScheduler');
    
    // Delete future untaken entries for this plan
    await (db.delete(db.medicationIntakeLogs)
      ..where((log) => log.planId.equals(planId))
      ..where((log) => log.scheduledTime.isBiggerThanValue(DateTime.now()))
      ..where((log) => log.wasTaken.equals(false)))
      .go();
    
    // Regenerate
    final plan = await (db.select(db.medicationPlans)
      ..where((p) => p.id.equals(planId)))
      .getSingle();
    
    final now = DateTime.now();
    final horizon = now.add(Duration(days: generationHorizonDays));
    
    await _generateForPlan(plan, now, horizon);
  }
}
