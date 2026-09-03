import assert from "node:assert/strict";
import test from "node:test";

import { __bh01BoundaryProbe } from "../src/index.js";

test("the experimental bridge boundary remains narrow", () => {
  assert.deepEqual(__bh01BoundaryProbe, {
    scope: "browser-bridge-only",
    status: "experimental-skeleton",
  });
});
