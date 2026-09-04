import assert from "node:assert/strict";
import test from "node:test";

import { detectBrowserPrerequisites, mayActivate } from "../src/index.js";

function environment(overrides = {}) {
  return {
    WebAssembly,
    Worker: class Worker {},
    SharedArrayBuffer,
    Atomics,
    fetch() {},
    AbortController,
    crypto: globalThis.crypto,
    isSecureContext: true,
    crossOriginIsolated: true,
    ...overrides,
  };
}

test("classifies full and buffered-only browser prerequisites", () => {
  const supported = detectBrowserPrerequisites(environment());
  assert.equal(supported.decision, "proceed");
  assert.equal(mayActivate(supported), true);
  const bufferedWasm = { validate: WebAssembly.validate, Memory: WebAssembly.Memory, instantiateStreaming: undefined };
  const buffered = detectBrowserPrerequisites(environment({ WebAssembly: bufferedWasm }));
  assert.equal(buffered.decision, "alternate-loading");
  assert.equal(mayActivate(buffered), true);
});

test("distinguishes deployment policy from browser capability failure", () => {
  const policy = detectBrowserPrerequisites(environment({ crossOriginIsolated: false }));
  assert.equal(policy.decision, "unsupported");
  assert.match(policy.message, /isolation/);
  const browser = detectBrowserPrerequisites(environment({ Worker: undefined }));
  assert.equal(browser.decision, "static-server-fallback");
  assert.match(browser.message, /Server-rendered fallback/);
  assert.equal(mayActivate(browser), false);
});
