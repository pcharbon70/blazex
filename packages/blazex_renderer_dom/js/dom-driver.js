import { DOMProtocolError, normalizeEvent, validateBatch } from "./dom-protocol.js";

export class BlazeXDOMDriver {
  #batch = null;
  #disposed = false;
  #document;
  #eventSequence = 0;
  #listeners = [];
  #nodes = new Map();
  #onEvent;
  #root = null;
  #target;

  constructor({ target, documentImpl, onEvent = () => {} }) {
    if (!target?.replaceChildren || !documentImpl?.createElement || typeof onEvent !== "function") {
      throw new TypeError("A target, document, and event callback are required");
    }
    this.#target = target;
    this.#document = documentImpl;
    this.#onEvent = onEvent;
  }

  apply(rawBatch) {
    const batch = validateBatch(rawBatch);
    if (batch.transition === "dispose") return this.#applyDispose(batch);
    this.#preflightTransition(batch);

    const previousFocus = this.#focusedNodeId();
    const candidate = { nodes: new Map(), listeners: [], autoFocus: null, selections: [] };
    const root = this.#build(batch.root, null, batch, candidate);

    this.#releaseListeners();
    this.#target.replaceChildren(root);
    this.#root = root;
    this.#nodes = candidate.nodes;
    this.#listeners = candidate.listeners;
    this.#batch = batch;
    this.#disposed = false;
    this.#applySelections(candidate.selections);

    const restored = batch.transition === "update" && previousFocus && this.#nodes.get(previousFocus);
    if (restored) restored.focus();
    else if (candidate.autoFocus) candidate.autoFocus.focus();
    return this.snapshot();
  }

  snapshot() {
    const nodes = [];
    if (this.#batch?.root && !this.#disposed) this.#snapshotNode(this.#batch.root, null, nodes);
    return Object.freeze({
      version: 1,
      generation: this.#batch?.generation ?? null,
      revision: this.#batch?.revision ?? null,
      transition: this.#batch?.transition ?? null,
      digest: this.#batch?.digest ?? null,
      disposed: this.#disposed,
      root_count: this.#root ? 1 : 0,
      node_count: this.#nodes.size,
      listener_count: this.#listeners.length,
      focused_node_id: this.#focusedNodeId(),
      nodes: Object.freeze(nodes),
    });
  }

  dispose() {
    if (this.#disposed) return this.snapshot();
    this.#releaseListeners();
    this.#target.replaceChildren();
    this.#root = null;
    this.#nodes.clear();
    this.#disposed = true;
    return this.snapshot();
  }

  #preflightTransition(batch) {
    if (!this.#batch) {
      if (batch.transition !== "mount" || batch.revision !== 0) throw new DOMProtocolError("dom-mount-required", "The first batch must mount revision zero");
      return;
    }
    if (this.#disposed) throw new DOMProtocolError("dom-driver-disposed", "The DOM driver is disposed");
    if (batch.transition === "update") {
      if (batch.generation !== this.#batch.generation || batch.revision !== this.#batch.revision + 1) {
        throw new DOMProtocolError("dom-update-stale", "A DOM update must use the current generation and next revision");
      }
      return;
    }
    if (batch.transition === "replace") {
      if (batch.generation !== this.#batch.generation + 1 || batch.revision !== 0) {
        throw new DOMProtocolError("dom-replacement-invalid", "A DOM replacement must use the next generation at revision zero");
      }
      return;
    }
    throw new DOMProtocolError("dom-transition-invalid", "A mounted driver accepts only update or replacement projection batches");
  }

  #applyDispose(batch) {
    if (this.#disposed) {
      if (batch.generation !== this.#batch.generation || batch.revision !== this.#batch.revision) {
        throw new DOMProtocolError("dom-disposal-stale", "Repeated DOM disposal must match the disposed lifecycle");
      }
      return this.snapshot();
    }
    if (!this.#batch || batch.generation !== this.#batch.generation || batch.revision !== this.#batch.revision) {
      throw new DOMProtocolError("dom-disposal-stale", "DOM disposal must match the current generation and revision");
    }
    this.#batch = batch;
    return this.dispose();
  }

  #build(projection, parentId, batch, candidate) {
    const element = this.#document.createElement(projection.tag);
    element.id = projection.id;
    for (const [name, value] of Object.entries(projection.attributes)) element.setAttribute(name, value);
    if (projection.text !== null) element.textContent = projection.text;
    candidate.nodes.set(projection.id, element);

    for (const listener of projection.listeners) {
      const handler = (event) => {
        if (this.#disposed) return;
        const normalized = normalizeEvent(event, listener, {
          generation: batch.generation,
          revision: batch.revision,
          sequence: ++this.#eventSequence,
        });
        this.#onEvent(normalized);
      };
      element.addEventListener(listener.native, handler);
      candidate.listeners.push({ element, native: listener.native, handler });
    }

    if (projection.focus?.behavior === "target") {
      element.setAttribute("tabindex", String(projection.focus.order));
      if (projection.focus.auto_focus) candidate.autoFocus = element;
    } else if (projection.focus?.behavior === "scope") {
      element.setAttribute("data-bx-focus-scope", "true");
      element.setAttribute("data-bx-focus-restore", projection.focus.restore);
      element.setAttribute("data-bx-focus-wrap", String(projection.focus.wrap));
    }
    if (projection.selection) candidate.selections.push({ element, selection: projection.selection });
    for (const child of projection.children) element.append(this.#build(child, projection.id, batch, candidate));
    void parentId;
    return element;
  }

  #applySelections(selections) {
    for (const { element, selection } of selections) {
      element.setAttribute("data-bx-selection-kind", selection.kind);
      if (selection.kind === "single") element.value = portableValue(selection.value);
      else if (selection.kind === "multiple") element.setAttribute("data-bx-selection-count", String(selection.value.length));
      else if (selection.kind === "text_range" && typeof element.setSelectionRange === "function") {
        element.setSelectionRange(selection.value.anchor, selection.value.focus, selection.value.direction);
      }
    }
  }

  #releaseListeners() {
    for (const listener of this.#listeners) listener.element.removeEventListener(listener.native, listener.handler);
    this.#listeners = [];
  }

  #focusedNodeId() {
    for (const [id, node] of this.#nodes) if (node === this.#document.activeElement) return id;
    return null;
  }

  #snapshotNode(projection, parentId, result) {
    const element = this.#nodes.get(projection.id);
    result.push(Object.freeze({
      id: projection.id,
      parent_id: parentId,
      tag: projection.tag,
      text: element?.textContent ?? null,
      attributes: Object.freeze({ ...projection.attributes }),
      listener_events: Object.freeze(projection.listeners.map((listener) => listener.semantic)),
      focus: projection.focus,
      selection: projection.selection,
    }));
    projection.children.forEach((child) => this.#snapshotNode(child, projection.id, result));
  }
}

function portableValue(portable) {
  if (portable.type === "atom" || portable.type === "binary" || portable.type === "integer") return String(portable.value);
  return JSON.stringify(portable);
}
