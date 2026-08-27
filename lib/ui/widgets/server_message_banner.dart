import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../database/drift_database.dart';
import '../../database/tables/server_messages.dart' show ServerMessageKind;
import '../screens/tip_screen.dart';

/// Whether a message has a button at all (link with a usable URL, or tip).
bool serverMessageHasAction(ServerMessage m) {
  switch (m.kind) {
    case ServerMessageKind.link:
      final uri = m.url == null ? null : Uri.tryParse(m.url!);
      return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    case ServerMessageKind.tip:
      return true;
    default:
      return false;
  }
}

/// Caption for the message's button; falls back to a sensible default when
/// the server sent none.
String serverMessageActionLabel(ServerMessage m) {
  final label = m.urlLabel?.trim();
  if (label != null && label.isNotEmpty) return label;
  return m.kind == ServerMessageKind.tip ? 'Podpri razvoj' : 'Odpri';
}

/// Perform the message's action: open the link in the external browser, or
/// push the in-app tip screen. Only http(s) URLs are ever opened. Returns true
/// if something was actually opened.
Future<bool> openServerMessageAction(
  BuildContext context,
  ServerMessage m,
) async {
  switch (m.kind) {
    case ServerMessageKind.link:
      if (!serverMessageHasAction(m)) return false;
      final uri = Uri.parse(m.url!);
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    case ServerMessageKind.tip:
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TipScreen()),
      );
      return true;
    default:
      return false;
  }
}

/// Compact one-off card shown on the dashboard for the newest unread server
/// message. The user dismisses it (✕) or acts on it; either marks it seen, and
/// the dashboard never shows it again — it stays listed in the island sheet.
class ServerMessageBanner extends StatelessWidget {
  const ServerMessageBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    required this.onAction,
  });

  final ServerMessage message;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = colors.primary;
    final hasAction = serverMessageHasAction(message);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(
              message.kind == ServerMessageKind.tip
                  ? Symbols.favorite
                  : Symbols.campaign,
              size: 24,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    message.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (hasAction) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: onAction,
                      icon: Icon(
                        message.kind == ServerMessageKind.tip
                            ? Symbols.favorite
                            : Symbols.open_in_new,
                        size: 18,
                      ),
                      label: Text(serverMessageActionLabel(message)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Zapri',
            icon: const Icon(Symbols.close, size: 20),
            visualDensity: VisualDensity.compact,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
