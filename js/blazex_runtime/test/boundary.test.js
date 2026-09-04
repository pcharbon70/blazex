import assert from "node:assert/strict";
import test from "node:test";

import { __bh01BoundaryProbe } from "../src/index.js";

test("the experimental bridge boundary remains narrow", () => {
  assert.deepEqual(__bh01BoundaryProbe, {
    scope: "browser-host-loader-only",
    status: "phase4-loader-experimental",
  });
});

test("the loader source owns no component or server behavior", async () => {
  const { readFile } = await import("node:fs/promises");
  const source = await Promise.all([
    "../src/manifest-loader.js",
    "../src/runtime-frame-port.js",
    "../src/runtime-loader.js",
  ].map((path) => readFile(new URL(path, import.meta.url), "utf8")));
  const joined = source.join("\n");
  for (const forbidden of ["innerHTML", "LiveView", "Phoenix.Socket", "componentState", "eval("]) {
    assert.equal(joined.includes(forbidden), false, `loader contains forbidden ownership marker: ${forbidden}`);
  }
});
