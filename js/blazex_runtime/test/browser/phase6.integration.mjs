import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import { chromium } from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4199/bh01/";
const executablePath = process.env.BLAZEX_CHROME_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? "/tmp/blazex-bh01-phase6-browser-evidence.json";
if (!executablePath) throw new Error("BLAZEX_CHROME_PATH is required");

const browser = await chromium.launch({
  executablePath,
  headless: true,
  args: ["--no-sandbox", "--disable-dev-shm-usage"],
});

const evidence = {
  schema_version: "1.0.0",
  evidence_id: "BX-BH01-PHASE-06-TRUST-AND-ISOLATION-EVIDENCE-0.1",
  captured_at: new Date().toISOString(),
  implementation_parent_revision: process.env.BLAZEX_REVISION ?? "unrecorded",
  observed_patch_scope: "Phase 6 integration harness, evidence, and AtomVM compatibility fix are committed together after this parent.",
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
  adapter_capability: {},
  command_path: {},
  failure_matrix: {},
  cleanup: {},
  audit: [],
  findings: [],
  limitations: [],
};

try {
  const healthResponse = await fetch(new URL("/bh01/health", baseUrl));
  assert.equal(healthResponse.status, 200);
  const health = await healthResponse.json();
  assert.equal(health.liveview_adapter.status, "eligible");
  assert.deepEqual(health.liveview_adapter.versions, {
    phoenix_live_view: "1.2.11",
    local_live_view: "0.1.0",
  });
  evidence.adapter_capability = health.liveview_adapter;

  const context = await browser.newContext();
  const page = await context.newPage();
  const pageErrors = [];
  const serverRequests = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  page.on("request", (request) => {
    if (request.url().includes("/bh01/commands/")) {
      serverRequests.push({ method: request.method(), path: new URL(request.url()).pathname });
    }
  });

  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await ready(page);
  await resetAndEstablish(page, "operator");

  await page.locator("#bx-server-action").click();
  const clicked = await page.evaluate(() => globalThis.blazexBh01Fixture.settle());
  assert.equal(clicked.runtime.server.value, 1);
  assert.equal(clicked.runtime.server.version, 1);
  assert.equal(clicked.runtime.server.status, "accepted");
  assert.equal(node(clicked.dom, "bx-server-status").text, "Server counter: 1 (version 1)");

  const accepted = await serverCommand(page, {
    correlationId: "phase6-accepted",
    idempotencyKey: "phase6-replay",
    expectedVersion: 1,
  });
  assert.equal(accepted.result.status, "ok");
  assert.equal(accepted.result.result.value, 2);
  assert.equal(accepted.result.result.replayed, false);

  const replayed = await serverCommand(page, {
    correlationId: "phase6-accepted",
    idempotencyKey: "phase6-replay",
    expectedVersion: 1,
  });
  assert.equal(replayed.result.status, "ok");
  assert.equal(replayed.result.result.value, 2);
  assert.equal(replayed.result.result.replayed, true);

  const stale = await serverCommand(page, {
    correlationId: "phase6-stale",
    idempotencyKey: "phase6-stale",
    expectedVersion: 0,
  });
  assert.equal(errorCode(stale), "state-stale");

  const limited = await serverCommand(page, {
    correlationId: "phase6-limited",
    idempotencyKey: "phase6-limited",
    expectedVersion: 2,
  });
  assert.equal(errorCode(limited), "rate-limited");

  let state = await serverState(page);
  assert.deepEqual(state.resource, { id: "counter", value: 2, version: 2 });
  assert.equal(state.idempotency_count, 2);
  assert.deepEqual(state.audit.map(({ outcome }) => outcome), ["accepted", "accepted", "replayed", "state-stale", "rate-limited"]);
  assertNoSecrets(state);

  evidence.command_path = {
    normalized_dom_action: true,
    runtime_projection: clicked.runtime.server,
    rendered_status: node(clicked.dom, "bx-server-status").text,
    accepted: publicResult(accepted.result),
    replayed: publicResult(replayed.result),
    authoritative_resource: state.resource,
    correlated_audit: state.audit.map(publicAudit),
    server_request_count: serverRequests.length,
  };

  await restartFixture(page);
  await resetAndEstablish(page, "viewer");
  const unauthorized = await serverCommand(page, {
    correlationId: "phase6-viewer",
    idempotencyKey: "phase6-viewer",
    expectedVersion: 0,
  });
  assert.equal(errorCode(unauthorized), "authorization-denied");
  assert.equal((await serverState(page)).resource.value, 0);

  await restartFixture(page);
  await resetAndEstablish(page, "operator");
  await page.evaluate(() => globalThis.blazexBh01Fixture.expireSession());
  const expired = await serverCommand(page, {
    correlationId: "phase6-expired",
    idempotencyKey: "phase6-expired",
    expectedVersion: 0,
  });
  assert.equal(errorCode(expired), "session-invalid");
  assert.equal((await serverState(page)).resource.value, 0);

  await restartFixture(page);
  await resetAndEstablish(page, "operator");
  const transaction = await serverCommand(page, {
    correlationId: "phase6-transaction",
    idempotencyKey: "phase6-transaction",
    expectedVersion: 0,
    failureMode: "transaction-error",
  });
  assert.equal(errorCode(transaction), "transaction-failed");
  const unavailable = await serverCommand(page, {
    correlationId: "phase6-server-error",
    idempotencyKey: "phase6-server-error",
    expectedVersion: 0,
    failureMode: "server-error",
  });
  assert.equal(errorCode(unavailable), "server-unavailable");
  assert.equal((await serverState(page)).resource.value, 0);

  await page.route("**/bh01/commands/counter-increment", (route) => route.abort("failed"));
  const disconnected = await serverCommand(page, {
    correlationId: "phase6-disconnect",
    idempotencyKey: "phase6-disconnect",
    expectedVersion: 0,
  });
  assert.equal(errorCode(disconnected), "transport-unavailable");
  await page.unroute("**/bh01/commands/counter-increment");

  const retried = await serverCommand(page, {
    correlationId: "phase6-disconnect",
    idempotencyKey: "phase6-disconnect",
    expectedVersion: 0,
  });
  assert.equal(retried.result.status, "ok");
  assert.equal(retried.result.result.value, 1);

  await restartFixture(page);
  await resetAndEstablish(page, "operator");
  await page.route("**/bh01/commands/counter-increment", async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 2_000));
    await route.abort("timedout").catch(() => {});
  });
  const timedOut = await serverCommand(page, {
    correlationId: "phase6-timeout",
    idempotencyKey: "phase6-timeout",
    expectedVersion: 0,
  });
  assert.equal(errorCode(timedOut), "transport-timeout");
  await page.unroute("**/bh01/commands/counter-increment");
  assert.equal((await serverState(page)).resource.value, 0);

  await page.route("**/bh01/commands/counter-increment", async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.abort("failed").catch(() => {});
  });
  await page.evaluate(() => {
    globalThis.__bh01Phase6Pending = globalThis.blazexBh01Fixture.serverCommand({
      correlationId: "phase6-dispose",
      idempotencyKey: "phase6-dispose",
      expectedVersion: 0,
    });
  });
  await page.waitForTimeout(100);
  await page.evaluate(() => globalThis.blazexBh01Fixture.dispose());
  const disposedRequest = await page.evaluate(() => globalThis.__bh01Phase6Pending);
  assert.equal(disposedRequest.delivered, false);
  await page.unroute("**/bh01/commands/counter-increment");

  await page.evaluate(() => globalThis.blazexBh01Stop());
  const stopped = await page.evaluate(() => ({
    state: globalThis.__blazexBH01.state,
    resources: globalThis.__blazexBH01.final_resources,
  }));
  assert.equal(stopped.state, "stopped");
  assert.deepEqual(stopped.resources.dom, { roots: 0, listeners: 0, nodes: 0 });
  assert.equal(stopped.resources.bridge.pending, 0);
  assert.equal(stopped.resources.server.pending, 0);
  assert.equal(stopped.resources.server.session_configured, false);
  assert.deepEqual(stopped.resources.lifecycle.resources, {});
  assert.deepEqual(pageErrors, []);

  state = await serverState(page);
  assert.equal(state.resource.value, 0);
  assertNoSecrets(state);
  evidence.failure_matrix = {
    unauthorized: errorCode(unauthorized),
    expired: errorCode(expired),
    stale: errorCode(stale),
    rate_limited: errorCode(limited),
    transaction: errorCode(transaction),
    server_error: errorCode(unavailable),
    disconnect: errorCode(disconnected),
    retry_after_disconnect: retried.result.status,
    timeout: errorCode(timedOut),
    disposal_delivery: disposedRequest.delivered,
    unauthorized_effects: 0,
  };
  evidence.cleanup = stopped.resources;
  evidence.audit = state.audit.map(publicAudit);
  evidence.findings = [
    "The first browser run exposed the unavailable Erlang re NIF behind Regex.match?/2 in AtomVM; byte-level identifier validation replaced it and a source guard now prevents regression.",
    "A normalized DOM action crossed the Elixir runtime, bridge, same-origin transport, Phoenix endpoint, server authority, audit, and DOM result path.",
    "Server-owned session identity, authorization, current resource version, idempotency, rate, and side effect remained outside browser runtime state.",
    "Mismatch and failure outcomes were bounded; disconnect retry applied once and disposal aborted pending transport without delivering a late runtime result.",
    "The optional LiveView compatibility adapter reported only exact pinned eligibility and retained standalone-dom as its explicit fallback.",
  ];
  evidence.limitations = [
    "Only Chrome for Testing 152.0.7977.75 on this Linux x86-64 host was executed; every browser remains unsupported.",
    "The counter, identity store, adapter descriptor, patch protocol, and test controls are disposable BH-01 fixtures, not production or public APIs.",
    "LiveView/LocalLiveView private renderer behavior was compatibility-probed and isolated, not adopted as the BlazeX component or standalone DOM model.",
    "The Plug and headless results are static dependency boundaries; neither scaffold is an executable profile in BH-01.",
    "No performance, accessibility, production security, persistence, multi-node, proxy, or cross-browser claim is made.",
  ];
  evidence.status = "observed-pass";
  assertNoSecrets(evidence);
  evidence.evidence_sha256 = createHash("sha256").update(JSON.stringify({
    command_path: evidence.command_path,
    failure_matrix: evidence.failure_matrix,
    cleanup: evidence.cleanup,
  })).digest("hex");
  await context.close();
} catch (error) {
  evidence.status = "observed-fail";
  evidence.findings.push(error instanceof Error ? `${error.name}: ${error.message}` : String(error));
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 6 browser integration: ${evidence.status.toUpperCase()}`);
console.log(`Evidence: ${evidencePath}`);

async function ready(page) {
  await page.waitForFunction(() => globalThis.__blazexBH01?.state === "ready", null, { timeout: 30_000 });
}

async function restartFixture(page) {
  await page.evaluate(() => globalThis.blazexBh01Stop());
  await page.evaluate(() => globalThis.blazexBh01Start());
  await ready(page);
}

async function resetAndEstablish(page, identityId) {
  const reset = await page.evaluate(async () => {
    const response = await fetch("/bh01/test/reset", { method: "POST", headers: { "x-bh01-test-control": "enabled" } });
    return response.status;
  });
  assert.equal(reset, 200);
  const session = await page.evaluate((identity) => globalThis.blazexBh01Fixture.establishSession(identity), identityId);
  assert.equal(session.identity_id, identityId);
  assert.deepEqual(Object.keys(session).sort(), ["expires_at_ms", "identity_id"]);
}

async function serverCommand(page, options) {
  return page.evaluate((value) => globalThis.blazexBh01Fixture.serverCommand(value), options);
}

async function serverState(page) {
  return page.evaluate(async () => {
    const response = await fetch("/bh01/test/state", { headers: { "x-bh01-test-control": "enabled" } });
    if (!response.ok) throw new Error(`state request failed: ${response.status}`);
    return response.json();
  });
}

function node(snapshot, id) {
  const found = snapshot.nodes.find((item) => item.id === id);
  assert.ok(found, `missing DOM node ${id}`);
  return found;
}

function errorCode(command) {
  return command.result.error.code;
}

function publicResult(result) {
  return {
    status: result.status,
    correlation_id: result.correlation_id,
    result: result.result,
    error: result.error,
  };
}

function publicAudit(event) {
  return {
    sequence: event.sequence,
    identity_id: event.identity_id,
    correlation_id: event.correlation_id,
    command: event.command,
    outcome: event.outcome,
    effect_applied: event.effect_applied,
    resource_version: event.resource_version,
    idempotency_digest: event.idempotency_digest,
  };
}

function assertNoSecrets(value) {
  const encoded = JSON.stringify(value).toLowerCase();
  for (const forbidden of ["csrf_token", "session_id", "allowed_actions", "authorization_rule", "stacktrace", "cookie"]) {
    assert.equal(encoded.includes(forbidden), false, `forbidden diagnostic field: ${forbidden}`);
  }
}
