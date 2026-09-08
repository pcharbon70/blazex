import test from "node:test";
import assert from "node:assert/strict";
import { InteractionBridge, InteractionStream, INTERACTION_BRIDGE } from "../src/interaction-stream.js";
import { INTERACTION_PROTOCOL, listenerIdentity } from "../src/interaction-record.js";
const source = "bx-" + "a".repeat(24), listener = listenerIdentity(source, "activate");
const header = { root_id: "one", lifecycle_generation: 2, owner: "root-owner", generation: 1, revision: 1, transaction_id: "tx-" + "b".repeat(24), digest: "c".repeat(64) };
const record = (sequence = 1) => ({ ...header, protocol: INTERACTION_PROTOCOL, provenance: "local-event", source, listener_id: listener, semantic: "activate", payload: {}, sequence, timestamp: sequence });
function response(request, transaction = null) {
  const ack = { ...header, sequence: request.payload.sequence, listener_id: listener, outcome: "accepted", diagnostic: null };
  return { protocol: INTERACTION_BRIDGE, root_id: "one", request_id: request.request_id, result: request.operation === "root.render_ack" ? { outcome: "committed", sequence: request.payload.sequence } : { ack, transaction } };
}
function setup(request = async req => response(req), timeoutMs = 5000) {
  const cancellations = [], calls = [], handle = { snapshot: () => ({ state: "ready", root_id: "one", root_generation: 2 }) };
  const bridge = new InteractionBridge({ protocol: INTERACTION_BRIDGE, rootId: "one", transport: { request: req => { calls.push(req); return request(req); }, cancel: req => cancellations.push(req) } });
  const stream = new InteractionStream({ bridge, rootHandle: handle, timeoutMs });
  stream.setContext({ ...header, listeners: [listener] }); return { stream, handle, calls, cancellations };
}
test("ordered local events and render acknowledgements use only negotiated v2 operations", async () => {
  const { stream, calls } = setup(async req => response(req, req.operation === "root.interaction" ? { transaction_id: "candidate" } : null));
  const commits = [];
  stream.bindDOM({ submit: async (_token, tx) => { commits.push(tx); return { state: "committed" }; } }, {});
  const result = await Promise.all([stream.enqueue(record(1)), stream.enqueue(record(2))]);
  assert.ok(result.every(r => r.outcome === "accepted")); assert.equal(commits.length, 2);
  assert.deepEqual(calls.map(c => c.operation), ["root.interaction", "root.render_ack", "root.interaction", "root.render_ack"]);
  assert.throws(() => stream.enqueue(record(2)), e => e.code === "duplicate"); stream.dispose();
});
test("bounded queue includes active work; independent stream progresses during delay", async () => {
  let release;
  const a = setup(req => new Promise(resolve => { release = () => resolve(response(req)); }));
  const pending = Array.from({ length: 64 }, (_, i) => a.stream.enqueue(record(i + 1)));
  assert.throws(() => a.stream.enqueue(record(65)), e => e.code === "limit");
  await Promise.resolve();
  const b = setup(); assert.equal((await b.stream.enqueue(record())).outcome, "accepted");
  assert.equal(a.stream.snapshot().max_depth, 64); a.stream.dispose(); release();
  assert.ok((await Promise.all(pending)).every(r => r.outcome === "rejected")); assert.equal(a.stream.snapshot().queued, 0); b.stream.dispose();
});
test("timeout cancels once, rejects queued work, and ignores late responses", async () => {
  let release;
  const a = setup(req => new Promise(resolve => { release = () => resolve(response(req)); }), 10);
  const pending = [a.stream.enqueue(record()), a.stream.enqueue(record(2))];
  const results = await Promise.all(pending);
  assert.equal(results[0].diagnostic, "timeout"); assert.equal(results[1].diagnostic, "disposed-root");
  assert.equal(a.cancellations.length, 1); release(); await Promise.resolve(); assert.equal(a.stream.snapshot().queued, 0);
});
test("wrong root, stale context, listener and bridge mismatches fail before component dispatch", async () => {
  const a = setup();
  for (const bad of [{ ...record(), root_id: "other" }, { ...record(), generation: 2 }, { ...record(), revision: 2 }, { ...record(), digest: "d".repeat(64) }, { ...record(), source: "bx-" + "e".repeat(24) }]) assert.throws(() => a.stream.enqueue(bad));
  assert.equal(a.calls.length, 0); a.stream.dispose();
  assert.throws(() => new InteractionBridge({ protocol: "blazex.host-bridge/1", rootId: "one", transport: {} }), e => e.code === "incompatible");
  const b = setup(async req => ({ ...response(req), request_id: "other" }));
  assert.equal((await b.stream.enqueue(record())).diagnostic, "ownership"); assert.ok(b.stream.snapshot().disposed);
});
test("a new committed revision rejects queued old-revision events without coalescing", async () => {
  let release;
  const a = setup(req => new Promise(resolve => { release = () => resolve(response(req)); }));
  const first = a.stream.enqueue(record()), second = a.stream.enqueue(record(2)); await Promise.resolve();
  a.stream.setContext({ ...header, revision: 2, listeners: [listener] });
  assert.equal((await second).diagnostic, "stale"); release();
  assert.equal((await first).diagnostic, "stale"); assert.equal(a.calls.length, 1);
});
