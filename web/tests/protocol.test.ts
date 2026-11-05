import { describe, expect, test } from "bun:test";
import { mapCanvasPoint, mouseMask } from "../src/protocol";

describe("Native browser input", () => {
  test("maps letterboxed canvas coordinates to the remote display", () => {
    expect(mapCanvasPoint(500, 250, 1000, 500, 1920, 1080)).toEqual({ x: 960, y: 540 });
    expect(mapCanvasPoint(-10, 1000, 1000, 500, 1920, 1080)).toEqual({ x: 0, y: 1079 });
    expect(mapCanvasPoint(500, 250, 1000, 500, 1920, 1080, -1920, 120)).toEqual({
      x: -960,
      y: 660,
    });
  });

  test("encodes mouse movement and button transitions without phantom clicks", () => {
    expect(mouseMask(0, 0, 0)).toBe(0);
    expect(mouseMask(0, 0, 1)).toBe(8);
    expect(mouseMask(1, 0, 1)).toBe(9);
    expect(mouseMask(2, 2, 0)).toBe(18);
  });

});
