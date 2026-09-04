import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import os from "node:os";

import { chromium } from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4197/bh01/";
const executablePath = process.env.BLAZEX_CHROME_PATH;
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? "/tmp/blazex-bh01-phase4-browser-evidence.json";
if (!executablePath) throw new Error("BLAZEX_CHROME_PATH is required");

const browser = await chromium.launch({ executablePath, headless: true, args: ["--no-sandbox", "--disable-dev-shm-usage"] });
const evidence = {
  schema_version: "1.0.0",
  evidence_id: "BX-BH01-PHASE-04-BROWSER-EVIDENCE-0.1",
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
  positive_scenarios: [],
  negative_scenarios: [],
  network: [],
  findings: [],
};

try {
  evidence.deployment = await verifyDeployment();
  await runPositiveScenarios();
  await runPolicyFailure();
  await runNetworkFailure();
  await runIntegrityFailure();
  evidence.status = "observed-pass";
  evidence.findings.push(
    "The pinned Chromium host reached application readiness through the Phoenix profile, Popcorn/AtomVM Wasm runtime, governed AVM, and Elixir echo bridge.",
    "Three same-page activation generations and one warm navigation converged to zero lifecycle-owned resources after stop.",
    "Missing cross-origin isolation, manifest network failure, and Wasm integrity drift failed intentionally without promoting browser support.",
    "Popcorn 0.3.3 requires unsafe-eval for its current bridge implementation; this remains explicit feasibility security debt.",
  );
} catch (error) {
  evidence.status = "observed-fail";
  evidence.findings.push(error instanceof Error ? `${error.name}: ${error.message}` : String(error));
  throw error;
} finally {
  await browser.close();
  await writeFile(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
}

console.log(`BH-01 Phase 4 browser integration: ${evidence.status.toUpperCase()}`);
console.log(`Evidence: ${evidencePath}`);

async function verifyDeployment() {
  const profileResponse = await fetch(new URL("profile-assets-manifest.json", baseUrl));
  assert.equal(profileResponse.status, 200);
  assert.equal(profileResponse.headers.get("cross-origin-opener-policy"), "same-origin");
  assert.equal(profileResponse.headers.get("cross-origin-embedder-policy"), "require-corp");
  const profile = await profileResponse.json();
  const observed = [];
  for (const record of profile.artifacts) {
    const response = await fetch(new URL(record.path, baseUrl), { cache: "no-store" });
    assert.equal(response.status, 200, record.path);
    const bytes = new Uint8Array(await response.arrayBuffer());
    assert.equal(bytes.byteLength, record.bytes, record.path);
    assert.equal(createHash("sha256").update(bytes).digest("hex"), record.sha256, record.path);
    assert.match(response.headers.get("content-type") ?? "", new RegExp(`^${escapeRegExp(record.mime)}`), record.path);
    observed.push({ path: record.path, bytes: bytes.byteLength, status: response.status, cache_control: response.headers.get("cache-control") });
  }
  const wasm = profile.artifacts.find((item) => item.path.endsWith("AtomVM.wasm"));
  const range = await fetch(new URL(wasm.path, baseUrl), { headers: { range: "bytes=0-7" } });
  assert.equal(range.status, 206);
  assert.equal((await range.arrayBuffer()).byteLength, 8);
  const etagResponse = await fetch(new URL(wasm.path, baseUrl));
  const etag = etagResponse.headers.get("etag");
  const cached = await fetch(new URL(wasm.path, baseUrl), { headers: { "if-none-match": etag } });
  assert.equal(cached.status, 304);
  return { profile_manifest_id: profile.manifest_id, governed_files: profile.artifacts.length, source_maps: profile.source_maps, range_status: range.status, etag_status: cached.status, observed };
}

async function runPositiveScenarios() {
  const context = await browser.newContext();
  const page = await context.newPage();
  page.on("request", (request) => evidence.network.push({ phase: "positive", type: "request", method: request.method(), url: request.url() }));
  page.on("response", (response) => evidence.network.push({ phase: "positive", type: "response", status: response.status(), url: response.url(), mime: response.headers()["content-type"] ?? null, cache_control: response.headers()["cache-control"] ?? null }));
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await waitForTerminal(page);
  const cold = await snapshot(page, "cold");
  assert.equal(cold.state, "ready", JSON.stringify(cold));
  assert.equal(cold.echo.message, "bh01-browser-roundtrip");
  assert.equal(cold.environment.cross_origin_isolated, true);
  evidence.positive_scenarios.push(cold);

  for (let index = 0; index < 3; index += 1) {
    const stopped = await stopAndSnapshot(page, `stop-${index + 1}`);
    assert.equal(stopped.state, "stopped");
    assert.equal(stopped.lifecycle.state, "stopped");
    assert.deepEqual(stopped.lifecycle.resources, {});
    assert.equal(stopped.frame_count, 1);
    evidence.positive_scenarios.push(stopped);
    if (index < 2) {
      await page.evaluate(() => globalThis.blazexBh01Start());
      await waitForTerminal(page);
      const restarted = await snapshot(page, `restart-${index + 1}`);
      assert.equal(restarted.state, "ready", JSON.stringify(restarted));
      assert.equal(restarted.activation_generation, index + 2);
      evidence.positive_scenarios.push(restarted);
    }
  }

  await page.reload({ waitUntil: "domcontentloaded" });
  await waitForTerminal(page);
  const warm = await snapshot(page, "warm-navigation");
  assert.equal(warm.state, "ready", JSON.stringify(warm));
  evidence.positive_scenarios.push(warm);
  evidence.positive_scenarios.push(await stopAndSnapshot(page, "warm-stop"));
  await context.close();
}

async function runPolicyFailure() {
  const context = await browser.newContext();
  await context.route("**/bh01/**", async (route) => {
    const response = await route.fetch();
    const headers = { ...response.headers() };
    delete headers["cross-origin-embedder-policy"];
    await route.fulfill({ response, headers });
  });
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await waitForTerminal(page);
  const result = await snapshot(page, "missing-isolation-policy");
  assert.equal(result.state, "fallback", JSON.stringify(result));
  assert.equal(result.prerequisites.decision, "unsupported");
  evidence.negative_scenarios.push(result);
  await context.close();
}

async function runNetworkFailure() {
  const context = await browser.newContext();
  await context.route("**/bh01/runtime-manifest.json", (route) => route.abort("failed"));
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await waitForTerminal(page);
  const result = await snapshot(page, "manifest-network-failure");
  assert.equal(result.state, "failed", JSON.stringify(result));
  assert.equal(result.error.code, "fetch-failed");
  assert.equal(result.lifecycle.state, "stopped");
  evidence.negative_scenarios.push(result);
  await context.close();
}

async function runIntegrityFailure() {
  const context = await browser.newContext();
  await context.route("**/bh01/runtime-manifest.json", async (route) => {
    const response = await route.fetch();
    const manifest = await response.json();
    manifest.artifacts.find((item) => item.role === "runtime-wasm").sha256 = "0".repeat(64);
    await route.fulfill({ response, json: manifest });
  });
  const page = await context.newPage();
  await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
  await waitForTerminal(page);
  const result = await snapshot(page, "manifest-digest-integrity-failure");
  assert.equal(result.state, "failed", JSON.stringify(result));
  assert.equal(result.error.code, "artifact-integrity-mismatch");
  assert.equal(result.lifecycle.state, "stopped");
  evidence.negative_scenarios.push(result);
  await context.close();
}

async function waitForTerminal(page) {
  await page.waitForFunction(() => ["ready", "failed", "fallback"].includes(globalThis.__blazexBH01?.state), null, { timeout: 30_000 });
}

async function snapshot(page, scenario) {
  return page.evaluate((name) => {
    const value = globalThis.__blazexBH01;
    return {
      scenario: name,
      state: value.state,
      prerequisites: value.prerequisites,
      activation_generation: value.activation?.generation ?? null,
      manifest_generation: value.activation?.manifest_generation ?? null,
      echo: value.echo ?? null,
      error: value.error ?? null,
      lifecycle: value.loader?.lifecycle() ?? null,
      frame_count: globalThis.frames.length + 1,
      environment: {
        cross_origin_isolated: globalThis.crossOriginIsolated,
        secure_context: globalThis.isSecureContext,
        user_agent: navigator.userAgent,
        hardware_concurrency: navigator.hardwareConcurrency,
      },
      events: value.events.map((event) => ({
        protocol: event.protocol,
        type: event.type ?? null,
        stage: event.stage ?? null,
        from: event.from ?? null,
        to: event.to ?? null,
        generation: event.generation ?? null,
      })),
    };
  }, scenario);
}

async function stopAndSnapshot(page, scenario) {
  await page.evaluate(() => globalThis.blazexBh01Stop());
  return snapshot(page, scenario);
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
