import { DOMRootQueues } from "./dom-root-queue.js";
import { decodeIntent } from "./render-intent-data.js";
import { requireDOM } from "./dom-transaction-plan.js";
import { InteractionListeners } from "./interaction-listeners.js";
import { FormContinuity } from "./form-continuity.js";
import { copyContinuity, verifyContinuity } from "./continuity-wire.js";
import { captureContinuity, restoreContinuity } from "./focus-continuity.js";

const claims = new WeakMap();
const properties = ["value", "disabled", "readOnly", "hidden", "checked", "required", "indeterminate"];
const defaults = { value: "", disabled: false, readOnly: false, hidden: false, checked: false };
const attrs = element => element.getAttributeNames().sort().map(name => [name, element.getAttribute(name)]);
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const selection = element => typeof element.selectionStart === "number" ? [element.selectionStart, element.selectionEnd, element.selectionDirection] : null;
const portable = value => ["atom", "binary", "integer"].includes(value.type) ? String(value.value) : JSON.stringify(value);

/** Only the lifecycle owner can bind a DOM container; callers receive opaque capabilities. */
export class AtomicDOMRoots {
  #queues;
  #continuities = new WeakMap();
  #doms = new WeakMap();
  constructor(options) { this.#queues = new DOMRootQueues(options); }
  get lifecycle() { return this.#queues.lifecycle; }
  register(rootId) { return this.#queues.register(rootId); }
  attach(handle, { container, owner, generation, fault = () => {}, interactions = null, continuity = false, onRelease = () => {} }) {
    requireDOM(typeof onRelease === "function");
    requireDOM(interactions === null || interactions instanceof InteractionListeners, "ownership");
    requireDOM(typeof continuity === "boolean", "ownership");
    const controller = continuity ? new FormContinuity() : null;
    if (controller) interactions?.setContinuity(controller);
    const dom = new AtomicDOM(container, fault, interactions, controller);
    try {
      interactions?.claim(handle.snapshot(), owner);
      const token = this.#queues.attach(handle, { owner, generation, preflight: args => dom.preflight(args), apply: args => dom.apply(args), release: () => { try { dom.release(); } finally { onRelease(); } }, rejected: () => controller?.rejected() });
      this.#doms.set(token, dom);
      if (controller) this.#continuities.set(token, controller);
      return token;
    } catch (error) { dom.release(); throw error; }
  }
  submit(token, transaction) {
    const controller = this.#continuities.get(token);
    if (!controller) return this.#queues.submit(token, transaction);
    return this.#submitContinuity(token, transaction, controller);
  }
  async #submitContinuity(token, raw, controller) {
    try {
      const envelope = copyContinuity(raw); await verifyContinuity(envelope);
      const ack = await this.#queues.submit(token, envelope.transaction, envelope);
      return Object.freeze({ state: ack.state, ack, continuity_digest: envelope.digest });
    } catch (error) { controller.rejected(); throw error; }
  }
  continuitySnapshot(token) { return this.#continuities.get(token)?.snapshot() ?? null; }
  snapshot(token) { return this.#queues.snapshot(token); }
  resources(token) { const dom = this.#doms.get(token); requireDOM(dom, "ownership"); return dom.resources(); }
  dispose(token) { return this.#queues.dispose(token); }
}

class AtomicDOM {
  #continuity;
  #prefix = "bx-dom-" + crypto.randomUUID() + "-";
  #container; #document; #nodes = new Map(); #listeners = []; #accepted = []; #fault; #released = false; #interactions;
  constructor(container, fault, interactions, continuity) {
    requireDOM(container?.nodeType === 1 && container.ownerDocument?.createElement && typeof fault === "function", "ownership");
    requireDOM(container.childNodes.length === 0, "ownership");
    this.#container = container; this.#document = container.ownerDocument; this.#fault = fault;
    this.#interactions = interactions;
    this.#continuity = continuity;
    const owned = claims.get(this.#document) ?? new Set();
    requireDOM(![...owned].some(other => other === container || other.contains(container) || container.contains(other)), "ownership");
    owned.add(container); claims.set(this.#document, owned);
    this.#accepted = this.#capture();
  }
  #capture() {
    return [this.#container, ...this.#nodes.values()].map(element => ({ element, children: [...element.childNodes], attributes: attrs(element), props: properties.map(name => element[name]), text: [...element.childNodes].map(n => n.nodeType === 3 ? n.data : null), selection: selection(element) }));
  }
  #matches(records) {
    return records.every(r => same(attrs(r.element), r.attributes) && properties.every((name, i) => r.element[name] === r.props[i]) && same(selection(r.element), r.selection) && r.element.childNodes.length === r.children.length && r.children.every((child, i) => r.element.childNodes[i] === child && (child.nodeType !== 3 || child.data === r.text[i])));
  }
  preflight({ next, transaction, metadata }) {
    requireDOM(!this.#released, "disposed-root");
    if (this.#continuity) {
      this.#continuity.validate(metadata, next);
      for (const record of this.#accepted) {
        if (this.#continuity.has(record.element)) { record.props[0] = record.element.value; record.props[4] = record.element.checked; }
        record.selection = selection(record.element);
      }
    }
    // Only successfully normalized native value reads may update the rollback
    // journal. All attributes, identities and tree structure still match exactly.
    for (const observation of this.#interactions?.takeObservations() ?? []) {
      const element = this.#nodes.get(observation.source), old = this.#accepted.find(r => r.element === element);
      if (old && element.value === observation.value && (observation.checked === null || element.checked === observation.checked)) {
        old.props = [...old.props]; old.props[0] = observation.value;
        if (observation.checked !== null) old.props[4] = observation.checked;
        old.selection = selection(element);
      }
    }
    requireDOM(this.#matches(this.#accepted), "stale");
    requireDOM([...this.#nodes.values()].every(n => this.#container.contains(n)), "ownership");
    for (const node of next?.nodes ?? []) {
      const type = node.attributes.find(c => c.name === "type")?.value;
      requireDOM(type === undefined || (node.tag === "input" && (type === "text" || (this.#continuity && type === "checkbox"))) || (node.tag === "button" && type === "button"), "incompatible");
      const allowed = node.tag === "input" ? ["value", "checked", "disabled", "readOnly"] : node.tag === "button" ? ["value", "disabled"] : [];
      requireDOM(node.properties.every(cell => allowed.includes(cell.name)), "incompatible");
    }
    for (const op of transaction.operations) if (op.type === "attribute" && op.name === "type") requireDOM(op.new === null || ["text", "button", ...(this.#continuity ? ["checkbox"] : [])].includes(op.new), "incompatible");
    for (const op of transaction.operations) if (op.type === "property") {
      const tag = transaction.operations.find(o => o.type === "create" && o.target === op.target)?.tag ?? this.#nodes.get(op.target)?.tagName.toLowerCase();
      requireDOM((tag === "input" ? ["value", "checked", "disabled", "readOnly"] : tag === "button" ? ["value", "disabled"] : []).includes(op.name), "incompatible");
    }
  }
  #unbind() { for (const { element, native, handler, id } of this.#listeners) { element.removeEventListener(native, handler); if (id) this.#interactions?.unregister(id); } this.#listeners = []; }
  #bind(element, encoded, source) {
    for (const listener of decodeIntent(encoded) ?? []) {
      const registration = this.#interactions && !this.#interactions.snapshot().disposed ? this.#interactions.register(source, element, listener) : { handler: () => {}, id: null };
      element.addEventListener(listener.native, registration.handler, { capture: false, passive: false });
      this.#listeners.push({ element, native: listener.native, ...registration });
    }
  }
  #intent(element, node) {
    for (const name of ["tabindex", "data-bx-focus-scope", "data-bx-focus-restore", "data-bx-focus-wrap", "data-bx-selection-kind", "data-bx-selection-count"]) element.removeAttribute(name);
    const focus = decodeIntent(node.focus), selected = decodeIntent(node.selection);
    if (focus?.behavior === "target") element.setAttribute("tabindex", String(focus.order));
    else if (focus?.behavior === "scope") {
      element.setAttribute("data-bx-focus-scope", "true"); element.setAttribute("data-bx-focus-restore", focus.restore); element.setAttribute("data-bx-focus-wrap", String(focus.wrap));
      if (this.#continuity) element.setAttribute("tabindex", "-1");
    }
    if (selected) {
      element.setAttribute("data-bx-selection-kind", selected.kind);
      if (selected.kind === "single") element.value = portable(selected.value);
      else if (selected.kind === "multiple") element.setAttribute("data-bx-selection-count", String(selected.value.length));
      else if (!this.#continuity && selected.kind === "text_range" && typeof element.setSelectionRange === "function") element.setSelectionRange(Number(selected.value.anchor), Number(selected.value.focus), selected.value.direction);
    }
  }
  #create(node) {
    const element = this.#document.createElement(node.tag);
    element.setAttribute("id", this.#prefix + node.id);
    if (node.tag === "button") element.setAttribute("type", "button");
    if (node.text !== null) element.textContent = node.text;
    return element;
  }
  #attribute(element, name, value) {
    const relationships = ["aria-labelledby", "aria-describedby", "aria-controls", "aria-owns", "aria-errormessage"];
    element.setAttribute(name, relationships.includes(name) ? value.split(" ").map(id => this.#prefix + id).join(" ") : value);
  }
  #finishProjection(projection, metadata = null) {
    this.#unbind();
    for (const node of projection?.nodes ?? []) {
      const element = this.#nodes.get(node.id);
      if (this.#interactions && !this.#continuity && node.tag === "input") {
        // Phase 6 owns continuity. This phase reapplies declared values/defaults.
        element.value = node.properties.find(c => c.name === "value")?.value ?? "";
        element.checked = node.properties.find(c => c.name === "checked")?.value ?? false;
      }
      this.#intent(element, node); this.#bind(element, node.listeners, node.id);
    }
    if (this.#continuity && metadata) this.#continuity.apply(metadata, this.#nodes);
    if (!this.#continuity) {
      const focused = projection?.nodes.find(node => decodeIntent(node.focus)?.auto_focus);
      if (focused) this.#nodes.get(focused.id).focus();
    }
  }
  #reconstruct(projection) {
    this.#unbind(); this.#nodes = new Map();
    for (const node of projection?.nodes ?? []) {
      const element = this.#create(node); this.#nodes.set(node.id, element);
      for (const { name, value } of node.attributes) this.#attribute(element, name, value);
      for (const { name, value } of node.properties) element[name] = value;
    }
    for (const node of projection?.nodes ?? []) for (const child of node.children) this.#nodes.get(node.id).append(this.#nodes.get(child));
    this.#container.replaceChildren(...(projection ? [this.#nodes.get(projection.root)] : []));
    this.#finishProjection(projection);
  }
  #verify(projection) {
    requireDOM(this.#nodes.size === (projection?.nodes.length ?? 0), "apply");
    requireDOM(this.#container.childNodes.length === (projection ? 1 : 0) && (!projection || this.#container.firstChild === this.#nodes.get(projection.root)), "apply");
    for (const node of projection?.nodes ?? []) {
      const element = this.#nodes.get(node.id), expected = this.#create(node);
      for (const { name, value } of node.attributes) this.#attribute(expected, name, value);
      for (const { name, value } of node.properties) expected[name] = value;
      this.#intent(expected, node);
      this.#continuity?.expected(expected, node.id);
      requireDOM(element.tagName === expected.tagName && same(attrs(element), attrs(expected)) && properties.every(name => element[name] === expected[name]) && (this.#continuity || same(selection(element), selection(expected))), "apply");
      requireDOM(element.parentNode === (node.parent === null ? this.#container : this.#nodes.get(node.parent)), "ownership");
      requireDOM(node.text === null ? element.childNodes.length === node.children.length && node.children.every((id, i) => element.childNodes[i] === this.#nodes.get(id)) : element.textContent === node.text && element.children.length === 0, "apply");
    }
  }
  apply({ previous, next, transaction, metadata }) {
    const oldNodes = new Map(this.#nodes), journal = this.#capture(), active = this.#document.activeElement;
    const checkpoint = this.#continuity?.checkpoint();
    const observation = this.#continuity ? captureContinuity(this.#container, this.#nodes) : null;
    try {
      this.#interactions?.suspend();
      const created = new Map();
      // All allocations are detached and validated by the pure transaction plan first.
      for (const op of transaction.operations) if (op.type === "create") { requireDOM(!created.has(op.target), "duplicate"); created.set(op.target, this.#create({ id: op.target, tag: op.tag, text: op.text })); }
      for (const op of transaction.operations) {
        this.#fault("before", op.op_id);
        const element = this.#nodes.get(op.target);
        if (op.type === "create") this.#nodes.set(op.target, created.get(op.target));
        else if (["insert", "move"].includes(op.type)) (op.parent === null ? this.#container : this.#nodes.get(op.parent)).insertBefore(element, op.anchor === null ? null : this.#nodes.get(op.anchor));
        else if (op.type === "remove") { element.remove(); this.#nodes.delete(op.target); }
        else if (op.type === "replace") { element.remove(); this.#nodes.delete(op.target); (op.parent === null ? this.#container : this.#nodes.get(op.parent)).insertBefore(this.#nodes.get(op.value), op.anchor === null ? null : this.#nodes.get(op.anchor)); }
        else if (op.type === "text") element.textContent = op.new ?? "";
        else if (op.type === "attribute") { if (op.new === null) { if (op.name === "type" && element.tagName === "BUTTON") element.setAttribute("type", "button"); else element.removeAttribute(op.name); } else this.#attribute(element, op.name, op.new); }
        else if (op.type === "property") {
          if (op.name === "value" && element.tagName === "BUTTON" && op.new === null) element.removeAttribute("value");
          else element[op.name] = op.new ?? defaults[op.name];
        }
        // Intent binding is finalized once, after structural mutations; effects remain prohibited.
        this.#fault("after", op.op_id);
      }
      if (transaction.kind === "dispose") { this.#container.replaceChildren(); this.#nodes.clear(); }
      this.#finishProjection(next, metadata); this.#fault("finalize", transaction.operations.length); this.#verify(next);
      if (observation) restoreContinuity(this.#container, this.#nodes, previous, next, observation);
      this.#accepted = this.#capture();
      this.#continuity?.committed(metadata);
      if (next) this.#interactions?.publish(transaction);
      else this.#interactions?.dispose();
      return { state: "committed" };
    } catch {
      try {
        this.#fault("rollback", -1); this.#unbind(); this.#nodes = oldNodes;
        for (const r of journal) {
          properties.forEach((name, i) => { if (r.props[i] !== undefined && r.element[name] !== r.props[i]) r.element[name] = r.props[i]; });
          for (const name of r.element.getAttributeNames()) r.element.removeAttribute(name);
          for (const [name, value] of r.attributes) r.element.setAttribute(name, value);
          r.children.forEach((child, i) => { if (child.nodeType === 3) child.data = r.text[i]; });
          r.element.replaceChildren(...r.children);
          if (r.selection) r.element.setSelectionRange(...r.selection);
        }
        for (const node of previous?.nodes ?? []) this.#bind(this.#nodes.get(node.id), node.listeners, node.id);
        if (active && this.#container.contains(active)) active.focus();
        requireDOM(this.#matches(journal), "rollback"); this.#accepted = journal;
        if (checkpoint) this.#continuity.rollback(checkpoint, this.#nodes);
        this.#interactions?.resume();
        return { state: "rolled-back" };
      } catch {
        this.#interactions?.dispose();
        this.#continuity?.dispose();
        try { this.#fault("fallback", -1); this.#reconstruct(previous); this.#verify(previous); }
        catch { this.#unbind(); this.#nodes.clear(); this.#container.replaceChildren(); }
        this.#accepted = this.#capture();
        return { state: "fallback" };
      }
    }
  }
  release() {
    if (this.#released) return;
    this.#unbind(); this.#interactions?.dispose(); this.#continuity?.dispose(); this.#container.replaceChildren(); this.#nodes.clear(); this.#accepted = [];
    this.#released = true; claims.get(this.#document).delete(this.#container);
    this.#container = null; this.#document = null; this.#interactions = null; this.#continuity = null; this.#fault = null;
  }
  resources() {
    const form = this.#continuity?.snapshot();
    return { nodes: this.#nodes.size, listeners: this.#listeners.length,
      rollback_records: this.#accepted.length, form_records: form?.controls ?? 0,
      composition_records: form?.composing ?? 0, form_listeners: form?.listeners ?? 0,
      interaction: this.#interactions?.resources() ?? { queued: 0, timers: 0, callbacks: 0, observations: 0 },
      disposed: this.#released };
  }
}
