/** Canonical bounded data codec. No DOM, runtime dispatch or framework imports. */
const encoder = new TextEncoder();
const decoder = new TextDecoder("utf-8", { fatal: true });
const MAX = 131072;
export class ProtocolError extends Error {
  constructor(code) { super(code); this.name = "ProtocolError"; this.code = code; }
}
export function fail(code) { throw new ProtocolError(code); }
export function encode(value) {
  let budget = 0;
  function emit(text) {
    budget += encoder.encode(text).length;
    if (budget > MAX) fail("limit");
    return text;
  }
  function walk(v, depth) {
    if (depth > 32) fail("limit");
    if (v === null) return emit("n");
    if (v === true) return emit("t");
    if (v === false) return emit("f");
    if (typeof v === "number") {
      if (!Number.isSafeInteger(v) || v < 0 || Object.is(v, -0)) fail("malformed");
      return emit("i" + v + ";");
    }
    if (typeof v === "string") {
      if (decoder.decode(encoder.encode(v)) !== v) fail("malformed");
      const bytes = encoder.encode(v).length;
      if (bytes > 4096) fail("limit");
      return emit("s" + bytes + ":" + v);
    }
    if (Array.isArray(v)) {
      if (v.length > 1024) fail("limit");
      if (Object.keys(v).length !== v.length || Reflect.ownKeys(v).length !== v.length + 1) fail("malformed");
      for (let i = 0; i < v.length; i++) {
        if (!Object.hasOwn(v, i) || !Object.hasOwn(Object.getOwnPropertyDescriptor(v, i), "value")) fail("malformed");
      }
      return emit("a" + v.length + ":") + v.map(x => walk(x, depth + 1)).join("");
    }
    if (v && Object.getPrototypeOf(v) === Object.prototype) {
      const keys = Object.keys(v).sort();
      if (keys.length > 64 || Reflect.ownKeys(v).length !== keys.length) fail("malformed");
      if (keys.some(k => !/^[a-z][a-z0-9_]{0,63}$/.test(k))) fail("malformed");
      if (keys.some(k => !Object.hasOwn(Object.getOwnPropertyDescriptor(v, k), "value"))) fail("malformed");
      return emit("m" + keys.length + ":") + keys.map(k => walk(k, depth + 1) + walk(v[k], depth + 1)).join("");
    }
    fail("malformed");
  }
  const bytes = encoder.encode(walk(value, 0));
  if (bytes.length > MAX) fail("limit");
  return bytes;
}
export function decode(bytes) {
  if (!(bytes instanceof Uint8Array)) fail("malformed");
  if (bytes.length > MAX) fail("limit");
  let offset = 0;
  function count(delimiter) {
    const start = offset;
    while (offset < bytes.length && bytes[offset] !== delimiter) offset++;
    if (offset === bytes.length) fail("malformed");
    const token = decoder.decode(bytes.slice(start, offset++));
    if (!/^(0|[1-9][0-9]*)$/.test(token)) fail("malformed");
    const n = Number(token);
    if (!Number.isSafeInteger(n)) fail("malformed");
    return n;
  }
  function parse(depth) {
    if (depth > 32) fail("limit");
    const type = bytes[offset++];
    if (type === 110) return null;
    if (type === 116) return true;
    if (type === 102) return false;
    if (type === 105) return count(59);
    if (type === 115) {
      const size = count(58);
      if (size > 4096) fail("limit");
      if (offset + size > bytes.length) fail("malformed");
      const value = decoder.decode(bytes.slice(offset, offset + size)); offset += size;
      return value;
    }
    if (type === 97 || type === 109) {
      const size = count(58);
      if (size > (type === 97 ? 1024 : 64)) fail("limit");
      if (type === 97) return Array.from({ length: size }, () => parse(depth + 1));
      const out = {};
      for (let i = 0; i < size; i++) {
        const key = parse(depth + 1);
        if (typeof key !== "string" || !/^[a-z][a-z0-9_]{0,63}$/.test(key) || Object.hasOwn(out, key)) fail("malformed");
        Object.defineProperty(out, key, { value: parse(depth + 1), enumerable: true, writable: true });
      }
      return out;
    }
    fail("malformed");
  }
  try {
    const value = parse(0);
    if (offset !== bytes.length) fail("malformed");
    const canonical = encode(value);
    if (canonical.length !== bytes.length || canonical.some((v, i) => v !== bytes[i])) fail("malformed");
    return value;
  } catch (error) { if (error instanceof ProtocolError) throw error; fail("malformed"); }
}
export async function digest(value) {
  const bytes = await globalThis.crypto.subtle.digest("SHA-256", encode(value));
  return Array.from(new Uint8Array(bytes), x => x.toString(16).padStart(2, "0")).join("");
}
