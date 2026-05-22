import 'package:drift/drift.dart' show OrderingTerm;

import '../../database/drift_database.dart';

/// Slovenian first-person verb forms differ by gender, so notification buttons
/// like "Bom vzel" / "Bom vzela" need to know who is taking the medication.
///
/// We use the lowest-ID active user as the "primary" speaker for global UI —
/// good enough for single-person installs and for families where the phone
/// belongs to one person. Returns labels for the medication taken/skip
/// actions plus the dismiss action on the ring screen.
class UserLabels {
  const UserLabels({
    required this.taken,
    required this.skip,
    required this.takenPast,
  });

  /// "Bom vzel" / "Bom vzela" — future-tense first person.
  /// Used on the ring screen and on notification action buttons where the
  /// user is *about to* take the dose.
  final String taken;

  /// "Preskoči" — imperative, gender-neutral.
  final String skip;

  /// "Sem vzel" / "Sem vzela" — past-tense first person.
  /// Used in the daily-view detail dialog where the user is confirming a
  /// dose they *have already* taken.
  final String takenPast;

  /// Fallback used when the database has no users yet (cold boot before
  /// onboarding finishes, etc.). Defaults to male form, matching the existing
  /// app voice.
  static const UserLabels fallback = UserLabels(
    taken: 'Bom vzel',
    skip: 'Preskoči',
    takenPast: 'Sem vzel',
  );

  static UserLabels forGender(String? gender) {
    final female = gender == 'female';
    return UserLabels(
      taken: female ? 'Bom vzela' : 'Bom vzel',
      skip: 'Preskoči',
      takenPast: female ? 'Sem vzela' : 'Sem vzel',
    );
  }

  /// Reads the lowest-ID active user from [db] and returns their labels.
  /// Falls back to [fallback] on error or empty users table.
  static Future<UserLabels> forPrimaryUser(AppDatabase db) async {
    try {
      final user = await (db.select(db.users)
            ..where((u) => u.isActive.equals(true))
            ..orderBy([(u) => OrderingTerm(expression: u.id)])
            ..limit(1))
          .getSingleOrNull();
      return forGender(user?.gender);
    } catch (_) {
      return fallback;
    }
  }
}
