import test from "node:test";
import assert from "node:assert/strict";
import { FormContinuity } from "../src/form-continuity.js";
import { validateControls, copyContinuity, verifyContinuity } from "../src/continuity-wire.js";
import { digest } from "../src/render-transaction-codec.js";
import { Document } from "./support/atomic-fake-dom.js";
const owner = "bx-" + "a".repeat(24);
const control = (value, edit_sequence = 0) => ({ owner, kind: "text", value, choices: [], edit_sequence, disabled: false, readonly: false, required: false, invalid: false, indeterminate: false });
const emit = (el, type, extra = {}) => { for (const fn of el.listeners.get(type) ?? []) fn({ target: el, ...extra }); };
test("closed manifests reject foreign choices, missing selection and files", async () => {
  assert.equal(validateControls([control("a")]).length, 1);
  for (const c of [{ ...control("a"), path: "private" }, { ...control("a"), kind: "file" }, { ...control("a"), value: "x".repeat(2049) }, { ...control("a"), kind: "single", value: "missing" }]) assert.throws(() => validateControls([c]));
  const payload = { protocol: "blazex.dom-continuity/1", transaction: {}, controls: [control("a")], base_control_digest: null, control_digest: await digest([control("a")]) };
  const envelope = copyContinuity({ ...payload, digest: await digest(payload) });
  await verifyContinuity(envelope);
  await assert.rejects(verifyContinuity({ ...envelope, controls: [control("changed")] }));
});
test("newer drafts survive pending semantic writes and composition never fabricates input", () => {
  const doc = new Document(), element = doc.createElement("input"), nodes = new Map([[owner, element]]), state = new FormContinuity();
  const envelope = (value, seq = 0) => ({ controls: [control(value, seq)], control_digest: "a" });
  state.apply(envelope("initial"), nodes); assert.equal(element.value, "initial");
  element.value = "draft"; state.admitted(owner, { value: "draft", checked: false }, 2);
  state.apply(envelope("older", 1), nodes); assert.equal(element.value, "draft");
  state.apply(envelope("accepted", 2), nodes); assert.equal(element.value, "accepted");
  emit(element, "compositionstart"); element.value = "composing"; emit(element, "compositionupdate");
  state.apply(envelope("conflict", 3), nodes); assert.equal(element.value, "composing");
  assert.equal(state.snapshot().composing, 1); emit(element, "compositionend"); assert.equal(state.snapshot().composing, 0);
  state.apply(envelope("still not acknowledged", 3), nodes); assert.equal(element.value, "composing");
  element.value = "unobserved mutation";
  const expected = doc.createElement("input"); state.expected(expected, owner); assert.equal(expected.value, "composing");
  element.value = "x".repeat(2049); emit(element, "input");
  assert.throws(() => state.validate({ base_control_digest: null }, null), error => error.code === "limit");
  state.expected(expected, owner); assert.equal(expected.value, "composing");
  state.rejected(); state.dispose(); state.dispose(); assert.deepEqual(state.snapshot(), { controls: 0, composing: 0, listeners: 0, disposed: true });
});
test("checked, mixed, required and invalid map distinctly and rollback releases composition", () => {
  const doc = new Document(), element = doc.createElement("input"), nodes = new Map([[owner, element]]), state = new FormContinuity();
  const c = { ...control(true), kind: "check", indeterminate: true, required: true, invalid: true };
  state.apply({ controls: [c] }, nodes);
  assert.equal(element.checked, true); assert.equal(element.indeterminate, true); assert.equal(element.required, true); assert.equal(element.getAttribute("aria-invalid"), "true");
  const checkpoint = state.checkpoint(); state.rollback(checkpoint, nodes); assert.equal(state.snapshot().composing, 0); state.dispose();
});
test("readonly choices cancel native toggles before a semantic event", () => {
  const doc = new Document(), element = doc.createElement("input"), nodes = new Map([[owner, element]]), state = new FormContinuity();
  state.apply({ controls: [{ ...control(false), kind: "check", readonly: true }] }, nodes);
  let cancelled = false; emit(element, "click", { preventDefault() { cancelled = true; } });
  assert.equal(cancelled, true); assert.equal(state.editable(owner), false); state.dispose();
});
test("invalid admissions cannot dirty a control or advance its edit fence", () => {
  for (const kind of ["text", "check"]) {
    const doc = new Document(), element = doc.createElement("input"), nodes = new Map([[owner, element]]), state = new FormContinuity();
    const c = { ...control(kind === "text" ? "initial" : true), kind };
    state.apply({ controls: [c] }, nodes);
    for (const payload of [null, {}, { value: undefined, checked: false }, { value: "bad", checked: undefined }]) state.admitted(owner, payload, 10);
    state.admitted(owner, { value: "bad", checked: false }, NaN);
    state.apply({ controls: [c] }, nodes);
    assert.equal(kind === "text" ? element.value : element.checked, c.value);
    state.admitted(owner, { value: "draft", checked: false }, 2);
    state.admitted(owner, {}, 10);
    state.apply({ controls: [{ ...c, edit_sequence: 2 }] }, nodes);
    assert.equal(kind === "text" ? element.value : element.checked, c.value);
    state.dispose();
  }
});
