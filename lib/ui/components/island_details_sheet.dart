import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../database/drift_database.dart';
import '../../data/services/appointment_service.dart';
import '../../data/services/water_service.dart';

/// Expanded view of the dashboard time-island. Opened by tapping the island.
/// Shows, at a glance:
///   * Hidracija — today's water for the prime (first active) user vs. goal.
///   * Zdravila danes — today's taken/total per active user.
///   * Prihajajoči termini — the next few appointments across all users.
Future<void> showIslandDetailsSheet({
  required BuildContext context,
  required AppDatabase db,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _IslandDetailsSheet(db: db),
  );
}

/// Aggregated numbers rendered by the sheet, loaded in one pass.
class _IslandStats {
  final String? primeUserName;
  final int waterTodayMl;
  final int waterGoalMl;
  final List<_UserMedStat> medStats;
  final List<_ApptStat> appointments;
  final bool multiUser;

  const _IslandStats({
    required this.primeUserName,
    required this.waterTodayMl,
    required this.waterGoalMl,
    required this.medStats,
    required this.appointments,
    required this.multiUser,
  });
}

class _UserMedStat {
  final String userName;
  final int taken;
  final int total;
  const _UserMedStat(this.userName, this.taken, this.total);
}

class _ApptStat {
  final String title;
  final String userName;
  final DateTime time;
  const _ApptStat(this.title, this.userName, this.time);
}

class _IslandDetailsSheet extends StatefulWidget {
  const _IslandDetailsSheet({required this.db});
  final AppDatabase db;

  @override
  State<_IslandDetailsSheet> createState() => _IslandDetailsSheetState();
}

class _IslandDetailsSheetState extends State<_IslandDetailsSheet> {
  late final Future<_IslandStats> _future = _load();

  Future<_IslandStats> _load() async {
    final db = widget.db;

    final users = await (db.select(db.users)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final userNames = {for (final u in users) u.id: u.name};
    final prime = users.isNotEmpty ? users.first : null;

    // ── Water (prime user only) ──────────────────────────────────────────
    int waterToday = 0;
    int waterGoal = 0;
    if (prime != null) {
      final water = WaterService(db);
      waterToday = await water.getTodayTotal(prime.id);
      waterGoal = (await water.getSettings(prime.id)).goalMl;
    }

    // ── Meds today, per user (taken / total) ─────────────────────────────
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todaysIntakes = await (db.select(db.medicationIntakeLogs)
          ..where((t) =>
              t.scheduledTime.isBiggerOrEqualValue(startOfDay) &
              t.scheduledTime.isSmallerThanValue(endOfDay)))
        .get();
    final totalByUser = <int, int>{};
    final takenByUser = <int, int>{};
    for (final intake in todaysIntakes) {
      totalByUser[intake.userId] = (totalByUser[intake.userId] ?? 0) + 1;
      if (intake.wasTaken) {
        takenByUser[intake.userId] = (takenByUser[intake.userId] ?? 0) + 1;
      }
    }
    final medStats = <_UserMedStat>[];
    for (final u in users) {
      final total = totalByUser[u.id] ?? 0;
      if (total == 0) continue; // skip users with nothing scheduled today
      medStats.add(_UserMedStat(u.name, takenByUser[u.id] ?? 0, total));
    }

    // ── Upcoming appointments (all users, next few) ──────────────────────
    final upcoming = await AppointmentService(db).getUpcomingAppointments();
    final appointments = upcoming
        .take(5)
        .map((a) => _ApptStat(
              a.title,
              userNames[a.userId] ?? '',
              a.appointmentTime,
            ))
        .toList();

    return _IslandStats(
      primeUserName: prime?.name,
      waterTodayMl: waterToday,
      waterGoalMl: waterGoal,
      medStats: medStats,
      appointments: appointments,
      multiUser: users.length > 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: FutureBuilder<_IslandStats>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final s = snap.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 4),
                    child: Text(
                      'Pregled',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildMedsCard(theme, s),
                  const SizedBox(height: 16),
                  _buildAppointmentsCard(theme, s),
                  const SizedBox(height: 16),
                  _buildWaterCard(theme, s),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionCard({
    required ThemeData theme,
    required IconData icon,
    required Color accent,
    required String title,
    required Widget child,
  }) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: accent),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildWaterCard(ThemeData theme, _IslandStats s) {
    const accent = Color(0xFF38BDF8);
    final colors = theme.colorScheme;
    final goal = s.waterGoalMl;
    final progress = goal == 0 ? 0.0 : (s.waterTodayMl / goal).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final hit = goal > 0 && s.waterTodayMl >= goal;

    return _sectionCard(
      theme: theme,
      icon: Symbols.water_drop,
      accent: accent,
      title: s.primeUserName != null ? 'Hidracija — ${s.primeUserName}' : 'Hidracija',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.waterTodayMl}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ $goal ml',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                hit ? 'cilj dosežen ✓' : '$percent %',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hit ? accent : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: accent.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedsCard(ThemeData theme, _IslandStats s) {
    const accent = Color(0xFF22C55E);
    final colors = theme.colorScheme;

    return _sectionCard(
      theme: theme,
      icon: Symbols.medication,
      accent: accent,
      title: 'Zdravila danes',
      child: s.medStats.isEmpty
          ? Text(
              'Ni načrtovanih zdravil za danes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (final m in s.medStats) ...[
                  _medRow(theme, s, m, accent),
                  if (m != s.medStats.last) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Widget _medRow(
    ThemeData theme,
    _IslandStats s,
    _UserMedStat m,
    Color accent,
  ) {
    final colors = theme.colorScheme;
    final done = m.total > 0 && m.taken >= m.total;
    final progress = m.total == 0 ? 0.0 : (m.taken / m.total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (s.multiUser) ...[
              Expanded(
                child: Text(
                  m.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else
              const Spacer(),
            Text(
              done ? 'vse vzeto' : '${m.taken} / ${m.total} vzeto',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: done ? accent : colors.onSurfaceVariant,
              ),
            ),
            if (done) ...[
              const SizedBox(width: 6),
              Icon(Symbols.check_circle, size: 18, color: accent),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: accent.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsCard(ThemeData theme, _IslandStats s) {
    const accent = Color(0xFF3B82F6);
    final colors = theme.colorScheme;

    return _sectionCard(
      theme: theme,
      icon: Symbols.calendar_month,
      accent: accent,
      title: 'Prihajajoči termini',
      child: s.appointments.isEmpty
          ? Text(
              'Ni prihajajočih terminov',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (final a in s.appointments) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (s.multiUser && a.userName.isNotEmpty)
                              Text(
                                a.userName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatWhen(a.time),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  if (a != s.appointments.last)
                    Divider(
                      height: 20,
                      color: colors.outlineVariant.withOpacity(0.4),
                    ),
                ],
              ],
            ),
    );
  }

  String _formatWhen(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final dayDiff = day.difference(today).inDays;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    if (dayDiff == 0) return 'danes $hh:$mm';
    if (dayDiff == 1) return 'jutri $hh:$mm';
    if (dayDiff < 7) return 'čez $dayDiff dni';
    final dd = time.day.toString().padLeft(2, '0');
    final mo = time.month.toString().padLeft(2, '0');
    return '$dd.$mo. $hh:$mm';
  }
}
