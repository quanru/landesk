import 'package:flutter/foundation.dart';

enum ConnectionPhase { connecting, authentication, connected, failed, closed }

ConnectionPhase? phaseForSessionEvent(
  Map<String, dynamic> event,
  ConnectionPhase current,
) {
  if (event['name'] == 'peer_info') return ConnectionPhase.connected;
  if (event['name'] != 'msgbox') return null;
  final type = event['type']?.toString() ?? '';
  if ([
    'lan-login-required',
    're-input-password',
    'input-password',
  ].contains(type)) {
    return ConnectionPhase.authentication;
  }
  if (event['title'] == 'Connection Error' ||
      (current != ConnectionPhase.connected && type.contains('error'))) {
    return ConnectionPhase.failed;
  }
  return null;
}

class ConnectionActivity {
  const ConnectionActivity(
    this.endpoint,
    this.attempt,
    this.revision,
    this.phase,
    this.message, {
    this.retryAvailable = false,
  });
  final String endpoint, message;
  final bool retryAvailable;
  final int attempt, revision;
  final ConnectionPhase phase;
  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'attempt': attempt,
    'revision': revision,
    'phase': phase.name,
    'message': message,
    'retryAvailable': retryAvailable,
  };
  static ConnectionActivity? fromJson(dynamic value) {
    if (value is! Map ||
        value['endpoint'] is! String ||
        value['attempt'] is! int ||
        value['revision'] is! int ||
        value['message'] is! String) {
      return null;
    }
    final phases = ConnectionPhase.values.where(
      (phase) => phase.name == value['phase'],
    );
    if (phases.isEmpty) return null;
    return ConnectionActivity(
      value['endpoint'],
      value['attempt'],
      value['revision'],
      phases.first,
      value['message'],
      retryAvailable: value['retryAvailable'] == true,
    );
  }
}

/// Session feedback only: never stores credentials, never writes to disk.
/// Attempt and revision ordering reject delayed events from old sessions/windows.
class ConnectionActivities extends ChangeNotifier {
  final _retries = <String, Future<bool> Function()>{};
  Future<bool> retry(String endpoint) async =>
      await _retries[endpoint.replaceAll(' ', '')]?.call() ?? false;
  final _entries = <String, ConnectionActivity>{};
  ConnectionActivity? forPeer(String endpoint) =>
      _entries[endpoint.replaceAll(' ', '')];
  void update(ConnectionActivity value, {Future<bool> Function()? onRetry}) {
    final key = value.endpoint.replaceAll(' ', '');
    final old = _entries[key];
    if (old != null &&
        (value.attempt < old.attempt ||
            (value.attempt == old.attempt && value.revision <= old.revision))) {
      return;
    }
    _entries.remove(key);
    _entries[key] = value;
    if (value.retryAvailable && onRetry != null) {
      _retries[key] = onRetry;
    } else {
      _retries.remove(key);
    }
    while (_entries.length > 128) {
      final oldest = _entries.keys.first;
      _entries.remove(oldest);
      _retries.remove(oldest);
    }
    notifyListeners();
  }
}

final connectionActivities = ConnectionActivities();
const connectionActivityMethod = 'landesk_connection_activity';

const connectionRetryMethod = 'landesk_retry_connection';
