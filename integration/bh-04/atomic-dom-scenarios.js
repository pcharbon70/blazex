import { AtomicDOMRoots } from "../../js/blazex_runtime/src/atomic-dom.js";
import { seal } from "../../js/blazex_runtime/src/render-transaction-v2.js";

const check = (value, message) => { if (!value) throw new Error(message); };
const bridge = () => ({ request: async (_op, p) => ({ root_id: p.root_id, root_generation: p.root_generation }), metrics: () => ({}), stop() {} });
const tree = node => node.nodeType === 3 ? node.data : { tag: node.tagName, attrs: node.getAttributeNames().sort().map(n => [n, node.getAttribute(n)]), value: node.value, children: [...node.childNodes].map(tree) };
const snapshot = container => JSON.stringify(tree(container));
const elements = container => [container, ...[...container.children].flatMap(elements)];

export async function runAtomicDOMScenarios(document, rows) {
  const traces = [], counters = { scenarios: 0, injected_boundaries: 0, stale_rejected: 0, max_queue: 0, terminal_acks: 0, cleanup: 0 };
  async function setup(row, options = {}) {
    const acks = [], container = document.createElement("div"); document.body.append(container);
    const roots = new AtomicDOMRoots({ scopeId: "atomic-test", createBridge: bridge, onAck: ack => acks.push(ack), ...options });
    const handle = await roots.register("root"); await handle.mount({ targetId: "owned", tree: {} });
    let enabled = false;
    const token = roots.attach(handle, { owner: row.transaction.owner, generation: 1, container, fault: (...args) => { if (enabled) options.fault?.(...args); } });
    if (row.setup) check((await roots.submit(token, row.setup)).state === "committed", row.name + " setup");
    enabled = true;
    const close = async () => { await roots.lifecycle.shutdown(); check(container.childNodes.length === 0 && roots.snapshot(token).nodes === 0, "cleanup failed"); container.remove(); counters.cleanup++; };
    return { roots, handle, token, container, acks, close };
  }
  for (const row of rows) {
    const a = await setup(row), result = await a.roots.submit(a.token, row.transaction);
    check(result.state === (row.after ? "committed" : "disposed"), row.name + ": " + JSON.stringify(result));
    check(a.roots.snapshot(a.token).fingerprint === (row.after?.fingerprint ?? null), row.name + " fingerprint");
    const terminal = a.acks.filter(x => x.transaction_id === row.transaction.transaction_id && x.state !== "accepted");
    check(terminal.length === 1, "exactly once " + row.name); counters.terminal_acks++;
    traces.push({ name: row.name, digest: row.transaction.digest, state: result.state }); counters.scenarios++; await a.close();
    for (const op of row.transaction.operations) for (const boundary of ["before", "after"]) {
      const b = await setup(row, { fault: (stage, id) => { if (stage === boundary && id === op.op_id) throw new Error("injected"); } });
      const before = snapshot(b.container), old = elements(b.container), result = await b.roots.submit(b.token, row.transaction);
      check(result.state === "rolled-back" && snapshot(b.container) === before && elements(b.container).every((e, i) => e === old[i]), row.name + " rollback " + boundary + op.op_id + " state=" + result.state + " equal=" + (snapshot(b.container) === before) + " identity=" + elements(b.container).every((e, i) => e === old[i]));
      check(b.roots.snapshot(b.token).fingerprint === (row.before?.fingerprint ?? null), "rollback revision changed");
      check(b.acks.filter(x => x.transaction_id === row.transaction.transaction_id && x.state !== "accepted").length === 1, "rollback duplicated acknowledgement");
      counters.terminal_acks++; counters.injected_boundaries++;
      traces.push({ name: row.name, digest: row.transaction.digest, boundary, operation: op.op_id, state: result.state }); await b.close();
    }
  }
  let propertyFailure = false;
  const property = await setup(rows[1], { fault: stage => { if (propertyFailure && stage === "finalize") throw new Error("property failure"); } });
  const field = rows[1].before.nodes.find(n => n.tag === "input").id;
  const propertyOps = [ ["value", "bounded"], ["checked", true], ["disabled", true], ["readOnly", true] ].map(([name, value], op_id) => ({ type: "property", op_id, depends: op_id ? [op_id - 1] : [], target: field, name, old: null, new: value }));
  propertyOps.push({ type: "property", op_id: 4, depends: [3], target: rows[1].before.nodes.find(n => n.tag === "button").id, name: "value", old: null, new: "action" });
  const propertyTx = await seal({ ...rows[1].transaction, transaction_id: "tx-" + "d".repeat(24), operations: propertyOps });
  check((await property.roots.submit(property.token, propertyTx)).state === "committed", "property application");
  const propertyBefore = snapshot(property.container);
  propertyFailure = true;
  const propertyRemove = await seal({ ...propertyTx, transaction_id: "tx-" + "c".repeat(24), base_revision: 2, target_revision: 3, operations: propertyOps.map(op => ({ ...op, old: op.new, new: null })) });
  check((await property.roots.submit(property.token, propertyRemove)).state === "rolled-back" && snapshot(property.container) === propertyBefore, "property rollback");
  propertyFailure = false;
  check((await property.roots.submit(property.token, await seal({ ...propertyRemove, transaction_id: "tx-" + "b".repeat(24) }))).state === "committed", "property removal");
  traces.push({ name: "properties", state: "committed", recovery: "rolled-back", digest: propertyTx.digest }); await property.close();
  const row = rows.find(r => r.name === "generation-replace"), stale = await setup(row);
  check((await stale.roots.submit(stale.token, row.transaction)).state === "committed", "replacement");
  const before = snapshot(stale.container);
  let seed = 731;
  for (let i = 0; i < 100; i++) {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    const tx = await seal({ ...rows[1].transaction, transaction_id: "tx-" + (i + 1000).toString(16).padStart(24, "0"), generation: seed % 2 ? 1 : 2, base_revision: 0, target_revision: 1 });
    const result = await stale.roots.submit(stale.token, tx);
    check(result.state === "rejected" && result.diagnostic === "stale" && snapshot(stale.container) === before, "stale mutation");
    traces.push({ name: "random-delayed", digest: tx.digest, seed, state: result.state, diagnostic: result.diagnostic }); counters.stale_rejected++;
  }
  await stale.close();
  const invalid = await setup(rows[1]), invalidBefore = snapshot(invalid.container);
  const badTransactions = [
    await seal({ ...rows[1].transaction, owner: "root-foreign" }),
    { ...rows[1].transaction, digest: "0".repeat(64) },
    await seal({ ...rows[1].transaction, operations: [{ op_id: 0, depends: [], type: "text", target: "bx-" + "f".repeat(24), old: null, new: "outside" }] }),
    await seal({ ...rows[1].transaction, operations: [{ op_id: 0, depends: [], type: "attribute", target: rows[1].transaction.root, name: "type", old: null, new: "file" }] })
  ];
  for (let i = 0; i < badTransactions.length; i++) {
    const tx = await seal({ ...badTransactions[i], transaction_id: "tx-" + (3000 + i).toString(16).padStart(24, "0") });
    if (i === 1) tx.digest = "0".repeat(64);
    const result = await invalid.roots.submit(invalid.token, tx);
    check(result.state === "rejected" && snapshot(invalid.container) === invalidBefore, "negative transaction mutated DOM");
    traces.push({ name: "invalid", digest: tx.digest, state: result.state, diagnostic: result.diagnostic });
  }
  let unknown = false; try { invalid.roots.submit({}, rows[1].transaction); } catch { unknown = true; } check(unknown, "unknown capability");
  const duplicateHandle = await invalid.roots.register("duplicate"); await duplicateHandle.mount({ targetId: "duplicate", tree: {} });
  let overlap = false; try { invalid.roots.attach(duplicateHandle, { container: invalid.container.firstChild, owner: rows[1].transaction.owner, generation: 1 }); } catch { overlap = true; } check(overlap, "overlapping root");
  invalid.container.firstChild.setAttribute("external", "untouched");
  const tampered = snapshot(invalid.container), rejected = await invalid.roots.submit(invalid.token, await seal({ ...rows[1].transaction, transaction_id: "tx-" + "e".repeat(24) }));
  check(rejected.state === "rejected" && snapshot(invalid.container) === tampered, "external mutation overwritten");
  traces.push({ name: "ownership-external", unknown, overlap, state: rejected.state }); await invalid.close();
  const tasks = [], q = await setup(rows[0], { schedule: f => tasks.push(f) }), pending = [];
  for (let i = 0; i < 64; i++) pending.push(q.roots.submit(q.token, await seal({ ...rows[0].transaction, transaction_id: "tx-" + (i + 2000).toString(16).padStart(24, "0") })));
  const overflow = await q.roots.submit(q.token, rows[0].transaction); check(overflow.diagnostic === "limit", "overflow");
  counters.max_queue = q.roots.snapshot(q.token).max_depth; check(counters.max_queue === 64, "queue bounds");
  const other = await q.roots.register("sibling"); await other.mount({ targetId: "sibling", tree: {} });
  const siblingContainer = document.createElement("div"); document.body.append(siblingContainer);
  const sibling = q.roots.attach(other, { container: siblingContainer, owner: rows[0].transaction.owner, generation: 1 });
  const siblingResult = q.roots.submit(sibling, rows[0].transaction); tasks.pop()();
  check((await siblingResult).state === "committed", "sibling blocked by slow root");
  while (tasks.length) { tasks.shift()(); await new Promise(resolve => setTimeout(resolve, 0)); }
  const results = await Promise.all(pending);
  check(results.filter(r => r.state === "committed").length === 1 && results.filter(r => r.diagnostic === "stale").length === 63, "unsafe coalescing");
  check(q.acks.filter(a => a.state !== "accepted").length === 66, "queue acknowledgement count");
  check(q.container.firstChild.getAttribute("id") !== siblingContainer.firstChild.getAttribute("id"), "global DOM identity collision");
  for (const container of [q.container, siblingContainer]) {
    const ids = new Set(elements(container).map(e => e.getAttribute("id")));
    for (const element of elements(container)) for (const name of ["aria-labelledby", "aria-describedby", "aria-controls", "aria-owns", "aria-errormessage"]) {
      const value = element.getAttribute(name); if (value) check(value.split(" ").every(id => ids.has(id)), "cross-root accessibility reference");
    }
  }
  traces.push({ name: "queue", depth: counters.max_queue, coalesced: 0, states: results.map(r => r.state), sibling: "committed", overflow: overflow.diagnostic });
  await q.close(); check(siblingContainer.childNodes.length === 0, "sibling cleanup"); siblingContainer.remove();

  for (const mode of ["rollback", "inert"]) {
    const a = await setup(rows[1], { fault: stage => { if (["finalize", "rollback", ...(mode === "inert" ? ["fallback"] : [])].includes(stage)) throw new Error("failure"); } });
    const siblingContainer = document.createElement("div"); document.body.append(siblingContainer);
    const handle = await a.roots.register("healthy"); await handle.mount({ targetId: "healthy", tree: {} });
    const sibling = a.roots.attach(handle, { container: siblingContainer, owner: rows[0].transaction.owner, generation: 1 });
    const previous = snapshot(a.container), result = await a.roots.submit(a.token, rows[1].transaction);
    check(result.state === "fallback" && a.roots.snapshot(a.token).quarantined, "fallback quarantine");
    check(mode === "inert" ? a.container.childNodes.length === 0 : snapshot(a.container) === previous, "fallback projection");
    check((await a.roots.submit(a.token, rows[1].transaction)).diagnostic === "disposed-root", "fallback retry");
    check((await a.roots.submit(sibling, rows[0].transaction)).state === "committed", "fallback blocked sibling");
    traces.push({ name: "fallback-" + mode, state: result.state, quarantined: true, sibling: "committed" }); await a.close();
    check(siblingContainer.childNodes.length === 0, "fallback sibling cleanup"); siblingContainer.remove();
  }
  for (const mode of ["loss", "shutdown", "dispose"]) {
    const tasks = [], a = await setup(rows[0], { schedule: task => tasks.push(task) });
    const pending = a.roots.submit(a.token, rows[0].transaction);
    if (mode === "loss") a.roots.lifecycle.runtimeLost();
    else if (mode === "shutdown") await a.roots.lifecycle.shutdown();
    else await a.handle.dispose();
    check((await pending).diagnostic === "disposed-root" && a.container.childNodes.length === 0, "lifecycle cancellation");
    tasks.forEach(t => t());
    if (mode === "dispose") {
      await a.handle.mount({ targetId: "remount", tree: {} });
      const token = a.roots.attach(a.handle, { owner: rows[0].transaction.owner, generation: 1, container: a.container });
      const result = a.roots.submit(token, rows[0].transaction); tasks.pop()(); check((await result).state === "committed", "remount");
    }
    traces.push({ name: mode, state: "rejected", remount: mode === "dispose" }); await a.close();
  }
  return { schema_version: "1.0.0", matrix: "BH-04 Phase 4 active Linux", support_state: "unsupported", counters, traces, result: "passed" };
}
