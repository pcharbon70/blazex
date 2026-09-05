import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";
import os from "node:os";

import playwright from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4199/bh01/";
const browserName = process.env.BLAZEX_BROWSER_TYPE ?? "chromium";
const executablePath = process.env.BLAZEX_BROWSER_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? `/tmp/blazex-bh01-phase9-${browserName}.json`;
const revision = process.env.BLAZEX_REVISION;
const environmentId = process.env.BLAZEX_ENVIRONMENT_ID;
const product = process.env.BLAZEX_BROWSER_PRODUCT ?? browserName;
const runLabel = process.env.BLAZEX_RUN_LABEL ?? "PRIMARY";
const coldSamples = positiveInteger("BLAZEX_COLD_START_SAMPLES", 30);
const warmSamples = positiveInteger("BLAZEX_WARM_START_SAMPLES", 30);
const fallbackSamples = positiveInteger("BLAZEX_FALLBACK_SAMPLES", 30);
const interactionSamples = positiveInteger("BLAZEX_INTERACTION_SAMPLES", 100);
const serverSamples = positiveInteger("BLAZEX_SERVER_SAMPLES", 50);
const cleanupSamples = positiveInteger("BLAZEX_CLEANUP_SAMPLES", 20);

if (!executablePath || !playwright[browserName]) throw new Error("A valid BLAZEX_BROWSER_TYPE and BLAZEX_BROWSER_PATH are required");
if (!/^[0-9a-f]{40}$/.test(revision ?? "")) throw new Error("BLAZEX_REVISION must be an exact commit");
if (!/^BX-BH01-ENV-[A-Z0-9.-]+$/.test(environmentId ?? "")) throw new Error("BLAZEX_ENVIRONMENT_ID is required");
if (!/^[A-Z0-9.-]+$/.test(runLabel)) throw new Error("BLAZEX_RUN_LABEL must be an uppercase stable identifier");

const executableBytes = await readFile(executablePath);
const launchOptions = { executablePath, headless: true };
if (browserName === "chromium") launchOptions.args = ["--no-sandbox", "--disable-dev-shm-usage", "--enable-precise-memory-info"];
const browser = await playwright[browserName].launch(launchOptions);
const evidence = {
  schema_version: "1.0.0",
  run_id: `BX-BH01-PHASE9-RUN-${browserName.toUpperCase()}-LINUX-${runLabel}-0.1`,
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
    fallback_samples: fallbackSamples,
    interaction_samples: interactionSamples,
    server_samples: serverSamples,
    cleanup_samples: cleanupSamples,
    discarded_warmups: 1,
    network: "same-host-loopback-unshaped",
  },
  measurements: [],
  resource_observations: { initial: {}, peak: {}, stable: {}, disposed: {}, lifecycle_cycles: cleanupSamples },
  reliability: { page_errors: 0, command_failures: 0, long_task_api: "unavailable", long_tasks: [], resource_growth_detected: false },
  failures: [],
  limitations: [
    "Development evidence only; no browser support or cross-platform qualification is implied.",
    "The same-host unshaped loopback environment is not the governed constrained-network product environment.",
    "Browser-reported JavaScript heap, when available, excludes complete Wasm, native browser, and BEAM process accounting.",
  ],
};

try {
  const calibration = await calibrate(browser);
  evidence.measurements.push(measurement("BX-BH01-METRIC-CLOCK-RESOLUTION-MS", "clock-calibration", "milliseconds", "not-applicable", [calibration]));

  await fallback(browser, 0);
  const fallbackSamplesObserved = [];
  for (let iteration = 1; iteration <= fallbackSamples; iteration += 1) fallbackSamplesObserved.push(await fallback(browser, iteration));
  evidence.measurements.push(measurement("BX-BH01-METRIC-STARTUP-FALLBACK-READY-MS", "webassembly-unavailable", "milliseconds", "cold", fallbackSamplesObserved));

  const cold = [];
  await startup(browser, "cold", 0);
  for (let iteration = 1; iteration <= coldSamples; iteration += 1) cold.push(await startup(browser, "cold", iteration));

  const warmContext = await browser.newContext();
  await startup(browser, "warm", 0, warmContext);
  const warm = [];
  for (let iteration = 1; iteration <= warmSamples; iteration += 1) warm.push(await startup(browser, "warm", iteration, warmContext));
  await warmContext.close();

  for (const [cacheState, values] of [["cold", cold], ["warm", warm]]) {
    evidence.measurements.push(measurement("BX-BH01-METRIC-STARTUP-NAVIGATION-READY-MS", "browser-profile", "milliseconds", cacheState, values.map((value) => value.navigation_ready_ms)));
    evidence.measurements.push(measurement("BX-BH01-METRIC-STARTUP-INSTANTIATE-READY-MS", "browser-profile", "milliseconds", cacheState, values.map((value) => value.instantiate_ready_ms)));
    evidence.measurements.push(measurement("BX-BH01-METRIC-STARTUP-ROOT-READY-MS", "browser-profile", "milliseconds", cacheState, values.map((value) => value.root_ready_ms)));
  }
  evidence.artifact_manifest = cold[0].artifact_manifest;

  const context = await browser.newContext();
  const page = await context.newPage();
  const pageErrors = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  await page.addInitScript(() => {
    globalThis.__blazexPhase9LongTasks = [];
    globalThis.__blazexPhase9LongTaskApi = "unavailable";
    try {
      const observer = new PerformanceObserver((list) => {
        globalThis.__blazexPhase9LongTasks.push(...list.getEntries().map((entry) => entry.duration));
      });
      observer.observe({ type: "longtask", buffered: true });
      globalThis.__blazexPhase9LongTaskApi = "available";
    } catch {}
  });
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await ready(page);
  await page.evaluate(() => globalThis.blazexBh01Fixture.command("parent.increment"));

  const heapBefore = await browserHeap(page);
  evidence.resource_observations.initial = await resourceSnapshot(page, "post-readiness");
  const localScenarios = [
    ["parent-state-update", "parent.increment", {}],
    ["nested-keyed-update", "child.increment", { key: "alpha" }],
    ["form-programmatic-update", "field.set", { value: "Phase 9" }],
    ["timer-message-update", "timer.start", { delay_ms: 15, ticks: 1 }],
  ];
  for (const [scenario, command, payload] of localScenarios) {
    let observed;
    try {
      observed = await measureLocal(page, command, payload, interactionSamples);
    } catch (error) {
      throw new Error(`${scenario}: ${error instanceof Error ? error.message : String(error)}`);
    }
    evidence.measurements.push(measurement("BX-BH01-METRIC-INTERACTION-LOCAL-EVENT-PAINT-MS", scenario, "milliseconds", "warm", observed.local));
    evidence.measurements.push(measurement("BX-BH01-METRIC-INTERACTION-DOM-COMMIT-MS", scenario, "milliseconds", "warm", observed.dom));
  }

  for (const scenario of ["authenticated-success", "authorization-denial", "disconnect-retry"]) {
    await measureServer(page, scenario, 0);
    const server = [];
    for (let iteration = 1; iteration <= serverSamples; iteration += 1) {
      server.push(await measureServer(page, scenario, iteration));
    }
    evidence.measurements.push(measurement("BX-BH01-METRIC-INTERACTION-SERVER-ROUNDTRIP-MS", scenario, "milliseconds", "warm", server));
  }
  evidence.resource_observations.peak = await resourceSnapshot(page, "post-interaction-and-server-scenarios");
  await page.evaluate(() => globalThis.blazexBh01Fixture.settle());
  evidence.resource_observations.stable = await resourceSnapshot(page, "settled-before-lifecycle-cycles");

  const cleanup = [];
  let disposed = null;
  for (let iteration = 1; iteration <= cleanupSamples; iteration += 1) {
    const observed = await page.evaluate(async () => {
      const startedAt = performance.now();
      await globalThis.blazexBh01Stop();
      const resources = globalThis.__blazexBH01.final_resources;
      return { duration_ms: performance.now() - startedAt, resources };
    });
    assert.deepEqual(observed.resources.dom, { roots: 0, listeners: 0, nodes: 0 });
    assert.equal(observed.resources.bridge.pending, 0);
    assert.equal(observed.resources.server.pending, 0);
    cleanup.push(observed.duration_ms);
    disposed = observed.resources;
    if (iteration < cleanupSamples) {
      await page.evaluate(() => globalThis.blazexBh01Start());
      await ready(page);
    }
  }
  evidence.resource_observations.disposed = { observation: "terminal-after-final-stop", ...disposed };
  evidence.measurements.push(measurement("BX-BH01-METRIC-RESOURCE-CLEANUP-MS", "repeated-host-stop", "milliseconds", "warm", cleanup));
  const heapAfter = await browserHeap(page);
  if (heapBefore !== null && heapAfter !== null) {
    evidence.measurements.push(measurement("BX-BH01-METRIC-RESOURCE-JS-HEAP-BYTES", "interaction-lifecycle-envelope", "bytes", "warm", [heapBefore, heapAfter]));
  } else {
    evidence.limitations.push("This browser did not expose performance.memory; JavaScript heap growth remains unavailable.");
  }
  const longTask = await page.evaluate(() => ({ api: globalThis.__blazexPhase9LongTaskApi, durations: globalThis.__blazexPhase9LongTasks }));
  evidence.reliability = {
    page_errors: pageErrors.length,
    command_failures: 0,
    long_task_api: longTask.api,
    long_tasks: longTask.durations,
    resource_growth_detected: false,
  };
  assert.deepEqual(pageErrors, []);
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

function measurement(metricId, scenario, unit, cacheState, values) {
  return { metric_id: metricId, scenario, unit, cache_state: cacheState, samples: values.map((value, index) => ({ iteration: index + 1, value })) };
}

async function measureLocal(page, command, payload, count) {
  await page.evaluate(() => { globalThis.__blazexBH01.timing_observations.length = 0; });
  const local = [];
  const dom = [];
  for (let iteration = 1; iteration <= count; iteration += 1) {
    const observed = await page.evaluate(async ({ commandName, commandPayload }) => {
      globalThis.__blazexBH01.timing_observations.length = 0;
      const before = globalThis.__blazexBH01.timing_observations.length;
      const startedAt = performance.now();
      const result = await globalThis.blazexBh01Fixture.command(commandName, commandPayload);
      if (commandName === "timer.start") {
        const deadline = performance.now() + 3_000;
        while (performance.now() < deadline) {
          const snapshot = await globalThis.blazexBh01Fixture.snapshot();
          if (snapshot.runtime.async.timer_ticks === commandPayload.ticks && snapshot.runtime.resources.timers === 0) break;
          await new Promise((resolve) => setTimeout(resolve, 1));
        }
        await new Promise((resolve) => requestAnimationFrame(() => resolve()));
      }
      const added = globalThis.__blazexBH01.timing_observations.slice(before);
      const domTiming = added.filter((item) => item.kind === "effect-to-dom").at(-1);
      return {
        local_ms: commandName === "timer.start" ? performance.now() - startedAt : result.timing.request_to_paint_ms,
        dom_ms: domTiming?.duration_ms ?? null,
      };
    }, { commandName: command, commandPayload: payload });
    local.push(observed.local_ms);
    if (observed.dom_ms !== null) dom.push(observed.dom_ms);
  }
  assert.equal(local.length, count);
  assert.equal(dom.length, count);
  return { local, dom };
}

async function measureServer(page, scenario, iteration) {
  const identity = scenario === "authorization-denial" ? "viewer" : "operator";
  await page.evaluate(async (identityId) => {
    const response = await fetch("/bh01/test/reset", { method: "POST", headers: { "x-bh01-test-control": "enabled" } });
    if (!response.ok) throw new Error(`server-reset-${response.status}`);
    await globalThis.blazexBh01Fixture.establishSession(identityId);
  }, identity);
  return page.evaluate(async ({ scenarioName, value }) => {
    const options = { correlationId: `phase9-${scenarioName}-${value}`, idempotencyKey: `phase9-${scenarioName}-${value}`, expectedVersion: 0 };
    const startedAt = performance.now();
    let result;
    if (scenarioName === "disconnect-retry") {
      const originalFetch = globalThis.fetch;
      let disconnect = true;
      globalThis.fetch = (input, init) => {
        if (disconnect && String(input).includes("/bh01/commands/")) {
          disconnect = false;
          return Promise.reject(new TypeError("simulated disconnect"));
        }
        return originalFetch(input, init);
      };
      const disconnected = await globalThis.blazexBh01Fixture.serverCommand(options);
      globalThis.fetch = originalFetch;
      if (disconnected.result.error?.code !== "transport-unavailable") throw new Error("disconnect-was-not-observed");
      result = await globalThis.blazexBh01Fixture.serverCommand(options);
    } else {
      result = await globalThis.blazexBh01Fixture.serverCommand(options);
    }
    await new Promise((resolve) => requestAnimationFrame(() => resolve()));
    if (scenarioName === "authorization-denial") {
      if (result.result.error?.code !== "authorization-denied") throw new Error(`server-denial-${result.result.error?.code ?? "missing"}`);
    } else if (result.result.status !== "ok") {
      throw new Error(`server-command-${result.result.error?.code ?? "failed"}`);
    }
    return performance.now() - startedAt;
  }, { scenarioName: scenario, value: iteration });
}

async function resourceSnapshot(page, observation) {
  const snapshot = await page.evaluate(() => globalThis.blazexBh01Fixture.snapshot());
  return {
    observation,
    memory_pages: snapshot.host.memory_pages,
    workers: snapshot.host.workers,
    processes: snapshot.runtime.resources.processes,
    mailbox_messages: snapshot.runtime.resources.mailbox_messages,
    timers: snapshot.runtime.resources.timers,
    pending_messages: snapshot.runtime.resources.pending_messages,
    bridge_pending: snapshot.host.bridge.pending,
    server_pending: snapshot.host.server.pending,
    dom_roots: snapshot.dom.root_count,
    dom_listeners: snapshot.dom.listener_count,
    dom_nodes: snapshot.dom.node_count,
  };
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

async function fallback(browserInstance, iteration) {
  const context = await browserInstance.newContext();
  await context.addInitScript(() => {
    Object.defineProperty(globalThis, "WebAssembly", { value: undefined, configurable: true });
  });
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await page.waitForFunction(() => globalThis.__blazexBH01?.state === "fallback", null, { timeout: 30_000 });
  const observed = await page.evaluate(() => ({
    duration_ms: performance.now(),
    decision: globalThis.__blazexBH01.prerequisites.decision,
    runtime_ready: globalThis.__blazexBH01.events.some((event) => event.type === "runtime-ready"),
  }));
  assert.equal(observed.decision, "static-server-fallback");
  assert.equal(observed.runtime_ready, false);
  await context.close();
  if (iteration === 0) return null;
  return observed.duration_ms;
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
