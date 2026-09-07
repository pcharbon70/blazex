// Strict, small DOM model. Browser runs remain the authority for native behavior.
class Text {
  constructor(data, document) { this.data = data; this.ownerDocument = document; this.parentNode = null; this.nodeType = 3; }
  get textContent() { return this.data; }
  remove() { this.parentNode?.childNodes.splice(this.parentNode.childNodes.indexOf(this), 1); this.parentNode = null; }
}
export class Element {
  constructor(tag, document) {
    this.nodeType = 1; this.tagName = tag.toUpperCase(); this.ownerDocument = document; this.parentNode = null; this.childNodes = []; this.attributes = new Map(); this.listeners = new Map();
    this.value = ""; this.checked = false; this.selectionStart = tag === "input" ? 0 : null; this.selectionEnd = this.selectionStart; this.selectionDirection = tag === "input" ? "none" : null;
  }
  get firstChild() { return this.childNodes[0] ?? null; }
  get children() { return this.childNodes.filter(n => n.nodeType === 1); }
  get textContent() { return this.childNodes.map(n => n.textContent).join(""); }
  set textContent(value) { this.replaceChildren(...(value === "" ? [] : [new Text(String(value), this.ownerDocument)])); }
  getAttributeNames() { return [...this.attributes.keys()]; }
  getAttribute(name) { return this.attributes.get(name) ?? null; }
  setAttribute(name, value) { this.attributes.set(name, String(value)); }
  removeAttribute(name) { this.attributes.delete(name); }
  contains(node) { return this === node || this.childNodes.some(n => n.nodeType === 1 ? n.contains(node) : n === node); }
  append(...nodes) { nodes.forEach(node => this.insertBefore(node, null)); }
  insertBefore(node, before) {
    if (before !== null && !this.childNodes.includes(before)) throw new Error("missing anchor");
    if (node === this || node.contains?.(this)) throw new Error("cycle");
    if (node === before) return node;
    node.remove(); const index = before === null ? this.childNodes.length : this.childNodes.indexOf(before);
    this.childNodes.splice(index, 0, node); node.parentNode = this; return node;
  }
  remove() { this.parentNode?.childNodes.splice(this.parentNode.childNodes.indexOf(this), 1); this.parentNode = null; }
  replaceChildren(...nodes) { [...this.childNodes].forEach(n => n.remove()); this.append(...nodes); }
  addEventListener(name, handler) { const set = this.listeners.get(name) ?? new Set(); set.add(handler); this.listeners.set(name, set); }
  removeEventListener(name, handler) { this.listeners.get(name)?.delete(handler); }
  focus() { this.ownerDocument.activeElement = this; }
  setSelectionRange(start, end, direction) { this.selectionEnd = Math.min(end, this.value.length); this.selectionStart = Math.min(start, this.selectionEnd); this.selectionDirection = direction; }
}
for (const [property, attribute] of [["disabled", "disabled"], ["readOnly", "readonly"], ["hidden", "hidden"]]) Object.defineProperty(Element.prototype, property, { get() { return this.attributes.has(attribute); }, set(value) { if (value) this.setAttribute(attribute, ""); else this.removeAttribute(attribute); } });
export class Document {
  constructor() { this.body = new Element("body", this); this.activeElement = this.body; }
  createElement(tag) { return new Element(tag, this); }
}
