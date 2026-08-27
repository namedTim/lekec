import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/services/server_message_service.dart';
import '../../database/drift_database.dart';
import '../../database/tables/server_messages.dart' show ServerMessageKind;
import '../widgets/server_message_banner.dart'
    show openServerMessageAction, serverMessageActionLabel, serverMessageHasAction;

/// Full list of server messages ("obvestila"), opened from the island sheet.
///
/// The sheet itself only shows the newest message to stay compact; everything
/// the app has cached lives here. Opening this page marks every message as
/// seen, which clears the island bell badge and the dashboard banner.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final ServerMessageService _service = ServerMessageService(widget.db);

  /// Which messages were unread when the page opened — they keep their "novo"
  /// chip while the user is reading, even though they are marked seen at once.
  Set<int>? _newIds;

  @override
  void initState() {
    super.initState();
    _markSeen();
  }

  Future<void> _markSeen() async {
    final messages = await _service.getAll();
    final unread = messages.where((m) => m.seenAt == null).map((m) => m.id).toSet();
    if (unread.isNotEmpty) await _service.markAllSeen();
    if (!mounted) return;
    setState(() => _newIds = unread);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sporočila')),
      body: StreamBuilder<List<ServerMessage>>(
        stream: _service.watchAll(),
        builder: (context, snap) {
          final messages = snap.data;
          if (messages == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (messages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.campaign,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ni sporočil',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _MessageCard(
              message: messages[i],
              isNew: _newIds?.contains(messages[i].id) ?? false,
            ),
          );
        },
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.isNew});

  final ServerMessage message;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = colors.primary;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  message.kind == ServerMessageKind.tip
                      ? Symbols.favorite
                      : Symbols.campaign,
                  size: 22,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    message.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'novo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (serverMessageHasAction(message)) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => openServerMessageAction(context, message),
                icon: Icon(
                  message.kind == ServerMessageKind.tip
                      ? Symbols.favorite
                      : Symbols.open_in_new,
                  size: 18,
                ),
                label: Text(serverMessageActionLabel(message)),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
