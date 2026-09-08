import { requireDOM } from "./dom-transaction-plan.js";
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const set = (element, key, value) => { if (element[key] !== value) element[key] = value; };

/** Root-owned local drafts; never emits synthetic events or retains native Events. */
export class FormContinuity {
  #entries = new Map(); #controls = []; #digest = null; #disposed = false;
  get digest() { return this.#digest; }
  has(element) { return [...this.#entries.values()].some(e => e.element === element); }
  admitted(source, payload, sequence) {
    const entry = this.#entries.get(source);
    if (entry) { entry.sequence = sequence; entry.dirty = true; entry.value = payload.value; entry.checked = payload.checked; }
  }
  validate(envelope, projection) {
    requireDOM(!this.#disposed && envelope && envelope.base_control_digest === this.#digest, "stale");
    const nodes = new Map((projection?.nodes ?? []).map(n => [n.id, n]));
    for (const control of envelope.controls) {
      const owner = nodes.get(control.owner); requireDOM(owner, "missing-target");
      requireDOM(owner.attributes.every(c => c.name !== "type" || ["text", "checkbox"].includes(c.value)), "incompatible");
      if (["text", "check"].includes(control.kind)) requireDOM(owner.tag === "input" && owner.children.length === 0, "incompatible");
      else requireDOM(owner.tag === "ul", "incompatible");
      for (const choice of control.choices) {
        const node = nodes.get(choice.owner); requireDOM(node && node.tag === "input" && node.children.length === 0, "incompatible");
        let parent = node.parent;
        while (parent !== null && parent !== control.owner) parent = nodes.get(parent)?.parent ?? null;
        requireDOM(parent === control.owner, "ownership");
      }
    }
  }
  #listen(source, element, text) {
    const entry = { element, text, composing: false, dirty: false, sequence: 0, value: element.value, checked: element.checked, listeners: [] };
    const listen = (name, fn) => { element.addEventListener(name, fn); entry.listeners.push([name, fn]); };
    if (text) {
      listen("compositionstart", () => { entry.composing = true; entry.dirty = true; });
      listen("compositionupdate", () => { entry.value = element.value; });
      listen("compositionend", () => { entry.composing = false; entry.value = element.value; });
      listen("blur", () => { entry.composing = false; });
      listen("input", event => { if (event.target === element) { entry.value = element.value; entry.dirty = true; if (event.isComposing) entry.composing = true; } });
    }
    this.#entries.set(source, entry); return entry;
  }
  #remove(source, entry) { for (const [name, fn] of entry.listeners) entry.element.removeEventListener(name, fn); this.#entries.delete(source); }
  #targets(controls) {
    return controls.flatMap(control => [control, ...control.choices.map(choice => ({ ...control, owner: choice.owner, kind: "check", value: control.kind === "single" ? control.value === choice.value : control.value.includes(choice.value), option: choice.value, choices: [], indeterminate: false }))]);
  }
  decorate(element, control, draft = null) {
    for (const [flag, property] of [["disabled", "disabled"], ["readonly", "readOnly"], ["required", "required"]]) {
      if (element.tagName === "INPUT") set(element, property, control[flag]);
      element.setAttribute("aria-" + flag, String(control[flag]));
    }
    element.setAttribute("aria-invalid", String(control.invalid));
    if (control.kind === "text") {
      element.setAttribute("type", "text");
      set(element, "value", draft ? draft.value : control.value);
    } else if (control.kind === "check") {
      element.setAttribute("type", "checkbox");
      set(element, "value", control.option ?? "on");
      set(element, "checked", draft ? draft.checked : control.value);
      set(element, "indeterminate", control.indeterminate);
      element.setAttribute("aria-checked", control.indeterminate ? "mixed" : String(element.checked));
      if (control.option !== undefined) element.setAttribute("aria-selected", String(element.checked));
    }
  }
  apply(envelope, nodes) {
    const targets = this.#targets(envelope.controls), wanted = new Map(targets.map(c => [c.owner, c]));
    for (const [source, entry] of this.#entries) if (!wanted.has(source) || nodes.get(source) !== entry.element || entry.text !== (wanted.get(source).kind === "text")) this.#remove(source, entry);
    for (const c of targets) {
      const element = nodes.get(c.owner);
      const entry = this.#entries.get(c.owner) ?? this.#listen(c.owner, element, c.kind === "text");
      const retain = entry.composing || (entry.dirty && (entry.sequence === 0 || c.edit_sequence < entry.sequence));
      this.decorate(element, c, retain ? entry : null);
      if (!retain) { entry.dirty = false; entry.value = element.value; entry.checked = element.checked; }
    }
    this.#controls = envelope.controls;
  }
  expected(element, source) {
    const control = this.#targets(this.#controls).find(c => c.owner === source);
    if (control) {
      const entry = this.#entries.get(source);
      this.decorate(element, control, entry ? { value: entry.element.value, checked: entry.element.checked } : null);
    }
  }
  committed(envelope) { this.#digest = envelope.control_digest; }
  checkpoint() { return { controls: this.#controls, digest: this.#digest, drafts: [...this.#entries].map(([source, e]) => [source, { ...e, listeners: undefined }]) }; }
  rollback(checkpoint, nodes) {
    for (const [source, entry] of this.#entries) this.#remove(source, entry);
    this.#controls = checkpoint.controls; this.#digest = checkpoint.digest;
    for (const [source, saved] of checkpoint.drafts) if (nodes.get(source) === saved.element) {
      const entry = this.#listen(source, saved.element, saved.text);
      Object.assign(entry, { value: saved.value, checked: saved.checked, dirty: saved.dirty, sequence: saved.sequence, composing: false });
    }
  }
  rejected() { for (const entry of this.#entries.values()) entry.composing = false; }
  snapshot() { return { controls: this.#entries.size, composing: [...this.#entries.values()].filter(e => e.composing).length, listeners: [...this.#entries.values()].reduce((n, e) => n + e.listeners.length, 0), disposed: this.#disposed }; }
  dispose() { if (this.#disposed) return; for (const [source, entry] of this.#entries) this.#remove(source, entry); this.#controls = []; this.#disposed = true; }
}
