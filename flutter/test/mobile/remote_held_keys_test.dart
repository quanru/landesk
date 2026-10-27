import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/remote_shortcut.dart';

void main() {
  test('slow bridge keeps press/release order and shared modifiers held', () async {
    final gate = Completer<void>();
    final events = <String>[];
    final keys = RemoteHeldKeys((key, down,
        {required ctrl, required alt, required shift, required command}) async {
      if (events.isEmpty) await gate.future;
      events.add('$key:$down:$command');
    }, onError: (e) => fail('$e'));
    final pending = [
      keys.press(1, const RemoteShortcut('Cmd', 'Meta')),
      keys.press(2, const RemoteShortcut('Space', 'VK_SPACE', command: true)),
      keys.release(2),
      keys.release(1),
    ];
    gate.complete();
    await Future.wait(pending);
    expect(events, ['Meta:true:true', 'VK_SPACE:true:true',
      'VK_SPACE:false:true', 'Meta:false:false']);
  });

  test('background cleanup releases every held key and ignores late ups', () async {
    final events = <String>[];
    final keys = RemoteHeldKeys((key, down,
        {required ctrl, required alt, required shift, required command}) async {
      events.add('$key:$down');
    }, onError: (e) => fail('$e'));
    await keys.press(1, const RemoteShortcut('Cmd', 'Meta'));
    await keys.press(2, const RemoteShortcut('Tab', 'VK_TAB'));
    await keys.releaseAll();
    await keys.release(1);
    await keys.release(2);
    expect(events, ['Meta:true', 'VK_TAB:true', 'VK_TAB:false', 'Meta:false']);
  });

  test('failed down attempts all releases and subsequent input still works', () async {
    final events = <String>[];
    final errors = <Object>[];
    final keys = RemoteHeldKeys((key, down,
        {required ctrl, required alt, required shift, required command}) async {
      events.add('$key:$down');
      if (key == 'VK_SPACE' && down) throw StateError('transport failed');
    }, onError: errors.add);
    await keys.press(1, const RemoteShortcut('Cmd', 'Meta'));
    await keys.press(2, const RemoteShortcut('Space', 'VK_SPACE'));
    await keys.release(1);
    await keys.press(3, const RemoteShortcut('C', 'VK_C'));
    await keys.release(3);
    expect(events, ['Meta:true', 'VK_SPACE:true', 'VK_SPACE:false', 'Meta:false', 'VK_C:true', 'VK_C:false']);
    expect(errors, hasLength(1));
  });
}
