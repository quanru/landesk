import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/remote_shortcut.dart';

void main() {
  test('Cmd Space is one complete chord, followed by an unmodified key',
      () async {
    final events = <String>[];
    Future<void> write(String key, bool down,
        {required bool ctrl,
        required bool alt,
        required bool shift,
        required bool command}) async {
      events.add('$key:$down:$command');
    }

    await sendRemoteShortcut(
        const RemoteShortcut('⌘ Space', 'VK_SPACE', command: true), write);
    await sendRemoteShortcut(const RemoteShortcut('Enter', 'VK_ENTER'), write);
    expect(events, [
      'Meta:true:true',
      'VK_SPACE:true:true',
      'VK_SPACE:false:true',
      'Meta:false:false',
      'VK_ENTER:true:false',
      'VK_ENTER:false:false',
    ]);
  });

  test('failed main key still releases it and all modifiers', () async {
    final releases = <String>[];
    Future<void> write(String key, bool down,
        {required bool ctrl,
        required bool alt,
        required bool shift,
        required bool command}) async {
      if (key == 'VK_P' && down) throw StateError('transport failure');
      if (!down) releases.add(key);
    }

    await expectLater(
        sendRemoteShortcut(
            const RemoteShortcut('Palette', 'VK_P', command: true, shift: true),
            write),
        throwsStateError);
    expect(releases, ['VK_P', 'Meta', 'VK_SHIFT']);
  });
  test('macro order, cancellation and failure stop subsequent steps', () async {
    const steps = [
      RemoteShortcut('Copy', 'VK_C', command: true),
      RemoteShortcut('Paste', 'VK_V', command: true)
    ];
    final sent = <String>[];
    await sendRemoteMacro(steps, 0, (s) async => sent.add(s.key),
        cancelled: () => false);
    expect(sent, ['VK_C', 'VK_V']);
    sent.clear();
    await sendRemoteMacro(steps, 0, (s) async => sent.add(s.key),
        cancelled: () => sent.isNotEmpty);
    expect(sent, ['VK_C']);
    sent.clear();
    await expectLater(
        sendRemoteMacro(steps, 0, (s) async {
          sent.add(s.key);
          throw StateError('disconnected');
        }, cancelled: () => false),
        throwsStateError);
    expect(sent, ['VK_C']);
  });
}
