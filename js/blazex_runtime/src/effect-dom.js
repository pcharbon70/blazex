import { AtomicDOMRoots } from "./atomic-dom.js";
import { RendererResources } from "./renderer-resources.js";
import { copyEffects } from "./effect-wire.js";
import { requireDOM } from "./dom-transaction-plan.js";
import { RendererFailure } from "./renderer-failure.js";

/** Explicitly negotiated effect companion. Only bounded timer requests execute. */
export class EffectDOMRoots {
  #dom; #states = new WeakMap();
  constructor(options) { this.#dom = new AtomicDOMRoots(options); }
  get lifecycle() { return this.#dom.lifecycle; }
  get deadlineMs() { return 750; }
  register(root) { return this.#dom.register(root); }
  attach(handle, options) {
    const grants = options.grants ?? [];
    requireDOM(Array.isArray(grants) && grants.length <= 1 && grants.every(g => g === "time"), "incompatible");
    const resources = new RendererResources(options.owner, options.generation);
    requireDOM(options.effectFault === undefined || typeof options.effectFault === "function");
    const state = { resources, grants: [...grants], busy: false, closed: false, cancel: null, token: null, trace: [], results: [], effectFault: options.effectFault ?? (() => {}) };
    state.failure = new RendererFailure(() => { state.closed = true; state.cancel?.(); resources.dispose(); });
    const token = this.#dom.attach(handle, { ...options, continuity: true, onRelease: () => {
      if (!state.closed) state.failure.report("lifecycle", "runtime-loss", true);
      state.closed = true; state.cancel?.(); resources.dispose();
    } });
    state.token = token;
    // The DOM lease owns its bounded subsystem inventories. Its cleanup is real,
    // not a counter reset; errors remain retained in the ledger.
    resources.acquire("dom", () => {
      this.#dom.dispose(token);
      const inventory = this.#dom.resources(token);
      requireDOM(inventory.disposed && Object.entries(inventory).every(([key, value]) =>
        key === "disposed" || (typeof value === "number" ? value === 0 : Object.values(value).every(n => n === 0))), "apply");
    });
    this.#states.set(token, state); return token;
  }
  #state(token) { const state = this.#states.get(token); requireDOM(state, "ownership"); return state; }
  snapshot(token) {
    const s = this.#state(token);
    return { ...this.#dom.snapshot(token), busy: s.busy, closed: s.closed, resources: s.resources.snapshot(), inventory: this.#dom.resources(token), trace: [...s.trace], results: [...s.results], failure: s.failure.snapshot() };
  }
  #trace(s, barrier) { s.trace.push(barrier); if (s.trace.length > 32) s.trace.shift(); }
  async submit(token, raw) {
    const s = this.#state(token);
    if (s.closed || s.busy) { s.failure.report("protocol", s.closed ? "disposed-root" : "limit"); requireDOM(false, s.closed ? "disposed-root" : "limit"); }
    s.busy = true; s.results = [];
    let deadline, expired = false;
    const abort = new Promise(resolve => { s.cancel = () => { expired = true; resolve(null); }; });
    const lease = s.resources.acquire("transaction", () => s.cancel?.());
    deadline = setTimeout(() => s.cancel?.(), 750);
    const clock = s.resources.acquire("deadline", () => clearTimeout(deadline));
    try {
      this.#trace(s, "preflight");
      const envelope = await Promise.race([copyEffects(raw, s.grants), abort]);
      requireDOM(envelope && !expired && !s.closed, "disposed-root");
      requireDOM(envelope.continuity.transaction.generation === s.resources.snapshot().generation, "stale");
      const ack = await Promise.race([this.#dom.submit(token, envelope.continuity), abort]);
      requireDOM(ack && !expired && !s.closed, "disposed-root");
      if (ack.state !== "committed") {
        s.failure.report("dom", ack.ack?.diagnostic ?? "apply", ack.state === "fallback");
        return { state: ack.state, ack, effects_digest: envelope.digest, results: [] };
      }
      this.#trace(s, "commit-focus-selection");
      for (const effect of envelope.effects) {
        requireDOM(!s.closed && !expired, "disposed-root");
        this.#trace(s, "post-commit:" + effect.id);
        const dependencyFailed = effect.depends.some(id => s.results.find(r => r.id === id)?.status !== "ok");
        const status = dependencyFailed ? "cancelled" : await Promise.race([this.#timer(s, effect), abort.then(() => "cancelled")]);
        s.results.push({ id: effect.id, status });
        requireDOM(!s.closed && !expired, "disposed-root");
        if (status !== "ok") s.failure.report("effect", status, effect.fallback === "fail");
        if (status !== "ok" && effect.fallback === "fail") return { state: "failed", ack, effects_digest: envelope.digest, results: [...s.results] };
      }
      this.#trace(s, "acknowledgement");
      return { state: "committed", ack, effects_digest: envelope.digest, results: [...s.results] };
    } catch (error) {
      s.failure.report(expired ? "effect" : "protocol", expired ? "timeout" : error?.code, expired);
      throw error;
    } finally {
      s.resources.release(clock); s.resources.release(lease); s.cancel = null; s.busy = false;
    }
  }
  #timer(s, effect) {
    try { const result = s.effectFault(effect.id); requireDOM(!result || typeof result.then !== "function"); }
    catch { return Promise.resolve("failed"); }
    return new Promise(resolve => {
      let settled = false, timer, timeout, lease;
      const finish = status => { if (settled) return; settled = true; clearTimeout(timer); clearTimeout(timeout); if (lease) s.resources.release(lease); resolve(status); };
      lease = s.resources.acquire("timer", () => finish("cancelled"));
      timer = setTimeout(() => finish("ok"), effect.payload.delay_ms);
      timeout = setTimeout(() => finish("timeout"), effect.timeout_ms);
    });
  }
  dispose(token) { const s = this.#state(token); if (!s.closed) { s.closed = true; s.cancel?.(); s.resources.dispose(); } }
  interactionFailure(token, code, terminal = true) { this.#state(token).failure.report(code === "timeout" ? "acknowledgement" : "interaction", code, terminal); }
}
