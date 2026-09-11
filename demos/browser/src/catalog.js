import { mountActionButton } from "./demos/action-button.js";
import { mountTextField } from "./demos/text-field.js";

export const controlCatalog = Object.freeze([
  Object.freeze({
    id: "text-field",
    title: "Text field",
    category: "Input",
    phase: "BH-02 Phase 6",
    status: "Experimental",
    description: "A labelled text input that emits a bounded semantic change event without retaining the browser event object.",
    mount: mountTextField,
  }),
  Object.freeze({
    id: "action-button",
    title: "Action button",
    category: "Actions",
    phase: "BH-02 Phase 6",
    status: "Experimental",
    description: "A semantic action that updates through a new full-root projection while preserving focus on the stable control identity.",
    mount: mountActionButton,
  }),
]);

export function filterCatalog(query) {
  const normalized = query.trim().toLocaleLowerCase();
  if (!normalized) return controlCatalog;
  return controlCatalog.filter((control) => [control.title, control.category, control.phase, control.status, control.description]
    .some((value) => value.toLocaleLowerCase().includes(normalized)));
}
