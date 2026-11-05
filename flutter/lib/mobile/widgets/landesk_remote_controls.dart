import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../common/landesk_text.dart';
import '../../consts.dart';
import '../../models/model.dart';
import '../../models/input_model.dart';
import '../../models/platform_model.dart';
import 'custom_key_overlay.dart';
import 'remote_input_stack.dart';
import 'remote_session_sidebar.dart';
import 'remote_shortcut.dart';
import 'window_overview.dart';

/// Product controls live outside the upstream remote pointer and key listeners.
/// Their widget position stays stable when the toolbar or soft keyboard changes.
class LandeskRemoteControls extends StatefulWidget {
  const LandeskRemoteControls({super.key, required this.ffi, required this.child,
    required this.onKeyboard, required this.onOptions, required this.onActions,
    required this.onChat, required this.onClose, required this.keyboardOpen});

  final FFI ffi;
  final bool keyboardOpen;
  final Widget child;
  final VoidCallback onKeyboard, onOptions, onActions, onChat, onClose;

  @override
  State<LandeskRemoteControls> createState() => _LandeskRemoteControlsState();
}

class _LandeskRemoteControlsState extends State<LandeskRemoteControls> {
  final keys = GlobalKey<CustomKeyOverlayState>();
  bool expanded = true;
  bool keysVisible = true;

  bool get canInput {
    final input = widget.ffi.inputModel;
    return !widget.ffi.closed && input.keyboardPerm && !input.isViewOnly &&
        !input.isViewCamera && input.keyboardInputAllowed;
  }

  Future<void> write(String name, bool down, {required bool ctrl,
    required bool alt, required bool shift, required bool command}) async {
    final input = widget.ffi.inputModel;
    if (down && (!canInput || input.ctrl || input.alt || input.shift || input.command)) {
      throw StateError('Remote keyboard is unavailable');
    }
    await bind.sessionInputKey(sessionId: widget.ffi.sessionId, name: name,
      down: down, press: false, ctrl: ctrl, alt: alt, shift: shift, command: command);
  }

  Future<void> shortcut(RemoteShortcut shortcut) => sendRemoteShortcut(shortcut, write);

  void overview() async {
    final platform = widget.ffi.ffiModel.pi.platform;
    final action = platform == kPeerPlatformMacOS ? macWindowOverview
        : platform == kPeerPlatformWindows ? windowsWindowOverview
        : decodeWindowOverview(await bind.sessionGetFlutterOption(
            sessionId: widget.ffi.sessionId, k: windowOverviewOption));
    if (!mounted) return;
    if (action == null) {
      await showDialog<void>(context: context, builder: (_) => WindowOverviewSettings(
        onSave: (value) async {
          // Settings widget encodes the selected shortcut itself via its model.
          await saveOverview(value);
        },
      ));
      return;
    }
    try {
      await shortcut(action);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('Could not send remote shortcut'))));
    }
  }

  Future<void> saveOverview(RemoteShortcut action) async {
    await bind.sessionSetFlutterOption(sessionId: widget.ffi.sessionId,
      k: windowOverviewOption, v: jsonEncode(action.toJson()));
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final model = widget.ffi.ffiModel;
    final ready = model.pi.isSet.isTrue && model.waitForFirstImage.isFalse;
    final enabled = ready && canInput;
    final keyboardOpen = widget.keyboardOpen;
    final showKeys = enabled && !keyboardOpen;
    Widget button(IconData icon, String label, VoidCallback? action,
        {bool selected = false}) => RemoteRailButton(icon: icon,
      label: landeskText(context, translate(label)), onPressed: action, selected: selected);
    return RemoteSessionLayout(
      rail: !ready ? null : !expanded || keyboardOpen
        ? RemoteEdgeControl(label: translate('Control Actions'),
            icon: Icons.chevron_left, onPressed: () => setState(() => expanded = true))
        : RemoteActionRail(collapseLabel: translate('Hide'),
            onCollapse: () => setState(() => expanded = false), children: [
          button(Icons.keyboard_outlined, 'Keyboard', enabled ? widget.onKeyboard : null),
          button(Icons.keyboard_alt_outlined, 'Virtual keys', enabled ? () {
            keys.currentState?.setVisible(!keysVisible);
          } : null, selected: keysVisible),
          button(Icons.edit_outlined, 'Edit layout', enabled ? () {
            keys.currentState?.editLayout();
          } : null),
          button(Icons.window_outlined, 'All windows', enabled ? overview : null),
          button(Icons.settings_outlined, 'Display', widget.onOptions),
          button(Icons.chat_bubble_outline, 'Chat', widget.onChat),
          button(Icons.more_horiz, 'Control Actions', widget.onActions),
          button(Icons.close, 'Disconnect', widget.onClose),
        ]),
      child: RemoteInputStack(child: widget.child, controls: Offstage(
        offstage: !showKeys,
        child: SafeArea(child: CustomKeyOverlay(key: keys, active: showKeys,
          onVisibilityChanged: (value) {
            if (mounted && value != keysVisible) setState(() => keysVisible = value);
          },
          isMac: model.pi.platform == kPeerPlatformMacOS,
          profileId: widget.ffi.id, translate: (text) => translate(text),
          send: shortcut, write: write,
          rightClick: () async {
            if (canInput) await widget.ffi.inputModel.tap(MouseButtons.right);
          },
          mouseScroll: (steps) async {
            if (canInput) await widget.ffi.inputModel.scroll(steps);
          },
        )),
      )),
    );
  });
}
