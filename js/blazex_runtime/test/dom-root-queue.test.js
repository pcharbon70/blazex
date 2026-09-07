import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { DOMRootQueues } from "../src/dom-root-queue.js";
import { decode, seal } from "../src/render-transaction-v2.js";
const rows = fs.readFileSync(new URL("../../../integration/bh-04/reconciliation-fixtures-v0.1.0.txt", import.meta.url), "utf8").trim().split("\n").map(l => decode(Buffer.from(l.split("|")[1], "base64")));
const initial = rows[0].transaction;
const bridge = () => ({ request: async (_op, p) => ({ root_id: p.root_id, root_generation: p.root_generation }), metrics: () => ({}), stop() {} });
async function setup(options = {}, rootId = "one") {
  const queues = new DOMRootQueues({ scopeId: "test", createBridge: bridge, ...options });
  const handle = await queues.register(rootId); await handle.mount({ targetId: "owned", tree: {} });
  const token = queues.attach(handle, { owner: initial.owner, generation: 1, apply: () => ({ state: "committed" }) });
  return { queues, token, handle };
}
test("real BH-03 handles gate initial, update, dispose and terminal rejection", async () => {
  const { queues, token } = await setup();
  assert.equal((await queues.submit(token, initial)).state, "committed");
  assert.equal((await queues.submit(token, rows[1].transaction)).state, "committed");
  const tx = await seal({ ...rows.find(r => r.name === "dispose").transaction, base_revision: 2, target_revision: 3 });
  assert.equal((await queues.submit(token, tx)).state, "disposed");
  assert.equal(queues.snapshot(token).nodes, 0);
  assert.equal((await queues.submit(token, initial)).diagnostic, "disposed-root");
});
test("wrong owner, revision, duplicate and unknown capabilities cannot apply", async () => {
  const { queues, token } = await setup();
  assert.throws(() => queues.submit({}, initial), e => e.code === "ownership");
  assert.equal((await queues.submit(token, await seal({ ...initial, owner: "root-other" }))).diagnostic, "ownership");
  assert.equal((await queues.submit(token, rows[1].transaction)).diagnostic, "stale");
  assert.equal((await queues.submit(token, initial)).state, "committed");
  assert.equal((await queues.submit(token, initial)).diagnostic, "duplicate");
});
test("capacity includes active work and never silently coalesces dependent revisions", async () => {
  const tasks = [], acks = [];
  const { queues, token } = await setup({ schedule: f => tasks.push(f), onAck: a => acks.push(a) });
  const pending = [];
  for (let i = 0; i < 64; i++) pending.push(queues.submit(token, await seal({ ...initial, transaction_id: "tx-" + i.toString(16).padStart(24, "0") })));
  const overflow = await queues.submit(token, await seal({ ...initial, transaction_id: "tx-" + "f".repeat(24) }));
  assert.equal(overflow.diagnostic, "limit"); assert.equal(queues.snapshot(token).max_depth, 64);
  while (pending.length && tasks.length) { tasks.shift()(); await new Promise(r => setTimeout(r, 1)); }
  const outcomes = await Promise.all(pending);
  assert.equal(outcomes.filter(a => a.state === "committed").length, 1);
  assert.equal(outcomes.filter(a => a.state === "rejected").length, 63);
  assert.equal(acks.filter(a => a.state !== "accepted").length, 65);
});
test("slow root does not block a sibling and runtime loss drains work", async () => {
  const tasks = [];
  const { queues, token } = await setup({ schedule: f => tasks.push(f) });
  const other = await queues.register("two"); await other.mount({ targetId: "other", tree: {} });
  const sibling = queues.attach(other, { owner: initial.owner, generation: 1, apply: () => ({ state: "committed" }) });
  const a = queues.submit(token, initial), b = queues.submit(sibling, initial);
  tasks[1](); assert.equal((await b).state, "committed");
  queues.lifecycle.runtimeLost(); assert.equal((await a).diagnostic, "disposed-root");
  tasks[0](); assert.equal(queues.snapshot(token).nodes, 0);
});
test("shutdown, remount and observer exceptions preserve exactly-once outcomes", async () => {
  const { queues, token, handle } = await setup({ onAck: () => { throw new Error("observer"); } });
  assert.equal((await queues.submit(token, initial)).state, "committed");
  await handle.dispose(); await handle.mount({ targetId: "owned", tree: {} });
  const remount = queues.attach(handle, { owner: initial.owner, generation: 1, apply: () => ({ state: "committed" }) });
  assert.equal((await queues.submit(remount, initial)).state, "committed");
  assert.equal((await queues.submit(token, initial)).diagnostic, "disposed-root");
  await queues.lifecycle.shutdown(); assert.equal(queues.snapshot(remount).disposed, true);
});
