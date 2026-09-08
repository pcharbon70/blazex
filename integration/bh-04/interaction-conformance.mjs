import fs from "node:fs";
import assert from "node:assert/strict";
import { validateInteraction, listenerIdentity } from "../../js/blazex_runtime/src/interaction-record.js";
import { decodeIntent } from "../../js/blazex_runtime/src/render-intent-data.js";
import { planTransaction } from "../../js/blazex_runtime/src/dom-transaction-plan.js";
const path = process.argv[2] ?? new URL("../../docs/research/assets/bh-04-baseline/blazex-bh-04-phase-05-browser-results-v0.1.0.json", import.meta.url);
const evidence = JSON.parse(fs.readFileSync(path, "utf8"));
const header = ["root_id", "lifecycle_generation", "owner", "generation", "revision", "transaction_id", "digest"];
let deliveries = 0, rejected = 0, commits = 0;
for (const browser of evidence.results) {
  const states = new Map();
  async function propose(state, tx) { const planned = await planTransaction(state, tx); state.pending = { tx, projection: planned.projection }; }
  function commit(state, sequence, ack) {
    assert.equal(ack.state, "committed"); assert.equal(ack.transaction_id, state.pending.tx.transaction_id); assert.equal(ack.digest, state.pending.tx.digest);
    const { tx, projection } = state.pending;
    state.projection = projection; state.revision = tx.target_revision; state.generation = tx.generation; state.digest = tx.digest; state.last_sequence = sequence;
    state.context = { root_id: state.root_id, lifecycle_generation: state.lifecycle_generation, owner: tx.owner, generation: tx.generation, revision: tx.target_revision, transaction_id: tx.transaction_id, digest: tx.digest };
    state.listeners = new Set(projection.nodes.flatMap(node => (decodeIntent(node.listeners) ?? []).map(binding => listenerIdentity(node.id, binding.semantic))));
    state.pending = null; commits++;
  }
  for (const row of browser.runtime) {
    const request = row.request, response = row.response;
    if (request.control === "init") {
      const tx = response.transaction, state = { root_id: request.root_id, lifecycle_generation: request.lifecycle_generation, owner: tx.owner, generation: tx.generation, revision: 0, projection: null, disposed: false, seen: [], pending: null, last_sequence: 0 };
      states.set(request.root_id, state); await propose(state, tx);
    } else if (request.control === "initial_ack") commit(states.get(request.root_id), 0, request.ack);
    else if (request.control === "stop") states.get(request.root_id).disposed = true;
    else if (request.operation === "root.interaction") {
      const state = states.get(request.root_id);
      let valid = request.protocol === "blazex.host-bridge/2" && state && !state.disposed && !state.pending;
      try {
        const event = validateInteraction(request.payload);
        valid &&= header.every(key => event[key] === state.context[key]) && event.sequence > state.last_sequence && state.listeners.has(event.listener_id);
      } catch { valid = false; }
      assert.equal(!response.error, Boolean(valid), browser.browser + " " + request.request_id);
      if (!valid) { rejected++; continue; }
      const ack = response.result.ack;
      assert.equal(ack.outcome, "accepted");
      for (const key of [...header, "sequence", "listener_id"]) assert.equal(ack[key], request.payload[key]);
      if (response.result.transaction) await propose(state, response.result.transaction);
      else state.last_sequence = request.payload.sequence;
      deliveries++;
    } else if (request.operation === "root.render_ack") {
      assert.equal(response.result.outcome, "committed"); assert.equal(response.result.sequence, request.payload.sequence);
      commit(states.get(request.root_id), request.payload.sequence, request.payload.ack);
    }
  }
  assert.ok([...states.values()].every(state => state.disposed && !state.pending));
}
console.log(JSON.stringify({ browsers: evidence.results.length, deliveries, rejected, commits, independent_transaction_replay: "exact", result: "passed" }));
