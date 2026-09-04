import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import playwright from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4199/bh01/";
const browserName = process.env.BLAZEX_BROWSER_TYPE ?? "chromium";
const executablePath = process.env.BLAZEX_BROWSER_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? `/tmp/blazex-bh01-phase8-prerequisites-${browserName}.json`;
const matrixIdentity = process.env.BLAZEX_MATRIX_IDENTITY ?? "unrecorded";
const authority = process.env.BLAZEX_ROW_AUTHORITY ?? "experimental-unqualified";
if (!executablePath) throw new Error("BLAZEX_BROWSER_PATH is required");
if (!playwright[browserName]) throw new Error(`Unsupported Playwright browser type: ${browserName}`);

const launchOptions = { executablePath, headless: true };
if (browserName === "chromium") launchOptions.args = ["--no-sandbox", "--disable-dev-shm-usage"];
const browser = await playwright[browserName].launch(launchOptions);
const evidence = {
  schema_version: "1.0.0",
  evidence_id: `BX-BH01-PHASE8-PREREQUISITES-${browserName.toUpperCase()}-0.1`,
  captured_at: new Date().toISOString(),
  implementation_revision: matrixIdentity,
  authority,
  support_status: "unsupported",
  browser: { type: browserName, version: browser.version(), os: `${os.platform()} ${os.release()}`, architecture: os.arch() },
  status: "running",
  capabilities: {},
  deployment: {},
  negative_scenarios: [],
  lifecycle_changes: {},
  unobservable: ["memory-pressure", "power-thermal-state", "service-worker-mutation"],
  page_errors: [],
};

try {
  const context = await browser.newContext();
  const page = await context.newPage();
  page.on("pageerror", (error) => evidence.page_errors.push(error.message));
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const initial = await state(page);
  evidence.capabilities = await capabilityProbe(page);
  evidence.deployment = await deploymentProbe(page);
  evidence.initial = initial;

  if (authority === "required-row") {
    assert.equal(initial.state, "ready", JSON.stringify(initial));
    assert.equal(initial.prerequisites.decision, "proceed");
  }

  evidence.negative_scenarios.push(await prerequisiteFailure("webassembly", { WebAssembly: undefined }, "static-server-fallback"));
  evidence.negative_scenarios.push(await prerequisiteFailure("workers", { Worker: undefined }, "static-server-fallback"));
  evidence.negative_scenarios.push(await prerequisiteFailure("streaming", { instantiateStreaming: undefined }, "alternate-loading"));
  evidence.negative_scenarios.push(await isolationFailure());

  await context.setOffline(true);
  const offline = await page.evaluate(async () => {
    try { await fetch("./runtime-manifest.json", { cache: "no-store" }); return "unexpected-success"; }
    catch { return "network-unavailable"; }
  });
  await context.setOffline(false);
  const online = await page.evaluate(async () => (await fetch("./runtime-manifest.json", { cache: "no-store" })).status);
  await page.evaluate(() => globalThis.blazexBh01Stop());
  const disposed = await page.evaluate(() => globalThis.__blazexBH01.final_resources);
  assert.equal(disposed.dom.roots, 0);
  assert.equal(disposed.bridge.pending, 0);
  await page.evaluate(() => globalThis.blazexBh01Start());
  await terminal(page);
  const restarted = await state(page);
  await page.reload({ waitUntil: "domcontentloaded" });
  await terminal(page);
  const navigated = await state(page);
  evidence.lifecycle_changes = {
    offline,
    online_status: online,
    disposed: { dom: disposed.dom, bridge: disposed.bridge, server: disposed.server },
    restarted_state: restarted.state,
    navigation_state: navigated.state,
    session_expiry: "covered-by-retained-phase6-evidence",
    server_restart: "covered-by-retained-phase6-evidence",
    visibility: "automation-not-authoritative",
    memory_pressure: "unobservable",
  };
  if (authority === "required-row") {
    assert.equal(restarted.state, "ready");
    assert.equal(navigated.state, "ready");
  }
  await page.evaluate(() => globalThis.blazexBh01Stop());
  await context.close();
  evidence.status = "observed";
  evidence.evidence_sha256 = createHash("sha256").update(JSON.stringify({ capabilities: evidence.capabilities, deployment: evidence.deployment, initial: evidence.initial, negative_scenarios: evidence.negative_scenarios, lifecycle_changes: evidence.lifecycle_changes })).digest("hex");
} catch (error) {
  evidence.status = "observed-fail";
  evidence.error = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 8 prerequisite probe (${browserName}): ${evidence.status.toUpperCase()}`);

async function terminal(page) {
  await page.waitForFunction(() => ["ready", "failed", "fallback"].includes(globalThis.__blazexBH01?.state), null, { timeout: 30_000 });
}

async function state(page) {
  return page.evaluate(() => ({
    state: globalThis.__blazexBH01.state,
    prerequisites: globalThis.__blazexBH01.prerequisites,
    error: globalThis.__blazexBH01.error ?? null,
    generation: globalThis.__blazexBH01.activation?.generation ?? null,
    runtime_ready: globalThis.__blazexBH01.events.some((event) => event.type === "runtime-ready"),
  }));
}

async function capabilityProbe(page) {
  return page.evaluate(async () => {
    const minimal = new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0]);
    const result = {
      webassembly_validate: WebAssembly.validate(minimal),
      memory: false,
      table: false,
      shared_memory: false,
      workers: typeof Worker === "function",
      modules: "noModule" in document.createElement("script"),
      streaming: typeof WebAssembly.instantiateStreaming === "function",
      buffered: false,
      structured_clone: typeof structuredClone === "function",
      transferable_array_buffer: false,
      timers: typeof setTimeout === "function" && typeof clearTimeout === "function",
      secure_context: isSecureContext,
      cross_origin_isolated: crossOriginIsolated,
    };
    try { result.memory = new WebAssembly.Memory({ initial: 1 }).buffer.byteLength === 65_536; } catch {}
    try { result.table = new WebAssembly.Table({ initial: 1, element: "anyfunc" }).length === 1; } catch {}
    try { result.shared_memory = new WebAssembly.Memory({ initial: 1, maximum: 1, shared: true }).buffer instanceof SharedArrayBuffer; } catch {}
    try { await WebAssembly.instantiate(minimal); result.buffered = true; } catch {}
    try {
      const channel = new MessageChannel();
      const bytes = new ArrayBuffer(8);
      channel.port1.postMessage(bytes, [bytes]);
      result.transferable_array_buffer = bytes.byteLength === 0;
      channel.port1.close(); channel.port2.close();
    } catch {}
    return result;
  });
}

async function deploymentProbe(page) {
  return page.evaluate(async () => {
    const manifest = await fetch("./runtime-manifest.json", { cache: "no-store" });
    const declaration = (await manifest.clone().json()).artifacts.find((item) => item.role === "runtime-wasm");
    const artifact = await fetch(new URL(declaration.path, manifest.url), { cache: "no-store", redirect: "manual" });
    return {
      manifest_status: manifest.status,
      manifest_cache: manifest.headers.get("cache-control"),
      wasm_status: artifact.status,
      wasm_mime: artifact.headers.get("content-type"),
      wasm_compression: artifact.headers.get("content-encoding") ?? "identity",
      wasm_redirected: artifact.redirected,
      coop: artifact.headers.get("cross-origin-opener-policy"),
      coep: artifact.headers.get("cross-origin-embedder-policy"),
      corp: artifact.headers.get("cross-origin-resource-policy"),
      cors: artifact.headers.get("access-control-allow-origin"),
    };
  });
}

async function prerequisiteFailure(name, overrides, expectedDecision) {
  const context = await browser.newContext();
  await context.addInitScript(({ name, overrides }) => {
    if (name === "streaming") {
      Object.defineProperty(WebAssembly, "instantiateStreaming", { value: overrides.instantiateStreaming, configurable: true });
    } else {
      Object.defineProperty(globalThis, name === "webassembly" ? "WebAssembly" : "Worker", { value: overrides[name === "webassembly" ? "WebAssembly" : "Worker"], configurable: true });
    }
  }, { name, overrides });
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await terminal(page);
  const result = await state(page);
  assert.equal(result.prerequisites.decision, expectedDecision);
  assert.equal(result.runtime_ready, expectedDecision === "alternate-loading" && result.state === "ready");
  await context.close();
  return { name, expected_decision: expectedDecision, ...result };
}

async function isolationFailure() {
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
  const result = await state(page);
  assert.equal(result.prerequisites.decision, "unsupported");
  assert.equal(result.runtime_ready, false);
  await context.close();
  return { name: "cross-origin-isolation", expected_decision: "unsupported", ...result };
}
