# Virtual wheel and canvas clicks

The iOS virtual-key layer includes **one independent circular wheel button**.
Press it and drag upward to scroll up, or downward to scroll down. Holding still
or tapping does not scroll. There are no separate arrow or left/right mouse buttons.
The arrows in the wheel icon only indicate the drag directions.

- 12 logical pixels per wheel step, at most 5 steps per update.
- Release/cancel ends the gesture. Slow transport drops intermediate samples
  instead of queuing a scroll tail. Hiding, editing and app inactivity stop it.
- Long-press the virtual-key toggle to edit, then drag the wheel to position it.
  Position persists per peer and adapts to screen dimensions.
- Canvas single-finger tap uses the existing left-click gesture. Two-finger tap
  right-clicks in both mouse and direct-touch modes. In direct-touch mode it
  moves to the tap position first; in mouse mode it uses the current cursor.
- Pinch and movement compete through the existing gesture arena, not an extra
  full-screen listener. The wheel's touches do not reach the canvas below it.

Validation: 12 Flutter tests passed, including key regression tests, wheel
movement/stationary hold/release/cancellation, secondary-finger isolation, slow
transport, editing, and canvas single/two-finger taps versus pinch recognition.
The interactive preview logs wheel events only and does not connect to a host.
Actual iPad with Mac/Hyprland scrolling and remote click execution remain unverified.
