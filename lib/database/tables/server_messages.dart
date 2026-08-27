import 'package:drift/drift.dart';

/// Local cache of messages ("obvestila") authored on the LekecAPI server and
/// fetched on every app launch (`GET /api/v1/messages`).
///
/// `id` is the *server's* id, not autoincrement — that is what lets the app
/// remember which messages it has already shown across launches. `seenAt`
/// is set the first time the user dismisses the dashboard banner or opens the
/// messages section of the island sheet. Rows the server stops returning are
/// deleted on the next sync, so a message can be retracted remotely.
class ServerMessages extends Table {
  IntColumn get id => integer()();

  TextColumn get title => text()();
  TextColumn get body => text()();

  /// 'text' | 'link' | 'tip' — see [ServerMessageKind].
  TextColumn get kind => text().withDefault(const Constant('text'))();

  /// http(s) URL for kind == 'link'.
  TextColumn get url => text().nullable()();

  /// Button caption for link/tip kinds.
  TextColumn get urlLabel => text().nullable()();

  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get seenAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Known message kinds. Anything else is rendered as plain text.
class ServerMessageKind {
  static const text = 'text';
  static const link = 'link';
  static const tip = 'tip';
}
