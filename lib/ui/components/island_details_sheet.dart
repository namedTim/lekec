import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../database/drift_database.dart';
import '../../database/tables/medications.dart' show MedicationStatus;
import '../../data/services/appointment_service.dart';
import '../../data/services/medication_service.dart';
import '../../data/services/water_service.dart';
import '../../utils/medication_utils.dart';
import 'quantity_selector.dart';

/// Expanded view of the dashboard time-island. Opened by tapping the island.
/// Shows, at a glance:
///   * Hidracija — today's water for the prime (first active) user vs. goal.
///   * Zaloga zdravil — medications running low / out of stock, with a refill
///     shortcut.
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
  final List<LowStockMed> lowStock;
  final List<_ApptStat> appointments;
  final bool multiUser;

  /// Count of critical (alarm) reminders still scheduled to ring later today.
  final int criticalPendingToday;

  const _IslandStats({
    required this.primeUserName,
    required this.waterTodayMl,
    required this.waterGoalMl,
    required this.lowStock,
    required this.appointments,
    required this.multiUser,
    required this.criticalPendingToday,
  });
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
  late Future<_IslandStats> _future = _load();

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

    // ── Medications running low / out of stock ───────────────────────────
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todaysIntakes = await (db.select(db.medicationIntakeLogs)
          ..where((t) =>
              t.scheduledTime.isBiggerOrEqualValue(startOfDay) &
              t.scheduledTime.isSmallerThanValue(endOfDay)))
        .get();
    final lowStock = await MedicationService(db).getLowStockMedications();

    // ── Critical reminders still pending later today ─────────────────────
    final criticalMedIds = (await (db.select(db.medications)
              ..where((m) => m.criticalReminder.equals(true))
              ..where((m) => m.status.equalsValue(MedicationStatus.active)))
            .get())
        .map((m) => m.id)
        .toSet();
    final criticalPendingToday = todaysIntakes
        .where((i) =>
            i.scheduledTime.isAfter(now) &&
            !i.wasTaken &&
            i.takenTime == null &&
            criticalMedIds.contains(i.medicationId))
        .length;

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
      lowStock: lowStock,
      appointments: appointments,
      multiUser: users.length > 1,
      criticalPendingToday: criticalPendingToday,
    );
  }

  /// Cancel all of today's remaining critical reminders, then refresh the sheet.
  Future<void> _stopTodaysCriticalReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Symbols.alarm_off, size: 48),
        title: const Text('Ustavi kritične opomnike'),
        content: const Text(
          'Vsi kritični opomniki, ki naj bi zazvonili še danes, bodo '
          'preklicani in ne bodo zazvonili. Jutri se ponastavijo.\n\n'
          'Ali želite nadaljevati?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Prekliči'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ustavi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final stopped = await MedicationService(widget.db).stopTodaysCriticalReminders();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          stopped == 0
              ? 'Ni kritičnih opomnikov za ustaviti'
              : 'Ustavljenih kritičnih opomnikov: $stopped',
        ),
      ),
    );
    // Reload the sheet so the button/count reflect the change.
    setState(() => _future = _load());
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
                  const SizedBox(height: 12),
                  // Always shown so the action is discoverable; disabled when
                  // there's nothing scheduled to ring later today.
                  OutlinedButton.icon(
                    onPressed: s.criticalPendingToday > 0
                        ? _stopTodaysCriticalReminders
                        : null,
                    icon: const Icon(Symbols.alarm_off),
                    label: Text(
                      s.criticalPendingToday > 0
                          ? 'Ustavi kritične opomnike do konca dneva '
                              '(${s.criticalPendingToday})'
                          : 'Ni kritičnih opomnikov za danes',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
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
    const accent = Color(0xFF22C55E); // green — the meds/stock section icon
    final colors = theme.colorScheme;

    return _sectionCard(
      theme: theme,
      icon: Symbols.medication,
      accent: accent,
      title: 'Zaloga zdravil',
      child: s.lowStock.isEmpty
          ? Row(
              children: [
                const Icon(
                  Symbols.check_circle,
                  size: 18,
                  color: Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zaloga vseh zdravil zadostuje',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                for (final m in s.lowStock) ...[
                  _lowStockRow(theme, s, m),
                  if (m != s.lowStock.last)
                    Divider(
                      height: 20,
                      color: colors.outlineVariant.withOpacity(0.4),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _lowStockRow(ThemeData theme, _IslandStats s, LowStockMed m) {
    final colors = theme.colorScheme;
    final isOut = m.isOut;
    final statusColor = isOut ? colors.error : const Color(0xFFF59E0B);

    final count = isOut ? 0 : m.remaining.ceil();
    final unit = getMedicationUnit(m.medType, count);
    final numStr = m.remaining == m.remaining.roundToDouble()
        ? m.remaining.toInt().toString()
        : m.remaining.toStringAsFixed(1);
    final remainingText = isOut ? 'Zmanjkalo' : 'Še $numStr $unit';
    final showOwner = s.multiUser && (m.ownerName?.isNotEmpty ?? false);

    return Row(
      children: [
        Icon(
          isOut ? Symbols.error : Symbols.warning,
          size: 20,
          color: statusColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                showOwner ? '$remainingText · ${m.ownerName}' : remainingText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _refillStock(m),
          icon: const Icon(Symbols.add_circle, size: 18),
          label: const Text('Dopolni'),
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }

  /// Opens the quantity picker to overwrite a medication's remaining stock,
  /// then refreshes the sheet so the row updates (or drops off the list).
  Future<void> _refillStock(LowStockMed m) async {
    final suggested = m.remaining > 0 ? m.remaining : m.doseAmount * 10;
    final newValue = await showQuantitySelector(
      context,
      initialValue: suggested <= 0 ? 1 : suggested,
      minValue: 0,
      maxValue: 99999,
      step: 1,
      label: 'Nova zaloga — ${m.name}',
    );
    if (newValue == null) return;

    await MedicationService(widget.db).setRemainingStock(m.medicationId, newValue);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zaloga posodobljena: ${m.name}')),
    );
    setState(() => _future = _load());
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
