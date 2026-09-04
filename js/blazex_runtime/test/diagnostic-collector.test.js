import assert from "node:assert/strict";
import test from "node:test";

import { DiagnosticCollector, errorRecord, redactDiagnostic } from "../src/index.js";

function record(overrides = {}) {
  return {
    scenarioId: "phase7",
    generation: 2,
    correlationId: "command-1",
    layer: "server-transport",
    category: "transport",
    severity: "error",
    owner: "browser-host-owner",
    code: "transport-unavailable",
    userMessage: "The operation could not reach the server.",
    internal: {},
    ...overrides,
  };
}

test("emits correlated developer and user summaries without console dependence", () => {
  const collector = new DiagnosticCollector({ source: "browser-host", clockId: "performance", clock: () => 42 });
  collector.record(record({ internal: { stage: "fetch", http_status: 503 } }));
  const summary = collector.summary();
  assert.equal(summary.count, 1);
  assert.equal(summary.developer[0].correlation_id, "command-1");
  assert.equal(summary.developer[0].internal.http_status, 503);
  assert.deepEqual(summary.user[0], { severity: "error", code: "transport-unavailable", message: "The operation could not reach the server.", correlation_id: "command-1" });
});

test("redacts keys, credentials, queries, local paths, and stack frames", () => {
  const value = redactDiagnostic({
    cookie: "sid=opaque",
    csrf_token: "csrf-value",
    request_body: { password: "password-value" },
    authorization_detail: "operator-rule",
    safe: "Bearer abc ?token=xyz /home/user/private.ex\n    at /tmp/source.js:1",
  });
  const encoded = JSON.stringify(value);
  for (const secret of ["opaque", "csrf-value", "password-value", "operator-rule", "abc", "xyz", "/home/user", "/tmp/source"]) assert.equal(encoded.includes(secret), false, secret);
  assert.equal(encoded.includes("[redacted]"), true);
  assert.equal(encoded.includes("[local-path]"), true);
  assert.equal(encoded.includes("[stack-redacted]"), true);
  assert.equal(errorRecord(new Error("token=hidden /var/app/source.ex\n at private" )).message.includes("hidden"), false);
});

test("drops identical diagnostics and counts the duplicate", () => {
  const collector = new DiagnosticCollector({ source: "browser-host", clockId: "performance", clock: () => 1 });
  assert.ok(collector.record(record()));
  assert.equal(collector.record(record()), null);
  assert.equal(collector.summary().count, 1);
  assert.equal(collector.summary().duplicate_drops, 1);
});

test("rejects orphan correlation, unknown classification, and retention overflow", () => {
  const collector = new DiagnosticCollector({ source: "browser-host", clockId: "performance", clock: () => 1 });
  assert.throws(() => collector.record(record({ correlationId: "" })), { code: "diagnostic-record-invalid" });
  assert.throws(() => collector.record(record({ category: "unknown" })), { code: "diagnostic-record-invalid" });
  for (let index = 0; index < 256; index += 1) collector.record(record({ correlationId: `event-${index}` }));
  assert.throws(() => collector.record(record({ correlationId: "overflow" })), { code: "diagnostic-retention-limit" });
});
