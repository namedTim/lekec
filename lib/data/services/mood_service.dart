import 'package:drift/drift.dart';
import '../../database/drift_database.dart';

class MoodService {
  final AppDatabase _db;

  MoodService(this._db);

  /// Mood level emoji mapping
  static const Map<int, String> moodEmojis = {
    1: '😢',
    2: '😕',
    3: '😐',
    4: '🙂',
    5: '😄',
  };

  /// Mood level labels in Slovenian
  static const Map<int, String> moodLabels = {
    1: 'Zelo slabo',
    2: 'Slabo',
    3: 'V redu',
    4: 'Dobro',
    5: 'Odlično',
  };

  /// Log a mood entry
  Future<int> logMood({
    required int userId,
    required int moodLevel,
    String? note,
  }) async {
    return _db
        .into(_db.moodEntries)
        .insert(
          MoodEntriesCompanion.insert(
            userId: userId,
            moodLevel: moodLevel,
            note: Value(note),
          ),
        );
  }

  /// Delete a mood entry
  Future<void> deleteMoodEntry(int id) async {
    await (_db.delete(_db.moodEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Get today's mood entry for a user (if any)
  Future<MoodEntry?> getTodaysMood(int userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final entries =
        await (_db.select(_db.moodEntries)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.createdAt.isBiggerOrEqualValue(startOfDay) &
                    t.createdAt.isSmallerThanValue(endOfDay),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .get();

    return entries.isEmpty ? null : entries.first;
  }

  /// Get mood entries for a user in the last N days
  Future<List<MoodEntry>> getMoodHistory(int userId, {int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));

    return (_db.select(_db.moodEntries)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.createdAt.isBiggerOrEqualValue(since),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get average mood for a user over the last N days
  Future<double?> getAverageMood(int userId, {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));

    final query = _db.selectOnly(_db.moodEntries)
      ..addColumns([_db.moodEntries.moodLevel.avg()])
      ..where(
        _db.moodEntries.userId.equals(userId) &
            _db.moodEntries.createdAt.isBiggerOrEqualValue(since),
      );

    final result = await query.getSingle();
    return result.read(_db.moodEntries.moodLevel.avg());
  }

  /// Get daily mood averages for the last N days (for chart)
  Future<List<Map<String, dynamic>>> getDailyMoodAverages(
    int userId, {
    int days = 14,
  }) async {
    final entries = await getMoodHistory(userId, days: days);

    // Group by date
    final Map<String, List<int>> byDate = {};
    for (final entry in entries) {
      final dateKey =
          '${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}-${entry.createdAt.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(dateKey, () => []).add(entry.moodLevel);
    }

    // Calculate daily averages
    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final moods = byDate[dateKey];

      result.add({
        'date': date,
        'dateKey': dateKey,
        'average': moods != null
            ? moods.reduce((a, b) => a + b) / moods.length
            : null,
        'count': moods?.length ?? 0,
      });
    }

    return result;
  }
}
