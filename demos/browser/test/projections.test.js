import assert from "node:assert/strict";
import test from "node:test";

import { validateBatch } from "../../../packages/blazex_renderer_dom/js/dom-protocol.js";
import { actionButtonBatch } from "../src/demos/action-button.js";
import { textFieldBatch } from "../src/demos/text-field.js";

test("text field demo is a valid Phase 6 DOM projection", async () => {
  const batch = await textFieldBatch();
  assert.equal(validateBatch(batch), batch);
  assert.equal(batch.root.children[1].listeners[0].semantic, "change");
  assert.equal(batch.root.children[1].attributes["aria-describedby"], batch.root.children[2].id);
});

test("action button demo supports valid consecutive projections", async () => {
  const mounted = await actionButtonBatch();
  const updated = await actionButtonBatch(1, 1);
  assert.equal(validateBatch(mounted), mounted);
  assert.equal(validateBatch(updated), updated);
  assert.equal(updated.transition, "update");
  assert.equal(updated.revision, 1);
  assert.equal(updated.root.children[2].text, "Activated 1 time.");
});
