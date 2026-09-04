export class FakeElement {
  constructor(tagName, documentImpl) {
    this.tagName = tagName.toUpperCase();
    this.ownerDocument = documentImpl;
    this.children = [];
    this.parentNode = null;
    this.attributes = new Map();
    this.listeners = new Map();
    this.textContent = "";
    this.value = "";
    this.disabled = false;
    this.readOnly = false;
    this.hidden = false;
  }

  append(node) {
    this.insertBefore(node, null);
  }

  insertBefore(node, before) {
    node.parentNode?.children.splice(node.parentNode.children.indexOf(node), 1);
    const index = before ? this.children.indexOf(before) : this.children.length;
    this.children.splice(index < 0 ? this.children.length : index, 0, node);
    node.parentNode = this;
  }

  setAttribute(name, value) { this.attributes.set(name, String(value)); }
  getAttribute(name) { return this.attributes.get(name) ?? null; }
  addEventListener(name, handler) { this.listeners.set(name, new Set([...(this.listeners.get(name) ?? []), handler])); }
  removeEventListener(name, handler) { this.listeners.get(name)?.delete(handler); }
  remove() {
    if (this.parentNode) this.parentNode.children.splice(this.parentNode.children.indexOf(this), 1);
    this.parentNode = null;
  }
  dispatch(name, values = {}) {
    const event = { target: this, relatedTarget: null, ...values };
    for (const handler of this.listeners.get(name) ?? []) handler(event);
  }
  focus() { this.ownerDocument.activeElement = this; }
}

export class FakeDocument {
  constructor() {
    this.activeElement = null;
    this.body = new FakeElement("body", this);
  }
  createElement(tagName) { return new FakeElement(tagName, this); }
}
