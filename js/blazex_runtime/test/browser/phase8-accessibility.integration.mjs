import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import playwright from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4199/bh01/";
const browserName = process.env.BLAZEX_BROWSER_TYPE ?? "chromium";
const executablePath = process.env.BLAZEX_BROWSER_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? `/tmp/blazex-bh01-phase8-accessibility-${browserName}.json`;
const revision = process.env.BLAZEX_MATRIX_IDENTITY ?? "unrecorded";
const authority = process.env.BLAZEX_ROW_AUTHORITY ?? "experimental-unqualified";
if (!executablePath || !playwright[browserName]) throw new Error("A valid BLAZEX_BROWSER_TYPE and BLAZEX_BROWSER_PATH are required");

const options = { executablePath, headless: true };
if (browserName === "chromium") options.args = ["--no-sandbox", "--disable-dev-shm-usage"];
const browser = await playwright[browserName].launch(options);
const evidence = {
  schema_version: "1.0.0",
  evidence_id: `BX-BH01-PHASE8-ACCESSIBILITY-${browserName.toUpperCase()}-0.1`,
  captured_at: new Date().toISOString(),
  implementation_revision: revision,
  authority,
  support_status: "unsupported",
  browser: { type: browserName, version: browser.version(), os: `${os.platform()} ${os.release()}`, architecture: os.arch() },
  status: "running",
  profile: {},
  fallback: {},
  keyboard_focus: {},
  field_input: {},
  user_preferences: {},
  manual_evidence: { assistive_technology: "not-executed-environment-unavailable", physical_keyboard: "not-executed-headless-automation", touch_and_virtual_keyboard: "not-applicable-to-desktop-probe" },
  page_errors: [],
};

try {
  const context = await browser.newContext();
  const page = await context.newPage();
  page.on("pageerror", (error) => evidence.page_errors.push(error.message));
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  evidence.profile = await profileIdentity(page);
  assert.equal(await page.evaluate(() => globalThis.__blazexBH01.state), "ready");

  const initial = await page.evaluate(() => ({
    main: document.querySelectorAll("main").length,
    heading: document.querySelector("h1")?.textContent,
    status_role: document.querySelector("[data-bh01-status]")?.getAttribute("role"),
    status_live: document.querySelector("[data-bh01-status]")?.getAttribute("aria-live"),
    status_described_by: document.querySelector("[data-bh01-status]")?.getAttribute("aria-describedby"),
    retry_hidden: document.querySelector("[data-bh01-retry]")?.hidden,
  }));
  assert.deepEqual(initial, { main: 1, heading: "BlazeX browser feasibility profile", status_role: "status", status_live: "polite", status_described_by: "bh01-detail", retry_hidden: true });

  const tabTrace = await keyboardTrace(page);
  const fieldIndex = tabTrace.findIndex((item) => item.id === "bx-field");
  const resetIndex = tabTrace.findIndex((item) => item.id === "bx-field-reset");
  assert.ok(fieldIndex >= 0 && resetIndex > fieldIndex);
  const fieldFocus = tabTrace[fieldIndex];
  assert.equal(fieldFocus.focus_visible, true);
  assert.notEqual(fieldFocus.outline_style, "none");

  await page.locator("#bx-field").focus();
  await poll(page, (value) => value.runtime.field.focused);
  await dispatchInput(page, "A", true);
  await poll(page, (value) => value.runtime.field.composing && value.runtime.field.value === "A");
  for (const value of ["A", "Ad", "Ada"]) await dispatchInput(page, value, false);
  await poll(page, (value) => value.runtime.field.value === "Ada" && value.runtime.field.valid && !value.runtime.field.composing);
  await page.locator("#bx-field").evaluate((field) => field.dispatchEvent(new Event("change", { bubbles: true })));
  await page.locator("#bx-field").blur();
  await poll(page, (value) => value.runtime.field.touched && !value.runtime.field.focused);

  await dispatchInput(page, "", false);
  await poll(page, (value) => value.runtime.field.value === "" && !value.runtime.field.valid);
  const invalid = await fieldAccessibility(page);
  assert.equal(invalid.accessible_name, "Name");
  assert.equal(invalid.invalid, "true");
  assert.deepEqual(invalid.relationships, { described_by: "bx-field-help bx-field-error", error_message: "bx-field-error" });
  assert.equal(invalid.alert_count, 1);

  await command(page, "field.disabled", { value: true });
  const disabled = await page.locator("#bx-field").isDisabled();
  const disabledRejection = await rejectedEvent(page, "input", { value: "blocked", is_composing: false, input_type: "insertText" }, 801);
  assert.equal(disabled, true);
  assert.equal(disabledRejection, "fixture-field-disabled");
  await command(page, "field.disabled", { value: false });

  await command(page, "field.read-only", { value: true });
  const readOnly = await page.locator("#bx-field").getAttribute("readonly");
  const readOnlyRejection = await rejectedEvent(page, "change", { value: "blocked", is_composing: false, input_type: "unknown" }, 802);
  assert.equal(readOnly, "");
  assert.equal(readOnlyRejection, "fixture-field-read-only");
  await command(page, "field.read-only", { value: false });

  await page.locator("#bx-field").focus();
  await command(page, "parent.increment");
  assert.equal(await page.evaluate(() => document.activeElement?.id), "bx-field");
  await command(page, "field.set", { value: "Ada" });
  await page.locator("#bx-field-reset").focus();
  await page.keyboard.press("Enter");
  await poll(page, (value) => value.runtime.field.value === "" && !value.runtime.field.valid);

  evidence.keyboard_focus = {
    tab_order: tabTrace.map((item) => item.id),
    field_before_reset: true,
    keyboard_action: "enter-activated-reset",
    focus_visible: { matches: fieldFocus.focus_visible, outline_style: fieldFocus.outline_style, outline_width: fieldFocus.outline_width },
    focus_preserved_after_dom_update: true,
  };
  evidence.field_input = {
    composition_like_sequence: "passed",
    rapid_input_final_value: "Ada",
    input_change_blur: "passed",
    invalid_accessibility: invalid,
    disabled: { property: disabled, event_rejection: disabledRejection },
    read_only: { property: readOnly === "", event_rejection: readOnlyRejection },
  };

  evidence.fallback.capability_unavailable = await capabilityFallback();
  evidence.fallback.unsupported_browser = await isolationFallback();
  evidence.fallback.no_javascript = await noJavaScriptFallback();
  evidence.user_preferences.reduced_motion = await preferenceProbe({ reducedMotion: "reduce" }, "(prefers-reduced-motion: reduce)");
  evidence.user_preferences.forced_colors = await preferenceProbe({ forcedColors: "active" }, "(forced-colors: active)");

  await page.evaluate(() => globalThis.blazexBh01Stop());
  await context.close();
  assert.deepEqual(evidence.page_errors, []);
  evidence.status = "observed";
  evidence.evidence_sha256 = createHash("sha256").update(JSON.stringify({ profile: evidence.profile, fallback: evidence.fallback, keyboard_focus: evidence.keyboard_focus, field_input: evidence.field_input, user_preferences: evidence.user_preferences, manual_evidence: evidence.manual_evidence })).digest("hex");
} catch (error) {
  evidence.status = "observed-fail";
  evidence.error = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 8 accessibility/input probe (${browserName}): ${evidence.status.toUpperCase()}`);

async function terminal(page) { await page.waitForFunction(() => ["ready", "failed", "fallback"].includes(globalThis.__blazexBH01?.state), null, { timeout: 30_000 }); }
async function profileIdentity(page) {
  return page.evaluate(async () => {
    const response = await fetch("./profile-assets-manifest.json", { cache: "no-store" });
    const bytes = new Uint8Array(await response.arrayBuffer());
    const manifest = JSON.parse(new TextDecoder().decode(bytes));
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    return { manifest_id: manifest.manifest_id, manifest_sha256: [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join(""), governed_files: manifest.artifacts.length };
  });
}
async function snapshot(page) { return page.evaluate(() => globalThis.blazexBh01Fixture.snapshot()); }
async function command(page, name, payload = {}) { return page.evaluate(({ name, payload }) => globalThis.blazexBh01Fixture.command(name, payload), { name, payload }); }
async function poll(page, predicate) {
  const deadline = Date.now() + 3_000;
  while (Date.now() < deadline) {
    const value = await snapshot(page);
    if (predicate(value)) return value;
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
  throw new Error("accessibility/input observation did not converge");
}
async function dispatchInput(page, value, composing) {
  await page.locator("#bx-field").evaluate((field, values) => {
    field.value = values.value;
    field.dispatchEvent(new InputEvent("input", { bubbles: true, data: values.value, inputType: "insertText", isComposing: values.composing }));
  }, { value, composing });
}
async function rejectedEvent(page, event, payload, sequence) {
  return page.evaluate(async ({ event, payload, sequence }) => {
    try {
      await globalThis.blazexBh01Fixture.event({ protocol: "blazex.bh01.fixture-event/0.1", record_type: "event", scenario_id: "BX-BH01-SCENARIO-BROWSER-MATRIX", generation: 1, sequence, node_id: "bx-field", event, payload });
      return "accepted";
    } catch (error) { return error?.code ?? "unknown"; }
  }, { event, payload, sequence });
}
async function keyboardTrace(page) {
  await page.evaluate(() => document.activeElement?.blur());
  const trace = [];
  for (let index = 0; index < 16; index += 1) {
    await page.keyboard.press("Tab");
    const observed = await page.evaluate(() => {
      const node = document.activeElement;
      const style = getComputedStyle(node);
      return { id: node?.id || node?.getAttribute?.("data-bh01-retry") && "bh01-retry" || node?.tagName?.toLowerCase() || "none", focus_visible: node?.matches?.(":focus-visible") ?? false, outline_style: style.outlineStyle, outline_width: style.outlineWidth };
    });
    trace.push(observed);
    if (observed.id === "body") break;
  }
  return trace;
}
async function fieldAccessibility(page) {
  const observed = await snapshot(page);
  const field = observed.dom.nodes.find(({ id }) => id === "bx-field");
  return {
    accessible_name: field.accessible_name,
    invalid: await page.locator("#bx-field").getAttribute("aria-invalid"),
    relationships: await page.locator("#bx-field").evaluate((node) => ({ described_by: node.getAttribute("aria-describedby"), error_message: node.getAttribute("aria-errormessage") })),
    alert_count: await page.getByRole("alert").count(),
    alert_text: await page.getByRole("alert").textContent(),
  };
}
async function fallbackObservation(page) {
  return page.evaluate(() => {
    const status = document.querySelector("[data-bh01-status]");
    const retry = document.querySelector("[data-bh01-retry]");
    return {
      state: globalThis.__blazexBH01.state,
      decision: globalThis.__blazexBH01.prerequisites.decision,
      runtime_ready: globalThis.__blazexBH01.events.some((event) => event.type === "runtime-ready"),
      main_count: document.querySelectorAll("main").length,
      heading: document.querySelector("h1")?.textContent,
      status_text: status?.textContent,
      status_role: status?.getAttribute("role"),
      status_live: status?.getAttribute("aria-live"),
      status_described_by: status?.getAttribute("aria-describedby"),
      detail_text: document.querySelector("[data-bh01-detail]")?.textContent,
      diagnostic_code: status?.dataset.code,
      correlation_id: status?.dataset.correlation,
      retry_visible: retry ? !retry.hidden : false,
      retry_name: retry?.textContent,
      retry_described_by: retry?.getAttribute("aria-describedby"),
      fixture_children: document.querySelector("[data-bh01-fixture-host]")?.children.length,
      focused: document.activeElement?.tagName?.toLowerCase(),
    };
  });
}
function assertFallback(value) {
  assert.equal(value.state, "fallback");
  assert.equal(value.runtime_ready, false);
  assert.equal(value.main_count, 1);
  assert.equal(value.status_role, "status");
  assert.equal(value.status_live, "polite");
  assert.equal(value.status_described_by, "bh01-detail");
  assert.ok(value.status_text.length > 0 && value.detail_text.length > 0);
  assert.ok(value.diagnostic_code && value.correlation_id === "prerequisite-check");
  assert.equal(value.retry_visible, true);
  assert.equal(value.retry_name, "Recheck browser capabilities");
  assert.equal(value.retry_described_by, "bh01-detail");
  assert.equal(value.fixture_children, 0);
  assert.equal(value.focused, "body");
}
async function capabilityFallback() {
  const context = await browser.newContext();
  await context.addInitScript(() => Object.defineProperty(globalThis, "WebAssembly", { value: undefined, configurable: true }));
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const beforeRetry = await fallbackObservation(page);
  assertFallback(beforeRetry);
  await Promise.all([page.waitForNavigation({ waitUntil: "domcontentloaded" }), page.locator("[data-bh01-retry]").click()]);
  await terminal(page);
  const afterRetry = await fallbackObservation(page);
  assertFallback(afterRetry);
  await context.close();
  return { before_retry: beforeRetry, after_retry: afterRetry, bounded_retry: "one-user-controlled-reload" };
}
async function isolationFallback() {
  const context = await browser.newContext();
  await context.route("**/bh01/**", async (route) => {
    const response = await route.fetch();
    const headers = { ...response.headers() };
    delete headers["cross-origin-embedder-policy"];
    await route.fulfill({ response, headers });
  });
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const value = await fallbackObservation(page);
  assertFallback(value);
  assert.equal(value.decision, "unsupported");
  await context.close();
  return value;
}
async function noJavaScriptFallback() {
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  const value = await page.evaluate(() => ({
    main_count: document.querySelectorAll("main").length,
    heading: document.querySelector("h1")?.textContent,
    status_role: document.querySelector("[data-bh01-status]")?.getAttribute("role"),
    status_text: document.querySelector("[data-bh01-status]")?.textContent,
    detail_text: document.querySelector("[data-bh01-detail]")?.textContent,
    noscript_text: document.querySelector("noscript")?.textContent,
    retry_hidden: document.querySelector("[data-bh01-retry]")?.hidden,
    fixture_children: document.querySelector("[data-bh01-fixture-host]")?.children.length,
  }));
  assert.equal(value.main_count, 1);
  assert.equal(value.status_role, "status");
  assert.ok(value.status_text.length > 0 && value.detail_text.length > 0 && value.noscript_text.includes("requires JavaScript"));
  assert.equal(value.retry_hidden, true);
  assert.equal(value.fixture_children, 0);
  await context.close();
  return { ...value, ordinary_host_reload: true, partial_activation: false };
}
async function preferenceProbe(contextOptions, query) {
  const context = await browser.newContext(contextOptions);
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const value = await page.evaluate((mediaQuery) => {
    const field = document.querySelector("#bx-field");
    field.focus();
    const style = getComputedStyle(field);
    return { active: matchMedia(mediaQuery).matches, state: globalThis.__blazexBH01.state, textbox_role: field.getAttribute("role") ?? "implicit", outline_style: style.outlineStyle, animation_duration: style.animationDuration, transition_duration: style.transitionDuration, forced_color_adjust: style.forcedColorAdjust };
  }, query);
  assert.equal(value.active, true);
  assert.equal(value.state, "ready");
  assert.notEqual(value.outline_style, "none");
  await page.evaluate(() => globalThis.blazexBh01Stop());
  await context.close();
  return value;
}
