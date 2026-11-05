import { hash } from "fast-sha256";
import type { Hash } from "./generated/message";

const encoder = new TextEncoder();

/** Matches native RustDesk password+salt, then salted hash+challenge. */
export function nativePasswordResponse(password: string, challenge: Hash): Uint8Array {
  if (!password) return new Uint8Array(); // Request manual approval.
  const plain = encoder.encode(password + challenge.salt);
  const salted = hash(plain);
  plain.fill(0);
  const nonce = encoder.encode(challenge.challenge);
  const input = new Uint8Array(salted.length + nonce.length);
  input.set(salted);
  input.set(nonce, salted.length);
  const response = hash(input);
  salted.fill(0);
  input.fill(0);
  return response;
}
