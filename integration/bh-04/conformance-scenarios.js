import { AtomicDOMRoots } from "../../js/blazex_runtime/src/atomic-dom.js";
import { decodeIntent } from "../../js/blazex_runtime/src/render-intent-data.js";
import { seal } from "../../js/blazex_runtime/src/render-transaction-v2.js";

const check = (ok, message) => { if (!ok) throw new Error(message); };
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const bridge = () => ({ request: async (_op, p) => ({ root_id: p.root_id, root_generation: p.root_generation }), metrics: () => ({}), stop() {} });
const id = element => element.id.match(/bx-[0-9a-f]{24}$/)?.[0] ?? null;
const relationships = new Set(["aria-labelledby", "aria-describedby", "aria-controls", "aria-owns", "aria-errormessage"]);

export function compareBindings(row) {
  if (!row.after) return true;
  const portable = value => [value.type, Array.isArray(value.value) ? value.value.map(portable) : String(value.value)];
  const identity = value => ["identity", portable(value.root), value.path.map(portable), String(value.generation)];
  const actual = row.after.nodes.flatMap(node => (decodeIntent(node.listeners) ?? []).map(binding =>
    ["binding", binding.semantic, identity(binding.owner), identity(binding.source)]));
  check(same(actual.map(JSON.stringify).sort(), row.headless_after.bindings.map(JSON.stringify).sort()), row.name + ": headless binding mismatch");
  return true;
}

export function observe(container) {
  return [...container.querySelectorAll("[id]")].map(element => ({
    id: id(element), tag: element.tagName.toLowerCase(),
    attributes: Object.fromEntries(element.getAttributeNames().sort().map(key => [key,
      key === "id" ? id(element) : relationships.has(key) ? element.getAttribute(key).split(" ").map(x => x.match(/bx-[0-9a-f]{24}$/)?.[0] ?? x).join(" ") : element.getAttribute(key)])),
    text: [...element.childNodes].filter(n => n.nodeType === 3).map(n => n.data).join("") || null,
    children: [...element.children].map(id),
    value: "value" in element ? element.value : null,
    disabled: "disabled" in element ? element.disabled : null,
    focused: element.ownerDocument.activeElement === element,
    selection: element.tagName === "INPUT" ? [element.selectionStart, element.selectionEnd, element.selectionDirection] : null,
  }));
}

export function compare(row, observed) {
  const expected = row.after?.nodes ?? [], oracle = row.headless_after;
  check(observed.length === expected.length, row.name + ": node count");
  check(new Set(observed.map(n => n.id)).size === observed.length, row.name + ": duplicate identity");
  check(same(observed.map(n => n.id), expected.map(n => n.id)), row.name + ": reading order");
  for (const semantic of oracle?.tree ?? []) {
    const node = observed.find(n => n.id === semantic.id);
    check(node && node.attributes["data-bx-kind"] === semantic.kind && node.text === semantic.text && same(node.children, semantic.children), row.name + ": headless semantic mismatch " + semantic.id);
  }
  for (const intent of oracle?.accessibility ?? []) {
    const node = observed.find(n => n.id === intent.id);
    for (const {name: key, value} of intent.attributes) check(node.attributes[key] === value, row.name + ": headless accessibility " + key);
  }
  for (const node of expected) {
    const actual = observed.find(n => n.id === node.id);
    check(actual.tag === node.tag && actual.text === node.text && same(actual.children, node.children), row.name + ": DOM projection mismatch");
    for (const {name, value} of node.attributes) check(actual.attributes[name] === value, row.name + ": attribute " + name);
    const focus = decodeIntent(node.focus);
    if (focus?.behavior === "target") check(actual.attributes.tabindex === String(focus.order), row.name + ": focus order");
    const allowed = new Set(node.attributes.map(cell => cell.name)); allowed.add("id");
    if (node.tag === "button") allowed.add("type");
    if (focus?.behavior === "target") allowed.add("tabindex");
    const selection = decodeIntent(node.selection);
    if (selection && selection.kind !== "none") allowed.add("data-bx-selection-kind");
    if (selection?.kind === "multiple") allowed.add("data-bx-selection-count");
    check(Object.keys(actual.attributes).every(key => allowed.has(key)), row.name + ": unexpected attribute");
    for (const key of relationships) if (actual.attributes[key]) for (const target of actual.attributes[key].split(" ")) check(observed.some(n => n.id === target), row.name + ": broken relationship");
  }
  return true;
}

export async function runConformanceScenarios(document, rows, accessibility) {
  const traces = [];
  for (let repeat = 0; repeat < 2; repeat++) for (const row of rows) {
    const container = document.createElement("div"); container.setAttribute("data-conformance", "active"); document.body.append(container);
    const roots = new AtomicDOMRoots({ scopeId: "conformance", createBridge: bridge });
    const handle = await roots.register("root"); await handle.mount({ targetId: "owned", tree: {} });
    let injected = false;
    const token = roots.attach(handle, { owner: row.transaction.owner, generation: 1, container,
      fault: (stage, operation) => { if (injected && stage === "before" && operation === 0) throw new Error("conformance fault"); } });
    try {
      if (row.setup) check((await roots.submit(token, row.setup)).state === "committed", "setup");
      const previous = new Map([...container.querySelectorAll("[id]")].map(e => [id(e), e]));
      let rollback = null;
      if (row.setup && row.transaction.operations.length) {
        const before = observe(container), beforeAccessibility = await accessibility();
        injected = true;
        rollback = await roots.submit(token, await seal({...row.transaction, transaction_id: "tx-" + "f".repeat(24)}));
        injected = false;
        check(rollback.state === "rolled-back" && same(before, observe(container)), row.name + ": failure continuity");
        check(beforeAccessibility === await accessibility(), row.name + ": failure accessibility continuity");
      }
      const ack = await roots.submit(token, row.transaction);
      check(ack.state === (row.after ? "committed" : "disposed"), row.name + ": acknowledgement");
      const observed = observe(container); compare(row, observed);
      if (row.name === "keyed-reorder") check([...container.querySelectorAll("[id]")].every(e => previous.get(id(e)) === e), "keyed identity");
      const ids = [...document.querySelectorAll("[id]")].map(e => e.id);
      check(new Set(ids).size === ids.length, "duplicate document ID");
      const ax = await accessibility();
      if (row.headless_after?.accessibility.length) {
        check(ax.includes("textbox") && ax.includes("Name"), row.name + ": accessible textbox/name");
        check(ax.includes("dialog"), row.name + ": accessible dialog");
      }
      let duplicate = null;
      if (row.after) {
        duplicate = await roots.submit(token, row.transaction);
        check(duplicate.state === "rejected" && same(observed, observe(container)), row.name + ": replay mutation");
        check(ax === await accessibility(), row.name + ": replay accessibility continuity");
      }
      await roots.lifecycle.shutdown();
      const cleanup = {...roots.snapshot(token), ...roots.resources(token)};
      check(container.childNodes.length === 0 && cleanup.nodes === 0 && cleanup.listeners === 0, row.name + ": cleanup");
      traces.push({ scenario: row.scenario_id, repeat, ack, rollback, duplicate, observed, accessibility: ax, cleanup, result: "passed" });
    } finally { await roots.lifecycle.shutdown(); container.remove(); }
  }
  return { result: "passed", support_state: "unsupported", scenarios: rows.length, repetitions: 2, traces };
}
