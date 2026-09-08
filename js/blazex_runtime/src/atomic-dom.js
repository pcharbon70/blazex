import { DOMRootQueues } from "./dom-root-queue.js";
import { decodeIntent } from "./render-intent-data.js";
import { requireDOM } from "./dom-transaction-plan.js";
import { InteractionListeners } from "./interaction-listeners.js";

const claims = new WeakMap();
const properties = ["value", "disabled", "readOnly", "hidden", "checked"];
const defaults = { value: "", disabled: false, readOnly: false, hidden: false, checked: false };
const attrs = element => element.getAttributeNames().sort().map(name => [name, element.getAttribute(name)]);
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const selection = element => typeof element.selectionStart === "number" ? [element.selectionStart, element.selectionEnd, element.selectionDirection] : null;
const portable = value => ["atom", "binary", "integer"].includes(value.type) ? String(value.value) : JSON.stringify(value);

/** Only the lifecycle owner can bind a DOM container; callers receive opaque capabilities. */
export class AtomicDOMRoots {
  #queues;
  constructor(options) { this.#queues = new DOMRootQueues(options); }
  get lifecycle() { return this.#queues.lifecycle; }
  register(rootId) { return this.#queues.register(rootId); }
  attach(handle, { container, owner, generation, fault = () => {}, interactions = null }) {
    requireDOM(interactions === null || interactions instanceof InteractionListeners, "ownership");
    const dom = new AtomicDOM(container, fault, interactions);
    try {
      interactions?.claim(handle.snapshot(), owner);
      return this.#queues.attach(handle, { owner, generation, preflight: args => dom.preflight(args), apply: args => dom.apply(args), release: () => dom.release() });
    } catch (error) { dom.release(); throw error; }
  }
  submit(token, transaction) { return this.#queues.submit(token, transaction); }
  snapshot(token) { return this.#queues.snapshot(token); }
}

class AtomicDOM {
  #prefix = "bx-dom-" + crypto.randomUUID() + "-";
  #container; #document; #nodes = new Map(); #listeners = []; #accepted = []; #fault; #released = false; #interactions;
  constructor(container, fault, interactions) {
    requireDOM(container?.nodeType === 1 && container.ownerDocument?.createElement && typeof fault === "function", "ownership");
    requireDOM(container.childNodes.length === 0, "ownership");
    this.#container = container; this.#document = container.ownerDocument; this.#fault = fault;
    this.#interactions = interactions;
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
  preflight({ next, transaction }) {
    requireDOM(!this.#released, "disposed-root");
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
      requireDOM(type === undefined || (node.tag === "input" && type === "text") || (node.tag === "button" && type === "button"), "incompatible");
      const allowed = node.tag === "input" ? ["value", "checked", "disabled", "readOnly"] : node.tag === "button" ? ["value", "disabled"] : [];
      requireDOM(node.properties.every(cell => allowed.includes(cell.name)), "incompatible");
    }
    for (const op of transaction.operations) if (op.type === "attribute" && op.name === "type") requireDOM(op.new === null || ["text", "button"].includes(op.new), "incompatible");
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
    }
    if (selected) {
      element.setAttribute("data-bx-selection-kind", selected.kind);
      if (selected.kind === "single") element.value = portable(selected.value);
      else if (selected.kind === "multiple") element.setAttribute("data-bx-selection-count", String(selected.value.length));
      else if (selected.kind === "text_range" && typeof element.setSelectionRange === "function") element.setSelectionRange(Number(selected.value.anchor), Number(selected.value.focus), selected.value.direction);
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
  #finishProjection(projection) {
    this.#unbind();
    for (const node of projection?.nodes ?? []) {
      const element = this.#nodes.get(node.id);
      if (this.#interactions && node.tag === "input") {
        // Phase 6 owns continuity. This phase reapplies declared values/defaults.
        element.value = node.properties.find(c => c.name === "value")?.value ?? "";
        element.checked = node.properties.find(c => c.name === "checked")?.value ?? false;
      }
      this.#intent(element, node); this.#bind(element, node.listeners, node.id);
    }
    const focused = projection?.nodes.find(node => decodeIntent(node.focus)?.auto_focus);
    if (focused) this.#nodes.get(focused.id).focus();
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
      requireDOM(element.tagName === expected.tagName && same(attrs(element), attrs(expected)) && properties.every(name => element[name] === expected[name]) && same(selection(element), selection(expected)), "apply");
      requireDOM(element.parentNode === (node.parent === null ? this.#container : this.#nodes.get(node.parent)), "ownership");
      requireDOM(node.text === null ? element.childNodes.length === node.children.length && node.children.every((id, i) => element.childNodes[i] === this.#nodes.get(id)) : element.textContent === node.text && element.children.length === 0, "apply");
    }
  }
  apply({ previous, next, transaction }) {
    const oldNodes = new Map(this.#nodes), journal = this.#capture(), active = this.#document.activeElement;
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
      this.#finishProjection(next); this.#fault("finalize", transaction.operations.length); this.#verify(next);
      this.#accepted = this.#capture();
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
        this.#interactions?.resume();
        return { state: "rolled-back" };
      } catch {
        this.#interactions?.dispose();
        try { this.#fault("fallback", -1); this.#reconstruct(previous); this.#verify(previous); }
        catch { this.#unbind(); this.#nodes.clear(); this.#container.replaceChildren(); }
        this.#accepted = this.#capture();
        return { state: "fallback" };
      }
    }
  }
  release() {
    if (this.#released) return;
    this.#unbind(); this.#interactions?.dispose(); this.#container.replaceChildren(); this.#nodes.clear(); this.#accepted = [];
    this.#released = true; claims.get(this.#document).delete(this.#container);
  }
}
