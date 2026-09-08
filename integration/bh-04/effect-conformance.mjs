import fs from "node:fs";
import assert from "node:assert/strict";
import { copyEffects } from "../../js/blazex_runtime/src/effect-wire.js";
import { validateInteraction, listenerIdentity } from "../../js/blazex_runtime/src/interaction-record.js";
import { decodeIntent } from "../../js/blazex_runtime/src/render-intent-data.js";
import { planTransaction } from "../../js/blazex_runtime/src/dom-transaction-plan.js";
const evidence = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
let proposed = 0, committed = 0, delivered = 0, results = 0;
const headers = ["root_id", "lifecycle_generation", "owner", "generation", "revision", "transaction_id", "digest"];
for (const browser of evidence.results) {
  const states = new Map();
  async function propose(state, raw) {
    const outer = await copyEffects(raw, ["time"]), envelope = outer.continuity;
    assert.equal(envelope.base_control_digest, state.control_digest);
    const planned = await planTransaction(state, envelope.transaction);
    state.pending = { outer, envelope, projection: planned.projection }; proposed++;
  }
  function commit(state, response, sequence) {
    const { outer, envelope, projection } = state.pending, tx = envelope.transaction;
    assert.equal(response.effects_digest, outer.digest); assert.equal(response.state, "committed");
    assert.equal(response.results.length, outer.effects.length);
    response.results.forEach((r, i) => { const e = outer.effects[i]; assert.equal(r.id, e.id); assert.ok(["ok", "timeout", "failed", "cancelled"].includes(r.status)); assert.ok(r.status === "ok" || e.fallback !== "fail"); });
    const continuity = response.ack, ack = continuity.ack;
    assert.equal(continuity.continuity_digest, envelope.digest); assert.equal(continuity.state, "committed"); assert.equal(ack.state, "committed");
    for (const key of ["owner", "generation", "root", "base_revision", "target_revision", "transaction_id", "digest"]) assert.equal(ack[key], tx[key]);
    Object.assign(state, { projection, revision: tx.target_revision, generation: tx.generation, digest: tx.digest, control_digest: envelope.control_digest, last_sequence: sequence, pending: null });
    state.context = { root_id: state.root_id, lifecycle_generation: state.lifecycle_generation, owner: tx.owner, generation: tx.generation, revision: tx.target_revision, transaction_id: tx.transaction_id, digest: tx.digest };
    state.listeners = new Set(projection.nodes.flatMap(n => (decodeIntent(n.listeners) ?? []).map(b => listenerIdentity(n.id, b.semantic))));
    results += response.results.length; committed++;
  }
  for (const { request: q, response: r } of browser.runtime) {
    if (q.control === "init") {
      const tx = r.transaction.continuity.transaction;
      const state = { root_id: q.root_id, lifecycle_generation: q.lifecycle_generation, owner: tx.owner, generation: tx.generation, revision: 0, projection: null, disposed: false, seen: [], control_digest: null, last_sequence: 0 };
      states.set(q.root_id, state); await propose(state, r.transaction);
    } else if (q.control === "initial_ack") commit(states.get(q.root_id), q.ack, 0);
    else if (q.control === "update") await propose(states.get(q.root_id), r.transaction);
    else if (q.control === "update_ack") { const s = states.get(q.root_id); commit(s, q.ack, s.last_sequence); }
    else if (q.control === "stop") { const s = states.get(q.root_id); s.disposed = true; s.pending = null; }
    else if (q.operation === "root.interaction") {
      assert.equal(q.protocol, "blazex.host-bridge/4"); const s = states.get(q.root_id), event = validateInteraction(q.payload);
      assert.ok(!s.pending && !s.disposed && event.sequence > s.last_sequence);
      assert.ok(headers.every(k => event[k] === s.context[k]) && s.listeners.has(event.listener_id));
      assert.equal(r.result.ack.outcome, "accepted");
      for (const k of [...headers, "sequence", "listener_id"]) assert.equal(r.result.ack[k], event[k]);
      await propose(s, r.result.transaction); delivered++;
    } else if (q.operation === "root.render_ack") {
      if (r.error) assert.notEqual(q.payload.ack.state, "committed");
      else { assert.equal(r.result.outcome, "committed"); commit(states.get(q.root_id), q.payload.ack, q.payload.sequence); }
    }
  }
  assert.ok([...states.values()].every(s => s.disposed && !s.pending));
}
console.log(JSON.stringify({ browsers: evidence.results.length, proposed, committed, delivered, results, result: "passed", independent_replay: "exact" }));
