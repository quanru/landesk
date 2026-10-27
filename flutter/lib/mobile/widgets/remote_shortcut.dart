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
