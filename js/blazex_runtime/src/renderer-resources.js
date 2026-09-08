import { requireDOM } from "./dom-transaction-plan.js";

/** Cleanup leases are private capabilities, never wire identifiers or DOM handles. */
export class RendererResources {
  #owner; #generation; #entries = new Map(); #known = new WeakSet(); #closed = false; #peak = 0; #failures = 0;
  constructor(owner, generation) {
    requireDOM(typeof owner === "string" && Number.isSafeInteger(generation) && generation > 0, "ownership");
    this.#owner = owner; this.#generation = generation;
  }
  acquire(kind, release) {
    requireDOM(!this.#closed && this.#entries.size < 64, "limit");
    requireDOM(["dom", "transaction", "timer", "deadline"].includes(kind) && typeof release === "function");
    const token = Object.freeze({}); this.#known.add(token); this.#entries.set(token, { kind, release, failed: false });
    this.#peak = Math.max(this.#peak, this.#entries.size); return token;
  }
  release(token, owner = this.#owner, generation = this.#generation) {
    requireDOM(owner === this.#owner && generation === this.#generation, "ownership");
    requireDOM(this.#known.has(token), "ownership");
    const entry = this.#entries.get(token); if (!entry) return;
    if (entry.failed || entry.releasing) return;
    entry.releasing = true;
    try {
      const result = entry.release(); requireDOM(!result || typeof result.then !== "function", "apply");
      this.#entries.delete(token);
    } catch { entry.failed = true; this.#failures++; }
  }
  dispose() {
    this.#closed = true;
    for (const token of [...this.#entries.keys()].reverse()) this.release(token);
    return this.snapshot();
  }
  snapshot() {
    const kinds = {};
    for (const entry of this.#entries.values()) kinds[entry.kind] = (kinds[entry.kind] ?? 0) + 1;
    return { owner: this.#owner, generation: this.#generation, active: this.#entries.size, peak: this.#peak, failures: this.#failures, closed: this.#closed, kinds };
  }
}
