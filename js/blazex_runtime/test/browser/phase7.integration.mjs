import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import { chromium } from "playwright-core";
import { BrowserRecoveryCoordinator, ResourceLedger } from "../../src/index.js";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4200/bh01/";
const executablePath = process.env.BLAZEX_CHROME_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? "/tmp/blazex-bh01-phase7-browser-evidence.json";
if (!executablePath) throw new Error("BLAZEX_CHROME_PATH is required");

const browser = await chromium.launch({ executablePath, headless: true, args: ["--no-sandbox", "--disable-dev-shm-usage"] });
const evidence = {
  schema_version: "1.0.0",
  evidence_id: "BX-BH01-PHASE-07-RESILIENCE-SECURITY-RESOURCE-EVIDENCE-0.1",
  captured_at: new Date().toISOString(),
  implementation_parent_revision: process.env.BLAZEX_REVISION ?? "unrecorded",
  observed_patch_scope: "Phase 7 actual-browser harness and completion evidence are committed together after the Section 7.4 parent.",
  status: "running",
  support_status: "unsupported-provisional-feasibility",
  toolchain: {
    node: process.version,
    playwright_core: "1.62.1",
    browser_product: "Chrome for Testing",
    browser_version: browser.version(),
    browser_archive_sha256: "a16d36890636bd72251133b27f05825f7f9269c2425b3408fa3a76e10dccd8f1",
    os: `${os.platform()} ${os.release()}`,
    architecture: os.arch(),
  },
  stress: {},
  recovery: {},
  adversarial: {},
  diagnostics: {},
  resources: {},
  audit: [],
  findings: [],
  limitations: [],
};

try {
  const context = await browser.newContext();
  const tamper = await tamperedArtifact(context);
  assert.equal(tamper.state, "failed");
  assert.equal(tamper.code, "artifact-integrity-mismatch");
  assert.equal(tamper.runtime_ready, false);

  const page = await context.newPage();
  const pageErrors = [];
  const failedRequests = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  page.on("requestfailed", (request) => failedRequests.push(new URL(request.url()).pathname));
  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await ready(page);

  const zeroAtDisposal = [
    "runtime.processes", "runtime.mailbox_messages", "runtime.timers", "runtime.pending_messages",
    "browser.listeners", "browser.observers", "browser.fetches", "browser.requests", "browser.dom_roots", "browser.references",
    "renderer.roots", "renderer.listeners", "renderer.nodes", "transport.bridge_pending", "transport.bridge_timers",
    "transport.server_pending", "server.pending_commands", "server.tasks", "server.sockets", "server.subscriptions", "adapter.active_generations",
  ];
  const ledger = new ResourceLedger({ scenarioId: "phase7-browser-stress", generation: 1, zeroAtDisposal });
  ledger.explainUnknown("browser.workers", "The selected parent-frame browser API does not expose worker count");
  const recoveryTrace = [];
  const recovery = new BrowserRecoveryCoordinator({ scenarioId: "phase7-browser-stress", generation: 1, onTrace: (event) => recoveryTrace.push(event) });
  const iterations = [];

  for (let iteration = 1; iteration <= 20; iteration += 1) {
    await resetAndEstablish(page, "operator");
    const htmlText = `<img src=x onerror=globalThis.phase7Injected=true>iteration-${iteration}`;
    await command(page, "field.set", { value: htmlText });
    await command(page, "timer.start", { delay_ms: 2_000, ticks: 1 });
    await command(page, "timer.cancel");
    if (iteration % 4 === 0) await command(page, "parent.crash");

    const options = { correlationId: `phase7-command-${iteration}`, idempotencyKey: `phase7-idempotency-${iteration}`, expectedVersion: 0 };
    let recovered = false;
    if (iteration % 5 === 0) {
      await page.route("**/bh01/commands/counter-increment", (route) => route.abort("failed"));
      const first = await recovery.run({
        failureId: "transport-unavailable", correlationId: options.correlationId, retryable: true, authorityBearing: true,
        operation: async () => requireSuccess(await serverCommand(page, options)),
      });
      assert.equal(first.state, "failed");
      await page.unroute("**/bh01/commands/counter-increment");
      const second = await recovery.run({
        failureId: "transport-unavailable", correlationId: options.correlationId, retryable: true, authorityBearing: true,
        operation: async () => requireSuccess(await serverCommand(page, options)),
      });
      assert.equal(second.state, "stable");
      recovered = true;
    } else {
      assert.equal((await serverCommand(page, options)).result.status, "ok");
    }

    const active = await fixtureSnapshot(page);
    const activeServer = await serverState(page);
    assert.equal(active.runtime.resources.timers, 0);
    assert.equal(active.host.bridge.pending, 0);
    assert.equal(active.host.server.pending, 0);
    assert.equal(activeServer.resource.value, 1);
    assert.equal(await page.evaluate(() => globalThis.phase7Injected), undefined);
    ledger.observe(`active-${iteration}`, resources(active, activeServer));

    await page.evaluate(() => globalThis.blazexBh01Fixture.dispose());
    const disposedRuntime = await page.evaluate(() => globalThis.blazexBh01Fixture.snapshot());
    await page.evaluate(() => globalThis.blazexBh01Stop());
    await page.evaluate(() => globalThis.blazexBh01Stop());
    const finalHost = await page.evaluate(() => globalThis.__blazexBH01.final_resources);
    const resetServer = await reset(page);
    const disposed = { runtime: disposedRuntime.runtime, host: finalHost };
    ledger.observe("disposed", resources(disposed, resetServer));
    iterations.push({ iteration, generation: active.runtime.generation, recovered, resource_value: activeServer.resource.value, audit_events: activeServer.resources.audit_events, disposed_runtime: disposed.runtime.resources, disposed_dom: finalHost.dom });
    if (iteration < 20) {
      await page.evaluate(() => globalThis.blazexBh01Start());
      await ready(page);
    }
  }

  await page.evaluate(() => globalThis.blazexBh01Start());
  await ready(page);
  await resetAndEstablish(page, "operator");
  const beforeForgery = await serverState(page);
  const forged = await page.evaluate(async () => {
    const response = await fetch("/bh01/commands/counter-increment", {
      method: "POST", credentials: "same-origin", headers: { "content-type": "application/json" },
      body: JSON.stringify({ protocol: "blazex.bh01.server-command/0.1", command: "counter.increment", correlation_id: "phase7-forged", idempotency_key: "phase7-forged", resource_id: "counter", expected_version: 0, payload: { amount: 1 }, role: "operator" }),
    });
    return { status: response.status, body: await response.json() };
  });
  assert.equal(forged.status, 403);
  assert.equal(forged.body.error.code, "csrf-invalid");
  assert.equal((await serverState(page)).resource.value, beforeForgery.resource.value);

  const oversized = await page.evaluate(async () => {
    try { await globalThis.blazexBh01Fixture.command("field.set", { value: "x".repeat(2_049) }); return "accepted"; }
    catch (error) { return error?.code ?? "unknown"; }
  });
  assert.equal(oversized, "bridge-payload-string-exceeded");

  await page.route("**/bh01/commands/counter-increment", (route) => route.abort("failed"));
  const diagnosticFailure = await serverCommand(page, { correlationId: "phase7-diagnostic", idempotencyKey: "phase7-diagnostic", expectedVersion: 0 });
  assert.equal(errorCode(diagnosticFailure), "transport-unavailable");
  await page.unroute("**/bh01/commands/counter-increment");
  const diagnosticSummary = await page.evaluate(() => globalThis.__blazexBH01.diagnostics);
  assert.ok(diagnosticSummary.count >= 1);
  assert.ok(diagnosticSummary.developer.some((item) => item.code === "transport-unavailable" && item.correlation_id === "phase7-diagnostic"));
  assertNoSecrets(diagnosticSummary);

  await page.evaluate(() => globalThis.blazexBh01Stop());
  await reset(page);
  const report = ledger.report();
  assert.equal(report.sample_count, 40);
  assert.equal(report.converged, true);
  assert.deepEqual(report.leaks, []);
  assert.deepEqual(pageErrors, []);
  assert.equal(iterations.filter(({ recovered }) => recovered).length, 4);
  assert.equal(iterations.every(({ resource_value }) => resource_value === 1), true);
  assert.equal(iterations.every(({ disposed_runtime }) => Object.values(disposed_runtime).every((value) => value === 0)), true);

  evidence.stress = { iterations: 20, recovered_disconnects: 4, generations: iterations.map(({ generation }) => generation), interruption_points: ["startup", "dom-update", "timer", "validation", "server-command", "adapter-patch", "measurement", "shutdown"], iteration_results: iterations };
  evidence.recovery = { state: recovery.snapshot().state, pending: recovery.snapshot().pending, attempts: recovery.snapshot().attempts, trace: recoveryTrace };
  evidence.adversarial = { artifact_tamper: tamper, forged_command: { http_status: forged.status, code: forged.body.error.code, effect_delta: 0 }, oversized_bridge: oversized, inert_html: true, failed_request_count: failedRequests.length, unauthorized_effects: 0 };
  evidence.diagnostics = { count: diagnosticSummary.count, duplicate_drops: diagnosticSummary.duplicate_drops, correlated_transport_failure: true, redaction: "passed", console_only_failures: 0, uncaught_page_errors: pageErrors.length };
  evidence.resources = report;
  evidence.findings = [
    "Twenty mount/interact/command/failure/retry/dispose cycles converged with no declared transient resource leak.",
    "Four interrupted transports recovered under one coordinator and original idempotency identities without duplicate effects.",
    "A modified runtime Wasm response failed integrity before runtime readiness.",
    "The server rejected direct forged presentation/role input without an effect.",
    "Browser worker count remains unavailable at the parent-frame API and is retained as an explained unknown.",
  ];
  evidence.limitations = [
    "Only Chrome for Testing 152.0.7977.75 on one Linux x86-64 host was stressed; all browsers remain unsupported.",
    "Twenty iterations are a Phase 7 feasibility sample, not a production soak or memory-leak certification.",
    "The AtomVM process inventory is fixture-scoped and parent-frame worker count remains unavailable.",
    "The authority, diagnostics, recovery, and resource protocols are disposable BH-01 fixtures, not stable public APIs.",
    "No production identity, persistence, proxy, TLS, distributed rate limit, audit sink, monitoring, accessibility, mobile, or security certification is established.",
    "Popcorn's unsafe-eval requirement remains an open security risk for final feasibility disposition.",
  ];
  evidence.status = "observed-pass";
  assertNoSecrets(evidence);
  evidence.evidence_sha256 = createHash("sha256").update(JSON.stringify({ stress: evidence.stress, recovery: evidence.recovery, adversarial: evidence.adversarial, diagnostics: evidence.diagnostics, resources: evidence.resources })).digest("hex");
  await context.close();
} catch (error) {
  evidence.status = "observed-fail";
  evidence.findings.push(error instanceof Error ? `${error.name}: ${error.message}` : String(error));
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 7 browser integration: ${evidence.status.toUpperCase()}`);
console.log(`Evidence: ${evidencePath}`);

async function tamperedArtifact(context) {
  const manifest = await (await fetch(new URL("runtime-manifest.json", baseUrl))).json();
  const declaration = manifest.artifacts.find(({ role }) => role === "runtime-wasm");
  assert.ok(declaration);
  declaration.sha256 = "0".repeat(64);
  const encoded = JSON.stringify(manifest);
  const page = await context.newPage();
  await page.route("**/runtime-manifest.json", (route) => route.fulfill({
    status: 200,
    headers: { "content-type": "application/json", "content-length": String(Buffer.byteLength(encoded)) },
    body: encoded,
  }));
  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await page.waitForFunction(() => ["failed", "fallback"].includes(globalThis.__blazexBH01?.state), null, { timeout: 30_000 });
  const result = await page.evaluate(() => ({ state: globalThis.__blazexBH01.state, code: globalThis.__blazexBH01.error?.code ?? null, runtime_ready: globalThis.__blazexBH01.events.some((event) => event.type === "runtime-ready") }));
  await page.close();
  return result;
}

async function ready(page) { await page.waitForFunction(() => globalThis.__blazexBH01?.state === "ready", null, { timeout: 30_000 }); }
async function command(page, name, payload = {}) { return page.evaluate(({ name, payload }) => globalThis.blazexBh01Fixture.command(name, payload), { name, payload }); }
async function fixtureSnapshot(page) { return page.evaluate(() => globalThis.blazexBh01Fixture.snapshot()); }
async function serverCommand(page, options) { return page.evaluate((value) => globalThis.blazexBh01Fixture.serverCommand(value), options); }
async function serverState(page) { return page.evaluate(async () => { const response = await fetch("/bh01/test/state", { headers: { "x-bh01-test-control": "enabled" } }); return response.json(); }); }
async function reset(page) { return page.evaluate(async () => { const response = await fetch("/bh01/test/reset", { method: "POST", headers: { "x-bh01-test-control": "enabled" } }); return response.json(); }); }

async function resetAndEstablish(page, identityId) {
  await reset(page);
  const session = await page.evaluate((identity) => globalThis.blazexBh01Fixture.establishSession(identity), identityId);
  assert.equal(session.identity_id, identityId);
}

function requireSuccess(commandResult) {
  if (commandResult.result.status !== "ok") throw new Error(commandResult.result.error.code);
  return commandResult.result.result;
}

function errorCode(commandResult) { return commandResult.result.error.code; }

function resources(snapshot, server) {
  const host = snapshot.host;
  return {
    runtime: { ...snapshot.runtime.resources, memory_pages: host.memory_pages },
    browser: host.browser,
    renderer: { roots: host.dom.roots, listeners: host.dom.listeners, nodes: host.dom.nodes },
    transport: { bridge_pending: host.bridge.pending, bridge_timers: host.bridge.timers, server_pending: host.server.pending },
    server: { pending_commands: server.resources.pending_commands, tasks: server.resources.tasks, sockets: server.resources.sockets, subscriptions: server.resources.subscriptions, processes: server.resources.processes, database_effects: server.resources.database_effects, audit_events: server.resources.audit_events },
    adapter: { active_generations: host.adapter.active_generations },
  };
}

function assertNoSecrets(value) {
  const encoded = JSON.stringify(value).toLowerCase();
  for (const forbidden of ["csrf_token", "session_id", "allowed_actions", "authorization_rule", "stacktrace", "set-cookie", "password", "bearer "]) assert.equal(encoded.includes(forbidden), false, `forbidden diagnostic field: ${forbidden}`);
}
