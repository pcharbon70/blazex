import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { FixtureDOMRenderer } from "../fixture-dom-renderer.js";
import { FIXTURE_DOM_PROTOCOL, FIXTURE_EFFECT_PROTOCOL, FixtureDOMError, validateFixtureOperation } from "../fixture-dom-protocol.js";
import { FakeDocument } from "./fake-dom.js";

const op = (name, values = {}) => ({ protocol: FIXTURE_DOM_PROTOCOL, op: name, generation: 1, ...values });
const effect = (operations, sequence = 1, generation = 1) => ({ protocol: FIXTURE_EFFECT_PROTOCOL, generation, sequence, operations });

function mounted({ onEvent = () => {}, onTrace = () => {} } = {}) {
  const documentImpl = new FakeDocument();
  const renderer = new FixtureDOMRenderer({ target: documentImpl.body, documentImpl, generation: 1, onEvent, onTrace });
  renderer.apply(effect([
    op("root.mount", { id: "bx-fixture-root", test_id: "bx-test-root" }),
    op("node.upsert", { id: "bx-label", parent_id: "bx-fixture-root", kind: "label", text: "Name", test_id: "bx-test-label" }),
    op("node.upsert", { id: "bx-help", parent_id: "bx-fixture-root", kind: "help", text: "Enter a name" }),
    op("node.upsert", { id: "bx-field", parent_id: "bx-fixture-root", kind: "field", test_id: "bx-test-field" }),
    op("node.relationship", { id: "bx-label", name: "label_for", target_ids: ["bx-field"] }),
    op("node.relationship", { id: "bx-field", name: "described_by", target_ids: ["bx-help"] }),
    op("listener.bind", { id: "bx-field", event: "input" }),
  ]));
  return { documentImpl, renderer };
}

test("applies the closed node, relationship, property, move, and removal operations", () => {
  const { renderer } = mounted();
  let view = renderer.apply(effect([
    op("node.property", { id: "bx-field", name: "value", value: "Ada" }),
    op("node.property", { id: "bx-field", name: "invalid", value: false }),
    op("node.text", { id: "bx-help", text: "Accepted" }),
  ], 2));
  assert.equal(view.node_count, 4);
  assert.equal(view.listener_count, 1);
  assert.equal(view.nodes.find((item) => item.id === "bx-field").value, "Ada");
  assert.equal(view.nodes.find((item) => item.id === "bx-field").described_by, "bx-help");
  view = renderer.apply(effect([op("node.remove", { id: "bx-help" })], 3));
  assert.equal(view.node_count, 3);
});

test("applies field validity, mutability, and accessible error relationships", () => {
  const { renderer } = mounted();
  const view = renderer.apply(effect([
    op("node.upsert", { id: "bx-error", parent_id: "bx-fixture-root", kind: "error", text: "Name is required" }),
    op("node.relationship", { id: "bx-field", name: "described_by", target_ids: ["bx-help", "bx-error"] }),
    op("node.relationship", { id: "bx-field", name: "error_message", target_ids: ["bx-error"] }),
    op("node.property", { id: "bx-field", name: "disabled", value: true }),
    op("node.property", { id: "bx-field", name: "read_only", value: true }),
    op("node.property", { id: "bx-field", name: "invalid", value: true }),
  ], 2));
  const field = view.nodes.find((item) => item.id === "bx-field");
  assert.equal(field.disabled, true);
  assert.equal(field.read_only, true);
  assert.equal(field.invalid, "true");
  assert.equal(field.described_by, "bx-help bx-error");
  assert.equal(field.error_message, "bx-error");
  assert.equal(field.role, "textbox");
  assert.equal(field.accessible_name, "Name");
  assert.equal(view.nodes.find((item) => item.id === "bx-error").role, "alert");
});

test("normalizes events to bounded value records without retaining the event object", () => {
  const events = [];
  const { renderer } = mounted({ onEvent: (event) => events.push(event) });
  const field = renderer.snapshot().nodes.find((item) => item.id === "bx-field");
  assert.equal(field.kind, "field");
  const node = renderer[Object.getOwnPropertySymbols(renderer)[0]];
  void node;
  const documentImpl = new FakeDocument();
  const captured = [];
  const local = new FixtureDOMRenderer({ target: documentImpl.body, documentImpl, generation: 1, onEvent: (event) => captured.push(event) });
  local.apply(effect([
    op("root.mount", { id: "bx-fixture-root", test_id: "bx-test-root" }),
    op("node.upsert", { id: "bx-field", parent_id: "bx-fixture-root", kind: "field" }),
    op("listener.bind", { id: "bx-field", event: "input" }),
  ]));
  const fieldNode = documentImpl.body.children[0].children[0];
  fieldNode.value = "Grace";
  fieldNode.dispatch("input", { isComposing: true, inputType: "insertText" });
  assert.deepEqual(captured[0].payload, { value: "Grace", is_composing: true, input_type: "insertText" });
  assert.equal(captured[0].node_id, "bx-field");
  assert.equal(Object.hasOwn(captured[0], "nativeEvent"), false);
});

test("normalizes focus, blur, change, and action events in listener order", () => {
  const documentImpl = new FakeDocument();
  const captured = [];
  const renderer = new FixtureDOMRenderer({ target: documentImpl.body, documentImpl, generation: 1, onEvent: (event) => captured.push(event) });
  renderer.apply(effect([
    op("root.mount", { id: "bx-fixture-root", test_id: "bx-test-root" }),
    op("node.upsert", { id: "bx-field", parent_id: "bx-fixture-root", kind: "field" }),
    op("node.upsert", { id: "bx-action", parent_id: "bx-fixture-root", kind: "action", text: "Apply" }),
    op("listener.bind", { id: "bx-field", event: "focus" }),
    op("listener.bind", { id: "bx-field", event: "change" }),
    op("listener.bind", { id: "bx-field", event: "blur" }),
    op("listener.bind", { id: "bx-action", event: "action" }),
  ]));
  const [field, action] = documentImpl.body.children[0].children;
  field.dispatch("focus");
  field.value = "Ada";
  field.dispatch("change", { inputType: "unknown", isComposing: false });
  field.dispatch("blur", { relatedTarget: action });
  action.dispatch("click", { detail: 1 });
  assert.deepEqual(captured.map(({ event }) => event), ["focus", "change", "blur", "action"]);
  assert.deepEqual(captured.map(({ sequence }) => sequence), [1, 2, 3, 4]);
});

test("rejects unknown operations, arbitrary kinds, undeclared fields, and stale generations", () => {
  assert.throws(() => validateFixtureOperation(op("html.inject", { id: "bx-field", html: "<script>" })), { code: "fixture-operation-unknown" });
  assert.throws(() => validateFixtureOperation(op("node.upsert", { id: "bx-field", parent_id: "bx-fixture-root", kind: "iframe" })), { code: "fixture-node-kind-forbidden" });
  assert.throws(() => validateFixtureOperation(op("node.text", { id: "bx-field", text: "x", style: "display:none" })), { code: "fixture-operation-key-forbidden" });
  const { renderer } = mounted();
  assert.throws(() => renderer.apply(effect([], 2, 2)), { code: "fixture-generation-stale" });
});

test("rejects missing targets, duplicate listeners, oversized values, and stale sequence", () => {
  const { renderer } = mounted();
  assert.throws(() => renderer.apply(effect([op("node.text", { id: "bx-missing", text: "x" })], 2)), { code: "fixture-target-missing" });
  assert.throws(() => renderer.apply(effect([op("listener.bind", { id: "bx-field", event: "input" })], 2)), { code: "fixture-listener-duplicate" });
  assert.throws(() => renderer.apply(effect([op("node.property", { id: "bx-field", name: "value", value: "x".repeat(2_049) })], 2)), { code: "fixture-value-exceeded" });
  assert.throws(() => renderer.apply(effect([], 1)), { code: "fixture-sequence-stale" });
});

test("preflights a whole batch before mutation and supports bounded no-op and burst updates", () => {
  const { renderer } = mounted();
  const before = renderer.snapshot();
  assert.throws(() => renderer.apply(effect([
    op("node.text", { id: "bx-help", text: "must not commit" }),
    op("node.remove", { id: "bx-help" }),
    op("node.text", { id: "bx-help", text: "detached" }),
  ], 2)), { code: "fixture-target-missing" });
  assert.equal(renderer.snapshot().nodes.find(({ id }) => id === "bx-help").text, "Enter a name");
  assert.equal(renderer.snapshot().sequence, before.sequence);

  const noOp = renderer.apply(effect([], 2));
  assert.equal(noOp.metrics.mutations, before.metrics.mutations);
  const burst = renderer.apply(effect([
    op("node.text", { id: "bx-help", text: "one" }),
    op("node.text", { id: "bx-help", text: "two" }),
    op("node.text", { id: "bx-help", text: "three" }),
  ], 3));
  assert.equal(burst.nodes.find(({ id }) => id === "bx-help").text, "three");
});

test("disposal removes roots/listeners and rejects post-disposal traffic idempotently", () => {
  const { renderer } = mounted();
  const disposed = renderer.dispose("test-complete");
  assert.equal(disposed.disposed, true);
  assert.equal(disposed.root_count, 0);
  assert.equal(disposed.listener_count, 0);
  assert.equal(renderer.dispose().root_count, 0);
  assert.throws(() => renderer.apply(effect([], 2)), { code: "fixture-renderer-disposed" });
});

test("adapter source has no generic mutation, selector, network, global, or code escape", async () => {
  const source = await readFile(new URL("../fixture-dom-renderer.js", import.meta.url), "utf8");
  for (const token of ["innerHTML", "outerHTML", "insertAdjacentHTML", "querySelector", ".style", "fetch(", "eval(", "Function(", "window.", "globalThis."]) {
    assert.equal(source.includes(token), false, token);
  }
  assert.equal(FixtureDOMError.prototype instanceof Error, true);
});
