import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { decode } from "../src/render-transaction-v2.js";
import { digest } from "../src/render-transaction-codec.js";
import { EffectDOMRoots } from "../src/effect-dom.js";
import { RendererResources } from "../src/renderer-resources.js";
import { Document } from "./support/atomic-fake-dom.js";
const rows = fs.readFileSync(new URL("../../../integration/bh-04/atomic-dom-fixtures-v0.1.0.txt", import.meta.url), "utf8").trim().split("\n").map(l => decode(Buffer.from(l.split("|")[1], "base64")));
const bridge = () => ({ request: async (_op, p) => ({ root_id: p.root_id, root_generation: p.root_generation }), metrics: () => ({}), stop() {} });
export async function envelope(tx, effects = [], base = null) {
  const body = { protocol: "blazex.dom-continuity/1", transaction: tx, controls: [], base_control_digest: base, control_digest: await digest([]) };
  const payload = { protocol: "blazex.dom-effects/1", continuity: { ...body, digest: await digest(body) }, effects };
  return { ...payload, digest: await digest(payload) };
}
const effect = (tx, extra = {}) => ({ id: "timer-1", owner: tx.root, generation: tx.generation, revision: tx.target_revision, capability: "time", operation: "schedule", payload: { delay_ms: 1 }, timeout_ms: 100, fallback: "fail", barrier: "post-commit", depends: [], ...extra });
async function setup(options = {}) {
  const document = new Document(), container = document.createElement("div"); document.body.append(container);
  const roots = new EffectDOMRoots({ scopeId: "test", createBridge: bridge });
  const handle = await roots.register("root"); await handle.mount({ targetId: "owned", tree: {} });
  const tx = rows[0].setup ?? rows[0].transaction;
  const token = roots.attach(handle, { container, owner: tx.owner, generation: 1, grants: ["time"], ...options });
  return { roots, token, tx, container };
}
test("effects run after DOM commit and all timer leases release before acknowledgement", async () => {
  const { roots, token, tx, container } = await setup();
  const result = await roots.submit(token, await envelope(tx, [effect(tx)]));
  assert.equal(result.state, "committed"); assert.equal(container.childNodes.length, 1);
  assert.deepEqual(result.results, [{ id: "timer-1", status: "ok" }]);
  assert.deepEqual(roots.snapshot(token).trace, ["preflight", "commit-focus-selection", "post-commit:timer-1", "acknowledgement"]);
  assert.deepEqual(roots.snapshot(token).resources.kinds, { dom: 1 });
  roots.dispose(token); roots.dispose(token);
  assert.equal(roots.snapshot(token).resources.active, 0); assert.equal(container.childNodes.length, 0);
});
test("malformed, ungranted, duplicate and future-dependent effects never mount", async () => {
  for (const effects of [tx => [effect(tx, { capability: "ui.storage" })], tx => [effect(tx), effect(tx)], tx => [effect(tx, { depends: ["future"] })], tx => [effect(tx, { generation: 2 })], tx => [effect(tx, { payload: { delay_ms: 251 } })]]) {
    const { roots, token, tx, container } = await setup();
    await assert.rejects(roots.submit(token, await envelope(tx, effects(tx))));
    assert.equal(container.childNodes.length, 0); assert.equal(roots.snapshot(token).resources.active, 1);
    roots.dispose(token);
  }
});
test("timeout fallback and disposal cancel timer work without acknowledgement promotion", async () => {
  const a = await setup();
  const result = await a.roots.submit(a.token, await envelope(a.tx, [effect(a.tx, { payload: { delay_ms: 50 }, timeout_ms: 1 })]));
  assert.equal(result.state, "failed"); assert.equal(a.container.childNodes.length, 0);
  assert.equal(a.roots.snapshot(a.token).resources.active, 0);
  const b = await setup();
  const pending = b.roots.submit(b.token, await envelope(b.tx, [effect(b.tx, { payload: { delay_ms: 250 } })]));
  await new Promise(resolve => setTimeout(resolve, 10)); b.roots.dispose(b.token);
  await assert.rejects(pending); assert.equal(b.roots.snapshot(b.token).resources.active, 0);
});
test("cleanup leases report failures instead of hiding leaks and reject cross-root release", () => {
  const ledger = new RendererResources("root-a", 1);
  const lease = ledger.acquire("dom", () => { throw Error("cleanup"); });
  assert.throws(() => ledger.release(lease, "root-b", 1));
  assert.equal(ledger.dispose().active, 1); assert.equal(ledger.dispose().failures, 1);
  const other = new RendererResources("root-b", 1);
  assert.throws(() => other.release(lease));
});
test("apply rollback, failed rollback, effect exceptions and ack loss elect one bounded recovery owner", async () => {
  for (const failure of ["apply", "rollback", "effect", "ack"]) {
    const a = await setup({ fault: stage => { if (failure === "apply" && stage === "finalize" || failure === "rollback" && ["finalize", "rollback"].includes(stage)) throw Error("injected"); }, effectFault: () => { if (failure === "effect") throw Error("injected"); } });
    const b = await setup();
    const result = await a.roots.submit(a.token, await envelope(a.tx, [effect(a.tx)]));
    if (failure === "ack") { a.roots.interactionFailure(a.token, "timeout"); a.roots.interactionFailure(a.token, "timeout"); }
    assert.equal(result.state, { apply: "rolled-back", rollback: "fallback", effect: "failed", ack: "committed" }[failure]);
    assert.equal((await b.roots.submit(b.token, await envelope(b.tx))).state, "committed");
    assert.equal(a.roots.snapshot(a.token).failure.retry_attempts, 0);
    assert.ok(a.roots.snapshot(a.token).failure.fallback_attempts <= 1);
    a.roots.dispose(a.token); b.roots.dispose(b.token);
    assert.equal(a.roots.snapshot(a.token).resources.active, 0);
    assert.equal(b.roots.snapshot(b.token).resources.active, 0);
  }
});
test("diagnostics, overload, cleanup and runtime-loss observations are bounded", async () => {
  const a = await setup();
  for (let i = 0; i < 100; i++) await assert.rejects(a.roots.submit(a.token, {}));
  assert.equal(a.roots.snapshot(a.token).failure.diagnostics.length, 32);
  assert.equal(a.roots.snapshot(a.token).failure.diagnostic_count, 100);
  const pending = a.roots.submit(a.token, await envelope(a.tx, [effect(a.tx, { payload: { delay_ms: 200 }, timeout_ms: 250 })]));
  await assert.rejects(a.roots.submit(a.token, {}), error => error.code === "limit");
  await a.roots.lifecycle.shutdown();
  await assert.rejects(pending);
  assert.equal(a.roots.snapshot(a.token).resources.active, 0);
});
test("omit failure results are explicit and failed dependencies never execute", async () => {
  let calls = 0;
  const a = await setup({ effectFault() { calls++; throw Error("injected"); } });
  const result = await a.roots.submit(a.token, await envelope(a.tx, [effect(a.tx, { fallback: "omit" }), effect(a.tx, { id: "timer-2", depends: ["timer-1"], fallback: "component" })]));
  assert.equal(result.state, "committed"); assert.equal(calls, 1);
  assert.deepEqual(result.results.map(r => r.status), ["failed", "cancelled"]);
  a.roots.dispose(a.token);
});
test("the batch deadline cancels pending timers and actual DOM cleanup errors remain blocking", async () => {
  const a = await setup();
  const effects = Array.from({ length: 16 }, (_, i) => effect(a.tx, { id: "timer-" + i, payload: { delay_ms: 100 }, timeout_ms: 200 }));
  const start = performance.now();
  await assert.rejects(a.roots.submit(a.token, await envelope(a.tx, effects)));
  assert.ok(performance.now() - start < 1000);
  assert.equal(a.roots.snapshot(a.token).resources.active, 0);
  const b = await setup();
  await b.roots.submit(b.token, await envelope(b.tx));
  const replace = b.container.replaceChildren;
  b.container.replaceChildren = () => { throw Error("cleanup injection"); };
  b.roots.dispose(b.token);
  assert.equal(b.roots.snapshot(b.token).resources.failures, 1);
  assert.equal(b.roots.snapshot(b.token).resources.active, 1);
  b.container.replaceChildren = replace;
});
