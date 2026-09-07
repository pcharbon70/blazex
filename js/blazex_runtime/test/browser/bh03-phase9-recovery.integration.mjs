import assert from "node:assert/strict";
import { readFile, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import os from "node:os";
import { chromium, firefox } from "playwright-core";

const baseUrl = process.env.BLAZEX_BASE_URL ?? "http://127.0.0.1:4197/bh03/";
const revision = process.env.BLAZEX_REVISION;
assert.match(revision ?? "", /^[0-9a-f]{40}$/, "An exact committed candidate is required");
const evidencePath = process.env.BLAZEX_EVIDENCE_PATH ?? "/tmp/bh03-phase9-recovery.json";
// Installed only into intercepted test responses, never into production assets.
// Calls the real runtime callback; it does not simulate an OS/process crash.
const instrumentation = `
globalThis.__bh03RecoveryProbe = {
  loss(type) {
    if (!active?.runtime) throw new Error("No real runtime");
    if (type === "exit") active.runtime.onExit(1);
    else active.runtime.onAbort("controlled-phase9-callback-fault");
  },
  stale() {
    post({ ...active, generation: active.generation + 99 }, "runtime-exited", { status: 1 });
  }
};
`;
const targets = [
  { browser: "chrome", engine: chromium, executable: process.env.BLAZEX_CHROME_PATH },
  { browser: "firefox", engine: firefox, executable: process.env.BLAZEX_FIREFOX_PATH },
];
const scenarios = ["stale-event-rejection", "exit-replacement-root-replay", "abort-replacement-root-replay",
  "second-loss-fallback", "intentional-shutdown-no-replacement"];
const evidence = {
  schema_version: "1.0.0", evidence_id: "BX-BH03-PHASE-09-RECOVERY-0.1",
  captured_at: new Date().toISOString(), implementation_revision: revision,
  platform: os.platform() + " " + os.release() + " " + os.arch(),
  node_version: process.version, scenario_set: scenarios,
  injection: "test-response-only real-runtime onExit/onAbort callback; not an OS crash",
  harness_sha256: createHash("sha256").update(await readFile(new URL(import.meta.url))).digest("hex"),
  results: [], support_state: "unsupported", api_state: "experimental-not-stable",
  deferred: ["safari", "mobile", "physical-devices", "second-host", "manual-assistive-technology"],
};
for (const target of targets) {
  let browser;
  const row = { browser: target.browser, executable: target.executable, result: "running", observations: [], failures: [] };
  evidence.results.push(row);
  try {
    assert.ok(target.executable);
    browser = await target.engine.launch({ executablePath: target.executable, headless: true,
      ...(target.browser === "chrome" ? { args: ["--no-sandbox", "--disable-dev-shm-usage"] } : {}) });
    row.browser_version = browser.version();
    for (const kind of ["exit", "abort"]) {
      const context = await browser.newContext();
      try {
        await context.route("**/bh03/runtime-frame.js", async route => {
          const response = await route.fetch();
          await route.fulfill({ response, body: await response.text() + instrumentation });
        });
        const page = await context.newPage();
        const errors = [];
        page.on("pageerror", error => errors.push(error.message));
        await page.goto(baseUrl);
        await page.waitForFunction(() => globalThis.__blazexBH03?.state === "ready", null, { timeout: 45000 });
        const initial = await snapshot(page);
        const first = runtimeFrame(page);
        await first.evaluate(() => globalThis.__bh03RecoveryProbe.stale());
        // Same frame sends stale then live exit in order; wait for stale diagnostic.
        await page.waitForFunction(() => globalThis.__blazexBH03.events.some(e => e.stage === "stale-event-rejected"));
        assert.equal((await snapshot(page)).runtime_starts, 1);
        await first.evaluate(value => globalThis.__bh03RecoveryProbe.loss(value), kind).catch(error => {
          if (!/destroyed|detached|closed/i.test(error.message)) throw error;
        });
        await page.waitForFunction(() => globalThis.__blazexBH03?.snapshot?.registry?.metrics.recoveries === 1, null, { timeout: 45000 });
        const recovered = await snapshot(page);
        assert.equal(recovered.state, "ready");
        assert.equal(recovered.runtime_starts, 2);
        assert.equal(recovered.scope.runtime_generation, initial.scope.runtime_generation + 1);
        assert.deepEqual(recovered.roots.states, initial.roots.states);
        assert.equal(recovered.runtime_acknowledgement_count, 12);
        assert.equal(recovered.registry.metrics.losses, 1);
        assert.equal(await page.locator('iframe[title="BlazeX experimental runtime host"]').count(), 1);
        if (kind === "exit") {
          await runtimeFrame(page).evaluate(() => globalThis.__bh03RecoveryProbe.loss("abort")).catch(error => {
            if (!/destroyed|detached|closed/i.test(error.message)) throw error;
          });
          await page.waitForFunction(() => globalThis.__blazexBH03?.state === "fallback");
          const fallback = await snapshot(page);
          assert.equal(fallback.runtime_starts, 2);
          assert.equal(fallback.registry.metrics.losses, 2);
          assert.equal(fallback.fallback.failure_class, "recovery-exhausted");
          assert.equal(fallback.fallback.partial_activation, false);
          assert.equal(fallback.roots.accepting, false);
          assert.ok(Object.values(fallback.roots.states).every(value => value !== "ready"));
          assert.equal(await page.locator("iframe").count(), 0);
          row.observations.push({ kind, recovered, terminal: fallback, frames_after_terminal: 0 });
        } else {
          await page.evaluate(() => globalThis.blazexBh03Stop());
          const stopped = await snapshot(page);
          assert.equal(stopped.state, "stopped");
          assert.equal(stopped.registry.metrics.losses, 1);
          assert.equal(stopped.runtime_starts, 2);
          assert.equal(stopped.shutdown.acknowledged, true);
          assert.equal(await page.locator("iframe").count(), 0);
          row.observations.push({ kind, recovered, terminal: stopped, frames_after_terminal: 0 });
        }
        assert.deepEqual(errors, []);
      } finally { await context.close(); }
    }
    row.result = "passed";
  } catch (error) {
    row.result = "failed";
    row.failures.push(String(error.stack ?? error).slice(0, 2048));
  } finally { await browser?.close(); }
}
await writeFile(evidencePath, JSON.stringify(evidence, null, 2) + "\n");
assert.ok(evidence.results.every(row => row.result === "passed"), JSON.stringify(evidence.results.map(r => r.failures)));
console.log("BH-03 Phase 9 recovery PASS: two browsers, five scenarios, real callback/transport/root replay.");
console.log(evidencePath);

function snapshot(page) { return page.evaluate(() => globalThis.__blazexBH03.snapshot); }
function runtimeFrame(page) {
  const frame = page.frames().find(item => item.url().endsWith("/bh03/runtime-frame.html"));
  assert.ok(frame, "Runtime frame missing");
  return frame;
}
