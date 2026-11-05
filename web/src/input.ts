import { ControlKey, KeyboardMode, Message, type KeyEvent, type DisplayInfo } from "./generated/message";
import { mapCanvasPoint, mouseMask } from "./protocol";
import type { PointerSample } from "./capabilities";

export function createRemoteInput(canvas: HTMLCanvasElement,
  canInput: () => boolean, display: () => DisplayInfo | undefined,
  send: (message: Message) => void) {
function currentModifiers(
  event: Pick<KeyboardEvent, "altKey" | "ctrlKey" | "shiftKey" | "metaKey">,
): ControlKey[] {
  const modifiers: ControlKey[] = [];
  if (event.altKey) modifiers.push(ControlKey.Alt);
  if (event.ctrlKey) modifiers.push(ControlKey.Control);
  if (event.shiftKey) modifiers.push(ControlKey.Shift);
  if (event.metaKey) modifiers.push(ControlKey.Meta);
  return modifiers;
}

const controlKeys: Record<string, ControlKey> = {
  Alt: ControlKey.Alt,
  Backspace: ControlKey.Backspace,
  CapsLock: ControlKey.CapsLock,
  Control: ControlKey.Control,
  Delete: ControlKey.Delete,
  ArrowDown: ControlKey.DownArrow,
  End: ControlKey.End,
  Escape: ControlKey.Escape,
  Home: ControlKey.Home,
  ArrowLeft: ControlKey.LeftArrow,
  Meta: ControlKey.Meta,
  PageDown: ControlKey.PageDown,
  PageUp: ControlKey.PageUp,
  Enter: ControlKey.Return,
  ArrowRight: ControlKey.RightArrow,
  Shift: ControlKey.Shift,
  " ": ControlKey.Space,
  Tab: ControlKey.Tab,
  ArrowUp: ControlKey.UpArrow,
  Insert: ControlKey.Insert,
};
for (let index = 1; index <= 12; index += 1) {
  controlKeys[`F${index}`] = ControlKey[`F${index}` as keyof typeof ControlKey] as ControlKey;
}

function sendKey(event: KeyboardEvent, release = false): void {
  if (!canInput()) return;
  const controlKey = controlKeys[event.key];
  if (release && controlKey === undefined) return;
  const keyEvent: Partial<KeyEvent> = {
    down: !release,
    press: !release,
    modifiers: currentModifiers(event),
    mode: KeyboardMode.Legacy,
  };
  if (controlKey !== undefined) {
    keyEvent.control_key = controlKey;
  } else {
    const codePoint = Array.from(event.key)[0]?.codePointAt(0);
    if (codePoint === undefined || event.key.length > 2) return;
    keyEvent.unicode = codePoint;
  }
  event.preventDefault();
  send(Message.create({ key_event: keyEvent }));
}

function sendText(value: string): void {
  if (!canInput() || !value) return;
  for (const character of Array.from(value)) {
    const codePoint = character.codePointAt(0);
    if (codePoint === undefined) continue;
    send(
      Message.create({
        key_event: {
          down: false,
          press: true,
          modifiers: [],
          mode: KeyboardMode.Legacy,
          unicode: codePoint,
        },
      }),
    );
  }
}

function canvasCoordinates(event: Pick<PointerSample, "clientX" | "clientY">): { x: number; y: number } {
  const remoteDisplay = display();
  if (!remoteDisplay) return { x: 0, y: 0 };
  const bounds = canvas.getBoundingClientRect();
  return mapCanvasPoint(
    event.clientX - bounds.left,
    event.clientY - bounds.top,
    bounds.width,
    bounds.height,
    remoteDisplay.width,
    remoteDisplay.height,
    remoteDisplay.x,
    remoteDisplay.y,
  );
}

function sendMouse(event: PointerSample, type: number): void {
  if (!canInput()) return;
  const point = canvasCoordinates(event);
  send(
    Message.create({
      mouse_event: {
        mask: mouseMask(type, event.button, event.buttons),
        x: point.x,
        y: point.y,
        modifiers: currentModifiers(event),
      },
    }),
  );
}

function pointerSample(event: PointerEvent): PointerSample {
  return {
    clientX: event.clientX,
    clientY: event.clientY,
    button: event.button,
    buttons: event.buttons,
    altKey: event.altKey,
    ctrlKey: event.ctrlKey,
    shiftKey: event.shiftKey,
    metaKey: event.metaKey,
  };
}


return { sendKey, sendText, sendMouse, pointerSample, currentModifiers };
}
