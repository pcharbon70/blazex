import { copyInteractionData, requireInteraction, validateInteraction, InteractionError, INTERACTION_DIAGNOSTICS, interactionDiagnostic } from "./interaction-record.js";

export const INTERACTION_BRIDGE = "blazex.host-bridge/2";
const identityKeys = ["root_id", "lifecycle_generation", "owner", "generation", "revision", "transaction_id", "digest"];
/** Negotiated companion to the immutable BH-03 lifecycle bridge, never fixture.event. */
export class InteractionBridge {
  #transport; #rootId;
  #protocol;
  constructor({ protocol, rootId, transport }) {
    requireInteraction([INTERACTION_BRIDGE, "blazex.host-bridge/3", "blazex.host-bridge/4"].includes(protocol), "incompatible");
    requireInteraction(typeof transport?.request === "function" && typeof transport?.cancel === "function");
    this.#transport = transport; this.#rootId = rootId; this.#protocol = protocol;
  }
  preflight(record) { copyInteractionData({ protocol: this.#protocol, root_id: this.#rootId, request_id: "00000000-0000-0000-0000-000000000000", operation: "root.interaction", payload: record }); }
  async request(operation, payload, signal) {
    requireInteraction(["root.interaction", "root.render_ack"].includes(operation), "incompatible");
    const request = copyInteractionData({ protocol: this.#protocol, root_id: this.#rootId, request_id: crypto.randomUUID(), operation, payload });
    requireInteraction(!signal.aborted, "cancelled");
    const cancel = () => { try { this.#transport.cancel({ protocol: this.#protocol, root_id: this.#rootId, request_id: request.request_id }); } catch { /* Local cancellation remains terminal. */ } };
    signal.addEventListener("abort", cancel, { once: true });
    try {
      const response = await this.#transport.request(request);
      requireInteraction(!signal.aborted, "cancelled");
      requireInteraction(response?.protocol === this.#protocol && response.root_id === this.#rootId && response.request_id === request.request_id, "ownership");
      requireInteraction(Object.keys(response).sort().join(" ") === "protocol request_id result root_id");
      return response.result;
    } finally { signal.removeEventListener("abort", cancel); }
  }
}

/** Independent root FIFO; uncertain results quarantine this stream, never retry. */
export class InteractionStream {
  #bridge; #handle; #context = null; #queue = []; #active = null; #closed = false; #lastSequence = 0; #maximum = 0; #timeout; #dom = null; #token = null;
  constructor({ bridge, rootHandle, timeoutMs = 5000 }) {
    requireInteraction(bridge instanceof InteractionBridge && typeof rootHandle?.snapshot === "function");
    requireInteraction(Number.isInteger(timeoutMs) && timeoutMs >= 1 && timeoutMs <= 10000, "limit");
    this.#bridge = bridge; this.#handle = rootHandle; this.#timeout = timeoutMs;
  }
  bindDOM(dom, token) { requireInteraction(this.#dom === null && typeof dom?.submit === "function"); this.#dom = dom; this.#token = token; }
  setContext(context) {
    requireInteraction(!this.#closed, "disposed-root");
    // Listener inventory is separately bounded; it need not fit one event's item budget.
    requireInteraction(Array.isArray(context.listeners) && context.listeners.length <= 256 && new Set(context.listeners).size === context.listeners.length && context.listeners.every(id => typeof id === "string" && id.length <= 64), "listener");
    const { listeners, ...header } = context;
    this.#context = { ...copyInteractionData(header), listeners: new Set(listeners) };
    for (const job of this.#queue.splice(0)) this.#finish(job, "rejected", "stale");
  }
  enqueue(raw) {
    const record = validateInteraction(raw); this.#validateContext(record);
    this.#bridge.preflight(record);
    requireInteraction(record.sequence > this.#lastSequence, "duplicate");
    requireInteraction(this.#queue.length + Number(this.#active !== null) < 64, "limit");
    this.#lastSequence = record.sequence;
    return new Promise(resolve => {
      const job = { record, resolve, settled: false, controller: new AbortController(), timer: null };
      this.#queue.push(job); this.#maximum = Math.max(this.#maximum, this.#queue.length + Number(this.#active !== null));
      job.timer = setTimeout(() => { this.#finish(job, "rejected", "timeout"); this.dispose(); }, this.#timeout);
      queueMicrotask(() => this.#pump());
    });
  }
  snapshot() { return Object.freeze({ queued: this.#queue.length + Number(this.#active !== null), max_depth: this.#maximum, disposed: this.#closed, last_sequence: this.#lastSequence }); }
  resources() { const jobs = [...this.#queue, ...(this.#active ? [this.#active] : [])].filter(j => !j.settled); return { queued: jobs.length, timers: jobs.length, callbacks: jobs.length }; }
  #validateContext(record) {
    requireInteraction(!this.#closed && this.#context && this.#handle.snapshot().state === "ready", "disposed-root");
    requireInteraction(this.#handle.snapshot().root_id === record.root_id && this.#handle.snapshot().root_generation === record.lifecycle_generation, "stale");
    requireInteraction(identityKeys.every(k => record[k] === this.#context[k]), "stale");
    requireInteraction(this.#context.listeners.has(record.listener_id), "listener");
  }
  #finish(job, outcome, diagnostic = null) {
    if (job.settled) return;
    job.settled = true; clearTimeout(job.timer);
    if (outcome !== "accepted") job.controller.abort();
    job.resolve(Object.freeze({ outcome, diagnostic, sequence: job.record.sequence, root_id: job.record.root_id }));
  }
  async #pump() {
    if (this.#active || this.#closed || !this.#queue.length) return;
    const job = this.#active = this.#queue.shift();
    try {
      this.#validateContext(job.record);
      const result = await this.#bridge.request("root.interaction", job.record, job.controller.signal);
      requireInteraction(!job.settled && !this.#closed, "disposed-root");
      this.#validateContext(job.record);
      const ack = copyInteractionData(result.ack);
      requireInteraction(identityKeys.concat("sequence", "listener_id").every(k => ack[k] === job.record[k]), "ownership");
      requireInteraction(Object.keys(ack).sort().join(" ") === [...identityKeys, "sequence", "listener_id", "outcome", "diagnostic"].sort().join(" "));
      requireInteraction(["accepted", "rejected"].includes(ack.outcome));
      if (ack.outcome === "rejected") { requireInteraction(INTERACTION_DIAGNOSTICS.includes(ack.diagnostic)); this.#finish(job, "rejected", ack.diagnostic); return; }
      requireInteraction(ack.diagnostic === null);
      if (result.transaction !== null) {
        requireInteraction(this.#dom !== null, "unmounted");
        const committed = await this.#dom.submit(this.#token, result.transaction);
        requireInteraction(!job.settled && !this.#closed, "disposed-root");
        const settled = await this.#bridge.request("root.render_ack", { sequence: job.record.sequence, ack: committed }, job.controller.signal);
        requireInteraction(settled?.outcome === "committed" && settled.sequence === job.record.sequence && committed.state === "committed", "render");
      }
      this.#finish(job, "accepted");
    } catch (error) {
      this.#finish(job, "rejected", error instanceof InteractionError ? interactionDiagnostic(error) : "transport"); this.dispose();
    } finally { this.#active = null; if (!this.#closed) queueMicrotask(() => this.#pump()); }
  }
  dispose() {
    if (this.#closed) return;
    this.#closed = true;
    for (const job of this.#queue.splice(0)) this.#finish(job, "rejected", "disposed-root");
    if (this.#active) this.#finish(this.#active, "rejected", "disposed-root");
    this.#active = null;
    this.#context = null; this.#dom = null; this.#token = null;
  }
}
