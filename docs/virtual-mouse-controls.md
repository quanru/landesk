# Virtual mouse controls

The iOS virtual-key layer now includes mouse and wheel groups, using the same
semi-transparent circular style as the supplied UU Remote screenshot.

- Left button: press/release at the current remote cursor; hold and slide to drag.
- Right button: independent right-click, with the highlighted half of the mouse icon.
- Wheel arrows: one step immediately, then repeat after 350 ms every 80 ms.
- Wheel centre: vertical drag; 12 logical pixels per wheel step, at most 5 steps
  per update. This is a scrolling surface, not a middle-click button.
- Release/cancel stops repeating. Slow scroll transport drops intermediate samples
  rather than building an unbounded queue. Hiding, editing, disposal and app
  inactivity release held buttons and cancel wheel timers.
- Long-press the virtual-key toggle to edit, then drag either mouse group. Positions
  persist in the existing per-peer layout and adapt to screen dimensions.
- Input permission/view-only checks are applied before presses, movement and scroll.
  Releases may still be sent after permission changes to avoid a stuck mouse.

Validation: 11 Flutter tests passed, including key regression tests and mouse
ordering, cancellation, hit testing, slow wheel, removal and background cleanup.
The production iOS simulator app and a separate interactive component preview
build successfully. The preview logs events and does not connect to a remote host.
Run `tools/virtual_keys_preview/run_simulator.sh <simulator-UDID>` to try it.

The screenshot establishes appearance, not UU gesture timing. The timing above
is an initial implementation, not a measured reproduction of UU Remote. Real iPad
with Mac/Hyprland input, perceived latency and scroll distance still need validation.
