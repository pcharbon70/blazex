import assert from "node:assert/strict";
import { summarize } from "./acceptance-report.mjs";
const txid = n => "tx-" + n.toString(16).padStart(24, "0");
const identity = (ack, row) => {
  for (const key of ["owner", "root", "generation", "transaction_id", "digest", "base_revision", "target_revision"]) assert.equal(ack[key], row[key], "acknowledgement " + key);
};
export function validateCorrectiveMeasurements(raw, auth) {
  summarize(raw, auth);
  for (const b of raw.results) {
    let seed = auth.metrics.stale.seed;
    for (const [index, row] of b.stale.entries()) {
      seed = (seed * 1664525 + 1013904223) >>> 0;
      const renderer = index < auth.metrics.stale.renderer_per_browser;
      const sample = renderer ? index : index - auth.metrics.stale.renderer_per_browser;
      assert.equal(row.path, renderer ? "renderer" : "effects"); assert.equal(row.sample, sample);
      assert.equal(row.seed, seed); assert.equal(row.delay_ms, seed % 3);
      assert.equal(row.before.generation, renderer ? 2 : 3);
      assert.equal(row.generation, 1 + seed % (row.before.generation - 1));
      assert.equal(row.transaction_id, txid((renderer ? 20000 : 31000) + sample));
      assert.ok(Number.isFinite(row.elapsed_ms) && row.elapsed_ms >= 0);
      assert.equal(typeof row.before.html, "string"); assert.match(row.before.fingerprint, /^[a-f0-9]{64}$/);
      assert.ok(Number.isSafeInteger(row.before.revision) && row.before.revision > 0);
      assert.deepEqual(row.after, row.before, "stale delivery mutated state");
      if (renderer) { assert.equal(row.ack.state, "rejected"); assert.equal(row.ack.diagnostic, "stale"); identity(row.ack, row); }
      else { assert.equal(row.diagnostic, "stale"); assert.equal(row.effect_id, "delayed-" + sample); assert.deepEqual(row.before.results, []); assert.equal(row.before.active, 1); }
    }
    for (const queue of b.queues) for (const [i, row] of queue.outcomes.entries()) {
      identity(row.ack, row); assert.equal(row.transaction_id, txid(10000 + queue.run * 100 + i));
      assert.ok(Number.isFinite(row.receipt) && Number.isFinite(row.terminal) && row.receipt >= 0 && row.terminal >= row.receipt);
      assert.equal(row.ack.state, i === 0 ? "committed" : "rejected");
      if (i > 0) assert.equal(row.ack.diagnostic, i === 64 ? "limit" : "stale");
    }
  }
  return { result: "passed", support_state: "unsupported" };
}
