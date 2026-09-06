import assert from "node:assert/strict";
import test from "node:test";

import {
  BH03_BROWSER_REQUIRED,
  BH03_DEPLOYMENT_REQUIRED,
  BH03_OPTIONAL,
  detectBrowserPrerequisites,
  evaluateHostPrerequisites,
  mayActivate,
  mayProceedToAcquisition,
} from "../src/index.js";

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

test("evaluates the exact BH-03 manifest-declared prerequisite contract", () => {
  const requirements = {
    browser_required: [...BH03_BROWSER_REQUIRED],
    deployment_required: [...BH03_DEPLOYMENT_REQUIRED],
    optional: [...BH03_OPTIONAL],
  };
  const compatible = evaluateHostPrerequisites(requirements, environment(), { sameOriginArtifacts: true });
  assert.equal(compatible.decision, "compatible");
  assert.equal(mayProceedToAcquisition(compatible), true);

  const buffered = evaluateHostPrerequisites(
    requirements,
    environment({ WebAssembly: { validate: WebAssembly.validate, Memory: WebAssembly.Memory } }),
    { sameOriginArtifacts: true },
  );
  assert.equal(buffered.decision, "alternate-loading");
  assert.equal(mayProceedToAcquisition(buffered), true);
});

test("rejects missing browser or deployment prerequisites before acquisition", () => {
  const requirements = {
    browser_required: [...BH03_BROWSER_REQUIRED],
    deployment_required: [...BH03_DEPLOYMENT_REQUIRED],
    optional: [...BH03_OPTIONAL],
  };
  const result = evaluateHostPrerequisites(requirements, environment({ Worker: undefined }), { sameOriginArtifacts: false });
  assert.equal(result.decision, "unsupported-prerequisite");
  assert.equal(result.failure_class, "unsupported-prerequisite");
  assert.deepEqual(result.missing, ["workers", "same-origin-artifacts"]);
  assert.equal(mayProceedToAcquisition(result), false);
});
