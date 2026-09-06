import assert from "node:assert/strict";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import { chromium, firefox } from "playwright-core";

import {
  describeByteSamples,
  describeSamples,
  normalizeMemoryObservation,
  summarizeLifecycleSamples,
} from "../support/bh03-measurement.mjs";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4197/bh03/";
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? "/tmp/blazex-bh03-phase7-measurements.json";
const retainedRepetitions = 5;
const scenarioSet = Object.freeze([
  "repeated-startup-readiness",
  "measurement-root-fanout",
  "resource-cleanup",
  "declared-failure-convergence",
  "capability-aware-memory-observation",
]);
const browsers = [
  { name: "chrome", engine: chromium, executable: process.env.BLAZEX_CHROME_PATH },
  { name: "firefox", engine: firefox, executable: process.env.BLAZEX_FIREFOX_PATH },
];

const evidence = {
  schema_version: "1.0.0",
  evidence_id: "BX-BH03-PHASE-07-ACTIVE-MEASUREMENTS-0.1",
  captured_at: new Date().toISOString(),
  implementation_revision: process.env.BLAZEX_REVISION ?? "working-tree",
  platform: `${os.platform()} ${os.release()} ${os.arch()}`,
  node_version: process.version,
  playwright_core_version: "1.62.1",
  profile_url: baseUrl,
  scenario_set: scenarioSet,
  sampling: {
    warmup_repetitions_per_browser: 1,
    retained_repetitions_per_browser: retainedRepetitions,
    profile_roots: 2,
    additional_measurement_roots: 8,
  },
  results: [],
  deferred: [
    { environment: "safari", state: "deferred-unavailable" },
    { environment: "mobile", state: "deferred-unavailable" },
    { environment: "physical-devices", state: "deferred-unavailable" },
    { environment: "second-host", state: "deferred-unavailable" },
    { environment: "manual-assistive-technology", state: "deferred-unavailable" },
  ],
  release_budgets: [],
  acceptance_evidence: [],
  api_state: "experimental-not-stable",
  support_state: "unsupported",
};

for (const target of browsers) {
  const result = {
    browser: target.name,
    executable: target.executable ?? null,
    browser_version: null,
    scenario_set: scenarioSet,
    result: "running",
    warmup: null,
    samples: [],
    summary: null,
    memory_growth: null,
    failure_scenarios: [],
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
    const warmup = await lifecycleSample(browser, 0);
    result.warmup = {
      result: "passed-discarded",
      root_count_before_shutdown: warmup.root_count_before_shutdown,
      disposed_root_count_after_shutdown: warmup.disposed_root_count_after_shutdown,
      runtime_iframes_after_shutdown: warmup.runtime_iframes_after_shutdown,
    };
    for (let iteration = 1; iteration <= retainedRepetitions; iteration += 1) {
      result.samples.push(await lifecycleSample(browser, iteration));
    }
    result.summary = summarizeLifecycleSamples(result.samples, { expectedCount: retainedRepetitions });
    result.memory_growth = memoryGrowth(result.samples);
    for (const scenario of [identityMismatch, unsupportedPrerequisite, artifactUnavailable]) {
      result.failure_scenarios.push(await scenario(browser));
    }
    assert.deepEqual(result.failure_scenarios.map(({ id }) => id), ["identity-mismatch", "unsupported-prerequisite", "artifact-unavailable"]);
    result.result = "passed";
  } catch (error) {
    result.result = browser ? "failed" : "unavailable";
    result.failures.push(boundedError(error));
  } finally {
    await browser?.close();
  }
}

await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
const failed = evidence.results.filter((row) => row.result !== "passed");
if (failed.length > 0) throw new Error(`BH-03 Phase 7 active measurements failed: ${failed.map((row) => `${row.browser}:${row.result}`).join(", ")}`);
assert.deepEqual(evidence.results.map((row) => row.scenario_set), [scenarioSet, scenarioSet]);
console.log(`BH-03 Phase 7 active measurements: PASS (${evidence.results.length} browsers; ${retainedRepetitions} retained lifecycle samples and 3 failure scenarios each)`);
console.log(`Evidence: ${evidencePath}`);

async function lifecycleSample(browser, iteration) {
  const context = await browser.newContext();
  const page = await context.newPage();
  const pageErrors = [];
  page.on("pageerror", (error) => pageErrors.push(boundedError(error)));
  try {
    const response = await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
    assert.equal(response.status(), 200);
    await page.waitForFunction(() => ["ready", "failed", "fallback"].includes(globalThis.__blazexBH03?.state), null, { timeout: 45_000 });
    const measured = await page.evaluate(async () => {
      const before = globalThis.__blazexBH03.snapshot;
      const rootCycle = await globalThis.blazexBh03MeasureRoots();
      const beforeShutdown = globalThis.__blazexBH03.snapshot;
      await globalThis.blazexBh03Stop();
      const stopped = globalThis.__blazexBH03.snapshot;
      return { before, rootCycle, beforeShutdown, stopped };
    });
    assert.equal(pageErrors.length, 0, JSON.stringify(pageErrors));
    assert.equal(measured.before.state, "ready");
    assert.equal(measured.before.runtime_starts, 1);
    assert.equal(measured.before.measurement.runtime_memory_pages, 256);
    assert.equal(measured.rootCycle.additional_roots, 8);
    assert.equal(measured.rootCycle.root_count, 10);
    assert.equal(measured.rootCycle.disposed_measurement_roots, 8);
    assert.equal(measured.rootCycle.runtime_acknowledgements, 32);
    assert.equal(measured.beforeShutdown.runtime_acknowledgement_count, 40);
    assert.equal(measured.stopped.state, "stopped");
    assert.equal(measured.stopped.shutdown.acknowledged, true);
    assert.equal(measured.stopped.shutdown.released, true);
    assert.equal(measured.stopped.shutdown.root_failures, 0);
    assert.equal(measured.stopped.roots.root_count, 10);
    assert.equal(Object.values(measured.stopped.roots.states).filter((state) => state === "disposed").length, 10);
    assert.equal(measured.stopped.measurement.runtime_iframes_after_shutdown, 0);
    assert.equal(measured.stopped.runtime_acknowledgement_count, 43);
    assert.equal(measured.stopped.support_state, "unsupported");
    return {
      iteration,
      startup_to_ready_ms: measured.before.measurement.startup_to_ready_ms,
      measurement_root_cycle_ms: measured.rootCycle.elapsed_ms,
      shutdown_ms: measured.stopped.measurement.shutdown_ms,
      runtime_memory_pages: measured.before.measurement.runtime_memory_pages,
      root_count_before_shutdown: measured.beforeShutdown.roots.root_count,
      disposed_root_count_after_shutdown: Object.values(measured.stopped.roots.states).filter((state) => state === "disposed").length,
      runtime_iframes_after_shutdown: measured.stopped.measurement.runtime_iframes_after_shutdown,
      runtime_acknowledgements: measured.stopped.runtime_acknowledgement_count,
      memory: rawMemory(measured.before.measurement.memory_ready, measured.rootCycle.memory_after_root_cycle, measured.stopped.measurement.memory_after_shutdown),
    };
  } finally {
    await context.close();
  }
}

async function identityMismatch(browser) {
  const context = await browser.newContext();
  await context.route("**/bh03/runtime-manifest.json", async (route) => {
    const response = await route.fetch();
    const body = await response.json();
    body.compatibility.renderer = "blazex.renderer/999";
    await route.fulfill({ response, json: body });
  });
  return failureScenario(context, "identity-mismatch", "identity-mismatch", "deployment-action");
}

async function unsupportedPrerequisite(browser) {
  const context = await browser.newContext();
  await context.route("**/bh03/**", async (route) => {
    const response = await route.fetch();
    const headers = { ...response.headers() };
    delete headers["cross-origin-embedder-policy"];
    await route.fulfill({ response, headers });
  });
  return failureScenario(context, "unsupported-prerequisite", "unsupported-prerequisite", "static-content");
}

async function artifactUnavailable(browser) {
  const context = await browser.newContext();
  await context.route("**/bh03/artifacts/AtomVM.wasm", (route) => route.abort("failed"));
  return failureScenario(context, "artifact-unavailable", "runtime-startup", "user-action");
}

async function failureScenario(context, id, failureClass, action) {
  const page = await context.newPage();
  try {
    await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
    await page.waitForFunction(() => ["fallback", "failed"].includes(globalThis.__blazexBH03?.state), null, { timeout: 15_000 });
    const result = await page.evaluate(() => ({ state: globalThis.__blazexBH03.state, fallback: globalThis.__blazexBH03.fallback }));
    assert.equal(result.state, "fallback", JSON.stringify(result));
    assert.equal(result.fallback.failure_class, failureClass);
    assert.equal(result.fallback.action, action);
    assert.equal(result.fallback.partial_activation, false);
    return { id, result: "passed", failure_class: failureClass, action, partial_activation: false };
  } finally {
    await context.close();
  }
}

function rawMemory(ready, afterRoots, afterShutdown) {
  if (ready?.available && afterRoots?.available && afterShutdown?.available) {
    return {
      available: true,
      api: "performance.memory.usedJSHeapSize",
      ready_bytes: ready.bytes,
      after_root_cycle_bytes: afterRoots.bytes,
      after_shutdown_bytes: afterShutdown.bytes,
    };
  }
  return { available: false, reason: "browser-memory-api-unavailable" };
}

function memoryGrowth(samples) {
  const observations = samples.map(({ memory }) => normalizeMemoryObservation(memory));
  const available = observations.filter((item) => item.available);
  if (available.length === 0) return { state: "unavailable", api: null, reason: "browser-memory-api-unavailable" };
  assert.equal(available.length, samples.length, "Memory capability changed within one browser row");
  return {
    state: "observed",
    api: available[0].api,
    observed_peak_growth_bytes: describeByteSamples(available.map((item) => item.observed_peak_growth_bytes), { expectedCount: samples.length }),
    release_budget: null,
  };
}

function boundedError(error) {
  return {
    name: String(error?.name ?? "Error").slice(0, 64),
    message: String(error?.message ?? error).slice(0, 512),
    stack: String(error?.stack ?? "").split("\n").slice(0, 8).join("\n"),
  };
}
