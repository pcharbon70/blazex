import { decodeIntent } from "./render-intent-data.js";
const compatible = element => element?.tagName === "INPUT" && ["text", "search", "tel", "url", "password", ""].includes(element.type ?? "text") && typeof element.selectionStart === "number";
const eligible = element => {
  if (!element || element.disabled || element.hidden || element.getAttribute("aria-disabled") === "true") return false;
  for (let cursor = element; cursor?.nodeType === 1; cursor = cursor.parentNode) {
    if (cursor.hidden || cursor.getAttribute("hidden") !== null || cursor.getAttribute("aria-hidden") === "true") return false;
    const style = cursor.ownerDocument.defaultView?.getComputedStyle(cursor);
    if (style && (style.display === "none" || style.visibility === "hidden")) return false;
  }
  return true;
};
export function captureContinuity(container, nodes) {
  const active = container.ownerDocument.activeElement;
  return { active, owned: container.contains(active), id: [...nodes].find(([, element]) => element === active)?.[0] ?? null,
    ranges: new Map([...nodes].filter(([, e]) => compatible(e)).map(([id, e]) => [id, { element: e, start: e.selectionStart, end: e.selectionEnd, direction: e.selectionDirection }])) };
}
const range = (element, start, end, direction) => {
  if (!compatible(element)) return;
  const length = element.value.length, a = Math.min(start, end, length), b = Math.min(Math.max(start, end), length);
  if (element.selectionStart !== a || element.selectionEnd !== b || element.selectionDirection !== direction) element.setSelectionRange(a, b, direction);
};
export function restoreContinuity(container, nodes, previous, next, observation) {
  const old = new Map((previous?.nodes ?? []).map(node => [node.id, node])), current = new Map((next?.nodes ?? []).map(node => [node.id, node]));
  const document = container.ownerDocument;
  const mayFocus = observation.owned || observation.active === document.body || observation.active == null;
  let target = null;
  if (mayFocus) {
    const explicit = [...current.values()].filter(node => decodeIntent(node.focus)?.auto_focus && node.focus !== old.get(node.id)?.focus).sort((a,b) => decodeIntent(a.focus).order - decodeIntent(b.focus).order);
    target = explicit.map(n => nodes.get(n.id)).find(eligible) ?? null;
    if (!target && observation.owned && eligible(nodes.get(observation.id))) target = nodes.get(observation.id);
    if (!target && observation.owned) {
      let parent = old.get(observation.id)?.parent;
      while (parent != null) {
        const scope = old.get(parent), focus = decodeIntent(scope?.focus ?? null);
        if (focus?.behavior === "scope" && focus.restore === "previous" && current.has(parent)) {
          const within = node => { let p = node.parent; while (p != null && p !== parent) p = current.get(p)?.parent ?? null; return p === parent; };
          const candidates = [...current.values()].filter(n => within(n) && decodeIntent(n.focus)?.behavior === "target" && eligible(nodes.get(n.id))).sort((a,b) => decodeIntent(a.focus).order - decodeIntent(b.focus).order);
          const order = decodeIntent(old.get(observation.id)?.focus ?? null)?.order ?? 0;
          const candidate = candidates.find(n => decodeIntent(n.focus).order >= order) ?? (focus.wrap ? candidates[0] : null);
          target = candidate ? nodes.get(candidate.id) : (eligible(nodes.get(parent)) ? nodes.get(parent) : null); break;
        }
        parent = scope?.parent;
      }
    }
  }
  for (const node of current.values()) {
    const element = nodes.get(node.id), selected = decodeIntent(node.selection);
    const captured = observation.ranges.get(node.id);
    if (selected?.kind === "text_range" && node.selection !== old.get(node.id)?.selection) range(element, Number(selected.value.anchor), Number(selected.value.focus), selected.value.direction);
    else if (captured?.element === element) range(element, captured.start, captured.end, captured.direction);
  }
  if (target && document.activeElement !== target) target.focus({ preventScroll: true });
}
