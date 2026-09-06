import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { BlazeXHostError, fetchHostManifest, inspectHostManifest, validateHostManifest } from "../src/index.js";

const fixtureUrl = new URL("../../../integration/bh-03/phase-02/pre-acquisition-fixtures-v0.1.0.json", import.meta.url);
const fixtures = JSON.parse(await readFile(fixtureUrl, "utf8"));
const manifestUrl = "https://example.test/bh01/bh03-runtime-manifest.json";

test("normalizes the valid profile manifest without acquiring artifacts", () => {
  const result = validateHostManifest(fixtures.valid_manifest, manifestUrl);
  assert.equal(result.compatibility.renderer, "blazex.renderer/1");
  assert.equal(result.artifacts.length, 3);
  assert.equal(result.artifacts[0].url, "https://example.test/bh01/artifacts/AtomVM.mjs");
  assert.equal(Object.isFrozen(result.artifacts), true);
});

test("rejects every versioned invalid manifest mutation atomically", () => {
  for (const fixture of fixtures.invalid_manifests) {
    const value = structuredClone(fixtures.valid_manifest);
    applyMutation(value, fixture.mutation);
    assert.throws(
      () => validateHostManifest(value, manifestUrl),
      (error) => error instanceof BlazeXHostError && error.code === fixture.error && error.details.reason === fixture.reason,
      fixture.id,
    );
  }
});

test("fetches only a bounded no-store same-origin JSON manifest", async () => {
  const fetchImpl = async (url, init) => {
    assert.equal(url.href, manifestUrl);
    assert.equal(init.cache, "no-store");
    assert.equal(init.credentials, "same-origin");
    assert.equal(init.redirect, "error");
    return withUrl(new Response(JSON.stringify(fixtures.valid_manifest), { status: 200, headers: { "content-type": "application/json" } }), manifestUrl);
  };
  const result = await fetchHostManifest(manifestUrl, { fetchImpl, baseUrl: "https://example.test/app/" });
  assert.equal(result.manifest_id, fixtures.valid_manifest.manifest_id);
  const redirected = async () => withUrl(new Response("{}", { status: 200, headers: { "content-type": "application/json" } }), "https://example.test/other.json", true);
  await assert.rejects(fetchHostManifest(manifestUrl, { fetchImpl: redirected, baseUrl: "https://example.test/app/" }), reason("fetch-redirect"));
  const oversized = async () => withUrl(new Response("x".repeat(65_537), { status: 200, headers: { "content-type": "application/json" } }), manifestUrl);
  await assert.rejects(fetchHostManifest(manifestUrl, { fetchImpl: oversized, baseUrl: "https://example.test/app/" }), reason("response-too-large"));
});

test("composes discovery, validation, and prerequisites as a pre-acquisition gate", async () => {
  const fetchImpl = async () => withUrl(new Response(JSON.stringify(fixtures.valid_manifest), { status: 200, headers: { "content-type": "application/json" } }), manifestUrl);
  const result = await inspectHostManifest({
    manifestUrl,
    baseUrl: "https://example.test/app/",
    document: { querySelectorAll: () => [] },
    fetchImpl,
    environment: supportedEnvironment(),
  });
  assert.equal(result.decision, "eligible-for-artifact-acquisition");
  assert.equal(result.artifacts_acquired, 0);
});

function supportedEnvironment() {
  return {
    WebAssembly,
    Worker: class Worker {},
    fetch() {},
    AbortController,
    crypto: globalThis.crypto,
    isSecureContext: true,
    crossOriginIsolated: true,
  };
}

function applyMutation(value, mutation) {
  let target = value;
  for (const segment of mutation.path.slice(0, -1)) target = target[segment];
  const key = mutation.path.at(-1);
  if (mutation.operation === "delete") delete target[key];
  else target[key] = mutation.value;
}

function withUrl(response, url, redirected = false) {
  Object.defineProperties(response, { url: { value: url }, redirected: { value: redirected } });
  return response;
}

function reason(value) {
  return (error) => error instanceof BlazeXHostError && error.code === "manifest-invalid" && error.details.reason === value;
}
