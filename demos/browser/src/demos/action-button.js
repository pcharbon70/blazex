import { BlazeXDOMDriver } from "../../../../packages/blazex_renderer_dom/js/dom-driver.js";
import { focus, listener, node, projection } from "../dom-demo.js";

const ROOT = "demo_action_button";
const ids = {
  root: "bx-200000000000000000000001",
  label: "bx-200000000000000000000002",
  button: "bx-200000000000000000000003",
  status: "bx-200000000000000000000004",
};

export async function actionButtonBatch(revision = 0, count = 0) {
  const root = node({
    id: ids.root,
    tag: "section",
    attributes: { "data-bx-kind": "surface", role: "group", "aria-labelledby": ids.label },
    children: [
      node({ id: ids.label, tag: "span", text: "Primary action", attributes: { "data-bx-kind": "text", role: "text" } }),
      node({
        id: ids.button,
        tag: "button",
        text: "Activate control",
        attributes: { "data-bx-kind": "action", role: "button", "aria-describedby": ids.status },
        listeners: [listener(ROOT, "activate", "click", "button")],
        focus: focus(0, false),
      }),
      node({
        id: ids.status,
        tag: "span",
        text: count === 0 ? "Not activated yet." : `Activated ${count} ${count === 1 ? "time" : "times"}.`,
        attributes: { "data-bx-kind": "text", role: "status", "aria-live": "polite" },
      }),
    ],
  });
  return projection({ rootName: ROOT, revision, transition: revision === 0 ? "mount" : "update", root });
}

export async function mountActionButton({ target, onEvent }) {
  let count = 0;
  let revision = 0;
  const driver = new BlazeXDOMDriver({
    target,
    documentImpl: document,
    onEvent: (event) => {
      onEvent(event);
      count += 1;
      revision += 1;
      void actionButtonBatch(revision, count).then((batch) => driver.apply(batch));
    },
  });
  driver.apply(await actionButtonBatch());
  return { dispose: () => driver.dispose() };
}
