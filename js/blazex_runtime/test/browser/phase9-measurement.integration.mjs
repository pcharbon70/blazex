import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";
import os from "node:os";
import { performance } from "node:perf_hooks";

import playwright from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4199/bh01/";
const browserName = process.env.BLAZEX_BROWSER_TYPE ?? "chromium";
const executablePath = process.env.BLAZEX_BROWSER_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? `/tmp/blazex-bh01-phase9-${browserName}.json`;
const revision = process.env.BLAZEX_REVISION;
const environmentId = process.env.BLAZEX_ENVIRONMENT_ID;
const product = process.env.BLAZEX_BROWSER_PRODUCT ?? browserName;
const coldSamples = positiveInteger("BLAZEX_COLD_START_SAMPLES", 30);
const warmSamples = positiveInteger("BLAZEX_WARM_START_SAMPLES", 30);
const interactionSamples = positiveInteger("BLAZEX_INTERACTION_SAMPLES", 100);
const serverSamples = positiveInteger("BLAZEX_SERVER_SAMPLES", 50);
const cleanupSamples = positiveInteger("BLAZEX_CLEANUP_SAMPLES", 20);

if (!executablePath || !playwright[browserName]) throw new Error("A valid BLAZEX_BROWSER_TYPE and BLAZEX_BROWSER_PATH are required");
if (!/^[0-9a-f]{40}$/.test(revision ?? "")) throw new Error("BLAZEX_REVISION must be an exact commit");
if (!/^BX-BH01-ENV-[A-Z0-9.-]+$/.test(environmentId ?? "")) throw new Error("BLAZEX_ENVIRONMENT_ID is required");

const executableBytes = await readFile(executablePath);
const launchOptions = { executablePath, headless: true };
if (browserName === "chromium") launchOptions.args = ["--no-sandbox", "--disable-dev-shm-usage", "--enable-precise-memory-info"];
const browser = await playwright[browserName].launch(launchOptions);
const evidence = {
  schema_version: "1.0.0",
  run_id: `BX-BH01-PHASE9-RUN-${browserName.toUpperCase()}-LINUX-0.1`,
  status: "running",
  captured_at: new Date().toISOString(),
  source_revision: revision,
  environment_id: environmentId,
  browser: {
    type: browserName,
    product,
    version: browser.version(),
    executable_sha256: createHash("sha256").update(executableBytes).digest("hex"),
    os: `${os.platform()} ${os.release()}`,
    architecture: os.arch(),
    authority: "active-development-evidence",
    support_status: "unsupported",
  },
  artifact_manifest: {},
  configuration: {
    clock: "browser-performance-now-monotonic",
    cold_start_samples: coldSamples,
    warm_start_samples: warmSamples,
    interaction_samples: interactionSamples,
    server_samples: serverSamples,
    cleanup_samples: cleanupSamples,
    discarded_warmups: 1,
    network: "same-host-loopback-unshaped",
  },
  measurements: [],
  failures: [],
  limitations: [
    "Development evidence only; no browser support or cross-platform qualification is implied.",
    "The same-host unshaped loopback environment is not the governed constrained-network product environment.",
    "Browser-reported JavaScript heap, when available, excludes complete Wasm, native browser, and BEAM process accounting.",
  ],
};

try {
  const calibration = await calibrate(browser);
  evidence.measurements.push(measurement("BX-BH01-METRIC-CLOCK-RESOLUTION-MS", "milliseconds", "not-applicable", [calibration]));

  const cold = [];
  await startup(browser, "cold", 0);
  for (let iteration = 1; iteration <= coldSamples; iteration += 1) cold.push(await startup(browser, "cold", iteration));

  const warmContext = await browser.newContext();
  await startup(browser, "warm", 0, warmContext);
  const warm = [];
  for (let iteration = 1; iteration <= warmSamples; iteration += 1) warm.push(await startup(browser, "warm", iteration, warmContext));
  await warmContext.close();

  for (const [cacheState, values] of [["cold", cold], ["warm", warm]]) {
    evidence.measurements.push(measurement("BX-BH01-METRIC-STARTUP-NAVIGATION-READY-MS", "milliseconds", cacheState, values.map((value) => value.navigation_ready_ms)));
    evidence.measurements.push(measurement("BX-BH01-METRIC-STARTUP-INSTANTIATE-READY-MS", "milliseconds", cacheState, values.map((value) => value.instantiate_ready_ms)));
    evidence.measurements.push(measurement("BX-BH01-METRIC-STARTUP-ROOT-READY-MS", "milliseconds", cacheState, values.map((value) => value.root_ready_ms)));
  }
  evidence.artifact_manifest = cold[0].artifact_manifest;

  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await ready(page);
  await page.evaluate(() => globalThis.blazexBh01Fixture.command("parent.increment"));

  const heapBefore = await browserHeap(page);
  const local = [];
  const dom = [];
  for (let iteration = 1; iteration <= interactionSamples; iteration += 1) {
    const observed = await page.evaluate(async () => {
      const before = globalThis.__blazexBH01.timing_observations.length;
      const result = await globalThis.blazexBh01Fixture.command("parent.increment");
      const added = globalThis.__blazexBH01.timing_observations.slice(before);
      const domTiming = added.filter((item) => item.kind === "effect-to-dom").at(-1);
      return { local_ms: result.timing.request_to_paint_ms, dom_ms: domTiming?.duration_ms ?? null };
    });
    local.push(observed.local_ms);
    if (observed.dom_ms !== null) dom.push(observed.dom_ms);
  }
  assert.equal(local.length, interactionSamples);
  assert.equal(dom.length, interactionSamples);
  evidence.measurements.push(measurement("BX-BH01-METRIC-INTERACTION-LOCAL-EVENT-PAINT-MS", "milliseconds", "warm", local));
  evidence.measurements.push(measurement("BX-BH01-METRIC-INTERACTION-DOM-COMMIT-MS", "milliseconds", "warm", dom));

  await page.evaluate(async () => fetch("/bh01/test/reset", { method: "POST", headers: { "x-bh01-test-control": "enabled" } }));
  await page.evaluate(() => globalThis.blazexBh01Fixture.establishSession("operator"));
  await page.evaluate(() => globalThis.blazexBh01Fixture.serverCommand({ correlationId: "phase9-warmup", idempotencyKey: "phase9-warmup" }));
  const server = [];
  for (let iteration = 1; iteration <= serverSamples; iteration += 1) {
    const duration = await page.evaluate(async (value) => {
      const startedAt = performance.now();
      const result = await globalThis.blazexBh01Fixture.serverCommand({ correlationId: `phase9-${value}`, idempotencyKey: `phase9-${value}` });
      await new Promise((resolve) => requestAnimationFrame(() => resolve()));
      if (result.result.status !== "ok") throw new Error(`server-command-${result.result.error?.code ?? "failed"}`);
      return performance.now() - startedAt;
    }, iteration);
    server.push(duration);
  }
  evidence.measurements.push(measurement("BX-BH01-METRIC-INTERACTION-SERVER-ROUNDTRIP-MS", "milliseconds", "warm", server));

  const cleanup = [];
  for (let iteration = 1; iteration <= cleanupSamples; iteration += 1) {
    const observed = await page.evaluate(async () => {
      const startedAt = performance.now();
      const resources = await globalThis.blazexBh01Stop();
      return { duration_ms: performance.now() - startedAt, resources };
    });
    assert.deepEqual(observed.resources.dom, { roots: 0, listeners: 0, nodes: 0 });
    assert.equal(observed.resources.bridge.pending, 0);
    assert.equal(observed.resources.server.pending, 0);
    cleanup.push(observed.duration_ms);
    if (iteration < cleanupSamples) {
      await page.evaluate(() => globalThis.blazexBh01Start());
      await ready(page);
    }
  }
  evidence.measurements.push(measurement("BX-BH01-METRIC-RESOURCE-CLEANUP-MS", "milliseconds", "warm", cleanup));
  const heapAfter = await browserHeap(page);
  if (heapBefore !== null && heapAfter !== null) {
    evidence.measurements.push(measurement("BX-BH01-METRIC-RESOURCE-JS-HEAP-BYTES", "bytes", "warm", [heapBefore, heapAfter]));
  } else {
    evidence.limitations.push("This browser did not expose performance.memory; JavaScript heap growth remains unavailable.");
  }
  await context.close();
  evidence.status = evidence.failures.length ? "observed-with-failures" : "observed";
} catch (error) {
  evidence.status = "failed";
  evidence.failures.push({ stage: "measurement-run", error: error instanceof Error ? `${error.name}: ${error.message}` : String(error) });
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 9 ${browserName} measurements: ${evidence.status.toUpperCase()} (${evidence.measurements.reduce((count, item) => count + item.samples.length, 0)} samples)`);

function positiveInteger(name, fallback) {
  const value = Number(process.env[name] ?? fallback);
  if (!Number.isSafeInteger(value) || value < 1) throw new Error(`${name} must be a positive integer`);
  return value;
}

function measurement(metricId, unit, cacheState, values) {
  return { metric_id: metricId, unit, cache_state: cacheState, samples: values.map((value, index) => ({ iteration: index + 1, value })) };
}

async function ready(page) {
  await page.waitForFunction(() => globalThis.__blazexBH01?.state === "ready", null, { timeout: 30_000 });
}

async function startup(browserInstance, cacheState, iteration, sharedContext = null) {
  const context = sharedContext ?? await browserInstance.newContext();
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await ready(page);
  const observed = await page.evaluate(async () => {
    const transitions = globalThis.__blazexBH01.events.filter((event) => event.protocol === "blazex.lifecycle.transition/1");
    const checking = transitions.find((event) => event.to === "checking");
    const instantiating = transitions.find((event) => event.to === "instantiating");
    const readyTransition = transitions.find((event) => event.to === "ready");
    const response = await fetch("./profile-assets-manifest.json", { cache: "no-store" });
    const bytes = new Uint8Array(await response.arrayBuffer());
    const manifest = JSON.parse(new TextDecoder().decode(bytes));
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    return {
      navigation_ready_ms: performance.now(),
      instantiate_ready_ms: readyTransition.at_ms - instantiating.at_ms,
      root_ready_ms: performance.now() - readyTransition.at_ms,
      lifecycle_start_ms: checking.at_ms,
      artifact_manifest: {
        id: manifest.manifest_id,
        sha256: [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join(""),
        governed_files: manifest.artifacts.length,
      },
    };
  });
  await page.evaluate(() => globalThis.blazexBh01Stop());
  await page.close();
  if (!sharedContext) await context.close();
  if (iteration === 0) return null;
  return observed;
}

async function calibrate(browserInstance) {
  const context = await browserInstance.newContext();
  const page = await context.newPage();
  const resolution = await page.evaluate(() => {
    let previous = performance.now();
    let minimum = Number.POSITIVE_INFINITY;
    for (let index = 0; index < 10_000; index += 1) {
      const current = performance.now();
      const delta = current - previous;
      if (delta > 0 && delta < minimum) minimum = delta;
      previous = current;
    }
    return Number.isFinite(minimum) ? minimum : 0;
  });
  await context.close();
  return resolution;
}

async function browserHeap(page) {
  return page.evaluate(() => Number.isFinite(performance.memory?.usedJSHeapSize) ? performance.memory.usedJSHeapSize : null);
}
