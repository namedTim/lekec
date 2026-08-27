import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../config/api_keys.dart';

/// One message as served by LekecAPI's `GET /api/v1/messages`.
class RemoteServerMessage {
  final int id;
  final String title;
  final String body;
  final String kind;
  final String? url;
  final String? urlLabel;

  const RemoteServerMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.url,
    this.urlLabel,
  });

  /// Null-tolerant: returns null for anything that is not a usable message
  /// so one malformed entry cannot poison the whole sync.
  static RemoteServerMessage? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    final body = json['body'];
    if (id is! int || title is! String || body is! String) return null;
    final url = json['url'];
    final urlLabel = json['url_label'];
    return RemoteServerMessage(
      id: id,
      title: title,
      body: body,
      kind: (json['kind'] is String) ? json['kind'] as String : 'text',
      url: url is String && url.isNotEmpty ? url : null,
      urlLabel: urlLabel is String && urlLabel.isNotEmpty ? urlLabel : null,
    );
  }
}

/// Thin client for the messages endpoint. Deliberately never throws: the
/// fetch runs on every app launch and a dead network, an expired TLS cert or
/// a server outage must not be visible to the user in any way.
class ServerMessagesApi {
  ServerMessagesApi({http.Client? client}) : _client = client;

  final http.Client? _client;
  static final _log = Logger('ServerMessagesApi');

  /// Returns the current list, or `null` if the server could not be reached
  /// or answered with anything other than a well-formed 200.
  Future<List<RemoteServerMessage>?> fetchMessages({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final uri = Uri.parse('${ApiKeys.lekecApiBaseUrl}/api/v1/messages');
      final headers = {'X-API-Key': ApiKeys.lekecApiKey};
      final response = await (_client != null
              ? _client.get(uri, headers: headers)
              : http.get(uri, headers: headers))
          .timeout(timeout);
      if (response.statusCode != 200) {
        _log.fine('messages: HTTP ${response.statusCode}');
        return null;
      }
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['messages'] is! List) return null;
      return (decoded['messages'] as List)
          .map(RemoteServerMessage.tryFromJson)
          .whereType<RemoteServerMessage>()
          .toList();
    } catch (e) {
      // Offline, DNS, TLS, timeout, bad JSON — all equally uninteresting here.
      _log.fine('messages: fetch failed: $e');
      return null;
    }
  }
}
