import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { decode } from "../src/render-transaction-v2.js";
import { AtomicDOMRoots } from "../src/atomic-dom.js";
import { Document } from "./support/atomic-fake-dom.js";
const rows = fs.readFileSync(new URL("../../../integration/bh-04/atomic-dom-fixtures-v0.1.0.txt", import.meta.url), "utf8").trim().split("\n").map(l => decode(Buffer.from(l.split("|")[1], "base64")));
const bridge = () => ({ request: async (_op, p) => ({ root_id: p.root_id, root_generation: p.root_generation }), metrics: () => ({}), stop() {} });
async function setup(row, fault = () => {}) {
  const document = new Document(), container = document.createElement("div"); document.body.append(container);
  const roots = new AtomicDOMRoots({ scopeId: "test", createBridge: bridge });
  const handle = await roots.register("root"); await handle.mount({ targetId: "owned", tree: {} });
  let enabled = false;
  const token = roots.attach(handle, { container, owner: row.transaction.owner, generation: 1, fault: (...args) => { if (enabled) fault(...args); } });
  if (row.setup) assert.equal((await roots.submit(token, row.setup)).state, "committed", row.name + " setup");
  enabled = true;
  return { roots, token, container, handle };
}
test("all actual reconciler scenarios commit through real BH-03 handles", async () => {
  for (const row of rows) {
    const { roots, token, container } = await setup(row);
    const result = await roots.submit(token, row.transaction);
    assert.equal(result.state, row.transaction.kind === "dispose" ? "disposed" : "committed", row.name + ": " + JSON.stringify(result));
    assert.equal(roots.snapshot(token).fingerprint, row.after?.fingerprint ?? null);
    await roots.lifecycle.shutdown(); assert.equal(container.childNodes.length, 0);
  }
});
test("every before/after operation boundary restores exact old elements", async () => {
  for (const row of rows) for (const op of row.transaction.operations) for (const boundary of ["before", "after"]) {
    const { roots, token, container } = await setup(row, (stage, id) => { if (stage === boundary && id === op.op_id) throw new Error("injected"); });
    const old = container.firstChild;
    const result = await roots.submit(token, row.transaction);
    assert.equal(result.state, "rolled-back", `${row.name} ${boundary} ${op.op_id}`);
    assert.equal(container.firstChild, old); assert.equal(roots.snapshot(token).fingerprint, row.before?.fingerprint ?? null);
    await roots.lifecycle.shutdown();
  }
});
test("unexpected DOM rejects before mutation and failed rollback quarantines", async () => {
  const row = rows[1], a = await setup(row);
  a.container.firstChild.setAttribute("unknown", "external");
  assert.equal((await a.roots.submit(a.token, row.transaction)).state, "rejected");
  assert.equal(a.container.firstChild.getAttribute("unknown"), "external");
  await a.roots.lifecycle.shutdown();
  const b = await setup(row, stage => { if (["finalize", "rollback"].includes(stage)) throw new Error("fault"); });
  assert.equal((await b.roots.submit(b.token, row.transaction)).state, "fallback");
  assert.equal(b.roots.snapshot(b.token).quarantined, true);
  assert.equal((await b.roots.submit(b.token, row.transaction)).diagnostic, "disposed-root");
  await b.roots.lifecycle.shutdown();
});
