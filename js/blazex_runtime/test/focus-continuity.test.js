import test from "node:test";
import assert from "node:assert/strict";
import { captureContinuity, restoreContinuity } from "../src/focus-continuity.js";
import { encode } from "../src/render-transaction-codec.js";
import { Document } from "./support/atomic-fake-dom.js";
const cell = value => Buffer.from(encode(value)).toString("base64");
const focus = (order, auto_focus = false) => cell({ behavior: "target", order, auto_focus, restore: "none", wrap: false });
const node = (id, order) => ({ id, parent: "scope", focus: focus(order), selection: null });
test("keyed identity retains backward range; changed explicit range clamps to the new value", () => {
  const doc = new Document(), container = doc.createElement("div"), field = doc.createElement("input");
  doc.body.append(container); container.append(field); field.type = "text"; field.value = "abcdef"; field.setSelectionRange(1, 5, "backward"); field.focus();
  const nodes = new Map([["field", field]]), old = { nodes: [node("field", 0)] }, observed = captureContinuity(container, nodes);
  field.value = "abc"; field.setSelectionRange(0, 0, "forward");
  restoreContinuity(container, nodes, old, old, observed); assert.deepEqual([field.selectionStart, field.selectionEnd, field.selectionDirection], [1, 3, "backward"]);
  const next = { nodes: [{ ...node("field", 0), selection: cell({ kind: "text_range", value: { anchor: 9, focus: 2, direction: "forward" } }) }] };
  restoreContinuity(container, nodes, old, next, observed); assert.deepEqual([field.selectionStart, field.selectionEnd], [2, 3]);
});
test("focus recovery respects scope order and never steals a sibling root", () => {
  const doc = new Document(), container = doc.createElement("div"), a = doc.createElement("input"), b = doc.createElement("input"), sibling = doc.createElement("button");
  doc.body.append(container, sibling); container.append(a, b); a.focus();
  const scope = { id: "scope", parent: null, selection: null, focus: cell({ behavior: "scope", order: null, auto_focus: false, restore: "previous", wrap: false }) };
  const previous = { nodes: [scope, node("a", 0), node("b", 1)] }, nodes = new Map([["scope", container], ["a", a], ["b", b]]), observed = captureContinuity(container, nodes);
  a.remove(); nodes.delete("a"); restoreContinuity(container, nodes, previous, { nodes: [scope, node("b", 1)] }, observed); assert.equal(doc.activeElement, b);
  sibling.focus(); const outside = captureContinuity(container, nodes);
  restoreContinuity(container, nodes, previous, { nodes: [{ ...node("b", 1), focus: focus(1, true) }] }, outside); assert.equal(doc.activeElement, sibling);
  b.disabled = true; restoreContinuity(container, nodes, previous, { nodes: [scope, node("b", 1)] }, observed); assert.notEqual(doc.activeElement, b);
});
