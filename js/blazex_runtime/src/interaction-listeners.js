import { EVENT_MAPPINGS, INTERACTION_PROTOCOL, listenerIdentity, normalizeNative, requireInteraction, validateInteraction } from "./interaction-record.js";

/** A root-local registry. No callback stores an Event, projection or transaction tree. */
export class InteractionListeners {
  #bindings = new Map(); #context; #receiver; #clock; #sequence = 0; #timestamp = 0; #suspended = true; #disposed = false; #onOutcome; #claimed = false; #lease = 0;
  constructor({ rootId, lifecycleGeneration, owner, receiver, clock = () => performance.now(), onOutcome = () => {} }) {
    requireInteraction(receiver && typeof receiver.enqueue === "function" && typeof receiver.setContext === "function" && typeof receiver.dispose === "function" && typeof clock === "function" && typeof onOutcome === "function");
    this.#context = { root_id: rootId, lifecycle_generation: lifecycleGeneration, owner };
    this.#receiver = receiver; this.#clock = clock; this.#onOutcome = onOutcome;
  }
  claim(snapshot, owner) {
    requireInteraction(!this.#claimed && !this.#disposed && snapshot.state === "ready" && snapshot.root_id === this.#context.root_id && snapshot.root_generation === this.#context.lifecycle_generation && owner === this.#context.owner, "ownership");
    this.#claimed = true;
  }
  register(source, element, binding) {
    requireInteraction(!this.#disposed && binding.native === EVENT_MAPPINGS[binding.semantic], "listener");
    const id = listenerIdentity(source, binding.semantic); requireInteraction(!this.#bindings.has(id), "duplicate");
    const lease = ++this.#lease;
    this.#bindings.set(id, { source, semantic: binding.semantic, generation: binding.source.generation, element, lease });
    return { id, handler: this.#handler(id, lease) };
  }
  #handler(id, lease) { return event => this.#capture(id, lease, event); }
  unregister(id) { this.#bindings.delete(id); }
  suspend() { this.#suspended = true; }
  resume() { if (!this.#disposed) this.#suspended = false; }
  publish(transaction) {
    requireInteraction(!this.#disposed && transaction.owner === this.#context.owner, "ownership");
    this.#context = { ...this.#context, generation: transaction.generation, revision: transaction.target_revision, transaction_id: transaction.transaction_id, digest: transaction.digest };
    this.#receiver.setContext({ ...this.#context, listeners: [...this.#bindings.keys()] }); this.resume();
  }
  dispose() { if (this.#disposed) return; this.#disposed = true; this.#suspended = true; this.#bindings.clear(); this.#receiver.dispose(); this.#context = null; }
  snapshot() { return Object.freeze({ listeners: this.#bindings.size, sequence: this.#sequence, suspended: this.#suspended, disposed: this.#disposed }); }
  #outcome(value) { try { this.#onOutcome(Object.freeze(value)); } catch { /* Observation has no dispatch authority. */ } }
  #observe(pending, sequence) {
    Promise.resolve(pending).then(outcome => this.#outcome(outcome), () => this.#outcome({ outcome: "rejected", diagnostic: "transport", sequence }));
  }
  #capture(id, lease, event) {
    try {
      requireInteraction(!this.#disposed && !this.#suspended, "disposed-root");
      const binding = this.#bindings.get(id); requireInteraction(binding && binding.lease === lease && binding.generation === this.#context.generation, "listener");
      const payload = normalizeNative(binding.semantic, binding.source, binding.element, event);
      const time = this.#clock(); requireInteraction(Number.isFinite(time) && time >= 0 && time <= Number.MAX_SAFE_INTEGER, "clock");
      this.#timestamp = Math.max(this.#timestamp, Math.floor(time));
      const record = validateInteraction({ ...this.#context, protocol: INTERACTION_PROTOCOL, provenance: "local-event", source: binding.source, listener_id: id, semantic: binding.semantic, sequence: this.#sequence + 1, timestamp: this.#timestamp, payload });
      this.#sequence++;
      const pending = this.#receiver.enqueue(record);
      if (event.cancelable) event.preventDefault(); event.stopPropagation();
      this.#observe(pending, record.sequence);
    } catch (error) { this.#outcome({ outcome: "rejected", diagnostic: error.code ?? "malformed" }); }
  }
}
