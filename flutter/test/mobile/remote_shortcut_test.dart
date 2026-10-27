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
  test('app switcher keeps Command across taps and releases on finish',
      () async {
    final events = <String>[];
    final switcher = RemoteAppSwitcher((key, down,
        {required ctrl, required alt, required shift, required command}) async {
      events.add('$key:$down:$command');
    }, isMac: true);
    await switcher.next();
    await switcher.next();
    expect(switcher.active, isTrue);
    expect(events.where((e) => e == 'Meta:false:false'), isEmpty);
    await switcher.finish();
    expect(events, [
      'Meta:true:true',
      'VK_TAB:true:true',
      'VK_TAB:false:true',
      'VK_TAB:true:true',
      'VK_TAB:false:true',
      'Meta:false:false'
    ]);
    expect(switcher.active, isFalse);
  });

  test('queued finish releases Command even when Tab fails', () async {
    final events = <String>[];
    final switcher = RemoteAppSwitcher((key, down,
        {required ctrl, required alt, required shift, required command}) async {
      events.add('$key:$down');
      if (key == 'VK_TAB' && down) throw StateError('failed');
    }, isMac: true);
    await expectLater(switcher.next(), throwsStateError);
    await switcher.finish();
    expect(events, ['Meta:true', 'VK_TAB:true', 'VK_TAB:false', 'Meta:false']);
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
