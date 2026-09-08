import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { EVENT_MAPPINGS, INTERACTION_PROTOCOL, listenerIdentity, normalizeNative, validateInteraction } from "../src/interaction-record.js";
import { InteractionListeners } from "../src/interaction-listeners.js";
import { AtomicDOMRoots } from "../src/atomic-dom.js";
import { decode } from "../src/render-transaction-v2.js";
import { Document } from "./support/atomic-fake-dom.js";
const source = "bx-" + "a".repeat(24), transaction = "tx-" + "b".repeat(24);
const context = { root_id: "one", lifecycle_generation: 2, owner: "root-owner", generation: 1, revision: 1, transaction_id: transaction, digest: "c".repeat(64) };
const record = (semantic, payload = {}) => ({ ...context, protocol: INTERACTION_PROTOCOL, provenance: "local-event", source, listener_id: listenerIdentity(source, semantic), semantic, sequence: 1, timestamp: 1, payload });
function native(semantic, element) { return { type: EVENT_MAPPINGS[semantic], target: element, currentTarget: element, isComposing: false, cancelable: true, preventDefault() { this.prevented = true; }, stopPropagation() { this.stopped = true; }, clientX: 1.25, clientY: -2, movementX: 0.5, movementY: -0.25, buttons: 1 }; }
test("all 13 mappings produce closed bounded immutable semantic payloads", () => {
  const element = { value: "example", checked: false, type: "text" };
  for (const semantic of Object.keys(EVENT_MAPPINGS)) {
    const event = native(semantic, element);
    Object.defineProperty(event, "dataTransfer", { get() { throw new Error("must not read"); } });
    const value = validateInteraction(record(semantic, normalizeNative(semantic, source, element, event)));
    assert.equal(value.semantic, semantic); assert.ok(Object.isFrozen(value.payload));
    assert.ok(!JSON.stringify(value).includes("dataTransfer"));
  }
});
test("malformed, cyclic, accessor, oversized and unrequested values fail closed", () => {
  for (const value of [ { ...record("activate"), extra: true }, { ...record("activate"), payload: { password: "secret" } }, record("change", { value: "x".repeat(2049), checked: null }), record("move", { x: Infinity, y: 0, dx: 0, dy: 0, buttons: 0 }) ]) assert.throws(() => validateInteraction(value));
  const cyclic = record("activate"); cyclic.payload = cyclic; assert.throws(() => validateInteraction(cyclic));
  const accessor = record("activate"); Object.defineProperty(accessor, "payload", { enumerable: true, get() { throw new Error("accessed"); } });
  assert.throws(() => validateInteraction(accessor), error => error.code === "malformed");
});
test("composition, credentials, unknown mapping and cross-target events are rejected", () => {
  for (const element of [{ type: "password", value: "private" }, { type: "file", value: "private" }, { type: "text", name: "credential", value: "private" }]) assert.throws(() => normalizeNative("change", source, element, native("change", element)), error => error.code === "privacy");
  const element = { type: "text", value: "ok" }, event = native("change", element); event.isComposing = true;
  assert.throws(() => normalizeNative("change", source, element, event), error => error.code === "composition");
  assert.throws(() => normalizeNative("activate", source, element, { ...native("activate", element), target: {} }), error => error.code === "ownership");
});
test("registry orders callbacks, cancels defaults, suspends and removes stale callbacks", async () => {
  const received = [], outcomes = [], receiver = { enqueue: r => { received.push(r); return Promise.resolve({ outcome: "accepted", sequence: r.sequence }); }, setContext() {}, dispose() {} };
  const registry = new InteractionListeners({ rootId: "one", lifecycleGeneration: 2, owner: context.owner, receiver, clock: () => 12.75, onOutcome: o => outcomes.push(o) });
  registry.claim({ state: "ready", root_id: "one", root_generation: 2 }, context.owner);
  const element = { type: "button" }, binding = { semantic: "activate", native: "click", source: { generation: 1 } };
  const a = registry.register(source, element, binding);
  assert.throws(() => registry.register(source, element, binding), e => e.code === "duplicate");
  registry.publish({ owner: context.owner, generation: 1, target_revision: 1, transaction_id: transaction, digest: context.digest });
  const event = native("activate", element); a.handler(event); a.handler(native("activate", element));
  assert.ok(event.prevented && event.stopped); assert.deepEqual(received.map(r => r.sequence), [1, 2]); assert.equal(received[0].timestamp, 12);
  registry.suspend(); a.handler(native("activate", element)); assert.equal(received.length, 2);
  registry.resume(); registry.unregister(a.id); a.handler(native("activate", element)); assert.equal(received.length, 2);
  registry.register(source, element, binding); a.handler(native("activate", element)); assert.equal(received.length, 2);
  registry.dispose(); a.handler(native("activate", element)); assert.equal(registry.snapshot().listeners, 0);
  await Promise.resolve(); assert.equal(outcomes.filter(o => o.outcome === "accepted").length, 2);
});
test("actual reconciler listeners register through the atomic DOM node index and clean up", async () => {
  const first = fs.readFileSync(new URL("../../../integration/bh-04/atomic-dom-fixtures-v0.1.0.txt", import.meta.url), "utf8").split("\n")[0];
  const tx = decode(Buffer.from(first.split("|")[1], "base64")).transaction;
  const roots = new AtomicDOMRoots({ scopeId: "test", createBridge: () => ({ request: async (_op,p) => ({ root_id:p.root_id, root_generation:p.root_generation }), metrics:()=>({}), stop(){} }) });
  const handle = await roots.register("one"); await handle.mount({ targetId: "owned", tree: {} });
  const document = new Document(), container = document.createElement("div"); document.body.append(container);
  const received = [], interactions = new InteractionListeners({ rootId: "one", lifecycleGeneration: handle.snapshot().root_generation, owner: tx.owner, receiver: { enqueue: r => { received.push(r); return Promise.resolve({ outcome: "accepted" }); }, setContext(){}, dispose(){} } });
  const token = roots.attach(handle, { owner: tx.owner, generation: 1, container, interactions });
  assert.equal((await roots.submit(token, tx)).state, "committed"); assert.equal(interactions.snapshot().listeners, 2);
  const action = container.firstChild.children.find(n => n.tagName === "BUTTON");
  const handler = [...action.listeners.get("click")][0]; handler(native("activate", action)); assert.equal(received.length, 1);
  await handle.dispose(); handler(native("activate", action)); assert.equal(received.length, 1); assert.equal(interactions.snapshot().listeners, 0);
});
