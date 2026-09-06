import assert from "node:assert/strict";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import { chromium, firefox } from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4197/bh03/";
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? "/tmp/blazex-bh03-phase6-browser-matrix.json";
const scenarioSet = Object.freeze([
  "verified-profile-startup",
  "shared-runtime-two-root-lifecycle",
  "identity-mismatch-fallback",
  "unsupported-prerequisite-fallback",
  "registry-owned-shutdown",
]);
const browsers = [
  { name: "chrome", engine: chromium, executable: process.env.BLAZEX_CHROME_PATH },
  { name: "firefox", engine: firefox, executable: process.env.BLAZEX_FIREFOX_PATH },
];

const evidence = {
  schema_version: "1.0.0",
  evidence_id: "BX-BH03-PHASE-06-ACTIVE-BROWSER-MATRIX-0.1",
  captured_at: new Date().toISOString(),
  implementation_revision: process.env.BLAZEX_REVISION ?? "working-tree",
  platform: `${os.platform()} ${os.release()} ${os.arch()}`,
  node_version: process.version,
  playwright_core_version: "1.62.1",
  profile_url: baseUrl,
  scenario_set: scenarioSet,
  results: [],
  deferred: [
    { environment: "safari", state: "deferred-unavailable" },
    { environment: "mobile", state: "deferred-unavailable" },
    { environment: "physical-devices", state: "deferred-unavailable" },
    { environment: "second-host", state: "deferred-unavailable" },
    { environment: "manual-assistive-technology", state: "deferred-unavailable" },
  ],
  support_state: "unsupported",
};

for (const target of browsers) {
  const result = {
    browser: target.name,
    executable: target.executable ?? null,
    browser_version: null,
    scenario_set: scenarioSet,
    result: "running",
    observations: {},
    failures: [],
  };
  evidence.results.push(result);
  let browser;
  try {
    assert.ok(target.executable, `BLAZEX_${target.name.toUpperCase()}_PATH is required`);
    browser = await target.engine.launch({
      executablePath: target.executable,
      headless: true,
      ...(target.name === "chrome" ? { args: ["--no-sandbox", "--disable-dev-shm-usage"] } : {}),
    });
    result.browser_version = browser.version();
    result.observations.positive = await positiveScenario(browser);
    result.observations.identity_mismatch = await mismatchScenario(browser);
    result.observations.unsupported_prerequisite = await prerequisiteScenario(browser);
    result.result = "passed";
  } catch (error) {
    result.result = browser ? "failed" : "unavailable";
    result.failures.push(boundedError(error));
  } finally {
    await browser?.close();
  }
}

await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
const failures = evidence.results.filter((result) => result.result !== "passed");
if (failures.length > 0) {
  throw new Error(`BH-03 Phase 6 active matrix failed: ${failures.map((item) => `${item.browser}:${item.result}`).join(", ")}`);
}
assert.deepEqual(evidence.results.map((result) => result.scenario_set), [scenarioSet, scenarioSet]);
console.log(`BH-03 Phase 6 active browser matrix: PASS (${evidence.results.length} browsers; ${scenarioSet.length} scenarios each)`);
console.log(`Evidence: ${evidencePath}`);

async function positiveScenario(browser) {
  const context = await browser.newContext();
  const page = await context.newPage();
  const pageErrors = [];
  page.on("pageerror", (error) => pageErrors.push(boundedError(error)));
  const response = await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  assert.equal(response.status(), 200);
  assert.equal(response.headers()["cross-origin-opener-policy"], "same-origin");
  assert.equal(response.headers()["cross-origin-embedder-policy"], "require-corp");
  await page.waitForFunction(() => ["ready", "failed", "fallback"].includes(globalThis.__blazexBH03?.state), null, { timeout: 45_000 });
  const ready = await page.evaluate(async () => {
    const state = globalThis.__blazexBH03;
    const profile = await fetch("./profile-assets-manifest.json", { cache: "no-store" }).then((item) => item.json());
    const wasm = profile.artifacts.find((item) => item.path.endsWith("AtomVM.wasm"));
    const range = await fetch(wasm.path, { headers: { range: "bytes=0-7" } });
    const etagResponse = await fetch(wasm.path);
    const cached = await fetch(wasm.path, { headers: { "if-none-match": etagResponse.headers.get("etag") } });
    return {
      snapshot: state.snapshot,
      profile_manifest_id: profile.manifest_id,
      governed_files: profile.artifacts.length,
      range_status: range.status,
      range_bytes: (await range.arrayBuffer()).byteLength,
      etag_status: cached.status,
      isolated: globalThis.crossOriginIsolated,
      primary_parent: document.querySelector('[data-root="primary-root"]').parentElement.id,
      secondary_parent: document.querySelector('[data-root="secondary-root"]').parentElement.id,
      primary_text: document.querySelector('[data-root="primary-root"]').textContent,
      secondary_text: document.querySelector('[data-root="secondary-root"]').textContent,
    };
  });

  assert.equal(ready.snapshot.state, "ready", JSON.stringify(ready.snapshot));
  assert.equal(ready.snapshot.support_state, "unsupported");
  assert.equal(ready.snapshot.runtime_starts, 1);
  assert.deepEqual(ready.snapshot.checks, [
    "exact-manifest-and-prerequisites",
    "one-shared-runtime",
    "two-independent-root-registrations",
    "independent-mount",
    "update-and-move-isolation",
    "dispose-and-remount-isolation",
    "intentional-fallback-decisions",
    "elixir-runtime-root-acknowledgements",
  ]);
  assert.equal(ready.snapshot.registry.metrics.shares, 1);
  assert.equal(ready.snapshot.registry.metrics.mismatches, 1);
  assert.deepEqual(ready.snapshot.roots.states, { "primary-root": "ready", "secondary-root": "ready" });
  assert.equal(ready.snapshot.runtime_acknowledgement_count, 8);
  assert.deepEqual(ready.snapshot.fallbacks.map((item) => item.action), ["deployment-action", "static-content"]);
  assert.equal(ready.isolated, true);
  assert.equal(ready.primary_parent, "primary-slot");
  assert.equal(ready.secondary_parent, "alternate-slot");
  assert.match(ready.primary_text, /Primary remounted/);
  assert.match(ready.secondary_text, /Secondary moved/);
  assert.equal(ready.range_status, 206);
  assert.equal(ready.range_bytes, 8);
  assert.equal(ready.etag_status, 304);
  assert.equal(pageErrors.length, 0, JSON.stringify(pageErrors));

  await page.evaluate(() => globalThis.blazexBh03Stop());
  const stopped = await page.evaluate(() => globalThis.__blazexBH03.snapshot);
  assert.equal(stopped.state, "stopped");
  assert.equal(stopped.shutdown.acknowledged, true);
  assert.equal(stopped.shutdown.released, true);
  assert.equal(stopped.shutdown.root_failures, 0);
  assert.deepEqual(stopped.roots.states, { "primary-root": "disposed", "secondary-root": "disposed" });
  assert.equal(stopped.registry.metrics.shutdowns, 1);
  assert.equal(stopped.registry.metrics.shutdown_failures, 0);
  assert.equal(stopped.runtime_acknowledgement_count, 11);
  await context.close();

  return {
    profile_manifest_id: ready.profile_manifest_id,
    governed_files: ready.governed_files,
    runtime_starts: ready.snapshot.runtime_starts,
    shared_opens: ready.snapshot.registry.metrics.shares + 1,
    roots: ready.snapshot.roots.states,
    runtime_acknowledgements_before_shutdown: ready.snapshot.runtime_acknowledgement_count,
    runtime_acknowledgements_after_shutdown: stopped.runtime_acknowledgement_count,
    shutdown: stopped.shutdown,
    range_status: ready.range_status,
    etag_status: ready.etag_status,
  };
}

async function mismatchScenario(browser) {
  const context = await browser.newContext();
  await context.route("**/bh03/runtime-manifest.json", async (route) => {
    const response = await route.fetch();
    const body = await response.json();
    body.compatibility.renderer = "blazex.renderer/999";
    await route.fulfill({ response, json: body });
  });
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await page.waitForFunction(() => ["fallback", "failed"].includes(globalThis.__blazexBH03?.state), null, { timeout: 15_000 });
  const result = await page.evaluate(() => ({ state: globalThis.__blazexBH03.state, fallback: globalThis.__blazexBH03.fallback }));
  assert.equal(result.state, "fallback", JSON.stringify(result));
  assert.equal(result.fallback.failure_class, "identity-mismatch");
  assert.equal(result.fallback.action, "deployment-action");
  assert.equal(result.fallback.partial_activation, false);
  await context.close();
  return { state: result.state, failure_class: result.fallback.failure_class, action: result.fallback.action };
}

async function prerequisiteScenario(browser) {
  const context = await browser.newContext();
  await context.route("**/bh03/**", async (route) => {
    const response = await route.fetch();
    const headers = { ...response.headers() };
    delete headers["cross-origin-embedder-policy"];
    await route.fulfill({ response, headers });
  });
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await page.waitForFunction(() => ["fallback", "failed"].includes(globalThis.__blazexBH03?.state), null, { timeout: 15_000 });
  const result = await page.evaluate(() => ({ state: globalThis.__blazexBH03.state, fallback: globalThis.__blazexBH03.fallback, isolated: globalThis.crossOriginIsolated }));
  assert.equal(result.isolated, false);
  assert.equal(result.state, "fallback", JSON.stringify(result));
  assert.equal(result.fallback.failure_class, "unsupported-prerequisite");
  assert.equal(result.fallback.action, "static-content");
  assert.equal(result.fallback.partial_activation, false);
  await context.close();
  return { state: result.state, failure_class: result.fallback.failure_class, action: result.fallback.action };
}

function boundedError(error) {
  return {
    name: String(error?.name ?? "Error").slice(0, 64),
    message: String(error?.message ?? error).slice(0, 512),
    stack: String(error?.stack ?? "").split("\n").slice(0, 8).join("\n"),
  };
}
