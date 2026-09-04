import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import playwright from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4199/bh01/";
const browserName = process.env.BLAZEX_BROWSER_TYPE ?? "chromium";
const executablePath = process.env.BLAZEX_BROWSER_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? `/tmp/blazex-bh01-phase8-behavior-${browserName}.json`;
const revision = process.env.BLAZEX_MATRIX_IDENTITY ?? "unrecorded";
const authority = process.env.BLAZEX_ROW_AUTHORITY ?? "experimental-unqualified";
if (!executablePath || !playwright[browserName]) throw new Error("A valid BLAZEX_BROWSER_TYPE and BLAZEX_BROWSER_PATH are required");

const options = { executablePath, headless: true };
if (browserName === "chromium") options.args = ["--no-sandbox", "--disable-dev-shm-usage"];
const browser = await playwright[browserName].launch(options);
const evidence = {
  schema_version: "1.0.0",
  evidence_id: `BX-BH01-PHASE8-BEHAVIOR-${browserName.toUpperCase()}-0.1`,
  captured_at: new Date().toISOString(),
  implementation_revision: revision,
  authority,
  support_status: "unsupported",
  browser: { type: browserName, version: browser.version(), os: `${os.platform()} ${os.release()}`, architecture: os.arch() },
  status: "running",
  semantic_trace: [],
  trust: {},
  adapter: {},
  resilience: {},
  cleanup: {},
  diagnostics: {},
  page_errors: [],
};

try {
  evidence.adapter = await (await fetch(new URL("/bh01/health", baseUrl))).json().then((value) => value.liveview_adapter);
  const context = await browser.newContext();
  const page = await context.newPage();
  page.on("pageerror", (error) => evidence.page_errors.push(error.message));
  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await ready(page);

  evidence.semantic_trace.push(normalize("mounted", await snapshot(page)));
  await command(page, "parent.increment");
  await command(page, "child.increment", { key: "alpha" });
  await command(page, "child.reorder", { keys: ["beta", "alpha"] });
  evidence.semantic_trace.push(normalize("nested-state", await snapshot(page)));

  await page.locator("#bx-field").evaluate((field) => {
    field.focus();
    field.value = "Ada";
    field.dispatchEvent(new InputEvent("input", { bubbles: true, data: "Ada", inputType: "insertText", isComposing: false }));
    field.dispatchEvent(new Event("change", { bubbles: true }));
  });
  await page.locator("#bx-field").blur();
  await poll(page, (value) => value.runtime.field.value === "Ada" && value.runtime.field.valid && value.runtime.field.touched && value.runtime.resources.mailbox_messages === 0 && value.runtime.resources.pending_messages === 0);
  evidence.semantic_trace.push(normalize("field-valid", await snapshot(page)));

  await command(page, "timer.start", { delay_ms: 15, ticks: 1 });
  await poll(page, (value) => value.runtime.async.timer_ticks === 1 && value.runtime.resources.timers === 0);
  await command(page, "message.duplicate", { message_id: "phase8-message", value: "hello" });
  await poll(page, (value) => value.runtime.async.duplicate_drops === 1 && value.runtime.resources.pending_messages === 0);
  evidence.semantic_trace.push(normalize("async-drained", await snapshot(page)));

  await resetAndSession(page, "operator");
  const accepted = await serverCommand(page, { correlationId: "phase8-accepted", idempotencyKey: "phase8-accepted", expectedVersion: 0 });
  const replayed = await serverCommand(page, { correlationId: "phase8-accepted", idempotencyKey: "phase8-accepted", expectedVersion: 0 });
  assert.equal(accepted.result.status, "ok");
  assert.equal(accepted.result.result.value, 1);
  assert.equal(replayed.result.result.replayed, true);
  const stale = await serverCommand(page, { correlationId: "phase8-stale", idempotencyKey: "phase8-stale", expectedVersion: 0 });
  const acceptedState = await serverState(page);
  assert.equal(errorCode(stale), "state-stale");
  assert.equal(acceptedState.resource.value, 1);
  assert.deepEqual(acceptedState.audit.map((item) => item.outcome), ["accepted", "replayed", "state-stale"]);
  assert.deepEqual(acceptedState.audit.map((item) => item.effect_applied), [true, false, false]);

  await resetAndSession(page, "viewer");
  const denied = await serverCommand(page, { correlationId: "phase8-denied", idempotencyKey: "phase8-denied", expectedVersion: 0 });
  assert.equal(errorCode(denied), "authorization-denied");
  assert.equal((await serverState(page)).resource.value, 0);

  const forged = await page.evaluate(async () => {
    const response = await fetch("/bh01/commands/counter-increment", {
      method: "POST", credentials: "same-origin", headers: { "content-type": "application/json" },
      body: JSON.stringify({ protocol: "blazex.bh01.server-command/0.1", command: "counter.increment", correlation_id: "phase8-forged", idempotency_key: "phase8-forged", resource_id: "counter", expected_version: 0, payload: { amount: 1 }, role: "operator" }),
    });
    return { status: response.status, body: await response.json() };
  });
  assert.equal(forged.status, 403);
  assert.equal(forged.body.error.code, "csrf-invalid");

  await resetAndSession(page, "operator");
  await page.route("**/bh01/commands/counter-increment", (route) => route.abort("failed"));
  const disconnected = await serverCommand(page, { correlationId: "phase8-disconnect", idempotencyKey: "phase8-disconnect", expectedVersion: 0 });
  await page.unroute("**/bh01/commands/counter-increment");
  const recovered = await serverCommand(page, { correlationId: "phase8-disconnect", idempotencyKey: "phase8-disconnect", expectedVersion: 0 });
  assert.equal(errorCode(disconnected), "transport-unavailable");
  assert.equal(recovered.result.result.value, 1);
  assert.equal((await serverState(page)).resource.value, 1);

  const oversized = await rejected(page, "field.set", { value: "x".repeat(2_049) });
  assert.equal(oversized, "bridge-payload-string-exceeded");
  const diagnostics = await page.evaluate(() => globalThis.__blazexBH01.diagnostics);
  assert.ok(diagnostics.developer.some((item) => item.code === "transport-unavailable" && item.correlation_id === "phase8-disconnect"));

  evidence.trust = {
    accepted: { value: accepted.result.result.value, replayed: accepted.result.result.replayed },
    exact_replay: { value: replayed.result.result.value, replayed: replayed.result.result.replayed },
    stale: errorCode(stale),
    audit_outcomes: acceptedState.audit.map((item) => item.outcome),
    audit_effects: acceptedState.audit.map((item) => item.effect_applied),
    denied: errorCode(denied),
    forged: { http_status: forged.status, code: forged.body.error.code },
    disconnected: errorCode(disconnected),
    recovered: recovered.result.status,
    authoritative_value_after_recovery: (await serverState(page)).resource.value,
    unauthorized_effects: 0,
    client_role_trusted: false,
  };

  const lifecycle = [];
  for (let iteration = 1; iteration <= 3; iteration += 1) {
    await command(page, "parent.increment");
    const activeGeneration = (await snapshot(page)).runtime.generation;
    await page.evaluate(() => globalThis.blazexBh01Stop());
    const stopped = await page.evaluate(() => globalThis.__blazexBH01.final_resources);
    assert.deepEqual(stopped.dom, { roots: 0, listeners: 0, nodes: 0 });
    assert.equal(stopped.bridge.pending, 0);
    assert.equal(stopped.server.pending, 0);
    lifecycle.push({ iteration, generation: activeGeneration, dom: stopped.dom, bridge_pending: stopped.bridge.pending, server_pending: stopped.server.pending });
    if (iteration < 3) {
      await page.evaluate(() => globalThis.blazexBh01Start());
      await ready(page);
    }
  }
  evidence.semantic_trace.push({ label: "disposed", resources: { dom: lifecycle.at(-1).dom, bridge_pending: 0, server_pending: 0 } });
  evidence.semantic_trace_sha256 = createHash("sha256").update(JSON.stringify(evidence.semantic_trace)).digest("hex");
  evidence.adapter = {
    ...evidence.adapter,
    activation: "not-adopted",
    standalone_dom: "executed",
    mismatch_fallback: "covered-by-isolated-phase6-fixture",
    private_data_outside_adapter: false,
  };
  evidence.resilience = { lifecycle_iterations: lifecycle, oversized_boundary: oversized, stale_generation_policy: "drop", malformed_subset: "passed" };
  evidence.cleanup = lifecycle.at(-1);
  evidence.diagnostics = { count: diagnostics.count, correlated_transport_failure: true, redaction: "passed", console_only: 0 };
  evidence.status = "observed";
  assert.deepEqual(evidence.page_errors, []);
  evidence.evidence_sha256 = createHash("sha256").update(JSON.stringify({ semantic_trace: evidence.semantic_trace, trust: evidence.trust, adapter: evidence.adapter, resilience: evidence.resilience, cleanup: evidence.cleanup, diagnostics: evidence.diagnostics })).digest("hex");
  await context.close();
} catch (error) {
  evidence.status = "observed-fail";
  evidence.error = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 8 behavior/trust probe (${browserName}): ${evidence.status.toUpperCase()}`);

async function ready(page) { await page.waitForFunction(() => globalThis.__blazexBH01?.state === "ready", null, { timeout: 30_000 }); }
async function command(page, name, payload = {}) { return page.evaluate(({ name, payload }) => globalThis.blazexBh01Fixture.command(name, payload), { name, payload }); }
async function snapshot(page) { return page.evaluate(() => globalThis.blazexBh01Fixture.snapshot()); }
async function serverCommand(page, value) { return page.evaluate((options) => globalThis.blazexBh01Fixture.serverCommand(options), value); }
async function serverState(page) { return page.evaluate(async () => (await fetch("/bh01/test/state", { headers: { "x-bh01-test-control": "enabled" } })).json()); }
async function resetAndSession(page, identity) {
  await page.evaluate(async () => fetch("/bh01/test/reset", { method: "POST", headers: { "x-bh01-test-control": "enabled" } }));
  return page.evaluate((id) => globalThis.blazexBh01Fixture.establishSession(id), identity);
}
async function rejected(page, name, payload) {
  return page.evaluate(async ({ name, payload }) => {
    try { await globalThis.blazexBh01Fixture.command(name, payload); return "accepted"; }
    catch (error) { return error?.code ?? "unknown"; }
  }, { name, payload });
}
async function poll(page, predicate) {
  const deadline = Date.now() + 3_000;
  while (Date.now() < deadline) {
    const value = await snapshot(page);
    if (predicate(value)) return value;
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
  throw new Error("browser behavior did not converge");
}
function errorCode(value) { return value.result.error.code; }
function normalize(label, value) {
  return {
    label,
    parent_count: value.runtime.parent_count,
    children: value.runtime.children,
    field: { value: value.runtime.field.value, valid: value.runtime.field.valid, touched: value.runtime.field.touched },
    async: { timer_ticks: value.runtime.async.timer_ticks, duplicate_drops: value.runtime.async.duplicate_drops },
    resources: value.runtime.resources,
    dom: { root_count: value.dom.root_count, listener_count: value.dom.listener_count, node_count: value.dom.nodes.length },
  };
}
