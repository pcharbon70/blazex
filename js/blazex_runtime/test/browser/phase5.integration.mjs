import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import { chromium } from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4198/bh01/";
const executablePath = process.env.BLAZEX_CHROME_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? "/tmp/blazex-bh01-phase5-browser-evidence.json";
if (!executablePath) throw new Error("BLAZEX_CHROME_PATH is required");

const browser = await chromium.launch({ executablePath, headless: true, args: ["--no-sandbox", "--disable-dev-shm-usage"] });
const evidence = {
  schema_version: "1.0.0",
  evidence_id: "BX-BH01-PHASE-05-LOCAL-BROWSER-EVIDENCE-0.1",
  captured_at: new Date().toISOString(),
  implementation_parent_revision: process.env.BLAZEX_REVISION ?? "unrecorded",
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
  deployment: {},
  runs: [],
  canonical_trace: [],
  repeatability: {},
  adapter_negative_scenarios: {},
  proofs: {},
  findings: [],
  limitations: [],
};

try {
  evidence.deployment = await verifyDeployment();
  const first = await runLocalVerticalSlice("repeat-1");
  const second = await runLocalVerticalSlice("repeat-2");
  evidence.canonical_trace = first.trace;
  evidence.runs = [withoutTrace(first), withoutTrace(second)];
  if (first.trace_sha256 !== second.trace_sha256) {
    const index = first.trace.findIndex((item, position) => JSON.stringify(item) !== JSON.stringify(second.trace[position]));
    evidence.repeatability = {
      equivalent: false,
      first_sha256: first.trace_sha256,
      second_sha256: second.trace_sha256,
      first_mismatch_index: index,
      first: first.trace[index],
      second: second.trace[index],
    };
  }
  assert.equal(first.trace_sha256, second.trace_sha256, "normalized local traces differ");
  evidence.repeatability = {
    equivalent: true,
    comparison: "byte-identical SHA-256 of normalized semantic checkpoints",
    trace_sha256: first.trace_sha256,
    checkpoint_count: first.trace.length,
  };
  evidence.adapter_negative_scenarios = first.adapter_negative_scenarios;
  evidence.proofs = {
    "BX-BH01-PROOF-NESTED-STATE": { status: "provisional-pass", final_closure: "Phases 7 and 8" },
    "BX-BH01-PROOF-FORM-EVENT": { status: "provisional-pass", final_closure: "Phases 6 and 8" },
    "BX-BH01-PROOF-TIMER-MESSAGE": { status: "provisional-pass", final_closure: "Phases 7 and 8" },
    "BX-BH01-PROOF-DOM-UPDATE": { status: "provisional-pass", final_closure: "Phases 8 and 9" },
  };
  evidence.findings = [
    "Elixir-authored state, keyed nesting, form validation, timers, and process messages produced bounded DOM operations in the pinned browser runtime.",
    "Two independent executions produced byte-identical normalized semantic traces and no local-behavior network request after readiness.",
    "A replacement activation used generation 2 and completed an AtomVM timer without accepting generation-1 ownership.",
    "Explicit stop converged fixture, DOM, bridge, and lifecycle ownership; renderer negatives failed before partial mutation.",
  ];
  evidence.limitations = [
    "Only Chrome for Testing 152.0.7977.75 on this Linux x86-64 host was executed; every browser remains unsupported.",
    "Fixture protocols and DOM operations are disposable BH-01 test boundaries, not public BlazeX component, tree, renderer, capability, effect, or forms APIs.",
    "Phoenix serves static governed assets only; no authenticated command, LiveView, LocalLiveView, server validation, or server authority behavior is established.",
    "Timings are preliminary observations only and no startup, interaction, cleanup, payload, memory, CPU, reliability, accessibility, or mobile budget passed.",
    "Wasm memory is fixed at 256 pages in this profile; the parent frame does not expose worker count or runtime-wide process inventory.",
    "Accessible role/name/relationship and keyboard observations were made without assistive technology and do not establish accessibility compliance.",
    "Popcorn 0.3.3 still requires CSP unsafe-eval; security and adversarial lifecycle closure remain Phase 7 work.",
  ];
  evidence.status = "observed-pass";
} catch (error) {
  evidence.status = "observed-fail";
  evidence.findings.push(error instanceof Error ? `${error.name}: ${error.message}` : String(error));
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 5 browser integration: ${evidence.status.toUpperCase()}`);
console.log(`Evidence: ${evidencePath}`);

async function verifyDeployment() {
  const response = await fetch(new URL("profile-assets-manifest.json", baseUrl));
  assert.equal(response.status, 200);
  const profile = await response.json();
  assert.equal(profile.manifest_id, "BX-BH01-PHASE-05-PROFILE-ASSETS-0.1");
  const artifacts = [];
  for (const record of profile.artifacts) {
    const artifactResponse = await fetch(new URL(record.path, baseUrl), { cache: "no-store" });
    assert.equal(artifactResponse.status, 200, record.path);
    const bytes = new Uint8Array(await artifactResponse.arrayBuffer());
    assert.equal(bytes.byteLength, record.bytes, record.path);
    assert.equal(createHash("sha256").update(bytes).digest("hex"), record.sha256, record.path);
    artifacts.push({ path: record.path, bytes: record.bytes, sha256: record.sha256, mime: record.mime, cache: record.cache });
  }
  return { manifest_id: profile.manifest_id, governed_files: artifacts.length, source_maps: profile.source_maps, artifacts };
}

async function runLocalVerticalSlice(runId) {
  const context = await browser.newContext();
  const page = await context.newPage();
  const requests = [];
  const pageErrors = [];
  page.on("request", (request) => requests.push({ method: request.method(), path: normalizedUrl(request.url()) }));
  page.on("pageerror", (error) => pageErrors.push(error.message));
  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await page.waitForFunction(() => globalThis.__blazexBH01?.state === "ready", null, { timeout: 30_000 });
  await page.waitForLoadState("networkidle");
  const behaviorRequestStart = requests.length;
  const trace = [];
  const failures = {};

  await checkpoint(page, trace, "mounted");
  await command(page, trace, "parent-increment", "parent.increment");
  await command(page, trace, "child-alpha-increment", "child.increment", { key: "alpha" });
  await command(page, trace, "child-gamma-insert", "child.insert", { key: "gamma" });
  await command(page, trace, "child-reorder", "child.reorder", { keys: ["gamma", "beta", "alpha"] });
  await command(page, trace, "child-replace", "child.replace", { old_key: "beta", new_key: "delta" });
  await command(page, trace, "child-remove", "child.remove", { key: "gamma" });
  await command(page, trace, "child-crash", "child.crash", { key: "alpha" });
  await command(page, trace, "child-late-output", "child.late-output", { key: "alpha", generation: 999 });
  failures.duplicate_child = await rejected(page, "command", "child.insert", { key: "alpha" });
  failures.missing_child = await rejected(page, "command", "child.increment", { key: "missing" });
  assert.equal(failures.duplicate_child, "fixture-child-duplicate");
  assert.equal(failures.missing_child, "fixture-child-missing");
  await command(page, trace, "parent-crash", "parent.crash");

  await page.locator("#bx-field").focus();
  await pollSnapshot(page, (snapshot) => snapshot.runtime.field.focused);
  await dispatchInput(page, "A", true);
  await pollSnapshot(page, (snapshot) => snapshot.runtime.field.composing && snapshot.runtime.field.value === "A");
  await dispatchInput(page, "A", false);
  await dispatchInput(page, "Ad", false);
  await dispatchInput(page, "Ada", false);
  await pollSnapshot(page, (snapshot) => snapshot.runtime.field.value === "Ada" && snapshot.runtime.field.valid);
  await dispatchInput(page, "Ada", false);
  await page.locator("#bx-field").evaluate((field) => field.dispatchEvent(new Event("change", { bubbles: true })));
  await page.locator("#bx-field").blur();
  await pollSnapshot(page, (snapshot) => snapshot.runtime.field.touched && !snapshot.runtime.field.focused);
  await checkpoint(page, trace, "form-valid-blurred");
  await dispatchInput(page, "", false);
  await pollSnapshot(page, (snapshot) => snapshot.runtime.field.value === "" && !snapshot.runtime.field.valid);
  await checkpoint(page, trace, "form-empty-invalid");

  await command(page, trace, "field-programmatic", "field.set", { value: "Grace" });
  const revision = (await fixtureSnapshot(page)).runtime.field.validation_revision;
  await command(page, trace, "field-stale-validation", "field.validation-result", { revision: revision - 1, value: "Grace" });
  await command(page, trace, "field-disabled", "field.disabled", { value: true });
  failures.disabled_input = await rejected(page, "event", "input", eventRecord("input", { value: "blocked", is_composing: false, input_type: "insertText" }, 80));
  await command(page, trace, "field-enabled", "field.disabled", { value: false });
  await command(page, trace, "field-read-only", "field.read-only", { value: true });
  failures.read_only_input = await rejected(page, "event", "change", eventRecord("change", { value: "blocked", is_composing: false, input_type: "unknown" }, 81));
  await command(page, trace, "field-writable", "field.read-only", { value: false });
  failures.malformed_event = await rejected(page, "event", "input", eventRecord("input", { value: "missing-flags" }, 82));
  failures.oversized_value = await rejected(page, "command", "field.set", { value: "x".repeat(2_049) });
  assert.deepEqual(failures, {
    duplicate_child: "fixture-child-duplicate",
    missing_child: "fixture-child-missing",
    disabled_input: "fixture-field-disabled",
    read_only_input: "fixture-field-read-only",
    malformed_event: "fixture-field-event-invalid",
    oversized_value: "bridge-payload-string-exceeded",
  });
  await page.locator("#bx-field-reset").click();
  await pollSnapshot(page, (snapshot) => snapshot.runtime.field.value === "" && snapshot.runtime.field.error === "Name is required");
  await checkpoint(page, trace, "form-reset");

  await executeCommand(page, "timer.start", { delay_ms: 15, ticks: 3 });
  await pollSnapshot(page, (snapshot) => snapshot.runtime.async.timer_ticks === 3 && snapshot.runtime.resources.timers === 0);
  await checkpoint(page, trace, "timer-complete");
  await executeCommand(page, "timer.start", { delay_ms: 2_000, ticks: 2 });
  await executeCommand(page, "timer.cancel");
  await checkpoint(page, trace, "timer-cancelled-stable");
  await executeCommand(page, "timer.start", { delay_ms: 2_000, ticks: 1 });
  await executeCommand(page, "timer.crash");
  await executeCommand(page, "timer.start", { delay_ms: 15, ticks: 1 });
  await pollSnapshot(page, (snapshot) => snapshot.runtime.async.timer_ticks === 1 && snapshot.runtime.resources.timers === 0);
  await checkpoint(page, trace, "timer-retry-complete");
  await executeCommand(page, "message.duplicate", { message_id: "message-one", value: "hello" });
  await executeCommand(page, "message.late", { message_id: "message-late", value: "late", generation: 999 });
  await pollSnapshot(page, (snapshot) => snapshot.runtime.resources.pending_messages === 0 && snapshot.runtime.async.duplicate_drops === 1);
  await checkpoint(page, trace, "messages-drained");
  await command(page, trace, "renderer-no-op", "snapshot");

  await command(page, trace, "preservation-field", "field.set", { value: "Ada" });
  await command(page, trace, "preservation-timer", "timer.start", { delay_ms: 2_000, ticks: 1 });
  await command(page, trace, "preservation-parent-crash", "parent.crash");
  const preserved = await fixtureSnapshot(page);
  assert.equal(preserved.runtime.field.value, "Ada");
  assert.equal(preserved.runtime.resources.timers, 1);
  await command(page, trace, "preservation-timer-cancel", "timer.cancel");

  const accessibility = await accessibilitySnapshot(page);
  assert.equal(accessibility.textbox_name, "Name");
  assert.equal(accessibility.alert_role_count, 1);
  assert.deepEqual(accessibility.relationships, { described_by: "bx-field-help bx-field-error", error_message: "bx-field-error" });
  assert.ok(accessibility.tab_order.includes("bx-field"));
  assert.ok(accessibility.tab_order.includes("bx-field-reset"));
  await page.evaluate(() => globalThis.blazexBh01Fixture.settle());

  const adapterNegative = await adapterNegatives(page);
  assert.deepEqual(adapterNegative.codes, {
    duplicate_listener: "fixture-listener-duplicate",
    missing_target: "fixture-target-missing",
    oversized_value: "fixture-value-exceeded",
    partial_batch: "fixture-target-missing",
    post_disposal: "fixture-renderer-disposed",
    stale_generation: "fixture-generation-stale",
  });
  assert.equal(adapterNegative.partial_text_after_failure, "before");

  const behaviorRequests = requests.slice(behaviorRequestStart);
  assert.deepEqual(behaviorRequests, []);
  const beforeStop = await fixtureSnapshot(page);
  assert.equal(beforeStop.runtime.resources.pending_messages, 0);
  assert.equal(beforeStop.runtime.resources.mailbox_messages, 0);
  assert.equal(beforeStop.host.bridge.pending, 0);
  await page.evaluate(() => { globalThis.__bh01OldFixture = globalThis.blazexBh01Fixture; });
  await executeCommand(page, "timer.start", { delay_ms: 2_000, ticks: 2 });
  await executeCommand(page, "message.send", { message_id: "final-message", value: "queued" });
  await page.evaluate(() => globalThis.blazexBh01Stop());
  const firstStop = await stoppedSnapshot(page);
  assertStopped(firstStop);
  failures.post_disposal = await page.evaluate(async () => {
    try { await globalThis.__bh01OldFixture.command("parent.increment"); return "accepted"; }
    catch (error) { return error?.code ?? "unknown"; }
  });
  assert.equal(failures.post_disposal, "bridge-stopped");

  await page.evaluate(() => globalThis.blazexBh01Start());
  await page.waitForFunction(() => globalThis.__blazexBH01?.state === "ready" && globalThis.__blazexBH01?.activation?.generation === 2, null, { timeout: 30_000 });
  await executeCommand(page, "timer.start", { delay_ms: 15, ticks: 1 });
  await pollSnapshot(page, (snapshot) => snapshot.runtime.generation === 2 && snapshot.runtime.async.timer_ticks === 1 && snapshot.runtime.resources.timers === 0);
  await checkpoint(page, trace, "generation-2-complete");
  await page.evaluate(() => globalThis.blazexBh01Stop());
  const restartStop = await stoppedSnapshot(page);
  assertStopped(restartStop);

  const timing = await page.evaluate(() => globalThis.__blazexBH01.timing_observations.map((item) => Object.fromEntries(Object.entries(item).map(([key, value]) => [key, typeof value === "number" ? Math.round(value * 1_000) / 1_000 : value]))));
  assert.ok(timing.some(({ kind }) => kind === "effect-to-dom"));
  assert.ok(timing.some(({ kind }) => kind === "command"));
  assert.deepEqual(pageErrors, []);
  const traceSha256 = createHash("sha256").update(JSON.stringify(trace)).digest("hex");
  const networkPaths = [...new Set(requests.map(({ path }) => path))].sort();
  const declaredPaths = new Set([new URL(baseUrl).pathname, ...evidence.deployment.artifacts.map(({ path }) => new URL(path, baseUrl).pathname)]);
  assert.deepEqual(networkPaths.filter((path) => !declaredPaths.has(path) && !path.startsWith("blob:")), []);
  await context.close();
  return {
    run_id: runId,
    status: "passed",
    trace,
    trace_sha256: traceSha256,
    failures,
    behavior_network_requests: behaviorRequests,
    network_paths: networkPaths,
    accessibility,
    timing_observations: timing,
    first_stop: firstStop,
    replacement_generation: 2,
    replacement_stop: restartStop,
    adapter_negative_scenarios: adapterNegative,
    page_errors: pageErrors,
  };
}

async function command(page, trace, label, name, payload = {}) {
  const result = await executeCommand(page, name, payload);
  trace.push(semanticCheckpoint(label, result));
  return result;
}

async function executeCommand(page, name, payload = {}) {
  return page.evaluate(({ commandName, commandPayload }) => globalThis.blazexBh01Fixture.command(commandName, commandPayload), { commandName: name, commandPayload: payload });
}

async function checkpoint(page, trace, label) {
  const snapshot = await fixtureSnapshot(page);
  trace.push(semanticCheckpoint(label, snapshot));
  return snapshot;
}

async function fixtureSnapshot(page) {
  return page.evaluate(() => globalThis.blazexBh01Fixture.snapshot());
}

async function dispatchInput(page, value, composing) {
  await page.locator("#bx-field").evaluate((field, values) => {
    field.value = values.value;
    field.dispatchEvent(new InputEvent("input", { bubbles: true, data: values.value, inputType: "insertText", isComposing: values.composing }));
  }, { value, composing });
}

async function pollSnapshot(page, predicate, timeoutMs = 3_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const snapshot = await fixtureSnapshot(page);
    if (predicate(snapshot)) return snapshot;
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
  throw new Error("fixture snapshot did not converge");
}

async function rejected(page, kind, name, payload) {
  return page.evaluate(async (request) => {
    try {
      if (request.kind === "command") await globalThis.blazexBh01Fixture.command(request.name, request.payload);
      else await globalThis.blazexBh01Fixture.event(request.payload);
      return "accepted";
    } catch (error) {
      return error?.code ?? "unknown";
    }
  }, { kind, name, payload });
}

function eventRecord(event, payload, sequence) {
  return {
    protocol: "blazex.bh01.fixture-event/0.1",
    record_type: "event",
    scenario_id: "BX-BH01-SCENARIO-LOCAL-BROWSER",
    generation: 1,
    sequence,
    node_id: "bx-field",
    event,
    payload,
  };
}

function semanticCheckpoint(label, result) {
  const runtime = result.runtime;
  const dom = result.dom;
  return {
    label,
    generation: runtime.generation,
    sequence: runtime.sequence,
    parent_count: runtime.parent_count,
    parent_restarts: runtime.parent_restarts,
    children: runtime.children,
    field: runtime.field,
    async: runtime.async,
    resources: runtime.resources,
    stale_drops: runtime.stale_drops,
    failures: runtime.failures,
    dom: {
      generation: dom.generation,
      sequence: dom.sequence,
      disposed: dom.disposed,
      root_count: dom.root_count,
      node_count: dom.node_count,
      listener_count: dom.listener_count,
      focused_node_id: dom.focused_node_id,
      nodes: dom.nodes.map(({ id, kind, text, value, disabled, read_only, invalid, described_by, error_message, role, accessible_name, parent_id }) => ({ id, kind, text, value, disabled, read_only, invalid, described_by, error_message, role, accessible_name, parent_id })),
    },
  };
}

async function accessibilitySnapshot(page) {
  const observed = await fixtureSnapshot(page);
  const fieldObservation = observed.dom.nodes.find(({ id }) => id === "bx-field");
  assert.equal(await page.getByRole("textbox", { name: "Name" }).count(), 1);
  await page.evaluate(() => document.activeElement?.blur());
  const tabOrder = [];
  for (let index = 0; index < 6; index += 1) {
    await page.keyboard.press("Tab");
    tabOrder.push(await page.evaluate(() => document.activeElement?.id ?? "none"));
  }
  return {
    textbox_name: fieldObservation.accessible_name,
    alert_role_count: await page.getByRole("alert").count(),
    relationships: await page.locator("#bx-field").evaluate((field) => ({ described_by: field.getAttribute("aria-describedby"), error_message: field.getAttribute("aria-errormessage") })),
    field_invalid: await page.locator("#bx-field").getAttribute("aria-invalid"),
    alert_text: await page.getByRole("alert").textContent(),
    tab_order: tabOrder,
    focus_visibility: "not styled or claimed in Phase 5",
    assistive_technology: "not exercised",
  };
}

async function adapterNegatives(page) {
  return page.evaluate(async () => {
    const { FixtureDOMRenderer } = await import("./dom/fixture-dom-renderer.js");
    const protocol = "blazex.bh01.dom/0.1";
    const envelope = "blazex.bh01.fixture-effect/0.1";
    const target = document.createElement("div");
    document.body.append(target);
    const op = (name, values = {}, generation = 1) => ({ protocol, op: name, generation, ...values });
    const effect = (operations, sequence = 1, generation = 1) => ({ protocol: envelope, generation, sequence, operations });
    const create = () => {
      const renderer = new FixtureDOMRenderer({ target, documentImpl: document, generation: 1 });
      renderer.apply(effect([
        op("root.mount", { id: "bx-fixture-root", test_id: "bx-test-root" }),
        op("node.upsert", { id: "bx-value", parent_id: "bx-fixture-root", kind: "text", text: "before" }),
        op("node.upsert", { id: "bx-action", parent_id: "bx-fixture-root", kind: "action", text: "Act" }),
        op("listener.bind", { id: "bx-action", event: "action" }),
      ]));
      return renderer;
    };
    const code = (run) => { try { run(); return "accepted"; } catch (error) { return error?.code ?? "unknown"; } };
    let renderer = create();
    const missingTarget = code(() => renderer.apply(effect([op("node.text", { id: "bx-missing", text: "x" })], 2)));
    const duplicateListener = code(() => renderer.apply(effect([op("listener.bind", { id: "bx-action", event: "action" })], 2)));
    const oversizedValue = code(() => renderer.apply(effect([op("node.property", { id: "bx-value", name: "value", value: "x".repeat(2_049) })], 2)));
    const staleGeneration = code(() => renderer.apply(effect([], 2, 2)));
    const partialBatch = code(() => renderer.apply(effect([
      op("node.text", { id: "bx-value", text: "must-not-commit" }),
      op("node.text", { id: "bx-missing", text: "failure" }),
    ], 2)));
    const partialText = renderer.snapshot().nodes.find(({ id }) => id === "bx-value").text;
    renderer.dispose("negative-test");
    const postDisposal = code(() => renderer.apply(effect([], 2)));
    target.remove();
    return {
      codes: {
        duplicate_listener: duplicateListener,
        missing_target: missingTarget,
        oversized_value: oversizedValue,
        partial_batch: partialBatch,
        post_disposal: postDisposal,
        stale_generation: staleGeneration,
      },
      partial_text_after_failure: partialText,
    };
  });
}

async function stoppedSnapshot(page) {
  return page.evaluate(() => ({
    state: globalThis.__blazexBH01.state,
    final_resources: globalThis.__blazexBH01.final_resources,
    disposal_runtime: globalThis.__blazexBH01.fixture_effects.at(-1)?.effect?.snapshot ?? null,
  }));
}

function assertStopped(stopped) {
  assert.equal(stopped.state, "stopped");
  assert.deepEqual(stopped.final_resources.dom, { roots: 0, listeners: 0, nodes: 0 });
  assert.equal(stopped.final_resources.bridge.pending, 0);
  assert.equal(stopped.final_resources.bridge.stopped, true);
  assert.equal(stopped.final_resources.lifecycle.state, "stopped");
  assert.deepEqual(stopped.final_resources.lifecycle.resources, {});
  assert.equal(stopped.disposal_runtime.resources.processes, 0);
  assert.equal(stopped.disposal_runtime.resources.timers, 0);
  assert.equal(stopped.disposal_runtime.resources.pending_messages, 0);
}

function normalizedUrl(value) {
  if (value.startsWith("blob:")) return "blob:<runtime-worker-module>";
  return new URL(value).pathname;
}

function withoutTrace(run) {
  const { trace: _trace, adapter_negative_scenarios: _adapter, ...summary } = run;
  return summary;
}
