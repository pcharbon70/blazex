import { AtomicDOMRoots } from "../../js/blazex_runtime/src/atomic-dom.js";
import { InteractionListeners } from "../../js/blazex_runtime/src/interaction-listeners.js";
import { InteractionBridge, InteractionStream, INTERACTION_BRIDGE } from "../../js/blazex_runtime/src/interaction-stream.js";
import { EVENT_MAPPINGS } from "../../js/blazex_runtime/src/interaction-record.js";
import { decodeIntent } from "../../js/blazex_runtime/src/render-intent-data.js";
const check = (value, message) => { if (!value) throw new Error(message); };
const tick = () => new Promise(resolve => setTimeout(resolve, 0));
async function until(checker) { for (let i = 0; i < 10000; i++) { if (checker()) return; await tick(); } throw new Error("scenario deadline"); }

export async function runInteractionScenarios(document, runtime, trustedClick) {
  const traces = [], counters = { mappings: 0, rejected: 0, roots: 3, dom_commits: 0, cleanup: 0, max_queue: 0, trusted_clicks: 0, no_render_events: 0 };
  const roots = new AtomicDOMRoots({ scopeId: "interactions", createBridge: () => ({ request: async (_op, p) => ({ root_id: p.root_id, root_generation: p.root_generation }), metrics: () => ({}), stop() {} }) });
  async function setup(rootId) {
    const handle = await roots.register(rootId); await handle.mount({ targetId: rootId, tree: {} });
    const init = await runtime({ control: "init", root_id: rootId, lifecycle_generation: handle.snapshot().root_generation });
    const container = document.createElement("div"); document.body.append(container);
    let lastTransaction = init.transaction;
    const outcomes = [], requests = [], bridge = new InteractionBridge({ protocol: INTERACTION_BRIDGE, rootId, transport: { request: async request => { requests.push(request); const response = await runtime(request); if (response.result?.transaction) lastTransaction = response.result.transaction; return response; }, cancel() {} } });
    const stream = new InteractionStream({ bridge, rootHandle: handle });
    const listeners = new InteractionListeners({ rootId, lifecycleGeneration: handle.snapshot().root_generation, owner: init.transaction.owner, receiver: stream, onOutcome: outcome => outcomes.push(outcome) });
    const token = roots.attach(handle, { container, owner: init.transaction.owner, generation: 1, interactions: listeners }); stream.bindDOM(roots, token);
    const ack = await roots.submit(token, init.transaction); check(ack.state === "committed", "initial DOM");
    await runtime({ control: "initial_ack", root_id: rootId, ack });
    const sources = new Map();
    for (const op of init.transaction.operations) if (op.type === "intent" && op.name === "listeners" && op.new) for (const binding of decodeIntent(op.new)) sources.set(binding.semantic, op.target);
    const control = semantic => [...container.firstChild.children].find(e => e.getAttribute("id")?.endsWith(sources.get(semantic)));
    return { handle, token, stream, listeners, outcomes, requests, container, control, rootId, get lastTransaction() { return lastTransaction; } };
  }
  const a = await setup("root-a"), b = await setup("root-b"), quiet = await setup("root-quiet");
  function fire(root, semantic, options = {}) {
    const element = root.control(semantic), name = EVENT_MAPPINGS[semantic];
    if (["change", "select"].includes(semantic) && !options.keepValue) element.value = "sample 🌍";
    let event;
    if (semantic === "move") event = new PointerEvent(name, { bubbles: true, cancelable: true, clientX: 10.5, clientY: -2, movementX: 1, movementY: -1, buttons: 1 });
    else if (["change", "select"].includes(semantic)) event = new InputEvent(name, { bubbles: true, cancelable: true, isComposing: options.composing ?? false });
    else event = new Event(name, { bubbles: true, cancelable: true });
    element.dispatchEvent(event); return event;
  }
  let accepted = 0;
  for (const semantic of Object.keys(EVENT_MAPPINGS)) {
    let event;
    if (semantic === "activate") {
      let observed;
      const button = a.control(semantic); button.addEventListener("click", e => { observed = { defaultPrevented: e.defaultPrevented, trusted: e.isTrusted }; }, { once: true });
      const box = button.getBoundingClientRect(); await trustedClick({ x: box.x + box.width / 2, y: box.y + box.height / 2 });
      check(observed?.trusted, "trusted browser activation"); event = observed; counters.trusted_clicks++;
    } else event = fire(a, semantic);
    await until(() => a.outcomes.length > accepted);
    const outcome = a.outcomes[accepted++]; check(outcome.outcome === "accepted", semantic + " " + JSON.stringify(outcome));
    check(event.defaultPrevented, "native default policy");
    check(a.container.firstChild.firstChild.textContent === "Events: " + accepted, "Elixir result not committed");
    const snapshot = await runtime({ control: "snapshot", root_id: a.rootId }); check(snapshot.count === accepted && snapshot.pending === null, "runtime semantic acknowledgement");
    traces.push({ semantic, sequence: outcome.sequence, count: snapshot.count, revision: snapshot.revision, default_prevented: event.defaultPrevented }); counters.mappings++; counters.dom_commits++;
  }
  // Real concurrent roots retain independent event sequence and component state.
  fire(a, "activate"); fire(b, "activate");
  await until(() => a.outcomes.length === accepted + 1 && b.outcomes.length === 1);
  check(a.outcomes.at(-1).outcome === "accepted" && b.outcomes[0].outcome === "accepted" && b.outcomes[0].sequence === 1, "root ordering");
  counters.dom_commits += 2;
  const quietDOM = quiet.container.innerHTML;
  fire(quiet, "activate"); await until(() => quiet.outcomes.length === 1);
  fire(quiet, "activate"); await until(() => quiet.outcomes.length === 2);
  const quietState = await runtime({ control: "snapshot", root_id: quiet.rootId });
  check(quiet.outcomes.every(o => o.outcome === "accepted") && quietState.count === 2 && quietState.revision === 1 && quiet.container.innerHTML === quietDOM, "events require not one transaction each");
  counters.no_render_events = 2; traces.push({ quiet: quietState, dom_unchanged: true });
  const template = a.requests.find(r => r.operation === "root.interaction").payload;
  const current = { ...template, sequence: a.stream.snapshot().last_sequence + 1, revision: a.lastTransaction.target_revision, transaction_id: a.lastTransaction.transaction_id, digest: a.lastTransaction.digest };
  const negative = [
    ["wrong-root", { ...current, root_id: "root-b" }],
    ["generation", { ...current, generation: 2 }],
    ["lifecycle", { ...current, lifecycle_generation: 3 }],
    ["revision", { ...current, revision: 1 }],
    ["owner", { ...current, owner: "root-other" }],
    ["duplicate", { ...current, sequence: current.sequence - 1 }],
    ["replay", template],
    ["unbound", { ...current, source: "bx-" + "f".repeat(24), listener_id: "li-bx-" + "f".repeat(24) + "-activate" }],
    ["malformed", { ...current, extra: true }],
    ["private-payload", { ...current, payload: { password: "fixture-only" } }],
    ["oversized", { ...current, semantic: "change", listener_id: "li-" + current.source + "-change", payload: { value: "x".repeat(2049), checked: false } }],
  ];
  const semanticBefore = await runtime({ control: "snapshot", root_id: a.rootId }), domBefore = a.container.innerHTML;
  for (const [name, payload] of negative) {
    let rejected = false;
    try { await runtime({ protocol: INTERACTION_BRIDGE, root_id: a.rootId, request_id: "negative-" + name, operation: "root.interaction", payload }); } catch { rejected = true; }
    check(rejected, "runtime negative accepted: " + name); counters.rejected++; traces.push({ negative: name, outcome: "rejected" });
  }
  let incompatible = false;
  try { await runtime({ protocol: "blazex.host-bridge/1", root_id: a.rootId, request_id: "wrong-bridge", operation: "root.interaction", payload: current }); } catch { incompatible = true; }
  check(incompatible, "bridge mismatch accepted"); counters.rejected++;
  const cyclic = { ...current }; cyclic.payload = cyclic;
  let cyclicRejected = false; try { a.stream.enqueue(cyclic); } catch { cyclicRejected = true; } check(cyclicRejected, "cyclic accepted"); counters.rejected++;
  check(JSON.stringify(await runtime({ control: "snapshot", root_id: a.rootId })) === JSON.stringify(semanticBefore) && a.container.innerHTML === domBefore, "negative mutated runtime or DOM");
  const queued = [];
  for (let i = 0; i < 64; i++) queued.push(a.stream.enqueue({ ...current, sequence: current.sequence + i }));
  let overflow = false; try { a.stream.enqueue({ ...current, sequence: current.sequence + 64 }); } catch (error) { overflow = error.code === "limit"; }
  check(overflow, "queue overflow accepted"); counters.rejected++;
  fire(b, "activate");
  const outcomes = await Promise.all(queued); await until(() => b.outcomes.length === 2);
  check(outcomes.filter(o => o.outcome === "accepted").length === 1 && outcomes.filter(o => o.diagnostic === "stale").length === 63 && b.outcomes[1].outcome === "accepted", "dependent queue/coalescing or sibling failure");
  counters.max_queue = a.stream.snapshot().max_depth; check(counters.max_queue === 64, "queue capacity"); counters.dom_commits += 2;
  traces.push({ queue: outcomes, overflow: "limit", coalesced: 0, sibling: "accepted" });
  const before = a.requests.length;
  fire(a, "change", { composing: true });
  const field = a.control("change"); field.value = "x".repeat(2049); fire(a, "change", { keepValue: true });
  field.value = ""; field.setAttribute("name", "password"); fire(a, "change", { keepValue: true }); field.removeAttribute("name");
  await tick(); check(a.requests.length === before, "private input delivered");
  counters.rejected += 3;
  check(a.outcomes.slice(-3).every(o => o.outcome === "rejected"), "privacy/composition rejection");
  const label = a.container.firstChild.firstChild.textContent;
  await a.handle.dispose(); await runtime({ control: "stop", root_id: a.rootId });
  check(a.listeners.snapshot().listeners === 0 && a.stream.snapshot().queued === 0 && a.container.childNodes.length === 0, "root cleanup"); counters.cleanup++;
  fire(b, "activate"); await until(() => b.outcomes.length === 3); check(b.outcomes[2].outcome === "accepted", "disposed sibling blocked healthy root"); counters.dom_commits++;
  const oldButton = b.control("activate"), beforeLoss = b.requests.length;
  roots.lifecycle.runtimeLost(); oldButton.dispatchEvent(new Event("click", { bubbles: true, cancelable: true }));
  check(b.requests.length === beforeLoss && b.stream.snapshot().disposed && quiet.stream.snapshot().disposed, "late event after runtime loss");
  await roots.lifecycle.shutdown(); await runtime({ control: "stop", root_id: b.rootId }); await runtime({ control: "stop", root_id: quiet.rootId });
  check(b.listeners.snapshot().listeners === 0 && b.stream.snapshot().queued === 0 && b.container.childNodes.length === 0, "shutdown cleanup"); counters.cleanup++;
  check(quiet.listeners.snapshot().listeners === 0 && quiet.stream.snapshot().queued === 0 && quiet.container.childNodes.length === 0, "quiet cleanup"); counters.cleanup++;
  a.container.remove(); b.container.remove(); quiet.container.remove();
  return { result: "passed", support_state: "unsupported", counters, traces, last_label: label, listener_cleanup: [a.listeners.snapshot(), b.listeners.snapshot(), quiet.listeners.snapshot()], stream_cleanup: [a.stream.snapshot(), b.stream.snapshot(), quiet.stream.snapshot()] };
}
