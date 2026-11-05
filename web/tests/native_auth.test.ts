import { expect, test } from "bun:test";
import { createHash } from "node:crypto";
import { nativePasswordResponse } from "../src/native_auth";

test("native password challenge matches the RustDesk two-stage hash", () => {
  const salted = createHash("sha256").update("sample-passwordsalt-123").digest();
  const expected = createHash("sha256").update(salted).update("nonce-456").digest();
  const actual = nativePasswordResponse("sample-password", { salt: "salt-123", challenge: "nonce-456" });
  expect(Buffer.from(actual)).toEqual(expected);
  expect(nativePasswordResponse("wrong", { salt: "salt-123", challenge: "nonce-456" })).not.toEqual(actual);
});

test("empty password requests approval without a fake password hash", () => {
  expect(nativePasswordResponse("", { salt: "salt", challenge: "nonce" })).toHaveLength(0);
});
