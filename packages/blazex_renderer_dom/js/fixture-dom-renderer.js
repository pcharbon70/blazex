import {
  FIXTURE_DOM_LIMITS,
  FIXTURE_EVENT_PROTOCOL,
  FIXTURE_NODE_KINDS,
  FixtureDOMError,
  normalizeFixtureEvent,
  validateFixtureEffect,
} from "./fixture-dom-protocol.js";

const RELATIONSHIPS = Object.freeze({
  label_for: "for",
  described_by: "aria-describedby",
  error_message: "aria-errormessage",
  controls: "aria-controls",
});

export class FixtureDOMRenderer {
  #disposed = false;
  #document;
  #eventSequence = 0;
  #generation;
  #lastSequence = 0;
  #listeners = new Map();
  #metrics = { batches: 0, operations: 0, mutations: 0, events: 0, failures: 0, stale_drops: 0 };
  #nodes = new Map();
  #onEvent;
  #onTrace;
  #root = null;
  #target;

  constructor({ target, generation, documentImpl, onEvent = () => {}, onTrace = () => {} }) {
    if (!target?.append || !documentImpl?.createElement || !Number.isSafeInteger(generation) || generation < 1) {
      throw new TypeError("A target, document, and positive fixture generation are required");
    }
    this.#target = target;
    this.#document = documentImpl;
    this.#generation = generation;
    this.#onEvent = onEvent;
    this.#onTrace = onTrace;
  }

  apply(rawEffect) {
    if (this.#disposed) throw new FixtureDOMError("fixture-renderer-disposed", "The fixture renderer is disposed");
    const effect = validateFixtureEffect(rawEffect);
    if (effect.generation !== this.#generation) {
      this.#metrics.stale_drops += 1;
      throw new FixtureDOMError("fixture-generation-stale", "The fixture effect belongs to another generation");
    }
    if (effect.sequence <= this.#lastSequence) throw new FixtureDOMError("fixture-sequence-stale", "Fixture effect sequence must increase");
    this.#preflight(effect.operations);
    try {
      for (const operation of effect.operations) this.#applyOperation(operation);
      this.#lastSequence = effect.sequence;
      this.#metrics.batches += 1;
      this.#metrics.operations += effect.operations.length;
      this.#trace("batch-applied", { sequence: effect.sequence, operations: effect.operations.map((item) => item.op) });
      return this.snapshot();
    } catch (error) {
      this.#metrics.failures += 1;
      this.#trace("batch-failed", { sequence: effect.sequence, code: error?.code ?? "fixture-adapter-error" });
      throw error;
    }
  }

  snapshot() {
    const nodes = [...this.#nodes.entries()].map(([id, entry]) => ({
      id,
      kind: entry.kind,
      text: entry.node.textContent,
      value: entry.node.value ?? null,
      disabled: Boolean(entry.node.disabled),
      read_only: Boolean(entry.node.readOnly),
      hidden: Boolean(entry.node.hidden),
      invalid: entry.node.getAttribute?.("aria-invalid") ?? null,
      described_by: entry.node.getAttribute?.("aria-describedby") ?? null,
      error_message: entry.node.getAttribute?.("aria-errormessage") ?? null,
      parent_id: entry.parentId,
    }));
    return Object.freeze({
      protocol: "blazex.bh01.dom-observation/0.1",
      generation: this.#generation,
      sequence: this.#lastSequence,
      disposed: this.#disposed,
      root_count: this.#root ? 1 : 0,
      node_count: this.#nodes.size,
      listener_count: this.#listeners.size,
      focused_node_id: this.#focusedNodeId(),
      nodes: Object.freeze(nodes),
      metrics: Object.freeze({ ...this.#metrics }),
    });
  }

  dispose(reason = "requested") {
    if (this.#disposed) return this.snapshot();
    for (const { node, nativeEvent, handler } of this.#listeners.values()) node.removeEventListener(nativeEvent, handler);
    this.#listeners.clear();
    this.#root?.remove();
    this.#root = null;
    this.#nodes.clear();
    this.#disposed = true;
    this.#trace("disposed", { reason });
    return this.snapshot();
  }

  #preflight(operations) {
    if (this.#nodes.size + operations.filter((item) => item.op === "node.upsert" && !this.#nodes.has(item.id)).length > FIXTURE_DOM_LIMITS.max_nodes) {
      throw new FixtureDOMError("fixture-node-count-exceeded", "The fixture node limit is exceeded");
    }
    const available = new Set(this.#nodes.keys());
    if (this.#root) available.add("bx-fixture-root");
    for (const operation of operations) {
      if (operation.generation !== this.#generation) throw new FixtureDOMError("fixture-generation-stale", "An operation belongs to another generation");
      if (operation.op === "root.mount") available.add(operation.id);
      else if (operation.op === "node.upsert") {
        if (!available.has(operation.parent_id)) throw new FixtureDOMError("fixture-parent-missing", "The fixture parent is missing", { id: operation.parent_id });
        available.add(operation.id);
      } else if (operation.op === "node.move") {
        if (!available.has(operation.id) || !available.has(operation.parent_id) || (operation.before_id && !available.has(operation.before_id))) throw new FixtureDOMError("fixture-target-missing", "A fixture move target is missing");
      } else if (operation.op !== "root.dispose" && !available.has(operation.id)) {
        throw new FixtureDOMError("fixture-target-missing", "The fixture operation target is missing", { id: operation.id });
      }
      if (operation.op === "node.relationship" && operation.target_ids.some((id) => !available.has(id))) throw new FixtureDOMError("fixture-relationship-target-missing", "A relationship target is missing");
      if (operation.op === "listener.bind" && this.#listeners.has(`${operation.id}:${operation.event}`)) throw new FixtureDOMError("fixture-listener-duplicate", "The fixture listener is already bound");
      if (operation.op === "node.remove") available.delete(operation.id);
      if (operation.op === "root.dispose") available.clear();
    }
  }

  #applyOperation(operation) {
    if (operation.op === "root.mount") {
      if (!this.#root) {
        this.#root = this.#document.createElement("section");
        this.#root.id = operation.id;
        this.#root.setAttribute("data-bh01-test-id", operation.test_id);
        this.#root.setAttribute("aria-label", "BH-01 disposable local behavior fixture");
        this.#target.append(this.#root);
        this.#nodes.set(operation.id, { node: this.#root, kind: "root", parentId: null });
        this.#metrics.mutations += 1;
      }
      return;
    }
    if (operation.op === "node.upsert") {
      const current = this.#nodes.get(operation.id);
      if (current && current.kind !== operation.kind) throw new FixtureDOMError("fixture-node-kind-mismatch", "An existing fixture node cannot change kind");
      const parent = this.#nodes.get(operation.parent_id).node;
      const entry = current ?? { node: this.#document.createElement(FIXTURE_NODE_KINDS[operation.kind]), kind: operation.kind, parentId: operation.parent_id };
      if (!current) {
        entry.node.id = operation.id;
        if (operation.test_id) entry.node.setAttribute("data-bh01-test-id", operation.test_id);
        if (operation.kind === "status" || operation.kind === "error") entry.node.setAttribute("aria-live", "polite");
        if (operation.kind === "action") entry.node.type = "button";
        parent.append(entry.node);
        this.#nodes.set(operation.id, entry);
      }
      if (operation.text !== undefined) entry.node.textContent = operation.text;
      entry.parentId = operation.parent_id;
      this.#metrics.mutations += 1;
      return;
    }
    if (operation.op === "node.move") {
      const node = this.#nodes.get(operation.id).node;
      const parent = this.#nodes.get(operation.parent_id).node;
      const before = operation.before_id ? this.#nodes.get(operation.before_id).node : null;
      parent.insertBefore(node, before);
      this.#nodes.get(operation.id).parentId = operation.parent_id;
    } else if (operation.op === "node.text") {
      this.#nodes.get(operation.id).node.textContent = operation.text;
    } else if (operation.op === "node.property") {
      const node = this.#nodes.get(operation.id).node;
      if (operation.name === "read_only") node.readOnly = operation.value;
      else if (operation.name === "invalid") node.setAttribute("aria-invalid", String(operation.value));
      else node[operation.name] = operation.value;
    } else if (operation.op === "node.relationship") {
      const node = this.#nodes.get(operation.id).node;
      node.setAttribute(RELATIONSHIPS[operation.name], operation.target_ids.join(" "));
    } else if (operation.op === "listener.bind") {
      this.#bind(operation);
    } else if (operation.op === "node.remove") {
      this.#remove(operation.id);
    } else if (operation.op === "root.dispose") {
      this.dispose("fixture-operation");
    }
    this.#metrics.mutations += 1;
  }

  #bind(operation) {
    const node = this.#nodes.get(operation.id).node;
    const nativeEvent = operation.event === "action" ? "click" : operation.event;
    const handler = (event) => {
      if (this.#disposed) return;
      const normalized = normalizeFixtureEvent(event, { generation: this.#generation, sequence: ++this.#eventSequence, nodeId: operation.id, eventName: operation.event });
      this.#metrics.events += 1;
      this.#trace("event-normalized", { protocol: FIXTURE_EVENT_PROTOCOL, node_id: operation.id, event: operation.event, sequence: normalized.sequence });
      this.#onEvent(normalized);
    };
    node.addEventListener(nativeEvent, handler);
    this.#listeners.set(`${operation.id}:${operation.event}`, { node, nativeEvent, handler });
  }

  #remove(id) {
    const children = [...this.#nodes.entries()].filter(([_childId, entry]) => entry.parentId === id).map(([childId]) => childId);
    for (const childId of children) this.#remove(childId);
    const prefix = `${id}:`;
    for (const [key, listener] of [...this.#listeners]) {
      if (key.startsWith(prefix)) {
        listener.node.removeEventListener(listener.nativeEvent, listener.handler);
        this.#listeners.delete(key);
      }
    }
    const entry = this.#nodes.get(id);
    entry.node.remove();
    this.#nodes.delete(id);
  }

  #focusedNodeId() {
    for (const [id, entry] of this.#nodes) if (entry.node === this.#document.activeElement) return id;
    return null;
  }

  #trace(stage, details) {
    this.#onTrace(Object.freeze({ protocol: "blazex.bh01.dom-trace/0.1", generation: this.#generation, stage, ...details, metrics: Object.freeze({ ...this.#metrics }) }));
  }
}
