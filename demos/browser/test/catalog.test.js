import assert from "node:assert/strict";
import test from "node:test";

import { controlCatalog, filterCatalog } from "../src/catalog.js";

test("catalog exposes unique extensible control records", () => {
  assert.equal(controlCatalog.length, 2);
  assert.equal(new Set(controlCatalog.map(({ id }) => id)).size, controlCatalog.length);
  for (const control of controlCatalog) {
    assert.match(control.id, /^[a-z0-9]+(?:-[a-z0-9]+)*$/);
    assert.equal(typeof control.mount, "function");
    for (const field of ["title", "category", "phase", "status", "description"]) assert.ok(control[field]);
    assert.equal(Object.isFrozen(control), true);
  }
  assert.equal(Object.isFrozen(controlCatalog), true);
});

test("catalog filtering searches human-facing metadata", () => {
  assert.deepEqual(filterCatalog("input").map(({ id }) => id), ["text-field"]);
  assert.deepEqual(filterCatalog("actions").map(({ id }) => id), ["action-button"]);
  assert.equal(filterCatalog("phase 6").length, 2);
  assert.equal(filterCatalog("missing").length, 0);
});
