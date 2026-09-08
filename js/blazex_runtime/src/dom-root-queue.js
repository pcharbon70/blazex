import { BrowserRootRegistry } from "./root-lifecycle.js";
import { copyTransaction, planTransaction, acknowledgement, requireDOM } from "./dom-transaction-plan.js";

const CODES = new Set(["malformed", "incompatible", "stale", "duplicate", "missing-target", "ownership", "limit", "apply", "rollback", "disposed-root"]);
const code = error => CODES.has(error?.code) ? error.code : "apply";

/** BH-03-owned root capabilities with independent, bounded transaction FIFOs. */
export class DOMRootQueues {
  #registry; #handles = new Set(); #states = new WeakMap(); #bindings = new Map(); #capacity; #onAck; #schedule;
  constructor({ scopeId, createBridge, capacity = 64, onAck = () => {}, schedule = task => queueMicrotask(task) }) {
    requireDOM(Number.isInteger(capacity) && capacity >= 1 && capacity <= 64, "limit");
    requireDOM(typeof onAck === "function" && typeof schedule === "function");
    this.#capacity = capacity; this.#onAck = onAck; this.#schedule = schedule;
    this.#registry = new BrowserRootRegistry({ scopeId, createBridge, onEvent: event => this.#lifecycle(event) });
  }
  get lifecycle() { return this.#registry; }
  async register(rootId) { const handle = await this.#registry.register(rootId); this.#handles.add(handle); return handle; }
  attach(handle, { owner, generation, apply, preflight = () => {}, release = () => {}, rejected = () => {} }) {
    requireDOM(this.#handles.has(handle), "ownership");
    const snapshot = handle.snapshot();
    requireDOM(snapshot.state === "ready", "disposed-root");
    requireDOM(typeof owner === "string" && /^root-[a-z0-9_-]{1,59}$/.exec(owner)?.[0] === owner && Number.isSafeInteger(generation) && generation > 0, "ownership");
    requireDOM(typeof apply === "function" && typeof release === "function" && typeof preflight === "function");
    requireDOM(!this.#bindings.has(handle) || this.#bindings.get(handle).disposed, "duplicate");
    const token = Object.freeze({});
    const state = { handle, owner, generation, projection: null, revision: 0, digest: null, disposed: false, quarantined: false, epoch: 0, lifecycleGeneration: snapshot.root_generation, queue: [], active: null, apply, preflight, release, seen: [], maxDepth: 0 };
    state.rejected = rejected;
    this.#states.set(token, state); this.#bindings.set(handle, state);
    return token;
  }
  submit(token, raw, metadata = null) {
    const state = this.#states.get(token);
    requireDOM(state, "ownership");
    const tx = copyTransaction(raw);
    if (state.disposed || state.quarantined) return Promise.resolve(this.#emit(tx, "rejected", "disposed-root"));
    if (tx.owner !== state.owner) return Promise.resolve(this.#emit(tx, "rejected", "ownership"));
    if (state.seen.includes(tx.transaction_id) || state.active?.tx.transaction_id === tx.transaction_id || state.queue.some(j => j.tx.transaction_id === tx.transaction_id)) return Promise.resolve(this.#emit(tx, "rejected", "duplicate"));
    if (state.queue.length + Number(state.active !== null) >= this.#capacity) return Promise.resolve(this.#emit(tx, "rejected", "limit"));
    return new Promise(resolve => {
      const job = { tx, metadata, resolve, settled: false, epoch: state.epoch };
      state.queue.push(job); state.maxDepth = Math.max(state.maxDepth, state.queue.length + Number(state.active !== null));
      this.#schedulePump(state);
    });
  }
  snapshot(token) {
    const s = this.#states.get(token); requireDOM(s, "ownership");
    return Object.freeze({ owner: s.owner, generation: s.generation, revision: s.revision, digest: s.digest, disposed: s.disposed, quarantined: s.quarantined, queued: s.queue.length + Number(s.active !== null), max_depth: s.maxDepth, nodes: s.projection?.nodes.length ?? 0, fingerprint: s.projection?.fingerprint ?? null });
  }
  #emit(tx, state, diagnostic = null) { const ack = acknowledgement(tx, state, diagnostic); try { this.#onAck(ack); } catch { /* Observers have no commit authority. */ } return ack; }
  #finish(job, outcome, diagnostic = null) { if (job.settled) return; job.settled = true; job.resolve(this.#emit(job.tx, outcome, diagnostic)); }
  #schedulePump(state) { try { this.#schedule(() => this.#pump(state)); } catch { this.#drain(state, "apply"); } }
  async #pump(state) {
    if (state.active || !state.queue.length || state.disposed || state.quarantined) return;
    const job = state.active = state.queue.shift();
    let applying = false;
    try {
      const planned = await planTransaction(state, job.tx);
      requireDOM(!job.settled && job.epoch === state.epoch && !state.disposed && state.handle.snapshot().state === "ready" && state.handle.snapshot().root_generation === state.lifecycleGeneration, "disposed-root");
      const preflight = state.preflight({ previous: state.projection, next: planned.projection, transaction: job.tx, metadata: job.metadata });
      requireDOM(!preflight || typeof preflight.then !== "function");
      this.#emit(job.tx, "accepted");
      requireDOM(!job.settled && job.epoch === state.epoch && !state.disposed, "disposed-root");
      state.preflight({ previous: state.projection, next: planned.projection, transaction: job.tx, metadata: job.metadata });
      applying = true;
      const result = state.apply({ previous: state.projection, next: planned.projection, transaction: job.tx, metadata: job.metadata });
      requireDOM(result && typeof result.then !== "function" && ["committed", "rolled-back", "fallback"].includes(result.state));
      requireDOM(!job.settled && job.epoch === state.epoch && !state.disposed, "disposed-root");
      if (result.state === "committed") {
        if (job.tx.kind === "dispose") state.release();
        state.projection = planned.projection; state.revision = job.tx.target_revision; state.generation = job.tx.generation; state.digest = job.tx.digest;
        if (job.tx.kind === "dispose") state.disposed = true;
        this.#finish(job, job.tx.kind === "dispose" ? "disposed" : "committed");
        if (job.tx.kind === "replace" || job.tx.kind === "dispose") this.#drain(state, "stale");
      } else {
        if (result.state === "fallback") { state.quarantined = true; this.#drain(state, "disposed-root"); }
        this.#finish(job, result.state, result.state === "fallback" ? "rollback" : "apply");
      }
    } catch (error) {
      if (applying) {
        state.quarantined = true; this.#drain(state, "disposed-root");
        try { state.release(); } catch { /* Quarantine remains terminal even if host cleanup fails. */ }
        this.#finish(job, "fallback", "rollback");
      } else { state.rejected(); this.#finish(job, "rejected", code(error)); }
    }
    finally {
      state.seen.push(job.tx.transaction_id); if (state.seen.length > 64) state.seen.shift();
      state.active = null;
      if (state.disposed) state.projection = null;
      if (state.queue.length) this.#schedulePump(state);
    }
  }
  #drain(state, reason) { for (const job of state.queue.splice(0)) this.#finish(job, "rejected", reason); }
  #lifecycle(event) {
    for (const state of this.#bindings.values()) if (state.handle.snapshot().root_id === event.root_id) {
      if (event.root_generation !== state.lifecycleGeneration || ["disposing", "disposed", "failed", "unregistered"].includes(event.state)) {
        state.epoch++; state.disposed = true;
        this.#drain(state, "disposed-root");
        if (state.active) this.#finish(state.active, "rejected", "disposed-root");
        try { state.release(); } catch { state.quarantined = true; }
        state.projection = null;
      }
    }
  }
}
