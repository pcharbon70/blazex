// Acceptance probe: reproduces the production composition, not a crash detector.
// Exit 0 means the recorded acceptance blocker reproduced, not that recovery passed.
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { webcrypto } from "node:crypto";
import {
  BrowserRuntimeStartup, REQUIRED_COMPATIBILITY, SharedRuntimeRegistry,
  validateHostManifest,
} from "../../src/index.js";

const fixtures = JSON.parse(await readFile(new URL("../../../../integration/bh-03/phase-03/startup-fixtures-v0.1.0.json", import.meta.url)));
const mime = ["text/javascript", "application/wasm", "application/vnd.atomvm.avm"];
const manifest = validateHostManifest({
  schema_version: "1.0.0", manifest_id: "BX-BH03-PHASE-08-LOSS-PROBE",
  generation: 8, profile_id: "acceptance-probe",
  compatibility: REQUIRED_COMPATIBILITY,
  prerequisites: {
    browser_required: ["webassembly", "workers", "module-scripts", "fetch", "abort-controller", "subtle-crypto"],
    deployment_required: ["secure-context", "cross-origin-isolation", "same-origin-artifacts"],
    optional: ["wasm-streaming"],
  },
  artifacts: fixtures.artifact_payloads.map((item, index) => ({
    id: `probe-${index}`, role: item.role, path: `./artifact-${index}`,
    mime: mime[index], bytes: item.bytes, sha256: item.sha256,
  })),
}, "https://example.test/bh03/manifest.json");
const gate = { protocol: "blazex.pre-acquisition-gate/1", decision: "eligible-for-artifact-acquisition", manifest };
let emit;
let message;
let stops = 0;
const startup = new BrowserRuntimeStartup({
  onEvent() {}, // Profile's record() only records events; it does not report loss.
  frameFactory: ({ onEvent }) => ({
    async attach() {},
    start(value) {
      message = value;
      emit = onEvent;
      queueMicrotask(() => emit({
        protocol: "blazex.runtime.frame/1", generation: value.generation,
        manifest_generation: value.manifest.generation, type: "application-ready",
        name: "popcorn_app_ready",
      }));
    },
    request() {}, cancel() {},
    stop() { stops += 1; },
  }),
});
const registry = new SharedRuntimeRegistry({ startRuntime: (options) => startup.start(options) });
const open = {
  scopeId: "probe-page", compatibility: REQUIRED_COMPATIBILITY,
  startupOptions: {
    gate, frameUrl: "https://example.test/bh03/frame.html", cryptoImpl: webcrypto,
    fetchImpl: async (url) => {
      const index = manifest.artifacts.findIndex((item) => item.url === url.href);
      return new Response(Buffer.from(fixtures.artifact_payloads[index].base64, "base64"), {
        headers: { "content-type": mime[index] },
      });
    },
  },
};
const scope = await registry.open(open);
emit({
  protocol: "blazex.runtime.frame/1", generation: message.generation,
  manifest_generation: manifest.generation, type: "runtime-exited", status: 1,
});
assert.equal(startup.snapshot().state, "failed");
assert.equal(stops, 1);
assert.equal(scope.snapshot().state, "ready");
assert.equal(registry.snapshot().metrics.losses, 0);
assert.strictEqual(await registry.open(open), scope);
console.log(JSON.stringify({
  finding_id: "BX-BH03-FINDING-UNREPORTED-RUNTIME-LOSS",
  result: "blocker-reproduced", evidence_class: "injected-frame-real-startup-and-registry",
  startup_state: startup.snapshot().state, scope_state: scope.snapshot().state,
  loss_reports: registry.snapshot().metrics.losses, transport_stops: stops,
  subsequent_open_returns_stale_scope: true,
}, null, 2));
