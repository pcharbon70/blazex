import { BlazeXDOMDriver } from "../../../../packages/blazex_renderer_dom/js/dom-driver.js";
import { focus, listener, node, projection } from "../dom-demo.js";

const ROOT = "demo_text_field";
const ids = {
  root: "bx-100000000000000000000001",
  label: "bx-100000000000000000000002",
  field: "bx-100000000000000000000003",
  hint: "bx-100000000000000000000004",
};

export async function textFieldBatch() {
  const root = node({
    id: ids.root,
    tag: "section",
    attributes: { "data-bx-kind": "surface", role: "group", "aria-labelledby": ids.label },
    children: [
      node({ id: ids.label, tag: "span", text: "Display name", attributes: { "data-bx-kind": "text", role: "text" } }),
      node({
        id: ids.field,
        tag: "input",
        attributes: { "data-bx-kind": "field", type: "text", role: "textbox", "aria-labelledby": ids.label, "aria-describedby": ids.hint },
        listeners: [listener(ROOT, "change", "input", "field")],
        focus: focus(0, false),
        selection: { kind: "text_range", value: { anchor: 0, focus: 0, direction: "forward" } },
      }),
      node({ id: ids.hint, tag: "span", text: "Input is normalized into a semantic change event.", attributes: { "data-bx-kind": "text" } }),
    ],
  });
  return projection({ rootName: ROOT, root });
}

export async function mountTextField({ target, onEvent }) {
  const driver = new BlazeXDOMDriver({ target, documentImpl: document, onEvent });
  driver.apply(await textFieldBatch());
  return { dispose: () => driver.dispose() };
}
