import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import playwright from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4199/bh01/";
const browserName = process.env.BLAZEX_BROWSER_TYPE ?? "chromium";
const executablePath = process.env.BLAZEX_BROWSER_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? `/tmp/blazex-bh01-phase8-compatibility-${browserName}.json`;
const revision = process.env.BLAZEX_MATRIX_IDENTITY ?? "unrecorded";
const authority = process.env.BLAZEX_ROW_AUTHORITY ?? "experimental-unqualified";
if (!executablePath || !playwright[browserName]) throw new Error("A valid BLAZEX_BROWSER_TYPE and BLAZEX_BROWSER_PATH are required");

const options = { executablePath, headless: true };
if (browserName === "chromium") options.args = ["--no-sandbox", "--disable-dev-shm-usage"];
const browser = await playwright[browserName].launch(options);
const evidence = {
  schema_version: "1.0.0",
  evidence_id: `BX-BH01-PHASE8-COMPATIBILITY-${browserName.toUpperCase()}-0.1`,
  captured_at: new Date().toISOString(),
  implementation_revision: revision,
  authority,
  support_status: "unsupported",
  browser: { type: browserName, version: browser.version(), os: `${os.platform()} ${os.release()}`, architecture: os.arch() },
  status: "running",
  exact_baseline: {},
  mismatch_scenarios: {},
  retained_server_adapter_evidence: {},
  cache_and_rollback: {},
  page_errors: [],
};

try {
  const baseline = await baselineObservation();
  evidence.exact_baseline = baseline;
  evidence.mismatch_scenarios.loader_manifest = await manifestFailure("loader-manifest", (manifest) => { manifest.schema_version = "2.0.0"; }, "manifest-schema-unsupported");
  evidence.mismatch_scenarios.runtime_bundle = await manifestFailure("runtime-bundle", (manifest) => { manifest.artifacts.find((item) => item.role === "application-bundle").sha256 = "0".repeat(64); }, "artifact-integrity-mismatch");
  evidence.mismatch_scenarios.artifact_cache = await manifestFailure("artifact-cache", (manifest) => { manifest.artifacts.find((item) => item.role === "runtime-wasm").sha256 = "f".repeat(64); }, "artifact-integrity-mismatch");
  evidence.mismatch_scenarios.browser_feature = await browserFeatureFailure();
  evidence.mismatch_scenarios.renderer_data = await rendererDataFailure();
  evidence.mismatch_scenarios.server_client_generation = await bridgeGenerationFailure();

  const after = await baselineObservation();
  assert.deepEqual(after.semantic_state, baseline.semantic_state);
  evidence.cache_and_rollback = {
    manifest_cache_control: baseline.manifest_cache_control,
    artifact_cache_control: baseline.artifact_cache_control,
    loader_fetch_policy: "no-store-manifest-and-artifacts",
    scoped_client_cache_owner: "none",
    cache_invalidation: "not-applicable-no-service-worker-or-client-cache",
    retry: "user-controlled-coherent-page-reload",
    fresh_baseline_after_mismatches: true,
    hidden_semantic_change: false,
  };
  evidence.retained_server_adapter_evidence = {
    phoenix: "1.8.13",
    phoenix_live_view: "1.2.11",
    local_live_view: "0.1.0",
    descriptor_mismatch: "covered-by-current-exunit-boundary-suite",
    adapter_disable: "standalone-dom",
    private_data_confinement: "packages/blazex_renderer_dom_liveview",
    adjacent_dependency_package_probe: "not-executed-no-locally-available-adjacent-package",
  };
  evidence.status = "observed";
  assert.deepEqual(evidence.page_errors, []);
  evidence.evidence_sha256 = createHash("sha256").update(JSON.stringify({ exact_baseline: evidence.exact_baseline, mismatch_scenarios: evidence.mismatch_scenarios, retained_server_adapter_evidence: evidence.retained_server_adapter_evidence, cache_and_rollback: evidence.cache_and_rollback })).digest("hex");
} catch (error) {
  evidence.status = "observed-fail";
  evidence.error = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 8 compatibility probe (${browserName}): ${evidence.status.toUpperCase()}`);

async function terminal(page) { await page.waitForFunction(() => ["ready", "failed", "fallback"].includes(globalThis.__blazexBH01?.state), null, { timeout: 30_000 }); }
async function baselineObservation() {
  const context = await browser.newContext();
  const page = await context.newPage();
  page.on("pageerror", (error) => evidence.page_errors.push(error.message));
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const value = await page.evaluate(async () => {
    const profileResponse = await fetch("./profile-assets-manifest.json", { cache: "no-store" });
    const profileBytes = new Uint8Array(await profileResponse.arrayBuffer());
    const profile = JSON.parse(new TextDecoder().decode(profileBytes));
    const profileDigest = await crypto.subtle.digest("SHA-256", profileBytes);
    const manifestResponse = await fetch("./runtime-manifest.json", { cache: "no-store" });
    const manifest = await manifestResponse.clone().json();
    const wasm = manifest.artifacts.find((item) => item.role === "runtime-wasm");
    const artifactResponse = await fetch(new URL(wasm.path, manifestResponse.url), { cache: "no-store" });
    const snapshot = await globalThis.blazexBh01Fixture.snapshot();
    return {
      state: globalThis.__blazexBH01.state,
      manifest_id: globalThis.__blazexBH01.activation.manifest_id,
      manifest_generation: globalThis.__blazexBH01.activation.manifest_generation,
      activation_generation: globalThis.__blazexBH01.activation.generation,
      profile_manifest_id: profile.manifest_id,
      profile_manifest_sha256: [...new Uint8Array(profileDigest)].map((byte) => byte.toString(16).padStart(2, "0")).join(""),
      profile_governed_files: profile.artifacts.length,
      manifest_cache_control: manifestResponse.headers.get("cache-control"),
      artifact_cache_control: artifactResponse.headers.get("cache-control"),
      semantic_state: { parent_count: snapshot.runtime.parent_count, children: snapshot.runtime.children.map(({ key, count }) => ({ key, count })), field: { value: snapshot.runtime.field.value, valid: snapshot.runtime.field.valid }, dom: { roots: snapshot.dom.root_count, nodes: snapshot.dom.node_count, listeners: snapshot.dom.listener_count } },
    };
  });
  assert.equal(value.state, "ready");
  await page.evaluate(() => globalThis.blazexBh01Stop());
  await context.close();
  return value;
}
async function manifestFailure(name, mutate, expectedCode) {
  const context = await browser.newContext();
  await context.route("**/bh01/runtime-manifest.json", async (route) => {
    const response = await route.fetch();
    const manifest = await response.json();
    mutate(manifest);
    await route.fulfill({ response, json: manifest, headers: { ...response.headers(), "cache-control": "no-store" } });
  });
  const page = await context.newPage();
  page.on("pageerror", (error) => evidence.page_errors.push(`${name}:${error.message}`));
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const value = await page.evaluate(() => {
    const status = document.querySelector("[data-bh01-status]");
    return { state: globalThis.__blazexBH01.state, code: globalThis.__blazexBH01.error?.code, runtime_ready: globalThis.__blazexBH01.events.some((event) => event.type === "runtime-ready"), loader_stopped: globalThis.__blazexBH01.loader?.lifecycle?.().state === "stopped", status_code: status?.dataset.code, status_correlation: status?.dataset.correlation, retry_visible: !document.querySelector("[data-bh01-retry]")?.hidden, fixture_children: document.querySelector("[data-bh01-fixture-host]")?.children.length };
  });
  assert.deepEqual(value, { state: "failed", code: expectedCode, runtime_ready: false, loader_stopped: true, status_code: expectedCode, status_correlation: "runtime-activation", retry_visible: true, fixture_children: 0 });
  await context.close();
  return { name, expected_code: expectedCode, ...value, detected_before_runtime_ready: true, partial_activation: false };
}
async function browserFeatureFailure() {
  const context = await browser.newContext();
  await context.addInitScript(() => Object.defineProperty(globalThis, "Worker", { value: undefined, configurable: true }));
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const value = await page.evaluate(() => ({ state: globalThis.__blazexBH01.state, decision: globalThis.__blazexBH01.prerequisites.decision, code: globalThis.__blazexBH01.prerequisites.reason, runtime_ready: globalThis.__blazexBH01.events.some((event) => event.type === "runtime-ready"), retry_visible: !document.querySelector("[data-bh01-retry]")?.hidden, fixture_children: document.querySelector("[data-bh01-fixture-host]")?.children.length }));
  assert.deepEqual(value, { state: "fallback", decision: "static-server-fallback", code: "browser-capability-missing", runtime_ready: false, retry_visible: true, fixture_children: 0 });
  await context.close();
  return { ...value, detected_before_runtime_ready: true, partial_activation: false };
}
async function rendererDataFailure() {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const value = await page.evaluate(async () => {
    const { FixtureDOMRenderer } = await import("./dom/fixture-dom-renderer.js");
    const target = document.createElement("div");
    document.body.append(target);
    const renderer = new FixtureDOMRenderer({ target, documentImpl: document, generation: 1 });
    const protocol = "blazex.bh01.dom/0.1";
    const effect = (operations, sequence = 1, generation = 1) => ({ protocol: "blazex.bh01.fixture-effect/0.1", generation, sequence, operations });
    const op = (name, values = {}, generation = 1) => ({ protocol, op: name, generation, ...values });
    renderer.apply(effect([op("root.mount", { id: "bx-fixture-root", test_id: "bx-test-root" }), op("node.upsert", { id: "bx-value", parent_id: "bx-fixture-root", kind: "text", text: "before" })]));
    let code;
    try { renderer.apply(effect([op("node.text", { id: "bx-value", text: "must-not-commit" }), op("node.text", { id: "bx-missing", text: "failure" })], 2)); }
    catch (error) { code = error?.code; }
    const text = renderer.snapshot().nodes.find(({ id }) => id === "bx-value").text;
    let stale;
    try { renderer.apply(effect([], 2, 2)); }
    catch (error) { stale = error?.code; }
    renderer.dispose("compatibility-probe");
    target.remove();
    return { code, stale_generation: stale, partial_text_after_failure: text, final_roots: renderer.snapshot().root_count };
  });
  assert.deepEqual(value, { code: "fixture-target-missing", stale_generation: "fixture-generation-stale", partial_text_after_failure: "before", final_roots: 0 });
  await page.evaluate(() => globalThis.blazexBh01Stop());
  await context.close();
  return { ...value, partial_activation: false };
}
async function bridgeGenerationFailure() {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const value = await page.evaluate(async () => {
    const { BrowserHostBridge } = await import("./js/host-bridge.js");
    const transport = {
      request: async (request) => ({ protocol: "blazex.host-bridge/1", type: "response", scenario_id: request.scenario_id, generation: request.generation + 1, correlation_id: request.correlation_id, sequence: request.sequence, status: "ok", result: {} }),
      cancel() {},
    };
    const bridge = new BrowserHostBridge({ transport, generation: 4, scenarioId: "phase8-generation" });
    let code;
    try { await bridge.request("runtime.echo", {}); }
    catch (error) { code = error?.code; }
    const metrics = bridge.metrics();
    bridge.stop("compatibility-probe");
    return { code, failures: metrics.failures, responses: metrics.responses, pending: metrics.pending };
  });
  assert.deepEqual(value, { code: "bridge-response-identity-mismatch", failures: 1, responses: 0, pending: 0 });
  await page.evaluate(() => globalThis.blazexBh01Stop());
  await context.close();
  return { ...value, partial_activation: false };
}
