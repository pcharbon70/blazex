import { BlazeXDOMDriver } from "./dom-driver.js";

const browser = new URL(location.href).searchParams.get("browser") ?? "unknown";
const id = (digit) => `bx-${digit.repeat(24)}`;
const portable = (value) => ({ type: "atom", value });
const identity = (generation = 1, path = []) => ({ root: portable("browser_conformance"), path: path.map(portable), generation });
const listener = (semantic, native, path, generation) => ({ semantic, native, owner: identity(generation), source: identity(generation, [path]) });

function node(values = {}) {
  return { version: 1, id: id("1"), tag: "section", text: null, attributes: { "data-bx-kind": "surface", role: "dialog", "aria-labelledby": id("2") }, listeners: [], focus: null, selection: null, children: [], ...values };
}

function batch(generation = 1, revision = 0, transition = "mount", label = "Name") {
  return {
    version: 1,
    owner: identity(generation),
    generation,
    revision,
    transition,
    root: node({ children: [
      node({ id: id("2"), tag: "span", text: label, attributes: { "data-bx-kind": "text" } }),
      node({ id: id("3"), tag: "input", attributes: { "data-bx-kind": "field", role: "textbox", "aria-labelledby": id("2") }, listeners: [listener("change", "input", "field", generation)], focus: { behavior: "target", order: 0, auto_focus: true, restore: "none", wrap: false }, selection: { kind: "text_range", value: { anchor: 0, focus: 0, direction: "forward" } } }),
      node({ id: id("4"), tag: "button", text: "Apply", attributes: { "data-bx-kind": "action", role: "button" }, listeners: [listener("activate", "click", "action", generation)], focus: { behavior: "target", order: 1, auto_focus: false, restore: "none", wrap: false } }),
    ] }),
    digest: "b".repeat(64),
  };
}

function check(condition, message) {
  if (!condition) throw new Error(message);
}

async function run() {
  const events = [];
  const target = document.getElementById("target");
  const driver = new BlazeXDOMDriver({ target, documentImpl: document, onEvent: (event) => events.push(event) });
  const mounted = driver.apply(batch());
  const [label, field, action] = target.children[0].children;
  check(mounted.node_count === 4 && mounted.listener_count === 2, "mount-counts");
  check(label.textContent === "Name" && field.getAttribute("aria-labelledby") === label.id, "semantic-accessibility");
  check(document.activeElement === field && field.selectionStart === 0 && field.selectionEnd === 0, "autofocus-selection");
  field.value = "Ada";
  field.dispatchEvent(new Event("input", { bubbles: true }));
  check(events.length === 1 && events[0].name === "change" && events[0].payload.value === "Ada", "event-normalization");
  action.focus();
  const updated = driver.apply(batch(1, 1, "update", "Updated"));
  check(updated.focused_node_id === id("4") && document.activeElement.id === id("4"), "focus-restoration");
  const acceptedRoot = target.children[0];
  let staleRejected = false;
  try { driver.apply(batch(1, 3, "update")); } catch (error) { staleRejected = error.code === "dom-update-stale"; }
  check(staleRejected && target.children[0] === acceptedRoot, "atomic-stale-rejection");
  const disposal = { ...batch(1, 1, "dispose"), root: null };
  check(driver.apply(disposal).root_count === 0, "dispose");
  check(driver.apply(disposal).listener_count === 0, "idempotent-dispose");
  return { browser, result: "passed", checks: ["mount", "semantic-accessibility", "autofocus-selection", "event-normalization", "focus-restoration", "atomic-stale-rejection", "dispose"] };
}

try {
  await fetch("/result", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(await run()) });
} catch (error) {
  await fetch("/result", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ browser, result: "failed", error: String(error?.stack ?? error) }) });
}
