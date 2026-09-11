const encoder = new TextEncoder();

export const portable = (value, type = "atom") => ({ type, value });

export function identity(root, generation = 1, path = []) {
  return { root: portable(root), path: path.map((part) => portable(part)), generation };
}

export function node(values) {
  return {
    version: 1,
    id: values.id,
    tag: values.tag,
    text: values.text ?? null,
    attributes: values.attributes ?? {},
    listeners: values.listeners ?? [],
    focus: values.focus ?? null,
    selection: values.selection ?? null,
    children: values.children ?? [],
  };
}

export function listener(root, semantic, native, source, generation = 1) {
  return {
    semantic,
    native,
    owner: identity(root, generation),
    source: identity(root, generation, [source]),
  };
}

export function focus(order, autoFocus = false) {
  return { behavior: "target", order, auto_focus: autoFocus, restore: "none", wrap: false };
}

export async function projection({ rootName, generation = 1, revision = 0, transition = "mount", root }) {
  const digestSource = JSON.stringify({ rootName, generation, revision, transition, root });
  const digestBytes = await globalThis.crypto.subtle.digest("SHA-256", encoder.encode(digestSource));
  const digest = Array.from(new Uint8Array(digestBytes), (byte) => byte.toString(16).padStart(2, "0")).join("");
  return {
    version: 1,
    owner: identity(rootName, generation),
    generation,
    revision,
    transition,
    root,
    digest,
  };
}
