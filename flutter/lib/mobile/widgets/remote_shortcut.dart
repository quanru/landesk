/// A key press is represented by a single native RustDesk key and modifiers.
/// Sent through the remote session, without injecting local keyboard events.
class RemoteShortcut {
  const RemoteShortcut(this.title, this.key,
      {this.ctrl = false,
      this.alt = false,
      this.shift = false,
      this.command = false});

  final String title;
  final String key;
  final bool ctrl, alt, shift, command;

  Map<String, dynamic> toJson() => {
        'title': title,
        'key': key,
        'ctrl': ctrl,
        'alt': alt,
        'shift': shift,
        'command': command,
      };

  factory RemoteShortcut.fromJson(Map<String, dynamic> json) => RemoteShortcut(
        json['title'] as String? ?? 'Key',
        json['key'] as String? ?? 'VK_ESCAPE',
        ctrl: json['ctrl'] == true,
        alt: json['alt'] == true,
        shift: json['shift'] == true,
        command: json['command'] == true,
      );
}

final Map<String, String> remoteKeyLabels = {
  'VK_ESCAPE': 'Esc',
  'VK_TAB': 'Tab',
  'VK_SPACE': 'Space',
  'VK_ENTER': 'Enter',
  'VK_BACK': 'Backspace',
  'VK_DELETE': 'Delete',
  'VK_UP': '↑',
  'VK_DOWN': '↓',
  'VK_LEFT': '←',
  'VK_RIGHT': '→',
  'VK_HOME': 'Home',
  'VK_END': 'End',
  for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
    'VK_$letter': letter,
  for (var i = 0; i <= 9; i++) 'VK_$i': '$i',
  for (var i = 1; i <= 12; i++) 'VK_F$i': 'F$i',
};

typedef RemoteKeyWriter = Future<void> Function(String name, bool down,
    {required bool ctrl,
    required bool alt,
    required bool shift,
    required bool command});

/// Each shortcut owns a complete press/release sequence. Callers must serialize
/// calls and must not start while physical or sticky modifiers are held.
Future<void> sendRemoteShortcut(
    RemoteShortcut shortcut, RemoteKeyWriter write) async {
  final held = <String>[];
  Future<void> emit(String key, bool down) => write(key, down,
      ctrl: held.contains('VK_CONTROL'),
      alt: held.contains('VK_MENU'),
      shift: held.contains('VK_SHIFT'),
      command: held.contains('Meta'));
  try {
    for (final key in [
      if (shortcut.ctrl) 'VK_CONTROL',
      if (shortcut.alt) 'VK_MENU',
      if (shortcut.shift) 'VK_SHIFT',
      if (shortcut.command) 'Meta',
      shortcut.key,
    ]) {
      held.add(key);
      await emit(key, true);
    }
  } finally {
    // Attempt every release even if one bridge call fails.
    Object? releaseError;
    while (held.isNotEmpty) {
      final key = held.removeLast();
      try {
        await emit(key, false);
      } catch (e) {
        releaseError ??= e;
      }
    }
    if (releaseError != null) throw releaseError;
  }
}

/// Runs complete chords in order; cancellation never interrupts key release.
Future<void> sendRemoteMacro(List<RemoteShortcut> steps, int delayMs,
    Future<void> Function(RemoteShortcut) send,
    {required bool Function() cancelled}) async {
  for (var i = 0; i < steps.length; i++) {
    if (cancelled()) return;
    await send(steps[i]);
    if (i + 1 < steps.length) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }
}

/// Owns only the modifier used by the on-screen application switcher.
/// Call finish before unrelated input, hiding the overlay or leaving the app.
class RemoteAppSwitcher {
  RemoteAppSwitcher(this.write, {required this.isMac});
  final RemoteKeyWriter write;
  final bool isMac;
  bool active = false;
  Future<void> _pending = Future.value();

  Future<void> _emit(String key, bool down) => write(key, down,
      ctrl: false,
      alt: active && !isMac,
      shift: false,
      command: active && isMac);

  Future<void> _queue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.catchError((Object _) {});
    return result;
  }

  Future<void> next() => _queue(() async {
        try {
          if (!active) {
            active = true;
            await _emit(isMac ? 'Meta' : 'VK_MENU', true);
          }
          try {
            await _emit('VK_TAB', true);
          } finally {
            await _emit('VK_TAB', false);
          }
        } catch (_) {
          await _release();
          rethrow;
        }
      });

  Future<void> _release() async {
    if (!active) return;
    active = false;
    await _emit(isMac ? 'Meta' : 'VK_MENU', false);
  }

  Future<void> finish() => _queue(_release);
}
