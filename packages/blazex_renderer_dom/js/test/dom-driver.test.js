import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { BlazeXDOMDriver } from "../dom-driver.js";
import { DOMProtocolError, validateBatch } from "../dom-protocol.js";
import { FakeDocument } from "./fake-dom.js";

const id = (digit) => `bx-${digit.repeat(24)}`;
const portable = (value) => ({ type: "atom", value });
const identity = (root = "component", generation = 1, path = []) => ({ root: portable(root), path: path.map(portable), generation });
const focus = (auto = false, order = 0) => ({ behavior: "target", order, auto_focus: auto, restore: "none", wrap: false });
const selection = (anchor = 0, end = 0) => ({ kind: "text_range", value: { anchor, focus: end, direction: "forward" } });
const listener = (semantic, native, sourcePath, generation = 1) => ({ semantic, native, owner: identity("component", generation), source: identity("component", generation, [sourcePath]) });

function node(values = {}) {
  return {
    version: 1,
    id: id("1"),
    tag: "section",
    text: null,
    attributes: { "data-bx-kind": "surface", role: "dialog", "aria-labelledby": id("2") },
    listeners: [],
    focus: null,
    selection: null,
    children: [],
    ...values,
  };
}

function projection(generation = 1, revision = 0, transition = "mount", text = "Name") {
  return {
    version: 1,
    owner: identity("component", generation),
    generation,
    revision,
    transition,
    digest: "a".repeat(64),
    root: node({
      children: [
        node({ id: id("2"), tag: "span", text, attributes: { "data-bx-kind": "text" } }),
        node({
          id: id("3"),
          tag: "input",
          attributes: { "data-bx-kind": "field", role: "textbox", "aria-labelledby": id("2") },
          listeners: [listener("change", "input", "field", generation)],
          focus: focus(true),
          selection: selection(0, 0),
        }),
        node({
          id: id("4"),
          tag: "button",
          text: "Apply",
          attributes: { "data-bx-kind": "action", role: "button" },
          listeners: [listener("activate", "click", "action", generation)],
          focus: focus(false, 1),
        }),
      ],
    }),
  };
}

function mounted(onEvent = () => {}) {
  const documentImpl = new FakeDocument();
  const driver = new BlazeXDOMDriver({ target: documentImpl.body, documentImpl, onEvent });
  const view = driver.apply(projection());
  return { documentImpl, driver, view };
}

test("validates and atomically applies one closed full-root projection", () => {
  const { documentImpl, view } = mounted();
  assert.equal(view.root_count, 1);
  assert.equal(view.node_count, 4);
  assert.equal(view.listener_count, 2);
  assert.deepEqual(view.nodes.map(({ id: nodeId }) => nodeId), [id("1"), id("2"), id("3"), id("4")]);
  assert.equal(documentImpl.body.children[0].tagName, "SECTION");
  assert.equal(documentImpl.body.children[0].children[1].getAttribute("aria-labelledby"), id("2"));
});

test("normalizes bounded semantic events without retaining browser objects", () => {
  const events = [];
  const { documentImpl } = mounted((event) => events.push(event));
  const field = documentImpl.body.children[0].children[1];
  field.value = "Ada";
  field.dispatch("input", { secret: "must-not-escape" });
  assert.deepEqual(events[0].payload, { value: "Ada" });
  assert.equal(events[0].name, "change");
  assert.equal(events[0].sequence, 1);
  assert.equal(Object.hasOwn(events[0], "secret"), false);
});

test("applies autofocus, restores same-ID update focus, and controls text selection", () => {
  const { documentImpl, driver } = mounted();
  const root = documentImpl.body.children[0];
  const field = root.children[1];
  const action = root.children[2];
  assert.equal(documentImpl.activeElement, field);
  assert.equal(field.selectionStart, 0);
  action.focus();

  const view = driver.apply(projection(1, 1, "update", "Updated"));
  assert.equal(view.focused_node_id, id("4"));
  assert.equal(documentImpl.activeElement.id, id("4"));
});

test("rejects stale and malformed batches before mutating the accepted root", () => {
  const { documentImpl, driver } = mounted();
  const accepted = documentImpl.body.children[0];
  assert.throws(() => driver.apply(projection(1, 2, "update")), { code: "dom-update-stale" });
  assert.equal(documentImpl.body.children[0], accepted);

  const malformed = projection(1, 1, "update");
  malformed.root.children[0].tag = "script";
  assert.throws(() => driver.apply(malformed), { code: "dom-tag-forbidden" });
  assert.equal(documentImpl.body.children[0], accepted);
});

test("accepts next-generation replacement and disposes roots/listeners idempotently", () => {
  const { driver } = mounted();
  assert.equal(driver.apply(projection(2, 0, "replace")).generation, 2);
  const disposal = { ...projection(2, 0, "dispose"), root: null };
  const disposed = driver.apply(disposal);
  assert.equal(disposed.disposed, true);
  assert.equal(disposed.root_count, 0);
  assert.equal(disposed.listener_count, 0);
  assert.equal(driver.apply(disposal).root_count, 0);
  assert.throws(() => driver.apply({ ...disposal, generation: 3 }), { code: "dom-disposal-stale" });
});

test("rejects undeclared fields, attributes, mappings, relationships, and disposal roots", () => {
  assert.throws(() => validateBatch({ ...projection(), extra: true }), { code: "dom-batch-invalid" });
  const attribute = projection();
  attribute.root.attributes.style = "display:none";
  assert.throws(() => validateBatch(attribute), { code: "dom-attribute-forbidden" });
  const mapping = projection();
  mapping.root.children[2].listeners[0].native = "keydown";
  assert.throws(() => validateBatch(mapping), { code: "dom-listener-mapping-invalid" });
  const relationship = projection();
  relationship.root.attributes["aria-labelledby"] = id("9");
  assert.throws(() => validateBatch(relationship), { code: "dom-relationship-target-missing" });
  assert.throws(() => validateBatch(projection(1, 0, "dispose")), { code: "dom-dispose-root-forbidden" });
  assert.equal(DOMProtocolError.prototype instanceof Error, true);
});

test("driver source has no generic markup, selector, style, global, network, or code escape", async () => {
  const source = await readFile(new URL("../dom-driver.js", import.meta.url), "utf8");
  for (const token of ["innerHTML", "outerHTML", "insertAdjacentHTML", "querySelector", ".style", "fetch(", "eval(", "Function(", "window.", "globalThis."]) {
    assert.equal(source.includes(token), false, token);
  }
});
