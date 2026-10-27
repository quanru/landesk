import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/models/connection_activity.dart';

void main() {
  test(
    'transport handshake is not authenticated success; optional feature errors do not disconnect',
    () {
      expect(
        phaseForSessionEvent({
          'name': 'connection_ready',
        }, ConnectionPhase.connecting),
        isNull,
      );
      expect(
        phaseForSessionEvent({
          'name': 'peer_info',
        }, ConnectionPhase.authentication),
        ConnectionPhase.connected,
      );
      expect(
        phaseForSessionEvent({
          'name': 'msgbox',
          'type': 'error',
          'title': 'Clipboard',
        }, ConnectionPhase.connected),
        isNull,
      );
      expect(
        phaseForSessionEvent({
          'name': 'msgbox',
          'type': 'error',
          'title': 'Connection Error',
        }, ConnectionPhase.connected),
        ConnectionPhase.failed,
      );
      expect(
        phaseForSessionEvent({
          'name': 'msgbox',
          'type': 'lan-login-required',
        }, ConnectionPhase.connecting),
        ConnectionPhase.authentication,
      );
    },
  );
  test(
    'delayed previous-window errors cannot overwrite newer success or retry handler',
    () async {
      final store = ConnectionActivities();
      var retries = 0;
      store.update(
        const ConnectionActivity(
          'host',
          2,
          2,
          ConnectionPhase.connected,
          '',
          retryAvailable: true,
        ),
        onRetry: () async {
          retries++;
          return true;
        },
      );
      store.update(
        const ConnectionActivity('host', 1, 50, ConnectionPhase.failed, 'old'),
      );
      store.update(
        const ConnectionActivity(
          'host',
          2,
          1,
          ConnectionPhase.failed,
          'out of order',
        ),
      );
      expect(store.forPeer('host')!.phase, ConnectionPhase.connected);
      expect(await store.retry('host'), isTrue);
      expect(retries, 1);
      store.dispose();
    },
  );
  test(
    'closing a failed session preserves reason but removes live retry callback',
    () async {
      final store = ConnectionActivities();
      store.update(
        const ConnectionActivity(
          'host',
          1,
          1,
          ConnectionPhase.failed,
          'timeout',
          retryAvailable: true,
        ),
        onRetry: () async => true,
      );
      store.update(
        const ConnectionActivity(
          'host',
          1,
          2,
          ConnectionPhase.failed,
          'timeout',
        ),
      );
      expect(store.forPeer('host')!.message, 'timeout');
      expect(
        await store.retry('host'),
        isFalse,
      ); // caller must open a new session
      store.dispose();
    },
  );
  test('window payload is validated and has no credential fields', () {
    const state = ConnectionActivity(
      'host',
      1,
      1,
      ConnectionPhase.authentication,
      'Password Required',
    );
    expect(
      ConnectionActivity.fromJson(state.toJson())!.phase,
      ConnectionPhase.authentication,
    );
    expect(state.toJson().keys, isNot(contains('password')));
    expect(
      ConnectionActivity.fromJson({'endpoint': 'host', 'phase': 'unknown'}),
      isNull,
    );
  });
  test('history and callbacks are bounded', () async {
    final store = ConnectionActivities();
    for (var i = 0; i < 130; i++) {
      store.update(
        ConnectionActivity(
          '$i',
          i,
          1,
          ConnectionPhase.failed,
          'timeout',
          retryAvailable: true,
        ),
        onRetry: () async => true,
      );
    }
    expect(store.forPeer('0'), isNull);
    expect(await store.retry('0'), isFalse);
    expect(store.forPeer('129'), isNotNull);
    store.dispose();
  });
}
