import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/drift_database.dart';
import '../../services/server_messages_api.dart';

/// Syncs server messages into the local `server_messages` table and tracks
/// which ones the user has seen.
///
/// Everything network-related is best-effort: [syncFromServer] swallows every
/// failure and leaves the local cache untouched, so the UI (which only ever
/// reads the local table) behaves identically offline.
class ServerMessageService {
  ServerMessageService(this._db, {ServerMessagesApi? api})
      : _api = api ?? ServerMessagesApi();

  final AppDatabase _db;
  final ServerMessagesApi _api;
  static final _log = Logger('ServerMessageService');

  /// Resume-triggered syncs are throttled to this; a cold start (first call
  /// in the process) always goes through.
  static const minSyncInterval = Duration(minutes: 15);
  static DateTime? _lastSyncAttempt;

  /// Messages stop being shown this long after the device first received
  /// them, even if the server still serves them. The row is kept (not
  /// deleted) so sync reconciliation doesn't re-insert a still-served
  /// message as new and unseen.
  static const maxMessageAge = Duration(days: 30);

  /// Fixed id for the locally generated welcome message. Negative so it can
  /// never collide with a server id and survives sync reconciliation.
  static const welcomeMessageId = -1;

  /// One-shot flag: has the very first server sync of this install already
  /// happened? Stored in `SharedPreferences` (the mechanism the app already
  /// uses for small cross-launch flags) rather than the database, because it
  /// is app state, not user data, and so needs no schema migration.
  static const _initialSyncDoneKey = 'initialMessageSyncDone';

  /// Fetch the current list and reconcile the local cache:
  ///   * new ids are inserted (unseen),
  ///   * known ids get their text refreshed but keep `seenAt`,
  ///   * ids the server no longer returns are deleted (retracted remotely).
  /// Rows with negative ids are app-generated (e.g. the welcome message) and
  /// are never touched by reconciliation.
  ///
  /// On the very first sync of a fresh install, new rows are inserted already
  /// seen, so the user's first load after onboarding shows only the welcome
  /// message as new instead of a backlog of server messages. Every later sync
  /// inserts new rows unseen, as usual.
  ///
  /// Returns true if a fetch actually happened and succeeded.
  Future<bool> syncFromServer({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastSyncAttempt != null &&
        now.difference(_lastSyncAttempt!) < minSyncInterval) {
      return false;
    }
    _lastSyncAttempt = now;

    final preSeenNewRows = !await _isInitialSyncDone();

    try {
      final remote = await _api.fetchMessages();
      if (remote == null) return false;

      await _db.transaction(() async {
        final ids = remote.map((m) => m.id).toList();
        if (ids.isEmpty) {
          await (_db.delete(_db.serverMessages)
                ..where((t) => t.id.isBiggerThanValue(0)))
              .go();
        } else {
          await (_db.delete(_db.serverMessages)
                ..where((t) =>
                    t.id.isNotIn(ids) & t.id.isBiggerThanValue(0)))
              .go();
        }
        for (final m in remote) {
          await _db.into(_db.serverMessages).insert(
                ServerMessagesCompanion.insert(
                  id: Value(m.id),
                  title: m.title,
                  body: m.body,
                  kind: Value(m.kind),
                  url: Value(m.url),
                  urlLabel: Value(m.urlLabel),
                  seenAt: preSeenNewRows ? Value(now) : const Value.absent(),
                ),
                // Refresh the content of a message we already have, but never
                // touch receivedAt/seenAt — that is what makes "show once" stick.
                onConflict: DoUpdate(
                  (old) => ServerMessagesCompanion(
                    title: Value(m.title),
                    body: Value(m.body),
                    kind: Value(m.kind),
                    url: Value(m.url),
                    urlLabel: Value(m.urlLabel),
                  ),
                ),
              );
        }
      });
      if (preSeenNewRows) await _markInitialSyncDone();
      return true;
    } catch (e, st) {
      _log.warning('syncFromServer failed', e, st);
      return false;
    }
  }

  /// True once the first successful server sync of this install has happened.
  ///
  /// Installs that predate the flag already hold server rows, and their user
  /// has seen (or dismissed) them — pre-seeing anything there would be wrong,
  /// so the flag is simply recorded as done on first check.
  Future<bool> _isInitialSyncDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_initialSyncDoneKey) ?? false) return true;

      final existing = await (_db.select(_db.serverMessages)
            ..where((t) => t.id.isBiggerThanValue(0))
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) {
        await prefs.setBool(_initialSyncDoneKey, true);
        return true;
      }
      return false;
    } catch (e, st) {
      // Never let a prefs failure block a sync; fall back to today's behaviour.
      _log.warning('initial sync flag check failed', e, st);
      return true;
    }
  }

  Future<void> _markInitialSyncDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_initialSyncDoneKey, true);
    } catch (e, st) {
      _log.warning('could not persist initial sync flag', e, st);
    }
  }

  /// Inserts the one-time welcome message shown to every new user after
  /// onboarding. Idempotent: the fixed id makes a repeat call a no-op, so a
  /// re-run of onboarding can't duplicate it or reset its seen state.
  Future<void> insertWelcomeMessage() async {
    await _db.into(_db.serverMessages).insert(
          ServerMessagesCompanion.insert(
            id: const Value(welcomeMessageId),
            title: 'Dobrodošli v aplikaciji Lekec!',
            body: 'Veseli nas, da ste z nami. Začnite tako, da dodate svoje '
                'prvo zdravilo — lahko tudi s fotografijo škatlice. Obvestila '
                'o novostih boste našli tukaj, med sporočili.',
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// All cached messages younger than [maxMessageAge], newest (highest
  /// server id) first.
  ///
  /// The cutoff is fixed when the stream is created; a message crossing the
  /// 30-day line while the app stays open disappears on the next re-query
  /// (any table write), which is close enough.
  Stream<List<ServerMessage>> watchAll() {
    final cutoff = DateTime.now().subtract(maxMessageAge);
    return (_db.select(_db.serverMessages)
          ..where((t) => t.receivedAt.isBiggerThanValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  Future<List<ServerMessage>> getAll() {
    final cutoff = DateTime.now().subtract(maxMessageAge);
    return (_db.select(_db.serverMessages)
          ..where((t) => t.receivedAt.isBiggerThanValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  Future<void> markSeen(int id) async {
    await (_db.update(_db.serverMessages)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.seenAt.isNull()))
        .write(ServerMessagesCompanion(seenAt: Value(DateTime.now())));
  }

  Future<void> markAllSeen() async {
    await (_db.update(_db.serverMessages)..where((t) => t.seenAt.isNull()))
        .write(ServerMessagesCompanion(seenAt: Value(DateTime.now())));
  }
}
