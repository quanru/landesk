export function mapCanvasPoint(
  clientX: number,
  clientY: number,
  canvasWidth: number,
  canvasHeight: number,
  remoteWidth: number,
  remoteHeight: number,
  remoteX = 0,
  remoteY = 0,
): { x: number; y: number } {
  if (canvasWidth <= 0 || canvasHeight <= 0 || remoteWidth <= 0 || remoteHeight <= 0) {
    return { x: 0, y: 0 };
  }

  const scale = Math.min(canvasWidth / remoteWidth, canvasHeight / remoteHeight);
  const renderedWidth = remoteWidth * scale;
  const renderedHeight = remoteHeight * scale;
  const offsetX = (canvasWidth - renderedWidth) / 2;
  const offsetY = (canvasHeight - renderedHeight) / 2;
  const x = Math.round((clientX - offsetX) / scale);
  const y = Math.round((clientY - offsetY) / scale);
  return {
    x: remoteX + Math.max(0, Math.min(remoteWidth - 1, x)),
    y: remoteY + Math.max(0, Math.min(remoteHeight - 1, y)),
  };
}

function buttonFlag(button: number): number {
  if (button === 0) return 1;
  if (button === 2) return 2;
  if (button === 1) return 4;
  return 0;
}

export function mouseMask(type: number, button: number, buttons: number): number {
  if (type !== 0) return type | (buttonFlag(button) << 3);
  let held = 0;
  if ((buttons & 1) !== 0) held |= 1;
  if ((buttons & 2) !== 0) held |= 2;
  if ((buttons & 4) !== 0) held |= 4;
  return held << 3;
}
