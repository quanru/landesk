function requiredElement<T extends HTMLElement>(id: string): T {
  const element = document.getElementById(id);
  if (!element) throw new Error(`页面元素缺失：${id}`);
  return element as T;
}

export const connectPanel = requiredElement<HTMLElement>("connect-panel");
export const viewerPanel = requiredElement<HTMLElement>("viewer-panel");
export const loginForm = requiredElement<HTMLFormElement>("login-form");
export const passwordInput = requiredElement<HTMLInputElement>("password");
export const connectButton = requiredElement<HTMLButtonElement>("connect");
export const disconnectButton = requiredElement<HTMLButtonElement>("disconnect");
export const fullscreenButton = requiredElement<HTMLButtonElement>("fullscreen");
export const canvas = requiredElement<HTMLCanvasElement>("screen");
export const deviceName = requiredElement<HTMLElement>("device-name");
export const statusElement = requiredElement<HTMLElement>("status");
export const viewerStatus = requiredElement<HTMLElement>("viewer-status");
export const connectionStats = requiredElement<HTMLElement>("connection-stats");
export const trustPanel = requiredElement<HTMLElement>("trust-panel");
export const caCertificateLink = requiredElement<HTMLAnchorElement>("ca-certificate");
export const displaySelect = requiredElement<HTMLSelectElement>("display");
export const qualitySelect = requiredElement<HTMLSelectElement>("quality");
export const clipboardReadButton = requiredElement<HTMLButtonElement>("clipboard-read");
export const clipboardWriteButton = requiredElement<HTMLButtonElement>("clipboard-write");
export const textInput = requiredElement<HTMLInputElement>("text-input");
export const sendTextButton = requiredElement<HTMLButtonElement>("send-text");


export function renderPermissions(keyboard: boolean, clipboard: boolean): void {
  textInput.hidden = sendTextButton.hidden = !keyboard;
  clipboardReadButton.hidden = clipboardWriteButton.hidden = !clipboard;
  canvas.dataset.viewOnly = keyboard ? "false" : "true";
}
