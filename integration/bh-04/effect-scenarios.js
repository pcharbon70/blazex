import { EffectDOMRoots } from "../../js/blazex_runtime/src/effect-dom.js";
import { InteractionBridge, InteractionStream } from "../../js/blazex_runtime/src/interaction-stream.js";
import { InteractionListeners } from "../../js/blazex_runtime/src/interaction-listeners.js";
import { digest } from "../../js/blazex_runtime/src/render-transaction-codec.js";
const check = (ok, message) => { if (!ok) throw Error(message); };
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(fn) { const start = performance.now(); while (!fn()) { check(performance.now() - start < 3000, "scenario deadline"); await pause(2); } }
export async function runEffectScenarios(document, runtime, trusted) {
  const roots = new EffectDOMRoots({ scopeId: "effects", createBridge: () => ({ request: async (_op, p) => ({ root_id: p.root_id, root_generation: p.root_generation }), metrics: () => ({}), stop() {} }) });
  const traces = [], cleanups = [], retired = []; let serial = 0;
  async function setup() {
    const rootId = "effects-" + ++serial, handle = await roots.register(rootId);
    await handle.mount({ targetId: rootId, tree: {} });
    let envelope = (await runtime({ control: "init", root_id: rootId, lifecycle_generation: handle.snapshot().root_generation })).transaction;
    const container = document.createElement("div"); document.body.append(container);
    let fault = null, effectFault = false, loseAck = false;
    const outcomes = [], requests = [];
    const bridge = new InteractionBridge({ protocol: "blazex.host-bridge/4", rootId, transport: {
      request: async request => {
        requests.push(request);
        if (loseAck && request.operation === "root.render_ack") return new Promise(() => {});
        const response = await runtime(request);
        if (response.result?.transaction) envelope = response.result.transaction;
        return response;
      }, cancel() {} } });
    const stream = new InteractionStream({ bridge, rootHandle: handle });
    const owner = envelope.continuity.transaction.owner;
    const listeners = new InteractionListeners({ rootId, lifecycleGeneration: handle.snapshot().root_generation, owner, receiver: stream, onOutcome: row => outcomes.push(row) });
    const token = roots.attach(handle, { container, owner, generation: 1, grants: ["time"], interactions: listeners,
      fault: stage => { if (fault === "apply" && stage === "finalize" || fault === "rollback" && ["finalize", "rollback"].includes(stage)) throw Error("injected"); },
      effectFault: () => { if (effectFault) throw Error("injected"); } });
    stream.bindDOM(roots, token);
    const ack = await roots.submit(token, envelope); check(ack.state === "committed", "initial mount");
    await runtime({ control: "initial_ack", root_id: rootId, ack });
    async function update(props, expected = "committed") {
      envelope = (await runtime({ control: "update", root_id: rootId, props })).transaction;
      const ack = await roots.submit(token, envelope); check(ack.state === expected, "props update " + JSON.stringify(ack));
      if (ack.state === "committed") await runtime({ control: "update_ack", root_id: rootId, ack });
      return ack;
    }
    async function activate(expected = "accepted") {
      const n = outcomes.length; container.querySelector("button").focus(); await trusted({ key: "Enter" });
      await until(() => outcomes.length > n); check(outcomes[n].outcome === expected, "event outcome " + JSON.stringify(outcomes[n]));
      return outcomes[n];
    }
    return { rootId, handle, container, token, stream, outcomes, requests, update, activate,
      snapshot: () => runtime({ control: "snapshot", root_id: rootId }), get envelope() { return envelope; },
      fail(mode) { fault = mode; }, failEffect() { effectFault = true; }, loseAck() { loseAck = true; } };
  }
  async function cleanup(root) {
    const start = performance.now(); roots.dispose(root.token); await pause(0);
    const snapshot = roots.snapshot(root.token), elapsed_ms = performance.now() - start;
    check(snapshot.resources.active === 0 && snapshot.resources.failures === 0 && snapshot.inventory.nodes === 0 && snapshot.inventory.listeners === 0 && snapshot.inventory.form_listeners === 0 && snapshot.inventory.interaction.queued === 0 && snapshot.queued === 0 && elapsed_ms < 1000, "cleanup convergence");
    cleanups.push({ root_id: root.rootId, elapsed_ms, snapshot });
    retired.push(root.token);
    await runtime({ control: "stop", root_id: root.rootId }); root.container.remove();
  }
  const sibling = await setup();
  const normal = await setup();
  await normal.activate();
  const actual = await normal.snapshot(); check(actual.count.count === 1 && actual.effects[0].status === "ok", "actual Elixir effect result");
  traces.push({ name: "semantic-effect-result", actual, browser: roots.snapshot(normal.token) });
  const field = normal.container.querySelector("input"); field.focus(); field.setSelectionRange(1,4,"backward");
  await normal.update({ reverse: true });
  check(normal.container.querySelector("input") === field && document.activeElement === field && field.selectionStart === 1 && field.selectionDirection === "backward", "focus selection reorder");
  await normal.update({ replace: true }); check(normal.container.querySelector("input") !== field, "replacement identity");
  traces.push({ name: "focus-reorder-replace", browser: roots.snapshot(normal.token) });
  await cleanup(normal);
  for (const mode of ["apply", "rollback", "effect", "timeout", "ack"]) {
    const a = await setup();
    if (mode === "timeout") await a.update({ delay_ms: 100, timeout_ms: 1 });
    if (["apply", "rollback"].includes(mode)) a.fail(mode);
    if (mode === "effect") a.failEffect();
    if (mode === "ack") a.loseAck();
    const start = performance.now(); await a.activate("rejected"); await pause(0);
    const snapshot = roots.snapshot(a.token), semantic = await a.snapshot();
    check(semantic.count.count === 0 && snapshot.resources.active === 0 && snapshot.failure.retry_attempts === 0 && snapshot.failure.fallback_attempts <= 1 && performance.now() - start < 1000, "failure authority/convergence " + mode);
    await sibling.activate();
    traces.push({ name: "failure-" + mode, elapsed_ms: performance.now() - start, browser: snapshot, semantic });
    await cleanup(a);
  }
  const negative = await setup();
  for (const mode of ["malformed", "digest", "stale", "diff", "duplicate", "foreign", "unsupported"]) {
    let envelope = structuredClone(negative.envelope);
    if (mode === "malformed") envelope = {};
    if (mode === "digest") envelope.digest = "0".repeat(64);
    if (["diff", "foreign", "unsupported"].includes(mode)) {
      const tx = envelope.continuity.transaction;
      envelope.effects = [{ id: "invalid", owner: tx.root, generation: tx.generation, revision: tx.target_revision, capability: "time", operation: "schedule", payload: { delay_ms: 0 }, timeout_ms: 50, fallback: "fail", barrier: "post-commit", depends: [] }];
      if (mode === "foreign") envelope.effects[0].owner = "bx-" + "0".repeat(24);
      if (mode === "unsupported") envelope.effects[0].capability = "ui.storage";
      if (mode === "diff") envelope.effects[0].depends = ["absent"];
      const { digest: _, ...body } = envelope; envelope.digest = await digest(body);
    }
    const before = negative.container.firstChild;
    let rejected = false;
    try { const ack = await roots.submit(negative.token, envelope); rejected = ack.state !== "committed"; } catch { rejected = true; }
    check(rejected, "invalid transaction committed");
    check(negative.container.firstChild === before && roots.snapshot(negative.token).resources.active === 1, "negative mutation/leak");
    traces.push({ name: "negative-" + mode, browser: roots.snapshot(negative.token) });
  }
  await cleanup(negative);
  const omit = await setup(); await omit.update({ delay_ms: 50, timeout_ms: 1, fallback: "omit" }); await omit.activate();
  check((await omit.snapshot()).effects[0].status === "timeout", "omit result delivery"); traces.push({ name: "omit-result", browser: roots.snapshot(omit.token) }); await cleanup(omit);
  const race = await setup(); await race.update({ delay_ms: 200, timeout_ms: 250 });
  race.container.querySelector("button").click(); await until(() => roots.snapshot(race.token).resources.kinds.timer === 1);
  roots.dispose(race.token); await until(() => race.outcomes.length > 0);
  check((await race.snapshot()).count.count === 0, "disposal promoted candidate"); traces.push({ name: "disposal-race", browser: roots.snapshot(race.token) }); await cleanup(race);
  for (let cycle = 0; cycle < 12; cycle++) {
    const a = await setup(); await a.update({ reverse: true }); await a.activate(); await a.update({ replace: true });
    a.fail("apply"); await a.activate("rejected"); await cleanup(a);
  }
  traces.push({ name: "repeated-lifecycle", cycles: 12, cleanup_count: cleanups.length });
  const loss = await setup(); await loss.update({ delay_ms: 200, timeout_ms: 250 });
  loss.container.querySelector("button").click(); await until(() => roots.snapshot(loss.token).resources.kinds.timer === 1);
  loss.handle.runtimeLost(); await until(() => loss.outcomes.length > 0);
  check(roots.snapshot(loss.token).resources.active === 0 && (await loss.snapshot()).count.count === 0, "runtime loss authority/cleanup");
  traces.push({ name: "runtime-loss", browser: roots.snapshot(loss.token) }); await cleanup(loss);
  const overload = await setup(); await overload.update({ delay_ms: 200, timeout_ms: 250 });
  const action = overload.container.querySelector("button");
  for (let n = 0; n < 65; n++) action.click();
  check(overload.stream.snapshot().max_depth === 64 && overload.outcomes.some(o => o.diagnostic === "limit"), "bounded event overload");
  roots.dispose(overload.token); await until(() => overload.outcomes.length === 65);
  check(overload.requests.length === 0, "disposed overload reached runtime");
  traces.push({ name: "event-overload", browser: roots.snapshot(overload.token), max_depth: overload.stream.snapshot().max_depth }); await cleanup(overload);
  await sibling.activate(); await cleanup(sibling); await roots.lifecycle.shutdown();
  await pause(1000);
  const late = retired.map(token => roots.snapshot(token));
  check(late.every(s => s.resources.active === 0 && s.inventory.nodes === 0 && s.inventory.interaction.queued === 0 && s.queued === 0), "late cleanup leak");
  return { result: "passed", support_state: "unsupported", observation_window_ms: 1000, counters: { scenarios: traces.length, roots: serial, cleanup: cleanups.length }, traces, cleanup: cleanups, late };
}
