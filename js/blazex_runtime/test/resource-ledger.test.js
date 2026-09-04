import assert from "node:assert/strict";
import test from "node:test";

import { ResourceLedger } from "../src/index.js";

const zero = ["runtime.processes", "browser.listeners", "transport.pending", "server.tasks"];

test("reports baseline, peak, disposed convergence, and explained unknowns", () => {
  const ledger = new ResourceLedger({ scenarioId: "phase7-resources", generation: 3, zeroAtDisposal: zero });
  ledger.explainUnknown("browser.workers", "The selected parent-frame API does not expose worker count");
  ledger.observe("baseline", { runtime: { processes: 0 }, browser: { listeners: 0, workers: null }, transport: { pending: 0 }, server: { tasks: 0 } });
  ledger.observe("peak", { runtime: { processes: 4 }, browser: { listeners: 7, workers: null }, transport: { pending: 2 }, server: { tasks: 1 } });
  ledger.observe("stable", { runtime: { processes: 2 }, browser: { listeners: 4, workers: null }, transport: { pending: 0 }, server: { tasks: 0 } });
  ledger.observe("disposed", { runtime: { processes: 0 }, browser: { listeners: 0, workers: null }, transport: { pending: 0 }, server: { tasks: 0 } });
  const report = ledger.report();
  assert.equal(report.sample_count, 4);
  assert.equal(report.peak["browser.listeners"], 7);
  assert.equal(report.unknown["browser.workers"].includes("does not expose"), true);
  assert.deepEqual(report.leaks, []);
  assert.equal(report.converged, true);
});

test("rejects unexplained unknown and invalid counts", () => {
  const ledger = new ResourceLedger({ scenarioId: "phase7-resources", generation: 1 });
  assert.throws(() => ledger.observe("baseline", { browser: { workers: null } }), { code: "resource-unknown-unexplained" });
  assert.throws(() => ledger.observe("baseline", { browser: { workers: -1 } }), { code: "resource-value-invalid" });
});

test("detects nonconverging disposal", () => {
  const ledger = new ResourceLedger({ scenarioId: "phase7-resources", generation: 1, zeroAtDisposal: zero });
  ledger.observe("baseline", { runtime: { processes: 0 }, browser: { listeners: 0 }, transport: { pending: 0 }, server: { tasks: 0 } });
  ledger.observe("disposed", { runtime: { processes: 0 }, browser: { listeners: 1 }, transport: { pending: 0 }, server: { tasks: 0 } });
  assert.deepEqual(ledger.report().leaks, ["browser.listeners"]);
  assert.equal(ledger.report().converged, false);
});

test("rejects stale generations and bounded sample overflow", () => {
  const ledger = new ResourceLedger({ scenarioId: "phase7-resources", generation: 2 });
  assert.throws(() => ledger.observe("stale", {}, { generation: 1 }), { code: "resource-sample-invalid" });
  for (let index = 0; index < 256; index += 1) ledger.observe(`sample-${index}`, {});
  assert.throws(() => ledger.observe("overflow", {}), { code: "resource-sample-limit" });
});
